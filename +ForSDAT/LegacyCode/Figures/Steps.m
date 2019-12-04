import Simple.*;
import Simple.App.*;

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

if settings.curveAnalysis.adjustments.shouldFixNonLinearBaseline
    tic;
    fourierFit = longWaveDisturbanceAdjuster.adjust(settings.parser.retractSegmentIndex, fdc);
    toc;
end

[frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, settings.parser.retractSegmentIndex);

figure();

%% Plot ruptures
subplot(1, 2, 1);
hold on;
plot(dst ,frc, 'LineWidth', 1.5);
yyaxis right;
plot(dst,data.derivative, 'LineWidth', 1.5);

if ~isempty(data.unfilteredSteps)
    [~, ~, dfNoiseAmp, ~, ~, ~] = curveAnalyzer.baselineDetector.detect(dst, data.derivative);
    [~, dfMaxima] = findpeaks(data.derivative, 'MinPeakHeight', dfNoiseAmp);
    plot(dst(dfMaxima), data.derivative(dfMaxima), 'ro', 'MarkerFaceColor', 'r');
    plot(dst(dfMaxima), frc(dfMaxima), 'gv', 'MarkerFaceColor', 'g');
            
%     plot(dst(data.unfilteredSteps(1,:)), frc(data.unfilteredSteps(1,:)), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 13);
%     plot(dst(data.unfilteredSteps(2,:)), frc(data.unfilteredSteps(2,:)), 'cs', 'MarkerFaceColor', 'c', 'MarkerSize', 13);    
%     if ~isempty(data.steps)
%         plot(dst(data.steps(1,:)), frc(data.steps(1,:)), 'gv', 'MarkerFaceColor', 'g');
%         plot(dst(data.steps(2,:)), frc(data.steps(2,:)), 'rv', 'MarkerFaceColor', 'r');
%     end
end

legend('Tip Retract','1st derivative', '1st derivative maxima', 'Identified discontinuities');

minX = -5;
maxX = 150;
minY = min([frc data.derivative]) - 50;
maxY = max([frc data.derivative]) + 50;

ylabel('dF/dZ (pN/nm)');
axis([minX maxX minY maxY]);
set(gca, 'ycolor', 'k');

yyaxis left;
xlabel('Distance (nm)'); 
ylabel('Force (pN)');
axis([minX maxX minY maxY]);


set(gca, 'FontSize', 14);

%% L.R
subplot(1, 2, 2);
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

minX = -5;
maxX = 150;
minY = min(frc) - 50;
maxY = max(frc) + 50;
axis([minX maxX minY maxY]);

xlabel('Distance (nm)'); 
ylabel('Force (pN)');
set(gca, 'FontSize', 14);
