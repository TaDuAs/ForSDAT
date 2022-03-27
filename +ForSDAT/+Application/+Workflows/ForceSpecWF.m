classdef ForceSpecWF < handle
    %FORCESPECWF Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess=protected, SetAccess=private)
        context;
        rawAnalyzer;
        dataAccessor;
        dataQueue;
        cookedAnalyzer;
        segment;
    end
    
    events
        ReportProgress;
        ProgressResetting;
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
        function this = ForceSpecWF(context, rawAnalyzer, cookedAnalyzer, dataAccessor, segment)
            this.context = context;
            this.rawAnalyzer = rawAnalyzer;
            this.cookedAnalyzer = cookedAnalyzer;
            this.dataAccessor = dataAccessor;
            this.segment = segment; 
        end
    end
    
    methods % API Methods

        function resetPermit = start(this)
            
            % notify before reseting the progress on an active process
            resetPermit = this.notifyBeforeResetProgess();
            
            % stop if reset permit was not granted
            if ~resetPermit
                return;
            end
            
            this.clearDataQueue();
            
            % prepare batch info
            batchInfo = ForSDAT.Application.Models.BatchInfo();
            batchInfo.N = this.getQueueSize();
            batchInfo.Path = this.dataAccessor.BatchPath;
            
            this.cookedAnalyzer.startFresh(batchInfo);
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
        
        function [data, curveName] = getCurrentCurveAnalysis(this, curveName)
            % Gets the analysis of the current curve in the queue from
            % cache, or analyzes it, if it's not there.
            % getCurrentCurveAnalysis(this)
            %   uses the current curve in the queue
            % getCurrentCurveAnalysis(this, curveName)
            %   jumps to the specified curveName in the queue if necessary
            
            if nargin < 2; curveName = []; end
            
            % Get current curve
            [~, curveName] = this.getCurveFromQueue(curveName);
            
            % Get current curve analysis from cache
            [data, lastAnalyzedItemKey] = this.getLastAnalyzedItem();
            
            % Check if the current curve mathces the current analysis from
            % cache
            if isempty(data) || ~strcmp(lastAnalyzedItemKey, curveName)
                % If not, analyze the curve (the new curve is now the
                % current curve since we moved the queue to the position of
                % the curve matching curveName
                data = this.analyzeCurve();
            end
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
            
            if isempty(curveName)
                data = [];
            else
                % Analyze the curve
                data = this.doAnalyzeCurve(curveName, fdc);
            end
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
            % rejectCurve() - Rejects the current curve in the queue and
            %       analyzes the next one
            % rejectCurve(curveName) - Jumps to the specified curve in the
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
            [fdcNext, curveNameNext] = this.dataQueue.previous();
            if ~isempty(fdcNext)
                fdc = fdcNext;
                curveName = curveNameNext;
            else
                % if previous curve is empty, this is the first curve in
                % the batch. take it from the queue again.
                [fdc, curveName] = this.dataQueue.peak();
            end
            
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
        
        function tf = discloseDecision(this)
            % Determines if the current curve should be accepted or
            % rejected
            
            % No need to analyze the current curve again if already did
            data = this.getCurrentCurveAnalysis();
            
            tf = this.cookedAnalyzer.examineCurveAnalysisResults(data);
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
        
        function raiseReportProgress(this, progressReported, itemsProcessed, itemsRemaining)
            notify(this, 'ReportProgress', util.ProcessProgressED(progressReported, itemsProcessed, itemsRemaining));
        end
    end
    
    methods (Access=protected)

        function tf = isProjectActive(this)
            repKey = [class(this) '_dataQueue'];
            
            % if there is NO data queue in context, the analysis did not
            % start - return false
            if ~this.context.hasEntry(repKey)
                tf = false;
                return;
            end
            
            % if the data queue in context does not match the current data
            % accessor object - i.e. an old and irrelevant data queue, it
            % is the same as having no data queue at all. The analysis did
            % not start - return false
            queue = this.context.get(repKey);
            if ~queue.DataLoader.equals(this.dataAccessor)
                tf = false;
                return;
            end
            
            % if no curves were analyzed already, the process did not
            % start - return false
            nCurvesAnalyzed = queue.progress();
            if nCurvesAnalyzed == 0
                tf = false;
                return;
            end
            
            % if reached this line, then the analysis process started
            % already - return true
            tf = true;
        end
        
        function queue = getDataQueue(this)
            repKey = [class(this) '_dataQueue'];
            if ~this.context.hasEntry(repKey)
                queue = this.dataAccessor.loadQueue();
                this.context.set(repKey, queue);
            else
                queue = this.context.get(repKey);
                if ~queue.DataLoader.equals(this.dataAccessor)
                    queue = this.dataAccessor.loadQueue();
                    this.context.set(repKey, queue);
                end
            end
        end
        
        function clearDataQueue(this)
            repKey = [class(this) '_dataQueue'];
            if this.context.hasEntry(repKey)
                this.context.removeEntry(repKey);
            end
        end
        
        function [data, key] = getLastAnalyzedItem(this)
            repkey = this.getLastAnalyzedItemContainerKey();
            if this.context.hasEntry(repkey)
                item = this.context.get(this.getLastAnalyzedItemContainerKey());
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
            this.context.set(this.getLastAnalyzedItemContainerKey(), item);
        end
        
        function resetPermit = notifyBeforeResetProgess(this)
            resetPermit = true;
            
            if this.isProjectActive()
                % raise project active message
                e = gen.CancelEventData();
                this.notify('ProgressResetting', e);
                
                if e.Cancel
                    resetPermit = false;
                end
            end
        end
    end
    
    
    methods (Access=private)
        function repkey = getLastAnalyzedItemContainerKey(this)
            repkey = [class(this) '_LastAnalyzedItem'];
        end
    end
end

