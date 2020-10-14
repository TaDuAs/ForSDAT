classdef (Abstract) IForceCurveParser < handle
    methods (Abstract)
        fdc = parse(this, filePath, wantedSegments);
        fileType = supportedFileTypes(this);
    end
end

