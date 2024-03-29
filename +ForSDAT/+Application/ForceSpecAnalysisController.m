classdef ForceSpecAnalysisController < ForSDAT.Application.ProjectController
    %ForceSpecAnalysisController exposes the API for running a data
    % analysis
    properties (Access=private)
        restorePointPath;
        processingProgressListener;
        progressbar util.ConsoleProggressBar;
        progressResetPermitListener event.listener;
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
                curveAnalyzer = this.Serializer.load(settingsFilePath);
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
                analyzer = this.Serializer.load(settingsFilePath);
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
                this.Project.DataAccessor = this.Serializer.load(settingsFilePath);
            end
        end
        function setAnalyzedSegment(this, seg)
            % only for backward compatibility for a massive amount of
            % scripts.
            this.Project.AnalyzedSegment = seg;
        end
    end
    
    methods % ctor
        function this = ForceSpecAnalysisController(serializer)
            this@ForSDAT.Application.ProjectController(serializer);
        end
    end
    
    methods % initialization
        function init(this, app)
            init@ForSDAT.Application.ProjectController(this, app);
            
            this.restorePointPath = fullfile(app.RootPath, 'Temp', 'projectResorePoint.forsdatRestoreXml');
        end
    end
    
    methods (Access=private)
        function wf = buildWF(this)
            wf = ForSDAT.Application.Workflows.ForceSpecWF(...
                this.App.Context,...
                this.Project.RawAnalyzer,...
                this.Project.CookedAnalyzer,...
                this.Project.DataAccessor,...
                this.Project.AnalyzedSegment);
            
            this.progressResetPermitListener = addlistener(wf, 'ProgressResetting', @this.raiseResetProgressNotification);
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
        
        function clearLastRestorePoint(this)
            delete(this.restorePointPath);
        end
        
        function resumeLastProcess(this)
            app = this.App.getApp();
            
            % check if restore point exists
            if ~exist(this.restorePointPath, 'file')
                return;
            end
            
            % get restore point
            restorePoint = this.Serializer.load(this.restorePointPath);
            
            % get permission to commit restore
            message = mvvm.RelayMessage(ForSDAT.Application.AppMessages.RestoreProcess, restorePoint);
            message.Result.flag = true;
            app.Messenger.send(message);
            
            % if there was an objection to project restoration
            if ~message.Result.flag
                this.clearLastRestorePoint();
                return;
            end
            
            % reload last unfinished process from app preferences
            this.setProject(restorePoint.Project);
            this.Project.CookedAnalyzer.restoreProcess(restorePoint.CookedAnalyzerRestorePoint);
%             this.AnalyzedSegment = restorePoint.AnalyzedSegment;
            
            % set the last edited curve
            wf = this.buildWF();
            wf.analyzeCurve(restorePoint.LastItemID);
            
            % clear restore point
            this.clearLastRestorePoint();
        end
        
        function saveAndContinueProcessLater(this)            
            % get id of current analyzed curve
            wf = this.buildWF();
            [~, currCurveName] = wf.getCurrentCurveAnalysis();
            
            % create project restoration point
            restorePoint = ForSDAT.Application.Models.ProjectRestorePoint();
            restorePoint.Project = this.Project;
            restorePoint.LastItemID = currCurveName;
            restorePoint.CookedAnalyzerRestorePoint = this.Project.CookedAnalyzer.createRestorePoint();
%             restorePoint.AnalyzedSegment = this.AnalyzedSegment;
            
            % save project restoration point in Application Preferences,
            % this will be automatically reloaded next time the app starts
            this.Serializer.save(restorePoint, this.restorePointPath);
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
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.FDC_Analyzed);
        end

        function [data, newCurveName] = acceptAndNext(this, plotTask)
            wf = this.buildWF();
            
            [data, newCurveName] = wf.acceptCurve();
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.FDC_Analyzed);
        end
        
        function plotLastAnalyzedCurve(this, plotTask, view)
            if nargin < 3
                view = figure(1); 
            end
            
            if nargin < 2 || isempty(plotTask)
                plotTask = this.Project.CurrentViewedTask;
            elseif ischar(plotTask) || isnumeric(plotTask)
                plotTask = this.Project.RawAnalyzer.getTask(plotTask);
            end
            
            wf = this.buildWF();
            data = wf.getCurrentCurveAnalysis();
            if isempty(data)
                cla(sui.gca(view));
                return;
            end
            
            plotTask.plotData(view, data);
        end
        
        function [data, newCurveName] = rejectAndNext(this, plotTask)
            wf = this.buildWF();
            
            [data, newCurveName] = wf.rejectCurve();

            this.App.Messenger.send(ForSDAT.Application.AppMessages.FDC_Analyzed);
        end

        function [data, newCurveName] = undoLastDecision(this, plotTask)
            wf = this.buildWF();

            [data, newCurveName] = wf.undo();
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.FDC_Analyzed);
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
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.FDC_Analyzed);
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
            this.Project.CookedAnalyzer.loadExperimentRepository(path);
        end
        
        function settings = loadSettings(this, settingsFile)
            if nargin > 1 && ~isempty(settingsFile)
                settings = this.Serializer.load(settingsFile);
            else
                % default settings
                
                settings = ForSDAT.Core.Setup.AnalysisSettings();
                % Measurement setup
                settings.Measurement.SamplingRate = 2048;
                settings.Measurement.Speed = 0.8;
                settings.Measurement.Probe = ForSDAT.Core.Setup.MolecularProbe();
                settings.Measurement.Probe.Molecule = chemo.PEG(0);
                settings.Measurement.Probe.linker = chemo.PEG(5000);
                settings.NoiseAnomally = ForSDAT.Core.NoiseAnomally(...
                    2, ...
                    settings.Measurement.Speed, ....
                    settings.Measurement.SamplingRate);
            end
        end
    end
end

