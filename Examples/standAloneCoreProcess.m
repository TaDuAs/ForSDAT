% This script shows how to build and run an analysis process programmaically
% The recommended method to run ForSDAT is using the App-Controller API, but 
% it is still applicable to run a standalone analysis pipeline.
%
% Author: TADA 2020
% ForSDAT version 1.1


%% 
% Prepare experimental setup configuration
%
settings = ForSDAT.Core.Setup.AnalysisSettings();
settings.FOOM = util.OOM.Pico;
settings.ZOOM = util.OOM.Nano;
retractSpeed = 1000; % nm/sec
samplingRate = 2048; % Hz
settings.NoiseAnomally = ForSDAT.Core.NoiseAnomally(2, retractSpeed, samplingRate);
settings.Measurement.Probe = ForSDAT.Core.Setup.MolecularProbe();
settings.Measurement.Probe.Linker = chemo.PEG(5000); % %kDa PEG linker
settings.Measurement.Probe.Molecule = chemo.GenericMolecule(15); % the single molecule is a generic molecule with size 15 nm
settings.Measurement.SamplingRate = samplingRate;
settings.Measurement.Speed = retractSpeed;


%% 
% define analysis process pipeline
%
analyzer = ForSDAT.Core.RawDataAnalyzer();

% define axes order of magnitude - pN, nm
oomAdj = ForSDAT.Core.Adjusters.FDCurveOOMAdjuster(util.OOM.Pico, util.OOM.Nano);
oomTask = ForSDAT.Core.Tasks.AdjustmentTask(oomAdj, 'Distance', 'Force', 'retract', false, true);
analyzer.addTask(oomTask);

% can also define smoothing
% smoothAdj = ForSDAT.Core.Adjusters.DataSmoothingAdjuster(7, 'sgolay', 3);
% smoothTask = ForSDAT.Core.Tasks.AdjustmentTask(smoothAdj, 'Distance', 'Force', 'retract');
% analyzer.addTask(smoothTask);

% "distance smoothing" is sometimes necessary to overcome oscillations in
% the distance signal which may interupt with rupture detection
distSmoothAdj = ForSDAT.Core.Adjusters.DistanceSmoothingAdjuster();
distSmoothTask = ForSDAT.Core.Tasks.AdjustmentTask(distSmoothAdj, 'Distance', 'Force', 'retract', false, true);
analyzer.addTask(distSmoothTask);

% define baseline detection
isBaselineTilted = false;
baselineDetector = ForSDAT.Core.Baseline.CompositeBaselineDetector(...
    ForSDAT.Core.Baseline.SimpleBaselineDetector(0.1, 2.5, isBaselineTilted),...
    ForSDAT.Core.Baseline.HistogramBaselineDetector('sqrt', 0.5, 1.25, 3));
baselineTask = ForSDAT.Core.Tasks.BaselineDetectorTask(baselineDetector, 2, 'Distance', 'Force', 'retract');
analyzer.addTask(baselineTask);

% define contact point detection
contactDetector = ForSDAT.Core.Contact.ContactPointDetector(0.015, 0.97, false);
contactTask = ForSDAT.Core.Tasks.ContactPointDetectorTask(contactDetector, 'Distance', 'Force', 'retract');
analyzer.addTask(contactTask);

% define distance to tip sample separation (tss) correction
tssAdj = ForSDAT.Core.Adjusters.TipHeightAdjuster([], util.OOM.Pico, util.OOM.Nano);
tssTask = ForSDAT.Core.Tasks.TipHeightAdjustTask(tssAdj, false, 'Distance', 'Force', 'retract');
analyzer.addTask(tssTask);

% define rupture detection task
ruptDetector = ForSDAT.Core.Ruptures.RuptureDetector(ForSDAT.Core.Baseline.SimpleBaselineDetector(0.1, 2, false), 0.1745, 'radians', false);
ruptDetector.thresholdingMethods =...
    [ForSDAT.Core.Ruptures.Thresholding.SizeVsNoiseMethod(),...
     ForSDAT.Core.Ruptures.Thresholding.StartBelowNoiseDomainMethod(),...
     ForSDAT.Core.Ruptures.Thresholding.RemoveContactMethod()];
ruptTask = ForSDAT.Core.Tasks.RuptureEventDetectorTask(ruptDetector, 'Distance', 'Force', 'retract',...
    ForSDAT.Core.Ruptures.NoiseOffsetLoadingDomainDetector());
analyzer.addTask(ruptTask);

% define the interaction window
iwFilter = ForSDAT.Core.Ruptures.InteractionWindowSMIFilter(20);
iwTask = ForSDAT.Core.Tasks.InteractionWindowTask(iwFilter, 'Distance', 'Force', 'retract');
analyzer.addTask(iwTask);

% define WLC fitting
wlcFitter = ForSDAT.Core.Ruptures.WLCLoadFitter(298);
wlcTask = ForSDAT.Core.Tasks.ChainFitTask(wlcFitter, [], 'Distance', 'Force', 'retract');
analyzer.addTask(wlcTask);

% define smoothing-based specific interaction filter
smiFilter = ForSDAT.Core.Ruptures.SmoothingSMIFilter(...
    ForSDAT.Core.Baseline.SimpleBaselineDetector(0.05, 4, false), ...
    ForSDAT.Core.Adjusters.DataSmoothingAdjuster(50, 'moving'), ...
    75, 'last');
smiTask = ForSDAT.Core.Tasks.SMIFilterTask(smiFilter, 'Distance', 'Force', 'retract', '', '', 'RuptureWindow');
smiTask.contactChannel = 'FixedContact';
analyzer.addTask(smiTask);


%%
% Load data
% 

% load batch of force vs distance curves (fdc) - of course this can be done
% in a curve-by-curve manner
[~, ~, dataFiles] = gen.dirfiles(gen.localPath('Data'), 'jpk-force');
curveParser = ForSDAT.Application.IO.JpkBinaryFDCParser();
fdcs = ForSDAT.Core.ForceDistanceCurve.empty();
for i = numel(dataFiles):-1:1
    fdcs(i) = curveParser.parse(dataFiles{i});
end

%% 
% Perform curve by curve iterative analysis
% 

% pass setup to the analyzer
analyzer.init(settings);
data = cell(size(fdcs));

% analyze all curves
for i = 1:numel(fdcs)
    data{i} = analyzer.analyze(fdcs(i), 'retract');
end

% follow the decision process of all curves
% for i = 1:numel(data)
%     smiTask.plotData(figure(1), data{i});
%     disp(dataFiles{i});
%     input('...');
% end

% get specific interaction rupture force and loading rate
isSpecificInteraction = cellfun(@(dat) dat.SingleInteraction.didDetect, data);
specificCurvesOutput = [data{isSpecificInteraction}];
specificInteractions = [specificCurvesOutput.SingleInteraction];
f = [specificInteractions.modeledForce];
lr = [specificInteractions.apparentLoadingRate];