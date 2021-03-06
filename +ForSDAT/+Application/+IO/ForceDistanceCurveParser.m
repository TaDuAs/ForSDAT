classdef ForceDistanceCurveParser < ForSDAT.Application.IO.IForceCurveParser
    properties (Access=private)
        MetaPattern;
        DataPattern;
    end
    
    methods
        function this = ForceDistanceCurveParser()
            dataFileSettings = ForSDAT.Application.IO.FDCurveTextFileSettings();
            
            metaPrefix = dataFileSettings.settingsPrefix;
            this.DataPattern = ['\n[^' metaPrefix ']+(' metaPrefix '|$)'];
            
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
            
            this.MetaPattern = ['#\s*(?<key>(', strjoin(metaProperties, ')|('), ')):\s*(?<val>[^\r\n]+)'];
        end
        
        function fdc = parseJpkTextFile(this, fileName, wantedSegments, flipExtendSegments)
            if nargin < 3; wantedSegments = []; end
            if nargin < 4; flipExtendSegments = false; end
            
            fdc = this.parse(fileName, wantedSegments, flipExtendSegments);
        end
        
        function fdc = parse(this, fileName, wantedSegments, flipExtendSegments)
            if nargin < 3; wantedSegments = []; end
            if nargin < 4; flipExtendSegments = false; end
            
            % Read curve data
            rawData = fileread(fileName);
            
            % parse data
            fdc = this.parseJpkText(rawData, wantedSegments, flipExtendSegments);
        end

        function fdc = parseJpkText(this, rawData, wantedSegments, flipExtendSegments)
            if nargin < 3; wantedSegments = []; end
            if nargin < 4; flipExtendSegments = false; end
            
            fdc = ForSDAT.Core.ForceDistanceCurve();
            
            % Ensure any data was read from the file
            if nargin < 2 || isempty(rawData) || ~ischar(rawData)
                fdc = [];
                return;
            end
            
            % Find start and end indices of the data segments
            [segDataStartIdx, segDataEndIdx] = regexp(rawData, this.DataPattern);
            segDataEndIdx(rawData(segDataEndIdx) == '#') = segDataEndIdx(rawData(segDataEndIdx) == '#') - 1;

            [props, propIdx] = regexpi(rawData, this.MetaPattern, 'names');
            
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
            
                segment = ForSDAT.Core.ForceDistanceSegment();
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
                if flipExtendSegments && strcmp(segment.name, dataFileSettings.defaultExtendSegmentName)
                    if ~isempty(dataFileSettings.forceColumnIndex)
                        segment.force = fliplr(data(:,dataFileSettings.forceColumnIndex)');
                    end
                    if ~isempty(dataFileSettings.distanceColumnIndex)
                        segment.distance = fliplr(data(:,dataFileSettings.distanceColumnIndex)');
                    end
                    if ~isempty(dataFileSettings.timeColumnIndex)
                        segment.time = fliplr(data(:,dataFileSettings.timeColumnIndex)');
                    end
                else
                    if ~isempty(dataFileSettings.forceColumnIndex)
                        segment.force = data(:,dataFileSettings.forceColumnIndex)';
                    end
                    if ~isempty(dataFileSettings.distanceColumnIndex)
                        segment.distance = data(:,dataFileSettings.distanceColumnIndex)';
                    end
                    if ~isempty(dataFileSettings.timeColumnIndex)
                        segment.time = data(:,dataFileSettings.timeColumnIndex)';
                    end
                end
                
                nf = numel(segment.force);
                nt = numel(segment.time);
                nd = numel(segment.distance);
                nDataPoints = max([nf, nd, nt]);
                if nf < nDataPoints
                    segment.force = horzcat(segment.force, nan(nDataPoints - nf));
                end
                if nd < nDataPoints
                    segment.distance = horzcat(segment.distance, nan(1, nDataPoints - nd));
                end
                if nt < nDataPoints
                    segment.time = horzcat(segment.time, nan(nDataPoints - nt));
                end
            end
        end
        
        function fileType = supportedFileTypes(this)
            fileType = 'txt';
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

