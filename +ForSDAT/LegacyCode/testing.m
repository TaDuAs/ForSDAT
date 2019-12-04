%% Load stuff
settings = MainSMFSDA.loadSettings('default');
[parser, ~, curveAnalyzer, batchDataAnalyzer] = MainSMFSDA.initialize();
longWaveDisturbanceAdjuster = LongWaveDisturbanceAdjusterBeta(...
    settings.curveAnalysis.adjustments.longwaveDisturbanceFitRange,...
    2,... %Fourier Series Order
    FDCurveTextFileSettings.defaultExtendSegmentName,...
    FDCurveTextFileSettings.defaultRetractSegmentName);
settings.measurement.speed = 0.4;
noiseAnomallySpecs = ForSDAT.Core.NoiseAnomally(...
    settings.curveAnalysis.noiseAnomallyLength,...
    settings.measurement.speed * 1000,...
    settings.measurement.samplingRate);

%% Load FDC
if ~exist('fdc', 'var') || isempty(fdc)
    dirName = [pwd '\Data Analyzer\Data Files'];
    fileName = 'Specific Interaction In Segment2.txt';

    dirName = [pwd '\Data Analyzer\Data Files\Wavy Curvy'];
    fileName = 'Perfect.txt';

    fdc = parser.parseJpkTextFile([dirName '\' fileName], [1 2]);
end

%% Prepare pipeline
settings = MainSMFSDA.loadSettings(MainSMFSDA.loadSettingsMethods.fromFile, [pwd '\Data Analyzer\defaultSettings.xml']);
mgr = RawDataAnalyzer([], settings);

oomAdj = curveAnalyzer.dataAdjuster;
oomTask = AdjustmentTask(oomAdj);

smoother = curveAnalyzer.smoothingAdjuster;
smoothTask = AdjustmentTask(smoother);

fourierAdj = longWaveDisturbanceAdjuster;
fourierTask = LongWaveAdjustTask(fourierAdj);

bslDetector = curveAnalyzer.baselineDetector;
% bslDetector.primary.isBaselineTilted_value = true;
bslDetector.primary.stdScore = 2;
bslTask = BaselineDetectorTask(bslDetector, 1.5);

cntctDetector = curveAnalyzer.contactDetector;
cntctTask = ContactPointDetectorTask(cntctDetector, true);

tipHeightAdjuster = TipHeightAdjuster([], Simple.Math.OOM.Pico, Simple.Math.OOM.Nano);
tipHeightTask = TipHeightAdjustTask(tipHeightAdjuster);

ruptureDetector = RuptureDetector(curveAnalyzer.stepsAnalyzer);
ruptureDetectorTask = RuptureEventDetectorTask(ruptureDetector);

loadingDomainDetector = NoiseHysteresisLoadingDomainDetector(noiseAnomallySpecs);
chainFitter = WLCSolutionFitter([], 0.1);
chainFitTask = ChainFitTask(...
    chainFitter,...
    loadingDomainDetector,...
    [],...DataSmoothingAdjuster(3, 'sgolay', 2),...  %DataSmoothingAdjuster(20, 'loess'),...
    'Distance',...
    true);

smfsFilter = BaselineThresholdSMIFilter(...
    curveAnalyzer.stepsAnalyzer.stepsFilter.startAt, ...
    curveAnalyzer.stepsAnalyzer.stepsFilter.endAt,...
    noiseAnomallySpecs);
smfsFilterTask = SMIFilterTask(smfsFilter);

mgr...addTask(fourierTask)...
   .addTask(oomTask)...
   ...addTask(smoothTask)...
   .addTask(bslTask)...
   .addTask(cntctTask)...
   .addTask(tipHeightTask)...
   .addTask(ruptureDetectorTask)...
   .addTask(chainFitTask)...
   .addTask(smfsFilterTask)...
   ;

%% Analyze & plot data
data = mgr.analyze(fdc, 'retract');
mgr.plotData(figure(1), data);
