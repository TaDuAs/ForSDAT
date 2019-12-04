classdef ForceDistanceCurveParser < handle & mfc.IDescriptor
    properties
        shouldFlipExtendSegments = false;
        metaPattern;
        dataPattern;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'shouldFlipExtendSegments'};
            defaultValues = {'shouldFlipExtendSegments', false};
        end
    end
    
    methods
        function this = ForceDistanceCurveParser(shouldFlipExtendSegments)
            import ForSDAT.Application.IO.FDCurveTextFileSettings;
            
            % ctor
            if exist('shouldFlipExtendSegments', 'var') && ~isempty(shouldFlipExtendSegments)
                this.shouldFlipExtendSegments = shouldFlipExtendSegments;
            end
            dataFileSettings = FDCurveTextFileSettings();
            
            metaPrefix = dataFileSettings.settingsPrefix;
            this.dataPattern = ['\n[^' metaPrefix ']+(' metaPrefix '|$)'];
            
            metaProperties = {dataFileSettings.springConstant,...
                dataFileSettings.sensitivity,...
                dataFileSettings.segmentName,...
                dataFileSettings.segmentIndex,...
                dataFileSettings.columns,...
                ...dataFileSettings.extendDataLength,...
                ...dataFileSettings.retractDataLength,...
                dataFileSettings.xPosition,...
                dataFileSettings.yPosition,...
                dataFileSettings.fdcIndex};
            
            this.metaPattern = ['#\s*(?<key>(', strjoin(metaProperties, ')|('), ')):\s*(?<val>[^\r\n]+)'];
        end
        
        function fdc = parseJpkTextFile(this, fileName, wantedSegments)
            if nargin < 3
                wantedSegments = [];
            end
            
            % Read curve data
            rawData = fileread(fileName);
            
            % parse data
            fdc = this.parseJpkText(rawData, wantedSegments);
        end

        function fdc = parseJpkText(this, rawData, wantedSegments)
            import ForSDAT.Core.ForceDistanceCurve;
            import ForSDAT.Core.ForceDistanceSegment;
            fdc = ForceDistanceCurve();
            
            % Ensure any data was read from the file
            if nargin < 2 || isempty(rawData) || ~ischar(rawData)
                fdc = [];
                return;
            end
            
            % Find start and end indices of the data segments
            [segDataStartIdx, segDataEndIdx] = regexp(rawData, this.dataPattern);
            segDataEndIdx(rawData(segDataEndIdx) == '#') = segDataEndIdx(rawData(segDataEndIdx) == '#') - 1;

            [props, propIdx] = regexpi(rawData, this.metaPattern, 'names');
            
            % ascribe settings to segments
            if nargin < 3 || isempty(wantedSegments)
                wantedSegments = 1:length(segDataEndIdx);
            else
                wantedSegments = sort(intersect(wantedSegments, 1:length(segDataEndIdx)));
            end
            if isempty(wantedSegments) || wantedSegments(1) == 1
                prevSegmentEnd = 0;
            else
                prevSegmentEnd = segDataEndIdx(wantedSegments(1) - 1);
            end
            for i = wantedSegments
                dataFileSettings = ForSDAT.Application.IO.FDCurveTextFileSettings();
            
                segment = ForceDistanceSegment();
                fdc.segments(length(fdc.segments) + 1) = segment;
                
                % find the settings of the current segment
                settings = props(propIdx < segDataStartIdx(i) & propIdx >= prevSegmentEnd);
                
                for j = 1:length(settings)
                    param = settings(j);
                    extractDataFromSettings(this, dataFileSettings, segment, param);
                end
                               
                % remember last data end index
                prevSegmentEnd = segDataEndIdx(i);
                
                % parse data
                data = sscanf(rawData(segDataStartIdx(i):segDataEndIdx(i)), '%f', [dataFileSettings.nCols, inf])';
                if isempty(data)
                    continue;
                end
                
                % set relevant data to segment
                if this.shouldFlipExtendSegments && strcmp(segment.name, dataFileSettings.defaultExtendSegmentName)
                    segment.force = fliplr(data(:,dataFileSettings.forceColumnIndex)');
                    segment.distance = fliplr(data(:,dataFileSettings.distanceColumnIndex)');
                    segment.time = fliplr(data(:,dataFileSettings.timeColumnIndex)');
                else
                    segment.force = data(:,dataFileSettings.forceColumnIndex)';
                    segment.distance = data(:,dataFileSettings.distanceColumnIndex)';
                    segment.time = data(:,dataFileSettings.timeColumnIndex)';
                end
            end
        end
    end
    methods (Access=private)
        function extractDataFromSettings(this, dataFileSettings, segment, param)
            switch param.key
                case dataFileSettings.springConstant
                    segment.springConstant = str2double(param.val);
                case dataFileSettings.sensitivity
                    segment.sensitivity = str2double(param.val);
                case dataFileSettings.segmentName
                    segment.name = param.val;
                case dataFileSettings.segmentIndex
                    segment.index = str2double(param.val);
                case dataFileSettings.columns
                    columns = strsplit(param.val, ' ');
                    dataFileSettings.colHeaders = columns;
                    dataFileSettings.nCols = length(columns);
                    dataFileSettings.findForceColIndex(columns);
                    dataFileSettings.findDistanceColIndex(columns);
                    dataFileSettings.findTimeColIndex(columns);
%                 case this.dataFileSettings.extendDataLength
%                 case this.dataFileSettings.retractDataLength
                case dataFileSettings.xPosition
                    segment.xPosition = str2double(param.val);
                case dataFileSettings.yPosition
                    segment.yPosition = str2double(param.val);
                case dataFileSettings.fdcIndex
                    segment.curveIndex = str2double(param.val);
            end
        end
    end
    
end

