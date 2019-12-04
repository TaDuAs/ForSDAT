import Simple.*;
import Simple.App.*;
import Simple.Math.*;
import Simple.Scientific.*;

%% Generate objects & settings
App.persistenceContainer.set('settings.prompt', struct(...
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

settings = MainSMFSDA.loadSettings('prompt');
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
histogramBaselineDetector = HistogramBaselineDetector(...
                settings.curveAnalysis.baseline.histogram.binningMethod, ...
                settings.curveAnalysis.baseline.histogram.fitR2Threshold, ...
                settings.curveAnalysis.baseline.histogram.stdScore, ...
                settings.curveAnalysis.baseline.histogram.order, ...
                settings.curveAnalysis.baseline.histogram.minimalBinsNumber);
histogramBaselineDetector.binningMethod = 1;

%% Generate Data
sr = 100; % sampling rate (Hz)
tmax = 20; % time of measurement (sec)
t1 = linspace(0, tmax, tmax*sr); % (sec)
rv = 1; % retract velocity (um/sec)
x1 = t1*rv; % (um)

% linear repultion
ylin = zeros(1, length(x1));
ylin(1:750) = fliplr(1:750)*0.11;

% exponentialy decaying repultion
yexp = 20*exp(-2*x1);

% far interactions
% yp = (-10^-2)*x1.^2;
% yp = polyval([-0.002 0 0.05 0], x1);
kBT = PhysicalConstants.kB * 298;
wlc =...
     Multiply(...
        Scalar(kBT/10),...
        Add(...
            Multiply(...
                Scalar(0.25),...
                Power(...
                    Subtract(...
                        One,...
                        Divide(X, Scalar(50))),...
                    Scalar(-2))),...
            Subtract(...
                Divide(X, Scalar(50)),...
                Scalar(0.25)))).evaluate();
wlcY = [wlc.invoke(x1(1:450)) x1(451:end)*0] * 200;

% noise
ynoise = rand(1, length(x1));

% final signal
driftSlope = -0.5;
y1 = driftSlope*x1 + 8 + yexp + ynoise - wlcY;


%% Gaussian Approach
figure();
[mu, sig] = normfit(y1);
plot(x1, y1, x1, 0*y1+mu);


[baseline, y, noiseAmp, coefficients, s1, mu1] = histogramBaselineDetector.detect(x1, y1);

plot(x1, y1, x1, 0*y1+mu, x1, x1*0);

%% Histogram approach
figure();

sfig = subplot(2, 3, 2);

[bins, binterval, nBins] = Histool.calcBins(y1, 1, 10);
freq = Histool.calcFrequencies(y1, bins);
h1 = histogram(y1, bins);

minX = min(y1);
maxX = max(y1);
minY = min(freq);
maxY = max(freq) + 5;
axis([minX maxX minY maxY]);
xlabel('Force [pN]'); ylabel('Probability');
set(gca,'view',[90 -90]);
set(gca, 'FontSize', 10);


% Find delta X from frequency
% dx1 = rv*(freq/sr);
% dy_dx = diff(bins)./dx1(2:end);
avgFreq = mean(freq);
stdFreq = std(freq);
baselineTiltSlopeEvalThreshold = avgFreq+1*stdFreq;
yFreq = freq(freq > baselineTiltSlopeEvalThreshold);
xFreq = bins(freq > baselineTiltSlopeEvalThreshold);

dx1 = rv*(yFreq/sr);
dy_dx = diff(xFreq)./dx1(2:end);

subplot(2, 3, 5);
hold on;
h1 = histogram(y1, bins);
axis([minX maxX minY maxY]);
xlabel('Force [pN]'); ylabel('Probability');
set(gca,'view',[90 -90]);
set(gca, 'FontSize', 10);

% find indexes of bins to account for
mocData = [];
for i = 1:length(xFreq)
    mocData = [mocData zeros(1, yFreq(i)) + xFreq(i) - 0.5*binterval];
end
h2 = histogram(mocData, bins);
axis([minX maxX minY maxY]);
xlabel('Force [pN]'); ylabel('Probability');
set(gca,'view',[90 -90]);
set(gca, 'FontSize', 10);

% Plot curve + estimations
subplot(2, 3, [1 4]);
hold on;
plot(x1,y1);
plot(x1, x1*mean(dy_dx)+9);
plot(x1, -x1*mean(dy_dx)+9);
legend('Tip Retract', 'Baseline', 'Noise Range');
minX = min(x1);
maxX = max(x1);
minY = min(y1);
maxY = max(y1);
axis([minX maxX minY maxY]);
xlabel('Distance [nm]'); ylabel('Force [pN]');
set(gca, 'FontSize', 10);


% Plot fixed curve
subplot(133);
hold on;
plot(x1, y1+x1*mean(dy_dx));
plot(x1, y1-x1*mean(dy_dx));

% Still not finding sign of slope though....

%% 2d histogram approach
figure();
subplot(2, 7, [1 2 8 9]);
plot(x1, y1);


[xBins, ~, ~] = Histool.calcBins(x1, range(x1)/50, 10);
[yBins, ~, ~] = Histool.calcBins(y1, range(y1)/50, 10);
edges = {xBins, yBins};
subplot(2, 7, [3 4 5]);
hist3([x1' y1'], 'Edges', edges);
set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
colorbar();
% view(gca,[133.3 34.8]);
view(2);
[probabilityMap, bins2D] = hist3([x1' y1'], 'Edges', edges);
xBins2D = bins2D{1};
yBins2D = bins2D{2};
N1 = probabilityMap(probabilityMap > 0);
avgN = mean(N1);
stdN = std(N1);
probabilityThreshold = avgN + 0.5*stdN;
MPP = zeros(size(probabilityMap)); % Most Probable Points
MPP(probabilityMap > probabilityThreshold) = 1;
[xIndices, yIndices] = ind2sub(size(MPP),find(MPP == 1));
[p, s, mu] = epolyfit(xBins2D(xIndices), yBins2D(yIndices), 1);

sumDev = 0;
sumDevSQR = 0;
sumFreq = 0;
for i = 1:length(xBins2D)
    colMPP = MPP(i, :);
    
    if sum(colMPP) > 0
        colProbMap = probabilityMap(i, :);
        sumDev = sumDev + sum(abs((yBins2D-polyval(p, xBins2D(i))) .* colProbMap));
        sumDevSQR = sumDevSQR + sum((abs((yBins2D-polyval(p, xBins2D(i))) .* colProbMap)).^2);
        
        sumFreq = sumFreq + sum(colProbMap);
    end
end
avgDev = sumDev / sumFreq;
stdDev = sqrt(sumDevSQR / sumFreq);
  
subplot(2, 7, [10 11 12]);
hist3([xBins2D(xIndices)' yBins2D(yIndices)'], 'Edges', edges);
set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
hold on;
plot3(xBins2D(xIndices), polyval(p, xBins2D(xIndices)),...
      ones(1, length(xIndices)),...%zeros(1, length(xIndices))+max(probabilityMap(:)),...
      'LineWidth', 3, 'Color', 'r');
view(2);

subplot(2, 7, [6 7 13 14]);
plot(x1, y1-polyval(p,x1),...
     x1, zeros(1, length(x1))+0.4*stdDev,...
     x1, zeros(1, length(x1))-0.4*stdDev);
