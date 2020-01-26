classdef ForceSpecAnalysisController < appd.AppController
    %ForceSpecAnalysisController exposes the API for running a data
    % analysis
    properties (SetObservable)
        settings;
        rawAnalyzer ForSDAT.Core.RawDataAnalyzer;
        dataAccessor;
        analyzedSegment;
        processingProgressListener;
        progressbar;
        serializer mxml.ISerializer = mxml.XmlSerializer.empty();
    end

    properties (Dependent)
        cookedAnalyzer;
    end
    
    methods % property accessors
        function this = set.settings(this, obj)
            this.App.persistenceContainer.set([class(this), '_Settings'], obj);
            this.initCookedAnalyzer();
            this.initRawAnalyzer();
        end
        function obj = get.settings(this)
            obj = this.App.persistenceContainer.get([class(this), '_Settings']);
        end
        function setSettings(this, settingsFilePath)
            if nargin < 2
                settingsFilePath = [];
            end
            this.settings = this.loadSettings(settingsFilePath);
        end
        
        function this = set.rawAnalyzer(this, obj)
            this.App.persistenceContainer.set([class(this), '_RawAnalyzer'], obj);
            this.initRawAnalyzer(obj);
        end
        function obj = get.rawAnalyzer(this)
            obj = this.App.persistenceContainer.get([class(this), '_RawAnalyzer']);
        end
        function setRawAnalyzer(this, settingsFilePath)
            if isa(settingsFilePath, 'RawDataAnalyzer')
                curveAnalyzer = settingsFilePath;
            else
                curveAnalyzer = Simple.IO.MXML.load(settingsFilePath);
            end
            
            if isempty(curveAnalyzer) || ~isa(curveAnalyzer, 'RawDataAnalyzer')
                error('Force-Spectroscopy analysis should be performed by a RawDataAnalyzer');
            end
            this.rawAnalyzer = curveAnalyzer;
        end
        
        function this = set.cookedAnalyzer(this, obj)
            this.App.persistenceContainer.set([class(this), '_CookedAnalyzer'], obj);
            this.initCookedAnalyzer(obj);
        end
        function obj = get.cookedAnalyzer(this)
            obj = this.App.persistenceContainer.get([class(this), '_CookedAnalyzer']);
        end
        function setCookedAnalyzer(this, settingsFilePath)
            if isa(settingsFilePath, 'CookedDataAnalyzer')
                analyzer = settingsFilePath;
            else
                analyzer = Simple.IO.MXML.load(settingsFilePath);
            end
            
            if isempty(analyzer) || ~isa(analyzer, 'CookedDataAnalyzer')
                error('Force-Spectroscopy final analysis should be performed by a CookedDataAnalyzer');
            end
            this.cookedAnalyzer = analyzer;
        end
        
        function this = set.dataAccessor(this, obj)
            this.App.persistenceContainer.set([class(this), '_DataAccessor'], obj);
            this.initCookedAnalyzer();
        end
        function obj = get.dataAccessor(this)
            obj = this.App.persistenceContainer.get([class(this), '_DataAccessor']);
        end
        function setDataAccessor(this, settingsFilePath)
            if isa(settingsFilePath, 'Simple.DataAccess.DataAccessor')
                this.dataAccessor = settingsFilePath;
            else
                this.dataAccessor = Simple.IO.MXML.load(settingsFilePath);
            end
        end
        
        function this = set.analyzedSegment(this, value)
            this.App.persistenceContainer.set([class(this), '_AnalyzedSegment'], value);
        end
        function obj = get.analyzedSegment(this)
            obj = this.App.persistenceContainer.get([class(this), '_AnalyzedSegment']);
        end
        function setAnalyzedSegment(this, seg)
            this.analyzedSegment = seg;
        end
    end
    
    methods % ctor
        function this = ForceSpecAnalysisController(serializer)
            this.serializer = serializer;
        end
    end
    
    methods (Access=private)
        function initCookedAnalyzer(this, obj)
            if nargin < 2
                obj = this.cookedAnalyzer;
            end
            if ~isempty(obj)
            	obj.init(this.App.persistenceContainer, this.dataAccessor, this.settings);
            end
        end
        
        function initRawAnalyzer(this, obj)
            if nargin < 2
                obj = this.rawAnalyzer;
            end
            if ~isempty(obj) && ~isempty(this.settings)
            	obj.init(this.settings);
            end
        end
        
        function wf = buildWF(this)
            wf = ForSDAT.Application.Workflows.ForceSpecWF(...
                this.App.persistenceContainer,...
                this.rawAnalyzer,...
                this.cookedAnalyzer,...
                this.dataAccessor,...
                this.analyzedSegment);
        end

        function reportProgress(this, args)
            this.progressbar.reportProggress(args.progressReported);
        end
    end

    methods
        function [results, progress, workLeft] = getAnalysisReport(this)
            wf = this.buildWF();
            
            results = wf.getAcceptedResults();
            [progress, workLeft] = wf.getProgress();
        end

        function list = getCurvesList(this)
            wf = this.buildWF(); 

            list = wf.getCurvesList();
        end
        
        function data = analyzeCurve(this, curveFileName, plotTask)
            wf = this.buildWF();
            
            if nargin < 2
                curveFileName = [];
            end
            data = wf.analyzeCurve(curveFileName);
            
            message = appd.RelayMessage('ForSDAT.Client.FDC_Analyzed');
            this.App.messenger.send(message);
        end

        function [data, newCurveName] = acceptAndNext(this, plotTask)
            wf = this.buildWF();
            
            [data, newCurveName] = wf.acceptCurve();
            
            message.Type = 'ForSDAT.Client.FDC_Analyzed';
            this.App.messenger.send(message);
        end
        
        function plotLastAnalyzedCurve(this, plotTask, sp)
            if nargin < 3; sp = figure(1); end
            wf = this.buildWF();
            
            if nargin < 2
                wf.plotLastAnalyzedCurve(sp);
            elseif ~isempty(plotTask) && (ischar(plotTask) || isnumeric(plotTask) || isa(plotTask, 'lists.PipelineTask'))
                wf.plotLastAnalyzedCurve(sp, plotTask);
            end
        end
        
        function [data, newCurveName] = rejectAndNext(this, plotTask)
            wf = this.buildWF();
            
            [data, newCurveName] = wf.rejectCurve();

            message.Type = 'ForSDAT.Client.FDC_Analyzed';
            this.App.messenger.send(message);
        end

        function [data, newCurveName] = undoLastDecision(this, plotTask)
            wf = this.buildWF();

            [data, newCurveName] = wf.undo();
            
            message.Type = 'ForSDAT.Client.FDC_Analyzed';
            this.App.messenger.send(message);
        end
        
        function analyzeAutomatically(this)
            wf = this.buildWF();
            this.progressbar = Simple.UI.ConsoleProggressBar(['Analyzing Data Batch ' this.dataAccessor.batchPath ':'], wf.getQueueSize(), 10, true);
            this.processingProgressListener = addlistener(wf, 'ReportProgress',@(obj, args) this.reportProgress(args));
            wf.completeAnalysisAutomatically();
        end
        
        function [data, newCurveName] = autoDecideAndNext(this, plotTask)
            wf = this.buildWF();

            [data, newCurveName] = wf.makeDecision();
            
            message.Type = 'ForSDAT.Client.FDC_Analyzed';
            this.App.messenger.send(message);
        end
        
        function output = wrapUpAndAnalyze(this)
            output = this.cookedAnalyzer.wrapUpAndAnalyze();
        end
        
        function output  = runPreviouslyCookedAnalysis(this, path)
            this.cookedAnalyzer.loadPreviouslyProcessedDataOutput(path);
            output = this.wrapUpAndAnalyze();
        end
        
        function settings = loadSettings(this, settingsFile)
            if nargin > 1 && ~isempty(settingsFile)
                settings = Simple.IO.MXML.load(settingsFile);
            else
                % default settings
                
                settings = [];
                % Measurement setup
                settings.measurement.samplingRate = 2048;
                settings.measurement.speed = 0.8;
                settings.measurement.linker = Simple.Scientific.PEG(5000);
%                 PEG(5000 - Chemistry.Mw([Chemistry.Groups.COONHS, Chemistry.Groups.NHFmoc])); % PEG Mw = 5000Da - sidegroups Mw
                settings.measurement.molecule = Simple.Scientific.Peptide('YFF');
                settings.noiseAnomally = ForSDAT.Core.NoiseAnomally(...
                    2, ...
                    settings.measurement.speed, ....
                    settings.measurement.samplingRate);
            end
        end
    end
end

