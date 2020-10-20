classdef JpkBinaryFDCParser < ForSDAT.Application.IO.IForceCurveParser
    
    methods
        function fdc = parse(this, filePath, wantedSegments, flipExtendSegments)
            if nargin < 3; wantedSegments = []; end
            if nargin < 4 || isempty(flipExtendSegments); flipExtendSegments = false; end
            dataFileSettings = ForSDAT.Application.IO.FDCurveTextFileSettings();
            
            % read wanted segments from file
            [segmentsCell, headers] = Fodis.IO.readJPK(filePath, wantedSegments);
            
            % prepare DTOs
            segments = ForSDAT.Core.ForceDistanceSegment();
            for i = size(segmentsCell, 1):-1:1
                currSegmentHeaders = headers(i);
                currSegment = ForSDAT.Core.ForceDistanceSegment();
                
                % get segment meta data
                currSegment.index = currSegmentHeaders.index;
                currSegment.name = currSegmentHeaders.name;
                currSegment.springConstant = currSegmentHeaders.springConstant;
                currSegment.sensitivity = currSegmentHeaders.sensitivity;
                currSegment.xPosition = currSegmentHeaders.xPosition;
                currSegment.yPosition = currSegmentHeaders.yPosition;
                currSegment.curveIndex = currSegmentHeaders.curveIndex;
                
                % get segment data
                if flipExtendSegments && strcmp(currSegment.name, dataFileSettings.defaultExtendSegmentName)
                    currSegment.force = fliplr(segmentsCell{i, 3});
                    currSegment.distance = fliplr(segmentsCell{i, 2});
                    currSegment.time = fliplr(segmentsCell{i, 1});
                else
                    currSegment.force = segmentsCell{i, 3};
                    currSegment.distance = segmentsCell{i, 2};
                    currSegment.time = segmentsCell{i, 1};
                end
                
                segments(i) = currSegment;
            end
            
            % ggenerate force distance curve
            fdc = ForSDAT.Core.ForceDistanceCurve(segments);
        end
        
        function fileType = supportedFileTypes(this)
            fileType = 'jpk-force';
        end
    end
end

