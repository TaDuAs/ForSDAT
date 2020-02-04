classdef ForceSpecWF < handle
    %FORCESPECWF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=protected, SetAccess=private)
        persistenceContainer;
        rawAnalyzer;
        dataAccessor;
        dataQueue;
        cookedAnalyzer;
        segment;
    end
    
    events
        ReportProgress;
    end
    
    methods % property accessors
        function queue = get.dataQueue(this)
            queue = this.getDataQueue();
        end
        
        function set.dataQueue(this, value)
            error('No setter available for dataQueue');
        end
    end
    
    methods % Ctors
        function this = ForceSpecWF(persistenceContainer, rawAnalyzer, cookedAnalyzer, dataAccessor, segment)
            this.persistenceContainer = persistenceContainer;
            this.rawAnalyzer = rawAnalyzer;
            this.cookedAnalyzer = cookedAnalyzer;
            this.dataAccessor = dataAccessor;
            this.segment = segment; 
        end
    end
    
    methods % API Methods

        function start(this)
            this.clearDataQueue();
        end
        
        function n = getQueueSize(this)
        % Gets the size of the data queue
            n = this.dataQueue.length();
        end
        function curveList = getCurvesList(this)
            % Gets a list of all curves in the data queue
            curveList = this.dataQueue.getDataNameList();
        end
        function [itemsProcessed, itemsRemaining] = getProgress(this)
            % 
            [itemsProcessed, itemsRemaining] = this.dataQueue.progress();
            
        end
        function results = getAcceptedResults(this)
            results = this.cookedAnalyzer.getAcceptedResults();
        end
        
        function [data, curveName] = analyzeCurve(this, curveName)
            % analyzeCurve() - Analyzes the current curve in the queue. Use
            %       this option when updating the analysis process pipeline
            % analyzeCurve(curveName) - Jumps to the specified curve and
            %       analyzes it. Use this option to change location in the
            %       data queue.
            if nargin < 2
                curveName = [];
            end
            
            % Get the curve from the queue
            [fdc, curveName] = this.getCurveFromQueue(curveName);
            
            % Analyze the curve
            data = this.doAnalyzeCurve(curveName, fdc);
        end
        
        function [data, curveName] = acceptCurve(this, curveName)
            % acceptCurve() - Accepts the current curve in the queue and
            %       analyzes the next one
            % acceptCurve(curveName) - Jumps to the specified curve in the
            %       queue, analyzes and accept it, and analyzes the next
            %       curve in the queue
            if nargin < 2
                curveName = [];
            end
            
            % No need to analyze again if we already did...
            [data, curveName] = this.getCurrentCurveAnalysis(curveName);
            
            % Save accepted data item for later analysis\plotting\whatever
            % if needed
            this.dataAccessor.acceptData(curveName);
            
            % Add to analyzed resultsSet
            this.cookedAnalyzer.acceptData(data, curveName);
            
            % Analyze the next curve
            [data, curveName] = this.next();
        end
        
        function [data, curveName] = rejectCurve(this, curveName)
            % acceptCurve() - Rejects the current curve in the queue and
            %       analyzes the next one
            % acceptCurve(curveName) - Jumps to the specified curve in the
            %       queue, rejects it, and analyzes the next curve in one
            if nargin < 2
                curveName = [];
            end
            
            % Get the curve from the queue
            [~, curveName] = this.getCurveFromQueue(curveName);
            
            % Save accepted data item for later analysis\plotting\whatever
            % if needed
            this.dataAccessor.rejectData(curveName);
            
            % Add to analyzed resultsSet
            this.cookedAnalyzer.rejectData(curveName);
            
            % Analyze the next curve
            [data, curveName] = this.next();
        end
        
        function [data, curveName] = undo(this)
            % undo() - undoes any decision made about the current curve and
            %       reanalyzes the previous one
            
            % Get current item from queue
            [~, curveName] = this.dataQueue.peak();

            % Revert decisions
            this.dataAccessor.revertDecision(curveName);
            this.cookedAnalyzer.revertDecision(curveName);

            % Get previous item
            [fdc, curveName] = this.dataQueue.previous();

            % Analyze it
            data = this.doAnalyzeCurve(curveName, fdc);
            
            % report progress
            [itemsProcessed, itemsRemaining] = this.dataQueue.progress();
            this.raiseReportProgress(0, itemsProcessed, itemsRemaining);
        end

        function [data, curveName] = next(this)
            % Get next item
            [fdc, curveName] = this.dataQueue.next();
            
            if ~this.dataQueue.isPending()
                data = [];
                curveName = '';
                return;
            end

            % Analyze it
            data = this.doAnalyzeCurve(curveName, fdc);
            
            % report progress
            [itemsProcessed, itemsRemaining] = this.dataQueue.progress();
            this.raiseReportProgress(1, itemsProcessed, itemsRemaining);
        end

        function completeAnalysisAutomatically(this)
            % fully automated data analysis of the current batch to the end
            % of it
            data = [];

            % iterates through all pending data items, analyzes and decides
            % whether to accept or reject them
            while this.dataQueue.isPending()
                if isempty(data)
                    data = this.analyzeCurve();
                end
                
                data = this.decideAndMoveOn(data);
            end
        end
        
        function [data, curveName] = makeDecision(this)
            % Decides whether to accept the current curve or reject it and
            % analyzes the next curve
            
            % No need to analyze the current curve again if already did
            data = this.getCurrentCurveAnalysis();
            
            % This private method is not directly exposed in the API to
            % prevent sending data from outside the WF layer for decision.
            % Data is only taken from the data queue and analyzed by the
            % WF's raw analyzer.
            [data, curveName] = this.decideAndMoveOn(data);
        end
        
        function plotLastAnalyzedCurve(this, fig, taskNameOrIndex)
            % Plots the last analyzed curve, if 
            if nargin < 3
                taskNameOrIndex = [];
            end
            data = this.getLastAnalyzedItem();
  
            % If didn't analyze yet, analyze now
            if isempty(data)
                data = this.analyzeCurve();
            end
            
            % If there are no curves to analyze, don't plot anything
            if isempty(data)
                return;
            end
            
            this.rawAnalyzer.plotData(fig, data, taskNameOrIndex);
        end
    end
    
    methods (Access=private)
        function [fdc, curveName] = getCurveFromQueue(this, curveName)
            if nargin >= 2 && ~isempty(curveName)
                % Get curve from queue by name/index
                fdc = this.dataQueue.jumpTo(curveName);
            else
                % Get current curve from queue
                [fdc, curveName] = this.dataQueue.peak();
            end
        end
        
        function data = doAnalyzeCurve(this, curveName, fdc)
            if isempty(fdc)
                data = [];
                return;
            end
            % Analyze the curve
            data = this.rawAnalyzer.analyze(fdc, this.segment);
            
            % Save as last analyzed item
            this.setLastAnalyzedItem(data, curveName);
        end
        
        function [data, curveName] = decideAndMoveOn(this, data)
            % decideAndMoveOn(this, data)
            %   decides whether to accept or reject the given analyzed data
            %   and analyzes the next curve
            
            if this.cookedAnalyzer.examineCurveAnalysisResults(data)
                [data, curveName] = this.acceptCurve();
            else
                [data, curveName] = this.rejectCurve();
            end
        end
        
        function [data, curveName] = getCurrentCurveAnalysis(this, curveName)
            % Gets the analysis of the current curve in the queue from
            % cache, or analyzes it, if it's not there.
            % getCurrentCurveAnalysis(this)
            %   uses the current curve in the queue
            % getCurrentCurveAnalysis(this, curveName)
            %   jumps to the specified curveName in the queue if necessary
            
            if nargin < 2; curveName = []; end;
            
            % Get current curve
            [fdc, curveName] = this.getCurveFromQueue(curveName);
            
            % Get current curve analysis from cache
            [data, lastAnalyzedItemKey] = this.getLastAnalyzedItem();
            
            % Check if the current curve mathces the current analysis from
            % cache
            if isempty(data) || ~strcmp(lastAnalyzedItemKey, curveName)
                % If not, analyze the curve
                data = this.analyzeCurve(fdc, curveName);
            end
        end
        
        function raiseReportProgress(this, progressReported, itemsProcessed, itemsRemaining)
            notify(this, 'ReportProgress', Simple.ProcessProgressED(progressReported, itemsProcessed, itemsRemaining));
        end
    end
    
    methods (Access=protected)

        function queue = getDataQueue(this)
            repKey = [class(this) '_dataQueue'];
            if ~this.persistenceContainer.hasEntry(repKey)
                queue = this.dataAccessor.loadQueue();
                this.persistenceContainer.set(repKey, queue);
            else
                queue = this.persistenceContainer.get(repKey);
                if ~queue.dataLoader.equals(this.dataAccessor)
                    queue = this.dataAccessor.loadQueue();
                    this.persistenceContainer.set(repKey, queue);
                end
            end
        end
        
        function clearDataQueue(this)
            repKey = [class(this) '_dataQueue'];
            if this.persistenceContainer.hasEntry(repKey)
                this.persistenceContainer.removeEntry(repKey);
            end
        end
        
        function [data, key] = getLastAnalyzedItem(this)
            repkey = this.getLastAnalyzedItemContainerKey();
            if this.persistenceContainer.hasEntry(repkey)
                item = this.persistenceContainer.get(this.getLastAnalyzedItemContainerKey());
                data = item.data;
                key = item.key;
            else
                data = [];
                key = [];
            end
        end
        
        function setLastAnalyzedItem(this, data, key)
            item.data = data;
            item.key = key;
            this.persistenceContainer.set(this.getLastAnalyzedItemContainerKey(), item);
        end
    end
    
    
    methods (Access=private)
        function repkey = getLastAnalyzedItemContainerKey(this)
            repkey = [class(this) '_LastAnalyzedItem'];
        end
    end
end

