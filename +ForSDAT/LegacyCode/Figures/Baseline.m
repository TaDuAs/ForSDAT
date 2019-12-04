import Simple.App.*;
import Simple.*;

%% Load curve - Classical single molecule interaction
dirName = [pwd '\Data Analyzer\Data Files'];
fileName = 'Specific Interaction In Segment2.txt';

%% Reset settings
PersistenceContainer.instance.set('settings.prompt', struct(...
    'retSpeed', 0.8,...
    'parseSegments', [1 2],...
    'retractSegmentId', 2,...
    'binningMethod', 'fd',...
    'histogramModel', 'gauss',...
    'gaussFitThreshold', 0.6,...
    'histogramPopulations', 3,...
    'isBaselineTilted', false,...
    'shouldFixLongWave', false,...
    'isSoftContact', false,...
    'runManualy', false));

%% analyze curve
settings = MainSMFSDA.loadSettings('prompt');
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
fdc2 = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);
fdc = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);

compositeBaselineDetector = curveAnalyzer.baselineDetector;
tailBaselineDetector = compositeBaselineDetector.primary;
histogramBaselineDetector = compositeBaselineDetector.secondary;

if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
    fourierFit = longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
end

% Use tail baseline detection
curveAnalyzer.baselineDetector = tailBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
tail.frc = frc;
tail.dst = dst;
tail.stepHeight = stepHeight;
tail.stepDist = stepDist;
tail.stepSlope = stepSlope;
tail.data = data;

% Use histogram baseline detection
curveAnalyzer.baselineDetector = histogramBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
hist.frc = frc;
hist.dst = dst;
hist.stepHeight = stepHeight;
hist.stepDist = stepDist;
hist.stepSlope = stepSlope;
hist.data = data;

% Use composite baseline detection
curveAnalyzer.baselineDetector = compositeBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);

dst1 = dst + data.contact.pos;
frc1 = frc + data.baseline.pos;

figure();


%% Plot Baseline Tail Method
subplot(3,6,1:6);
hold on;
plot(dst1,frc1);
sero = zeros(1,length(dst1));
ibsl = round(0.9*length(dst1)):length(dst1);
plot(dst1(ibsl), frc1(ibsl), 'green');
plot(dst1,zeros(1,length(dst1))+tail.data.baseline.pos, 'black');
plot(dst1, sero+tail.data.baseline.pos+tail.data.noiseAmp, 'red');
plot(dst1, sero+tail.data.baseline.pos-tail.data.noiseAmp, 'red');

legend('Tip Retract', 'Segment for evaluating baseline', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 10);

%% Load tilted curve
dirName = [pwd '\Data Analyzer\Data Files\End of Baseline Tilt'];
% fileName = 'force-save-2016.08.16-18.36.05.283-1.txt';
fileName = 'force-save-2016.08.16-18.36.16.298-1.txt';

%% Reset settings
PersistenceContainer.instance.set('settings.prompt', struct(...
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
    'runManualy', false));

%% analyze curve
settings = MainSMFSDA.loadSettings('prompt');
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
fdc2 = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);
fdc = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);

compositeBaselineDetector = curveAnalyzer.baselineDetector;
tailBaselineDetector = compositeBaselineDetector.primary;
histogramBaselineDetector = compositeBaselineDetector.secondary;

if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
    fourierFit = longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
end

% Use tail baseline detection
curveAnalyzer.baselineDetector = tailBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
tail.frc = frc;
tail.dst = dst;
tail.stepHeight = stepHeight;
tail.stepDist = stepDist;
tail.stepSlope = stepSlope;
tail.data = data;

% Use histogram baseline detection
curveAnalyzer.baselineDetector = histogramBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
hist.frc = frc;
hist.dst = dst;
hist.stepHeight = stepHeight;
hist.stepDist = stepDist;
hist.stepSlope = stepSlope;
hist.data = data;

% Use composite baseline detection
curveAnalyzer.baselineDetector = compositeBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);

dst1 = dst + data.contact.pos;
frc1 = frc + data.baseline.pos;


%% Plot Baseline Tail Method
subplot(3,6,[7 8]);
% figure();
hold on;
plot(dst1,frc1);
sero = zeros(1,length(dst1));
ibsl = round(0.9*length(dst1)):length(dst1);
plot(dst1(ibsl), frc1(ibsl), 'green');
plot(dst1,zeros(1,length(dst1))+tail.data.baseline.pos, 'black');
plot(dst1, sero+tail.data.baseline.pos+tail.data.noiseAmp, 'red');
plot(dst1, sero+tail.data.baseline.pos-tail.data.noiseAmp, 'red');

legend('Tip Retract', 'Segment for evaluating baseline', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 10);

