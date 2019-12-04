classdef JpkFDCDataAccessor < Simple.DataAccess.FileSystemDataAccessor & mfc.IDescriptor
    properties
        parser;
        wantedSegments;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'%App', 'wantedSegments', 'parser', 'exporter', 'batchPath', 'processedResultsPath', 'errorLogPath'};
            defaultValues = {...
                'wantedSegments', [],...
                'parser', ForSDAT.Application.IO.ForceDistanceCurveParser.empty(),...
                'exporter', Simple.DataAccess.DelimiterValuesDataExporter.empty(),...
                'batchPath', '', ...
                'processedResultsPath', '',...
                'errorLogPath', ''};
        end
    end
    
    methods
        function this = JpkFDCDataAccessor(app, wantedSegments, parser, exporter, batchPath, processedResultsPath, errorLogPath)
            if (nargin < 5); processedResultsPath = []; end
            if (nargin < 6); errorLogPath = []; end

            this@Simple.DataAccess.FileSystemDataAccessor(app, exporter, batchPath, processedResultsPath, errorLogPath);

            this.parser = parser;
            this.wantedSegments = wantedSegments;
        end
        
        function item = load(this, path)
            item = this.parser.parseJpkTextFile(fullfile(this.batchPath, path), this.wantedSegments);
        end
        
        function filter = fileTypeFilter(this)
            filter = '*.txt';
        end
    end
end

