classdef MainSMFSDA
    % script manager for SMFS data analysis
    
    methods (Static)
        function [chi, koff, p, R2] = bellEvansPlot(lr, lrErr, mpf, mpfErr, plotOpt)
            % Plots the Bell-Evans curve for a set of MPFs and LRs
            % Returns:
            %   chi - energy barrier distance [?]
            %   koff - Dissosiation rate [Hz]
            %   p - Bell-Evans regression curve coefficients
            %   R2 - R^2
            % Bell-Evans model:
            %   F = (kB*T/X)*ln(Xr/kB*T*koff)
            %   where F is the MPF
            %         kB is boltzmans constant
            %         T is the temperature
            %         X is the distance of the energy barrier needed to be
            %                  overcome for unbinding to occur allong the
            %                  direction of applied force
            %         r is the apparent loading rate
            %         koff is the rate of dissosiation at equilibrium
            
            if ~exist('plotOpt', 'var')
                plotOpt = struct(...
                    'Marker', 'o',...
                    'MarkerFaceColor', 'b',...
                    'MarkerEdgeColor', 'b',...
                    'LineStyle', 'none');
            end
            
            % Calculate reggression
            x = log(lr);
            xErr = calcerr(lr, lrErr, 'ln');
            
            [p, R2, ~] = epolyfit(x, mpf, 1);
            
            fig = figure();
            xyerrorbar(x, mpf, xErr, mpfErr, plotOpt);
            
            hold on;
            regY = polyval(p, x);
            plot(x, regY);
            
            slope = p(1); % KBT/chi
            intersect = p(2);
            secondParameter = intersect/slope; % ln(chi/KBT*Koff)
            T = 298; % RT in K
            heatEnergy = physconst('Boltzmann')*T;% KBT in J
            chi = heatEnergy/slope * 10^22; % 10^12 adjusts the energy to pJ (cause we're using pN MPFs)
                                            % 10^10 adjusts the chi to ?
            koff = exp(-secondParameter)/slope;
            
            % Create xlabel
            xlabel({'ln(r)'});

            % Create ylabel
            ylabel({'MPF (pN)'});

            % Create textbox
            annotation(fig,'textbox',...
                [0.2 0.7 0.20 0.19],...
                'String',{['R^2=' num2str(round(R2, 4))],...
                          ['\chi_\beta=' num2str(round(chi, 2)), char(197)],...
                          ['k_o_f_f=' num2str(round(koff*1000, 2)) 'ª10^-^3Hz']},...
                'FitBoxToText','off');
            
        end
        
        function [frc, dst, stepHeight, stepDist, stepSlope, data, fdc] = ...
                analyzeCurve(fileName, parser, longWaveDisturbanceAdjuster, curveAnalyzer)
            settings = MainSMFSDA.getSettings();
            
            % Parse FDC
            fdc = parser.parseJpkTextFile(fileName, settings.parser.parseSegmentIndices);

            % Fix non linear baseline
            if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
                longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
            end

            % Analyze FDC
            [frc, dst, stepHeight, stepDist, stepSlope, data] = ...
                curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
        end
        
        function fig = debugPlotCurve(fileName, fileIndex, frc, dst, data, fdc, curveAnalyzer, fig)
            if ~exist('fig', 'var')
                fig = [];
            end
            fig = MainSMFSDA.getFigureInstance('debugPlotCurve_CurrentFigure', fig);
            
            if isempty(fileIndex) || mod(fileIndex-1,4) == 0 || isempty(fig)
                fig = figure();
                App.getRepository.set('debugPlotCurve_CurrentFigure', fig);
            end
            
            if ~isempty(fileIndex)
                subplot(220 + mod(fileIndex-1,4) + 1);
            end
            plot(dst, frc);
            hold on;
            if ~isempty(data.unfilteredSteps)
                plot(dst(data.unfilteredSteps(1,:)), frc(data.unfilteredSteps(1,:)), 'bs', 'MarkerFaceColor', 'b');
                plot(dst(data.unfilteredSteps(2,:)), frc(data.unfilteredSteps(2,:)), 'cs', 'MarkerFaceColor', 'c');
                if ~isempty(data.steps)
                    plot(dst(data.steps(1,:)), frc(data.steps(1,:)), 'gv', 'MarkerFaceColor', 'g');
                    plot(dst(data.steps(2,:)), frc(data.steps(2,:)), 'rv', 'MarkerFaceColor', 'r');
                    slopeFit = data.stepsSlopeFittingData.model;
                    slopeRange = ...
                        data.stepsSlopeFittingData.range(1):data.stepsSlopeFittingData.range(2);
                    plot(dst(slopeRange), slopeFit.invoke(slopeRange));
                end
                plot(dst, zeros(1,length(dst))+data.noiseAmp,dst, zeros(1,length(dst))-data.noiseAmp);
            end
            minX = min(dst) - 20;
            maxX = max(dst) + 20;
            minY = min(frc) - 50;
            maxY = max(frc) + 50;
            axis([minX maxX minY maxY]);
            xlabel('Distance [nm]'); ylabel('Force [pN]');
            grid('on');
            legend('Tip Retract', 'Detected Rupture Start', 'Detected Rupture End',...
                'Specific Interaction Start', 'Specific Interaction Start', 'L.R. Evaluation');
            title({fileName});
            hold off;
            
            
            
            if ismethod(curveAnalyzer.baselineDetector, 'plotHistogram')
                baselineFig = MainSMFSDA.getFigureInstance('debugPlotCurve_BaselineDetectorFigure');
                curveAnalyzer.baselineDetector.plotHistogram(dst, frc, baselineFig, 211, baselineFig, 212);
                movegui(baselineFig, 'southwest');
            end

        end
        
        function fig = getFigureInstance(name, fig)
            if isempty(App.getRepository.get(name))
                if ~exist('fig', 'var') || isempty(fig)
                    fig = figure();
                end
            else
                fig = App.getRepository.get(name);
                if isnumeric(fig)
                    fig = figure(fig);
                elseif ~ishandle(fig) || ~isvalid(fig)
                    fig = figure();
                end
            end
            App.getRepository.set(name, fig);
        end
        
        function [jpkDataFileParser, longWaveDisturbanceAdjuster, curveAnalyzer, batchDataAnalyzer] = initialize()
            settings = MainSMFSDA.getSettings();
            
            jpkDataFileParser = ForceDistanceCurveParser(true);
            longWaveDisturbanceAdjuster = LongWaveDisturbanceAdjuster(...
                settings.curveAnalysis.adjustments.longwaveDisturbanceFitRange,...
                FDCurveTextFileSettings.defaultExtendSegmentName);
            
            % Baseline\Contact Point detectors
            primaryBaselineDetector = SimpleBaselineDetector(...
                settings.curveAnalysis.baseline.simple.fragment,...
                settings.curveAnalysis.baseline.simple.stdScore,...
                settings.curveAnalysis.baseline.simple.isBaselineTilted);
            secondaryBaselineDetector = HistogramBaselineDetector(...
                settings.curveAnalysis.baseline.histogram.binningMethod, ...
                settings.curveAnalysis.baseline.histogram.fitR2Threshold, ...
                settings.curveAnalysis.baseline.histogram.stdScore, ...
                settings.curveAnalysis.baseline.histogram.order, ...
                settings.curveAnalysis.baseline.histogram.minimalBinsNumber);
            compositeBaselineDetector = CompositeBaselineDetector(primaryBaselineDetector, secondaryBaselineDetector, ...
                settings.curveAnalysis.baseline.composite.stdThreshold);
            baselineDetector = compositeBaselineDetector;
            
%             probabilityMapBaselineDetector = ProbabilityMapBaselineDetector(...
%                 settings.curveAnalysis.baseline.histogram.binningMethod,...
%                 125,...%settings.curveAnalysis.baseline.histogram.binningMethod,...
%                 [],...
%                 0.25);
%             
%             
%             
%             % Prompt for manual supervision
%             dlgResult = questdlg('Should use probability map for baseline analysis?', 'Baseline Analysis', 'Yes', 'No', 'No');
%             useProbabilityMapForBaselineDetection = strcmp(dlgResult, 'Yes');
%             
%             if useProbabilityMapForBaselineDetection
%                 baselineDetector = probabilityMapBaselineDetector;
%             else
%                 baselineDetector = compositeBaselineDetector;
%             end
            
            contactDetector = ContactPointDetector( ...
                settings.curveAnalysis.contact.fragment, ...
                settings.curveAnalysis.contact.iterativeApproachR2Threshold,...
                settings.curveAnalysis.contact.isSoftSurface);
            
            % Curve analyzer
            stepFilter = SingleInteractionStepPicker(settings.measurement.linker.backboneLength,...
                settings.curveAnalysis.steps.filtering.rupturePositionError,...
                settings.measurement.molecule.backboneLength);
            % A good polynomial load fit is one that has a negative second derivative
%             function isGood = determineIfPolynomialLoadFitIsGood(func, fitCoefficients, s, mu)
%                 p = fitCoefficients;
%                 isGood = p(1) < 0 || (p(1) == 0 && p(2) < 0);
%             end
            parabolicLoadFitter = PolynomialLoadFitter(2);%, @determineIfPolynomialLoadFitIsGood);
            stepsAnalyzer = RelevantStepsAnalyzer(compositeBaselineDetector, parabolicLoadFitter, stepFilter,...
                settings.curveAnalysis.steps.detection, settings.curveAnalysis.steps.filtering);
