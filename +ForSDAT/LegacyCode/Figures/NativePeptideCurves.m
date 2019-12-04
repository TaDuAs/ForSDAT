import Simple.*;
import Simple.App.*;

fig = figure();
minX = -5;
maxX = 150;
minY = -200;
maxY = 200;


%% Load curve - Classical single molecule interaction
dirName = [pwd '\Data Analyzer\Data Files\Native Peptide Force Curve Figure'];
fileName = 'Probe D RV=0.2um_sec LR=5.56nN_sec.txt';

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

% analyze curve
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

% Plot it
subplot(1, 3, 1);
hold on;
plot(dst, frc, 'LineWidth', 1.5);
if ~isempty(data.steps)
    indices = data.stepsSlopeFittingData.range(1):data.stepsSlopeFittingData.range(2);
    
    plot(dst([data.steps(1,:) data.steps(2,:)]), frc([data.steps(1,:) data.steps(2,:)]), 'gv', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
end

legend('Tip retract', 'Specific interaction');

axis([minX maxX minY maxY]);

annotation(fig,'textbox',...
    [0.2 0.7 0.17 0.19],...
    'String',{['F=' num2str(round(stepHeight,1)) ' pN'], 'L.R=5.56 nN/sec'},...
    'FitBoxToText','on');

xlabel('Distance (nm)'); 
ylabel('Force (pN)');
set(gca, 'FontSize', 14);


%% Load curve - Classical single molecule interaction
dirName = [pwd '\Data Analyzer\Data Files\Native Peptide Force Curve Figure'];
fileName = 'Pobe D RV=0.6um_sec LR=23.16nN_sec - 4.txt';

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

% analyze curve
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

% Plot it
subplot(1, 3, 2);
hold on;
plot(dst, frc, 'LineWidth', 1.5);
if ~isempty(data.steps)
    indices = data.stepsSlopeFittingData.range(1):data.stepsSlopeFittingData.range(2);
    
    plot(dst([data.steps(1,:) data.steps(2,:)]), frc([data.steps(1,:) data.steps(2,:)]), 'gv', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
end

legend('Tip retract', 'Specific interaction');

axis([minX maxX minY maxY]);

annotation(fig,'textbox',...
    [0.2 0.7 0.17 0.19],...
    'String',{['F=' num2str(round(stepHeight,1)) ' pN'], 'L.R=23.16 nN/sec'},...
    'FitBoxToText','on');

xlabel('Distance (nm)'); 
ylabel('Force (pN)');
set(gca, 'FontSize', 14);


%% Load curve - Classical single molecule interaction
dirName = [pwd '\Data Analyzer\Data Files\Native Peptide Force Curve Figure'];
fileName = 'Probe E RV=0.8 LR=44.88nN_sec.txt';

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

% analyze curve
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

% Plot it
subplot(1, 3, 3);
hold on;
plot(dst, frc, 'LineWidth', 1.5);
if ~isempty(data.steps)
    indices = data.stepsSlopeFittingData.range(1):data.stepsSlopeFittingData.range(2);
    
    plot(dst([data.steps(1,:) data.steps(2,:)]), frc([data.steps(1,:) data.steps(2,:)]), 'gv', 'MarkerFaceColor', 'g', 'MarkerSize', 10);
end

legend('Tip retract', 'Specific interaction');

axis([minX maxX minY maxY]);

annotation(fig,'textbox',...
    [0.2 0.7 0.17 0.19],...
    'String',{['F=' num2str(round(stepHeight,1)) ' pN'], 'L.R=44.88 nN/sec'},...
    'FitBoxToText','on');

xlabel('Distance (nm)'); 
ylabel('Force (pN)');
set(gca, 'FontSize', 14);