%% Plot Baseline Histogram Method
[baseline, y, noiseAmp, coefficients, s, mu] = histogramBaselineDetector.detect(dst1, frc1);

sfig = subplot(3, 6, [11 12]);
% figure();
% sfig = subplot(1, 2, 2);
[h1, bins, freq] = histogramBaselineDetector.plotHistogram(dst1, frc1);
minX = min(frc1) - 50;
maxX = max(frc1) + 50;
minY = min(freq./sum(freq));
maxY = max(freq./sum(freq)) + 0.01;
axis([minX maxX minY maxY]);
xlabel('Force [pN]'); ylabel('Probability');
% Rotate histogram
set(gca,'view',[90 -90]);

set(gca, 'FontSize', 10);

subplot(3, 6, [9 10]);
% subplot(1, 2, 1);
hold on;
plot(dst1,frc1);
sero = zeros(1,length(dst1));
plot(dst1, zeros(1,length(dst1))+hist.data.baseline.pos, 'black');
plot(dst1, sero+hist.data.baseline.pos+hist.data.noiseAmp, 'red');
plot(dst1, sero+hist.data.baseline.pos-hist.data.noiseAmp, 'red');

legend('Tip Retract', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');


set(gca, 'FontSize', 10);


%% Load perfect oscillating curve 
dirName = [pwd '\Data Analyzer\Data Files\Wavy Curvy'];
fileName = 'Perfect.txt';

%% Reset settings
PersistenceContainer.instance.set('settings.prompt', struct(...
    'retSpeed', 0.8,...
    'parseSegments', [1 2],...
    'retractSegmentId', 2,...
    'binningMethod', 'fd',...
    'histogramModel', 'gauss',...
    'gaussFitThreshold', 0.6,...
    'histogramPopulations', 3,...
    'isBaselineTilted', true,...
    'shouldFixLongWave', true,...
    'isSoftContact', false,...
    'runManualy', false));

%% analyze curve
settings = MainSMFSDA.loadSettings('prompt');
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
fdc2 = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);
fdc = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);

compositeBaselineDetector = curveAnalyzer.baselineDetector;
tailBaselineDetector = compositeBaselineDetector.primary;
histogramBaselineDetector = compositeBaselineDetector.secondary;

if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
    fourierFit = longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
end

% Use tail baseline detection
curveAnalyzer.baselineDetector = tailBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
tail.frc = frc;
tail.dst = dst;
tail.stepHeight = stepHeight;
tail.stepDist = stepDist;
tail.stepSlope = stepSlope;
tail.data = data;

% Use histogram baseline detection
curveAnalyzer.baselineDetector = histogramBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);
hist.frc = frc;
hist.dst = dst;
hist.stepHeight = stepHeight;
hist.stepDist = stepDist;
hist.stepSlope = stepSlope;
hist.data = data;

% Use composite baseline detection
curveAnalyzer.baselineDetector = compositeBaselineDetector;
[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);

dst1 = dst + data.contact.pos;
frc1 = frc + data.baseline.pos;

%% Longwave disturbance fix#2
subplot(3, 6, 16:18);
hold on;
plot(dst1,tail.frc+tail.data.baseline.pos);
sero = zeros(1,length(dst1));
plot(dst1, sero+tail.data.baseline.pos, 'black');
plot(dst1, sero+tail.data.baseline.pos+tail.data.noiseAmp, 'red');
plot(dst1, sero+tail.data.baseline.pos-tail.data.noiseAmp, 'red');

legend('Tip Retract', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(tail.frc) + tail.data.baseline.pos - 50;
maxY = max(tail.frc) + tail.data.baseline.pos + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 10);

subplot(3, 6, 13:15);
hold on;
fdc2ExtDist = fdc2.segments(1).distance * 10^9;
fdc2RetDist = fdc2.segments(2).distance * 10^9;
fdc2ExtFrc = fdc2.segments(1).force * 10^12;
fdc2RetFrc = fdc2.segments(2).force * 10^12;
plot(fdc2RetDist, fdc2RetFrc');
plot(fdc2ExtDist, fdc2ExtFrc);

z = fdc2ExtFrc;
waveFVector = (longWaveDisturbanceAdjuster.calcWaveVector(fdc2.segments(1).distance, fourierFit)+fourierFit.a0)*10^12;
plot(fdc2ExtDist, waveFVector, 'g');

legend('Tip Retract', 'Tip Approach', 'Wave Function');
minX = min([fdc2RetDist fdc2ExtDist]) - 20;
maxX = max([fdc2RetDist fdc2ExtDist]) + 20;
minY = min([fdc2RetFrc fdc2ExtFrc]) - 50;
maxY = max([fdc2RetFrc fdc2ExtFrc]) + 50;
% axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 10);