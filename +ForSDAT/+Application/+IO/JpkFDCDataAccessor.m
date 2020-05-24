classdef JpkFDCDataAccessor < dao.FileSystemDataAccessor & mfc.IDescriptor
    properties
        Parser;
        WantedSegments;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'WantedSegments', 'Parser', '%ErrorHandler', 'Exporter'};
            defaultValues = {...
                'WantedSegments', [],...
                'Parser', ForSDAT.Application.IO.ForceDistanceCurveParser.empty(),...
                'Exporter', dao.DelimiterValuesDataExporter.empty()};
        end
    end
    
    methods
        function this = JpkFDCDataAccessor(wantedSegments, parser, errHandler, exporter, queueFactory)
            if nargin < 5; queueFactory = dao.SimpleDataQueueFactory.empty(); end

            this@dao.FileSystemDataAccessor(errHandler, exporter, queueFactory);

            this.Parser = parser;
            this.WantedSegments = wantedSegments;
        end
        
        function item = load(this, path)
            item = this.Parser.parseJpkTextFile(fullfile(this.BatchPath, path), this.WantedSegments);
        end
        
        function filter = fileTypeFilter(this)
            filter = '*.txt';
        end
    end
end

