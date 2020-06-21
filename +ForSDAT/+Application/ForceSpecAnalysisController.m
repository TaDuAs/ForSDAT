classdef ForceSpecAnalysisController < ForSDAT.Application.ProjectController
    %ForceSpecAnalysisController exposes the API for running a data
    % analysis
    properties (Dependent, SetObservable)
        AnalyzedSegment;
    end
    
    properties (Access=private)
        processingProgressListener;
        progressbar util.ConsoleProggressBar;
        serializer mxml.ISerializer = mxml.XmlSerializer.empty();
    end
    
    methods % property accessors
        function setSettings(this, settingsFilePath)
            if nargin < 2
                settingsFilePath = [];
            end
            if isStringScalar(settingsFilePath) || ischar(settingsFilePath)
                this.Project.Settings = this.loadSettings(settingsFilePath);
            else
                this.Project.Settings = settingsFilePath;
            end
        end
        
        function setRawAnalyzer(this, settingsFilePath)
            if isa(settingsFilePath, 'ForSDAT.Core.RawDataAnalyzer')
                curveAnalyzer = settingsFilePath;
            else
                curveAnalyzer = this.serializer.load(settingsFilePath);
            end
            
            if isempty(curveAnalyzer) || ~isa(curveAnalyzer, 'ForSDAT.Core.RawDataAnalyzer')
                error('Force-Spectroscopy analysis should be performed by a ForSDAT.Core.RawDataAnalyzer');
            end
            this.Project.RawAnalyzer = curveAnalyzer;
        end
        
        function setCookedAnalyzer(this, settingsFilePath)
            if isa(settingsFilePath, 'ForSDAT.Application.Workflows.CookedDataAnalyzer')
                analyzer = settingsFilePath;
            else
                analyzer = this.serializer.load(settingsFilePath);
            end
            
            if isempty(analyzer) || ~isa(analyzer, 'ForSDAT.Application.Workflows.CookedDataAnalyzer')
                error('Force-Spectroscopy final analysis should be performed by a ForSDAT.Application.Workflows.CookedDataAnalyzer');
            end
            this.Project.CookedAnalyzer = analyzer;
        end
        
        function setDataAccessor(this, settingsFilePath)
            if isa(settingsFilePath, 'dao.DataAccessor')
                this.Project.DataAccessor = settingsFilePath;
            else
                this.Project.DataAccessor = this.serializer.load(settingsFilePath);
            end
        end
        
        function set.AnalyzedSegment(this, value)
            this.App.Context.set([class(this), '_AnalyzedSegment'], value);
        end
        function obj = get.AnalyzedSegment(this)
            obj = this.App.Context.get([class(this), '_AnalyzedSegment']);
        end
        function setAnalyzedSegment(this, seg)
            this.AnalyzedSegment = seg;
        end
    end
    
    methods % ctor
        function this = ForceSpecAnalysisController(serializer)
            this.serializer = serializer;
        end
    end
    
    methods (Access=private)
        function wf = buildWF(this)
            wf = ForSDAT.Application.Workflows.ForceSpecWF(...
                this.App.Context,...
                this.Project.RawAnalyzer,...
                this.Project.CookedAnalyzer,...
                this.Project.DataAccessor,...
                this.AnalyzedSegment);
        end
        
        function reportProgress(this, args)
            this.progressbar.reportProggress(args.progressReported);
        end
    end

    methods % Analysis control
        function start(this)
            wf = this.buildWF();
            wf.start();
        end
        
        function [results, progress, workLeft] = getAnalysisReport(this)
            wf = this.buildWF();
            
            results = wf.getAcceptedResults();
            [progress, workLeft] = wf.getProgress();
        end

        function list = getCurvesList(this)
            wf = this.buildWF(); 

            list = wf.getCurvesList();
        end
        
        function [data, curveName] = analyzeCurve(this, curveFileName, plotTask)
            wf = this.buildWF();
            
            if nargin < 2
                curveFileName = [];
            end
            [data, curveName] = wf.analyzeCurve(curveFileName);
            
            this.App.Messenger.send('ForSDAT.Client.FDC_Analyzed');
        end

        function [data, newCurveName] = acceptAndNext(this, plotTask)
            wf = this.buildWF();
            
            [data, newCurveName] = wf.acceptCurve();
            
            this.App.Messenger.send('ForSDAT.Client.FDC_Analyzed');
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

            this.App.Messenger.send('ForSDAT.Client.FDC_Analyzed');
        end

        function [data, newCurveName] = undoLastDecision(this, plotTask)
            wf = this.buildWF();

            [data, newCurveName] = wf.undo();
            
            this.App.Messenger.send('ForSDAT.Client.FDC_Analyzed');
        end
        
        function analyzeAutomatically(this)
            wf = this.buildWF();
            this.progressbar = util.ConsoleProggressBar(['Analyzing Data Batch ' this.Project.DataAccessor.BatchPath ':'], wf.getQueueSize(), 10, true);
            this.processingProgressListener = addlistener(wf, 'ReportProgress',@(obj, args) this.reportProgress(args));
            wf.completeAnalysisAutomatically();
        end
        
        function [data, newCurveName] = autoDecideAndNext(this, plotTask)
            wf = this.buildWF();

            [data, newCurveName] = wf.makeDecision();
            
            this.App.Messenger.send('ForSDAT.Client.FDC_Analyzed');
        end
        
        function tf = discloseDecision(this)
            wf = this.buildWF();
            
            tf = wf.discloseDecision();
        end
        
        function output = wrapUpAndAnalyze(this)
            output = this.Project.CookedAnalyzer.wrapUpAndAnalyze();
        end
        
        function output  = runPreviouslyCookedAnalysis(this, path)
            experimentId = this.Project.CookedAnalyzer.loadPreviouslyProcessedDataOutput(path);
            this.Project.RunningExperimentId = experimentId;
            output = this.wrapUpAndAnalyze();
        end
        
        function loadExperimentRepository(this, path)
            this.Project.CookedAnalyzer.importExperimentsRepository(path);
        end
        
        function settings = loadSettings(this, settingsFile)
            if nargin > 1 && ~isempty(settingsFile)
                settings = this.serializer.load(settingsFile);
            else
                % default settings
                
                settings = [];
                % Measurement setup
                settings.measurement.samplingRate = 2048;
                settings.measurement.speed = 0.8;
                settings.measurement.linker = chemo.PEG(5000);
%                 PEG(5000 - Chemistry.Mw([Chemistry.Groups.COONHS, Chemistry.Groups.NHFmoc])); % PEG Mw = 5000Da - sidegroups Mw
                settings.measurement.molecule = chemo.Peptide('YFF');
                settings.noiseAnomally = ForSDAT.Core.NoiseAnomally(...
                    2, ...
                    settings.measurement.speed, ....
                    settings.measurement.samplingRate);
            end
        end
    end
end

