classdef FDCurveTextFileSettings < handle
    properties (Constant)
        
        % File structure
        settingsPrefix = '#';
        settingsNameValueDelimiter = ':';
        dataRowDelimiter = newline;
        dataFieldDelimiter = sprintf(' ');
        metaDataPattern = '#\s*(?<name>.+):\s*(?<value>.+)\s*';
        
        % Metadata properties
        springConstant = 'springConstant';
        sensitivity = 'sensitivity';
        segmentName = 'segment';
        segmentIndex = 'segmentIndex';
        columns = 'columns';
        extendDataLength = 'force-settings.extend-k-length';
        retractDataLength = 'force-settings.retract-k-length';
        extendPauseDataLength = 'force-settings.extended-pause-k-length';
        retractPauseDataLength = 'force-settings.retracted-pause-k-length';
        xPosition = 'xPosition';
        yPosition = 'yPosition';
        fdcIndex = 'index';
        
        % Metadata property entries
        defaultExtendSegmentName = 'extend';
        defaultRetractSegmentName = 'retract';
        forceColumnName = {'vDeflection'}; % "Vertical Deflection"
        distanceColumnName = {'smoothedMeasuredHeight', 'smoothedCapacitiveSensorHeight', 'height'}; % "Head Height (Measured and Smoothed)"
        timeColumnName = {'seriesTime', 'time'};  % "Series Time"
        
    end
    
    properties
        % These default values don't mean anything in any possible scenario
        colHeaders = {};
        nCols = 9;
        forceColumnIndex = 2;
        distanceColumnIndex = 1;
        timeColumnIndex = 9;
    end
    
    methods
        function colIndex = findColIndex(this, colNamesInDataFile, colNamesOrderedByDesirability)
            for i = 1:length(colNamesOrderedByDesirability)
                desiredColName = colNamesOrderedByDesirability{i};
                idx = find(strcmp(colNamesInDataFile, desiredColName), 1, 'first');
                if ~isempty(idx)
                    colIndex = idx;
                    return;
                end
            end
            
            colIndex = [];
        end
        
        function findForceColIndex(this, columnNames)
            this.forceColumnIndex = findColIndex(this, columnNames, ForSDAT.Application.IO.FDCurveTextFileSettings.forceColumnName);
            
%             if isempty(this.forceColumnIndex)
%                 error('Force column doesn''t appear in data file');
%             end
        end
        
        function findDistanceColIndex(this, columnNames)
            this.distanceColumnIndex = findColIndex(this, columnNames, ForSDAT.Application.IO.FDCurveTextFileSettings.distanceColumnName);
            
%             if isempty(this.distanceColumnIndex)
%                 error('Distance column doesn''t appear in data file');
%             end
        end
        
        function findTimeColIndex(this, columnNames)
            this.timeColumnIndex = findColIndex(this, columnNames, ForSDAT.Application.IO.FDCurveTextFileSettings.timeColumnName);
            
%             if isempty(this.timeColumnIndex)
%                 error('Time column doesn''t appear in data file');
%             end
        end
    end
end