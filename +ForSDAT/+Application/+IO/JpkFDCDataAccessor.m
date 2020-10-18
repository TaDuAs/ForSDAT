classdef JpkFDCDataAccessor < dao.FileSystemDataAccessor & mfc.IDescriptor
    properties
        BinaryParser ForSDAT.Application.IO.IForceCurveParser = ForSDAT.Application.IO.JpkBinaryFDCParser.empty();
        TextParser ForSDAT.Application.IO.IForceCurveParser = ForSDAT.Application.IO.ForceDistanceCurveParser.empty();
        WantedSegments;
        ShouldFlipExtendSegments (1,1) logical = false;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'WantedSegments', '%ErrorHandler', 'Exporter'};
            defaultValues = {...
                'WantedSegments', [],...
                'Exporter', dao.DelimiterValuesDataExporter.empty()};
        end
    end
    
    methods
        function this = JpkFDCDataAccessor(wantedSegments, errHandler, exporter, queueFactory)
            if nargin < 5; queueFactory = dao.SimpleDataQueueFactory.empty(); end

            this@dao.FileSystemDataAccessor(errHandler, exporter, queueFactory);

            this.BinaryParser = ForSDAT.Application.IO.JpkBinaryFDCParser();
            this.TextParser = ForSDAT.Application.IO.ForceDistanceCurveParser();
            this.WantedSegments = wantedSegments;
        end
        
        function item = load(this, path)
            [~, ~, fileType] = fileparts(path);
            
            if ismember(fileType(2:end), this.BinaryParser.supportedFileTypes)
                item = this.BinaryParser.parse(fullfile(this.BatchPath, path), this.WantedSegments, this.ShouldFlipExtendSegments);
            else
                item = this.TextParser.parse(fullfile(this.BatchPath, path), this.WantedSegments, this.ShouldFlipExtendSegments);
            end
        end
        
        function filter = fileTypeFilter(this)
            supportedFileTypes = [...
                cellstr(this.TextParser.supportedFileTypes()),...
                cellstr(this.BinaryParser.supportedFileTypes())];
            filter = strcat('*.', supportedFileTypes);
        end
    end
end

