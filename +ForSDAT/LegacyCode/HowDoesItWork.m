import Simple.*;
import Simple.App.*;


%% Load curve - baseline tilted near the end
dirName = [pwd '\Data Analyzer\Data Files\End of Baseline Tilt'];
fileName = 'force-save-2016.08.16-18.36.05.283-1.txt';

%% Longwave disturbance fix
dirName = [pwd '\Data Analyzer\Data Files\Wavy Curvy'];
fileName = 'force-save-2016.07.21-14.44.49.054.txt';

%% Perfect Longwave disturbance fix#2
dirName = [pwd '\Data Analyzer\Data Files\Wavy Curvy'];
fileName = 'Perfect.txt';

%% Load curve - Classical single molecule interaction
dirName = [pwd '\Data Analyzer\Data Files'];
fileName = 'Specific Interaction In Segment2.txt';

%% Reset settings
App.getPersistenceContainer.set('settings.prompt', struct(...
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

%% Browse curve
if ~exist('dirName', 'var') || isempty(dirName)
    dirName = [pwd '\..\Reches Lab Share\TADA\Force Spectroscopy\Peptide 3 on HAp\2017-01-24 Probe F RV=0.4\processed_2017-05-24.13.36.12.707\*.*'];
else
    dirName = [dirName '\*.*'];
end
[fileName, dirName, filterIndex] = uigetfile(dirName, 'Open Processed Data File');

%% analyze curve
settings = MainSMFSDA.loadSettings(MainSMFSDA.loadSettingsMethods.prompt);
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
fdc2 = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);
fdc = parser.parseJpkTextFile([dirName '\' fileName], settings.parser.parseSegmentIndices);

compositeBaselineDetector = curveAnalyzer.baselineDetector;
tailBaselineDetector = compositeBaselineDetector.primary;
histogramBaselineDetector = compositeBaselineDetector.secondary;

if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
    tic;
    
    fourierFit = longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
    toc;
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
plot(dst1, frc1);

%% Plot Baseline Tail Method
figure();
hold on;

plot(dst1,frc1, 'LineWidth', 1.5);
sero = zeros(1,length(dst1));
ibsl = round(0.9*length(dst1)):length(dst1);
plot(dst1(ibsl), frc1(ibsl), 'green', 'LineWidth', 1.5);
plot(dst1,zeros(1,length(dst1))+tail.data.baseline.pos, 'black', 'LineWidth', 2);
plot(dst1, sero+tail.data.baseline.pos+tail.data.noiseAmp, 'red', 'LineWidth', 2);
plot(dst1, sero+tail.data.baseline.pos-tail.data.noiseAmp, 'red', 'LineWidth', 2);

legend('Tip Retract', 'Segment for evaluating baseline', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 20);

%% Plot Baseline Histogram Method
figure();

tic;
[baseline, y, noiseAmp, coefficients, s, mu] = histogramBaselineDetector.detect(dst1, frc1);
toc;

sfig = subplot(122);
[h1, bins, freq] = histogramBaselineDetector.plotHistogram(dst1, frc1);
minX = min(frc1) - 50;
maxX = max(frc1) + 50;
minY = min(freq./sum(freq));
maxY = max(freq./sum(freq)) + 0.01;
axis([minX maxX minY maxY]);
xlabel('Force [pN]'); ylabel('Probability');
% Rotate histogram
set(gca,'view',[90 -90]);

set(gca, 'FontSize', 20);

subplot(121);
hold on;
plot(dst1,frc1, 'LineWidth', 1.5);
sero = zeros(1,length(dst1));
plot(dst1, zeros(1,length(dst1))+hist.data.baseline.pos, 'black', 'LineWidth', 2);
plot(dst1, sero+hist.data.baseline.pos+hist.data.noiseAmp, 'red', 'LineWidth', 2);
plot(dst1, sero+hist.data.baseline.pos-hist.data.noiseAmp, 'red', 'LineWidth', 2);

legend('Tip Retract', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');


set(gca, 'FontSize', 20);

%% Plot contact point
figure();
hold on;
grid on;

plot(dst1,frc1);
sero = zeros(1,length(dst1));
icnt = 1:round(0.008*length(dst1));
plot(dst1(icnt), frc1(icnt), 'green');
cntctCoeff = data.contact.coeff;
plot(dst1, sero+data.baseline.pos, 'black');
plot(dst1, sero+cntctCoeff(1)*dst1+cntctCoeff(2), 'red');
plot(data.contact.pos, data.baseline.pos, 'bo');

legend('Tip Retract', 'Contact domain', 'Baseline', 'Contact linear domain', 'Contact point');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(frc1) - 50;
maxY = max(frc1) + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');
set(gca, 'FontSize', 20);


%% Plot ruptures
figure();
hold on;
% yyaxis left;
plot(dst ,frc, 'LineWidth', 1.5);
% yyaxis right;
plot(dst,data.derivative, 'LineWidth', 1.5);
% yyaxis left;
if ~isempty(data.unfilteredSteps)
    
    plot(dst(data.unfilteredSteps(1,:)), frc(data.unfilteredSteps(1,:)), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 13);
    plot(dst(data.unfilteredSteps(2,:)), frc(data.unfilteredSteps(2,:)), 'cs', 'MarkerFaceColor', 'c', 'MarkerSize', 13);    
    if ~isempty(data.steps)
        plot(dst(data.steps(1,:)), frc(data.steps(1,:)), 'gv', 'MarkerFaceColor', 'g');
        plot(dst(data.steps(2,:)), frc(data.steps(2,:)), 'rv', 'MarkerFaceColor', 'r');
    end
end

legend('Tip Retract','1st derivative', 'Detected rupture start', 'Detected rupture end',...
    'Specific interaction start', 'Specific interaction end');

minX = min(dst) - 20;
maxX = max(dst) + 20;
minY = min([frc data.derivative]) - 50;
maxY = max([frc data.derivative]) + 50;
axis([minX maxX minY maxY]);

xlabel('Distance [nm]'); 
% yyaxis left;
ylabel('Force [pN]');
% yyaxis right;
% ylabel('dF/dZ [pN/nm]');
set(gca, 'FontSize', 14);

%% L.R
figure();
hold on;
plot(dst, frc, 'LineWidth', 1.5);
if ~isempty(data.steps)
    indices = data.stepsSlopeFittingData.range(1):data.stepsSlopeFittingData.range(2);
    lrvec = data.stepsSlopeFittingData.model.invoke(dst(indices));
    
    plot(dst(indices), lrvec, 'LineWidth', 2);
    plot(dst(data.stepsSlopeFittingData.range(1)), frc(data.stepsSlopeFittingData.range(1)), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10);
    plot(dst([data.steps(1,:) data.steps(2,:)]), frc([data.steps(1,:) data.steps(2,:)]), 'gv', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
end

legend('Tip retract', 'Load function', 'Loading domain start', 'Specific interaction');

minX = min(dst) - 20;
maxX = max(dst) + 20;
minY = min(frc) - 50;
maxY = max(frc) + 50;
axis([minX maxX minY maxY]);

xlabel('Distance [nm]'); 
ylabel('Force [pN]');
set(gca, 'FontSize', 14);

%% Longwave disturbance fix#2
figure();

subplot(122);
hold on;
plot(dst1,tail.frc+tail.data.baseline.pos, 'LineWidth', 1.5);
sero = zeros(1,length(dst1));
plot(dst1, sero+tail.data.baseline.pos, 'black', 'LineWidth', 2);
plot(dst1, sero+tail.data.baseline.pos+tail.data.noiseAmp, 'red', 'LineWidth', 2);
plot(dst1, sero+tail.data.baseline.pos-tail.data.noiseAmp, 'red', 'LineWidth', 2);

legend('Tip Retract', 'Baseline', 'Noise Range');
minX = min(dst1) - 20;
maxX = max(dst1) + 20;
minY = min(tail.frc) + tail.data.baseline.pos - 50;
maxY = max(tail.frc) + tail.data.baseline.pos + 50;
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 20);

subplot(121);
hold on;
fdc2ExtDist = fdc2.segments(1).distance * 10^9;
fdc2RetDist = fdc2.segments(2).distance * 10^9;
fdc2ExtFrc = fdc2.segments(1).force * 10^12;
fdc2RetFrc = fdc2.segments(2).force * 10^12;
plot(fdc2RetDist, fdc2RetFrc', 'LineWidth', 1.5);
plot(fdc2ExtDist, fdc2ExtFrc, 'LineWidth', 1.5);

z = fdc2ExtFrc;
waveFVector = (longWaveDisturbanceAdjuster.calcWaveVector(fdc2.segments(1).distance, fourierFit)+fourierFit.a0)*10^12;
plot(fdc2ExtDist, waveFVector, 'y', 'LineWidth', 1.5);

legend('Tip Retract', 'Tip Approach', 'Wave Function');
minX = min([fdc2RetDist fdc2ExtDist]) - 20;
maxX = max([fdc2RetDist fdc2ExtDist]) + 20;
minY = min([fdc2RetFrc fdc2ExtFrc]) - 50;
maxY = max([fdc2RetFrc fdc2ExtFrc]) + 50;
% axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');

set(gca, 'FontSize', 20);