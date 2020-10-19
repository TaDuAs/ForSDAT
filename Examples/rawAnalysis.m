% define analysis process pipeline
analyzer = ForSDAT.Core.RawDataAnalyzer();

% define axes order of magnitude - pN, nm
oomAdj = ForSDAT.Core.Adjusters.FDCurveOOMAdjuster(util.OOM.Pico, util.OOM.Nano);
oomTask = ForSDAT.Core.Tasks.AdjustmentTask(oomTask, 'Distance', 'Force', 'retract', false, true);
analyzer.addTask(oomTask);

% define smoothing
smoothAdj = ForSDAT.Core.Adjusters.DataSmoothingAdjuster(7, 'sgolay', 3);
smoothTask = ForSDAT.Core.Tasks.AdjustmentTask(smoothAdj, 'Distance', 'Force', 'retract');
analyzer.addTask(smoothTask);

% define baseline detection
isBaselineTilted = false;
baselineDetector = ForSDAT.Core.Baseline.CompositeBaselineDetector(...
    ForSDAT.Core.Baseline.SimpleBaselineDetector(0.1, 2.5, isBaselineTilted),...
    ForSDAT.Core.Baseline.HistogramBaselineDetector('sqrt', 0.5, 1.25, 3));
baselineTask = ForSDAT.Core.Tasks.BaselineDetectorTask(baselineDetector, 2, 'Distance', 'Force', 'retract');
analyzer.addTask(baselineTask);

% define contact point detection
contactDetector = ForSDAT.Core.Contact.ContactPointDetector(0.007, 0.97, false);
contactTask = ForSDAT.Core.Tasks.ContactPointDetectorTask(contactDetector, 'Distance', 'Force', 'retract');
analyzer.addTask(contactTask);

% define distance to tip sample separation (tss) correction
tssAdj = ForSDAT.Core.Adjusters.TipHeightAdjuster([], util.OOM.Pico, util.OOM.Nano);
tssTask = ForSDAT.Core.Tasks.TipHeightAdjustTask(tssAdj, false, 'Distance', 'Force', 'retract');
analyzer.addTask(tssTask);

% define rupture detection task
ruptDetector = ForSDAT.Core.Ruptures.RuptureDetector(ForSDAT.Core.Baseline.SimpleBaselineDetector(0.1, 2, false), 0.1745);
ruptDetector.thresholdingMethods =...
    [ForSDAT.Core.Ruptures.Thresholding.SizeVsNoiseMethod(),...
     ForSDAT.Core.Ruptures.Thresholding.StartBelowNoiseDomainMethod(),...
     ForSDAT.Core.Ruptures.Thresholding.RemoveContactMethod()];
ruptTask = ForSDAT.Core.Tasks.RuptureEventDetectorTask(ruptureDetector, 'Distance', 'Force', 'retract',...
    ForSDAT.Core.Ruptures.NoiseOffsetLoadingDomainDetector());
analyzer.addTask(tssTask);

% define the interaction window
iwTask = ForSDAT.Core.Tasks.InteractionWindowTask()

% load a single force vs distance curve (fdc)
curveParser = ForSDAT.Application.IO.JpkBinaryFDCParser();
fdcFilePath = 'Add curve full path here';
fdc = curveParser.parse(fdcFilePath);