%             function isGood = determineIfWLCFitIsGood(func, fitCoefficients, s, mu)
% %                 isGood = fitCoefficients
%                 isGood = true;
%             end
%             wlcLoadFitter = WLCLoadFitter(...
%                 PhysicalConstants.RT,...
%                 settings.measurement.linker.backboneLength,...
%                 settings.measurement.linker.persistenceLength);
%             stepsAnalyzer = RelevantStepsAnalyzer(baselineDetector, wlcLoadFitter, stepFilter,...
%                 settings.curveAnalysis.steps.detection, settings.curveAnalysis.steps.filtering);
            
            % Data adjustments
            dataAdjuster = FDCurveOOMAdjuster(settings.curveAnalysis.adjustments.oom.f,...
                settings.curveAnalysis.adjustments.oom.z);
            smoothingAdjuster = DataSmoothingAdjuster(settings.curveAnalysis.adjustments.smoothing.span,...
                settings.curveAnalysis.adjustments.smoothing.algorithm,...
                settings.curveAnalysis.adjustments.smoothing.degree);
            
            % Curve analysis manager
            curveAnalyzer = ForceDistanceCurveAnalysisManager(baselineDetector, contactDetector, stepsAnalyzer,...
                dataAdjuster, smoothingAdjuster);
            % Final data analysis handler
            batchDataAnalyzer = StepsDataAnalyzer(settings.dataAnalysis.binningMethod,...
                settings.dataAnalysis.minimalBinsNumber,...
                settings.dataAnalysis.distributionModel,...
                settings.dataAnalysis.histogramGausFitR2Threshold);
        end
        
        function settings = loadSettings(settingsLoadMethod, settingsFile)
            
            % load previous settings
            inputOptionFieldNames = {...
                'Retract Speed (um/sec):',...
                'Parse Seegments (indices):',...
                'Retract Segment Index:',...
                'Binning Method\Bin Size (fd, sqrt, sturges, bin width - number):',...
                'Histogram Distribution Model (gauss,gamma):',...
                'Gaussian Fit R2 Threshold:',...
                'Histogram Baseline Populations Number:',...
                'Tilted Baseline (true, false)?',...
                'Fix Long Wavelength Disturbance (true, false)?',...
                'Is Tip\Substrate Surface Soft (true, false)?',...
                'Run Manualy (true, false)?'};
            inputOptionFieldIDs = {...
                'retSpeed',...
                'parseSegments',...
                'retractSegmentId',...
                'binningMethod',...
                'histogramModel',...
                'gaussFitThreshold',...
                'histogramPopulations',...
                'isBaselineTilted',...
                'shouldFixLongWave',...
                'isSoftContact',...
                'runManualy'};
            defaultInputOptionsValues = struct(...
                'retSpeed', 0.8,...
                'parseSegments', 1,...
                'retractSegmentId', 1,...
                'binningMethod', 'fd',...
                'histogramModel', 'gauss',...
                'gaussFitThreshold', 0.6,...
                'histogramPopulations', 3,...
                'isBaselineTilted', false,...
                'shouldFixLongWave', false,...
                'isSoftContact', false,...
                'runManualy', false);
            inputOptionsDataTypes = {'double', 'double', 'double', 'double|string', 'string', 'double', 'double', 'bool', 'bool', 'bool', 'bool'};
            inputOptionsValues = App.getRepository.get('settings.prompt');
            if isempty(inputOptionsValues) || ...
               (iscell(inputOptionsValues) && length(inputOptionsValues) ~= length(inputOptionFieldNames)) || ...
               (isstruct(inputOptionsValues) && length(fieldnames(inputOptionsValues)) ~= length(inputOptionFieldNames))
                inputOptionsValues = defaultInputOptionsValues;
            end
            
            % Prompt handler for settings
            if exist('settingsLoadMethod', 'var') && ischar(settingsLoadMethod) && ~isempty(settingsLoadMethod)
                switch settingsLoadMethod
                    case MainSMFSDA.loadSettingsMethods.prompt
                        inputOptionsValues = dlgInputValues(...
                            inputOptionFieldNames,... % Fields titles
                            inputOptionsValues,...    % Default values
                            inputOptionsDataTypes,... % Field data types
                            'Process Input',...       % Dialogue title
                            1,...                     % number of lines per input
                            inputOptionFieldIDs);     % Identifiers for struct output
                    case MainSMFSDA.loadSettingsMethods.default
                        inputOptionsValues = defaultInputOptionsValues;
                    case MainSMFSDA.loadSettingsMethods.fromFile
                        settings = Simple.IO.MXML.load(settingsFile);
                        % Save settings
                        App.getRepository.set('settings', settings);
                        return;
                    otherwise
                        inputOptionsValues = Simple.IO.MXML.load(settingsLoadMethod);
                end
            end

            App.getRepository.set('settings.prompt', inputOptionsValues);
            
            % Parser settings
            settings.parser.parseSegmentIndices = inputOptionsValues.parseSegments;
            settings.parser.retractSegmentIndex = inputOptionsValues.retractSegmentId;
            
            % Measurement setup
            settings.measurement.samplingRate = 2048;
            settings.measurement.speed = inputOptionsValues.retSpeed;
            settings.measurement.linker = ...
                PEG(5000 - Chemistry.Mw([Chemistry.Groups.COONHS, Chemistry.Groups.NHFmoc])); % PEG Mw = 5000Da - sidegroups Mw
            settings.measurement.molecule = Peptide('SVSVGMKPSPRP');
            
            settings.curveAnalysis.noiseAnomallyLength = 2;
            
            % Data adjustments
            settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline = inputOptionsValues.shouldFixLongWave;
            settings.curveAnalysis.adjustments.longwaveDisturbanceFitRange = {0.8, 'end'};
            settings.curveAnalysis.adjustments.oom.f = Simple.Math.OOM.Pico;
            settings.curveAnalysis.adjustments.oom.z = Simple.Math.OOM.Nano;
            
            % Smoothing
            settings.curveAnalysis.adjustments.smoothing.algorithm = 'sgolay';
            settings.curveAnalysis.adjustments.smoothing.span = 7;
            settings.curveAnalysis.adjustments.smoothing.degree = 3;
            
            % Baseline
            settings.curveAnalysis.baseline.simple.fragment = 0.1;
            settings.curveAnalysis.baseline.simple.stdScore = 3;
            settings.curveAnalysis.baseline.simple.isBaselineTilted = inputOptionsValues.isBaselineTilted;
            settings.curveAnalysis.baseline.histogram.binningMethod = 10;
            settings.curveAnalysis.baseline.histogram.minimalBinsNumber = 15;
            settings.curveAnalysis.baseline.histogram.fitR2Threshold = 0.5;
            settings.curveAnalysis.baseline.histogram.stdScore = 1;
            settings.curveAnalysis.baseline.histogram.order = inputOptionsValues.histogramPopulations;
            settings.curveAnalysis.baseline.composite.stdThreshold = 0.1;
            
            % Contact point
            settings.curveAnalysis.contact.fragment = 0.025;
            % linear fit R^2 threshold value for finding contact using iterative approach - for noisy contact domain
            settings.curveAnalysis.contact.iterativeApproachR2Threshold = 0.97;
            settings.curveAnalysis.contact.isSoftSurface = inputOptionsValues.isSoftContact;
            
            % Step analysis settings
            % as long as the step slope is 80°-90°, its a single step
            settings.curveAnalysis.steps.detection.stepSlopeDeviation = 10;
            settings.curveAnalysis.steps.filtering.rupturePositionError = 25;
            
            % Data analysis settings
            settings.dataAnalysis.binningMethod = inputOptionsValues.binningMethod;
            settings.dataAnalysis.minimalBinsNumber = 7;
            settings.dataAnalysis.distributionModel = inputOptionsValues.histogramModel;
            settings.dataAnalysis.histogramGausFitR2Threshold = inputOptionsValues.gaussFitThreshold;
            
            settings.manualSupervision = inputOptionsValues.runManualy;
            
            % Save settings
            App.getRepository.set('settings', settings);
        end
        
        function settings = getSettings()
            settings = App.getRepository.get('settings');

            if isempty(settings)
                settings = MainSMFSDA.loadSettings();
            end
        end
        
        function [batchFoundStepsCount, mpf, mpfSTD, lr] = analyzeFDCurveBatch(folderPath, loadSettingsMethod, plotData, plotAnalyzedData, proggressMessage)
            mpf = []; mpfSTD = []; lr = [];
            
            % Load Settings
            settings = MainSMFSDA.loadSettings(loadSettingsMethod);

            % Prepare everything
            dataFileList = dir([folderPath '\*.txt']);
            [parser, longWaveDisturbanceAdjuster, curveAnalyzer, batchDataAnalyzer] = MainSMFSDA.initialize();
            steps = Simple.List(200, AnalyzedFDCData.empty);
            failed = {};
            fig = [];

            curvesNum = length(dataFileList);
            onAlertProggress = @(prog) display(['So far, ' num2str(steps.length()) ' specific interactions were evaluated.']);
            if ~exist('proggressMessage', 'var') || ~ischar(proggressMessage)
                proggressMessage = '';
            else
                proggressMessage = [', ' proggressMessage];
            end
            proggressBar = Simple.UI.ConsoleProggressBar(['FDC parsing & analysis' proggressMessage], curvesNum, 10, true, [], onAlertProggress);

            
            consoleNow(['Start FDC Batch Analyzis. ' num2str(curvesNum) ' curves to go...']);
            tic;

            for i = 1:curvesNum
                dataFileMetadata = dataFileList(i);

                fileName = [folderPath '\' dataFileMetadata.name];

                try
                    % Analyze FDC
                    [frc, dst, stepHeight, stepDist, stepSlope, data, fdc] = ...
                        MainSMFSDA.analyzeCurve(fileName, parser, longWaveDisturbanceAdjuster, curveAnalyzer);

                    if ~settings.manualSupervision
                        %Completely automatic analysis...

                        % Save FDC with valid rupture events, and the ruptures of course
                        if any(stepHeight)
                            steps.add(AnalyzedFDCData(stepHeight, stepDist, stepSlope, dataFileMetadata.name));
                        end

                        % Plot curve when debugging
                        if Simple.isdebug() && curvesNum <= 100 && plotData
                            MainSMFSDA.debugPlotCurve(dataFileMetadata.name, i, frc, dst, data, fdc);
                        end
                    else
                        % Auto analysis with parental supervision...

                        % Plot curve when debugging
                        fig = MainSMFSDA.debugPlotCurve(dataFileMetadata.name, [], frc, dst, data, fdc, fig);

                        % Prompt for manual supervision
                        dlgResult = questdlg(['Curve #' '' ' was analyzed. Keep It?'], 'Curve Analysis', 'Yes', 'No', 'STOP!', 'Yes');
                        
                        if strcmp(dlgResult, 'Yes')
                            % Save FDC with valid rupture events, and the ruptures of course
                            if any(stepHeight)
                                steps.add(AnalyzedFDCData(stepHeight, stepDist, stepSlope, dataFileMetadata.name));
                            end
                        elseif strcmp(dlgResult, 'STOP!')
                            return;
                        end
                    end
                catch ex
                    failed{length(failed)+1} = dataFileMetadata.name;
                    App.handleException(strcat('Couldnt analyze force curve: ', fileName), ex);
                end
                
                proggressBar.reportProggress(1);
            end

            Simple.UI.tocmsg('Elapsed batch runtime:');
            Simple.UI.consoleNow('End FDC Batch Analyzis');

            endTime = datestr(now, 'YYYY-mm-dd.HH.MM.SS.FFF');
            % Copy processed curves to a new folder. Just in case...
            if steps.length > 0
                processedFolderPath = [folderPath '\processed_' endTime];
                mkdir(processedFolderPath);
                for i = 1:length(steps)
                    goodCurveFileName = steps.get(i).file;
                    [status, msg] = copyfile([folderPath '\' goodCurveFileName], [processedFolderPath '\' goodCurveFileName], 'f');
                    if ~status
                        display(['Could not copy processed curve ' folderPath '\' goodCurveFileName]);
                        display(msg);
                    end
                end
            end

            % copy failed curves to a new folder...
            if any(folderPath) && ~isempty(failed)
                failedFolderPath = [folderPath '\failed_' endTime];
                mkdir(failedFolderPath);
                for i = 1:length(failed)
                    failedFileName = failed{i};
                    [status, msg] = copyfile([folderPath '\' failedFileName], [failedFolderPath '\' failedFileName], 'f');
                    if ~status
                        display(['Could not copy processed curve ' folderPath '\' failedFileName]);
                        display(msg);
                    end
                end
            end

            % Analyze batch only if there is a substantial amount of ruptures saved
            batchFoundStepsCount = length(steps);
            if batchFoundStepsCount < 30
                consoleNow('Not enough steps for proper analyzis...');
                consoleNow('You should repeat the experiment, SOB U_U');

                % save the analyzed data though
                if steps.length > 0
                    Simple.IO.MXML.save([processedFolderPath '\processedSteps.xml'], steps.vector);
                end
                return;
            end

            if plotAnalyzedData
                dlgResult = inputdlg('What should be the title of your histogram?','Plot Title'); 
                if iscell(dlgResult) && ~isempty(dlgResult);
                    histTitle = dlgResult{1};
                elseif ~isempty(dlgResult)
                    histTitle = dlgResult;
                else
                    histTitle = '';
                end
            else
                histTitle = '';
            end

            histogramOpt = struct('title', {histTitle, folderPath(max(strfind(folderPath, '\')) + 1 : length(folderPath))});
            stepAnalyzisOpt = struct(...
                'showHistogram', plotAnalyzedData,...
                'binsInterval', settings.dataAnalysis.binningMethod,...
                'model', settings.dataAnalysis.distributionModel,...
                'fitR2Threshold', settings.dataAnalysis.histogramGausFitR2Threshold,...
                'plotOptions', histogramOpt);

            consoleNow('Begin Statistical Analysis');
            tic;

            stepsFDS = steps.foreach(@(obj, i) [obj.z; obj.f; obj.slope], 3).vector;
            stepDist = stepsFDS(1,:);
            stepHeight = stepsFDS(2,:);
            stepSlope = stepsFDS(3,:);
            [mpf, mpfStd, lr, lrErr, analyzisData] = batchDataAnalyzer.doYourThing(stepHeight, stepDist, stepSlope,...
                settings.measurement.speed, [], stepAnalyzisOpt);

            Simple.UI.tocmsg('Step Analyzis Done:');
            Simple.UI.consoleNow('End Statistical Analysis');

            Simple.IO.MXML.save(...
                [processedFolderPath '\processedSteps.xml'],...
                steps.vector,...
                struct('mpf', mpf, 'mpfStd', mpfStd, 'lr', lr));
        end
        
        function out = loadSettingsMethods()
            persistent methods;
            if isempty(methods)
                methods.prompt = 'prompt';
                methods.default = 'default';
                methods.fromFile = 'fromFile';
            end
            
            out = methods;
        end
        
        function fdc = loadCurve(fileName, parseSegmentIndices)
            settings = MainSMFSDA.getSettings();
            parser = MainSMFSDA.initialize();
            
            if nargin < 1 || isempty(fileName)
                folderPath = App.getRepository.get('MainSMFSDA.loadCurve_folderPath');
                if isempty(folderPath)
                    folderPath = [pwd '\Data Analyzer\Data Files'];
                end

                [file, folderPath, ~] = uigetfile([folderPath '\*.txt'], 'Choose Single Force-Distance Curve Data File');

                App.getRepository.set('MainSMFSDA.loadCurve_folderPath', folderPath);
                
                fileName = [folderPath '\' file];
            end
            
            % Parse FDC
            if nargin >= 2 && ~isempty(parseSegmentIndices)
                indices = parseSegmentIndices;
            else
                indices = settings.parser.parseSegmentIndices;
            end
            fdc = parser.parseJpkTextFile(fileName, indices);
        end
    end
    
end

