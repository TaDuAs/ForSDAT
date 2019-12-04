%% Prepare data
peps = peptides;
startAtTimes = [0.5145 0.1683 1.676 0.5004 0.4694];
startAtPoints = zeros(1, 5);

for i = 1:length(peps)
    pep = peps(i);
    zeroPointTime = startAtTimes(i);
    startAtTime = zeroPointTime - 0.4;
%     endAtTime = startAtPoints(i) + 14;

    startAt = find(pep.t > startAtTime, 1);
    zeroPoint = find(pep.t >= zeroPointTime, 1);
    startAtPoints(i) = zeroPoint;
%     endAt = find(pep.t>=endAtTime, 1);
    
    timeShift = pep.t(zeroPoint) - 0.4;
%     newTime = pep.t(startAt:endAt);
    newTime = pep.t(startAt:end);
    newTime = newTime - timeShift;
    pep.t = newTime;

    for j = 1:2:17
        overtone = num2str(j);
        if pep.f.isKey(overtone) 
            f = pep.f(overtone);
            f = f-f(zeroPoint);
            f = f(startAt:end);
%             f = f(startAt:endAt);
            pep.f(overtone) = f;
        end
    end
    for j = 1:2:17
        overtone = num2str(j);
        if pep.d.isKey(overtone)
            d = pep.d(overtone);
            d = d-d(zeroPoint);
            d = d(startAt:end);
%             d = d(startAt:endAt);
            pep.d(overtone) = d;
        end
    end

    peps(i) = pep;
end

%average all overtones
overtoneList = {'3' '5' '7' '9' '11'};
for i = 1:length(peps)
    currPep = peps(i);
%     
%     endAt = find(currPep.t > endAtTimes(i), 1);
%     startAt = find(currPep.t > startAtTimes(i), 1);
%     
    f = zeros(length(overtoneList), length(currPep.t));
    d = zeros(length(overtoneList), length(currPep.t));
    for j = 1:length(overtoneList)
        f(j, :) = currPep.f(overtoneList{j});
        d(j, :) = currPep.d(overtoneList{j});
    end
    
%     f = cell2mat(currPep.f.values)';
%     f = f(:, startAt:endAt);
%     f = f-f(:, 1);
%     d = cell2mat(currPep.d.values)';
%     d = d(:, startAt:endAt);
%     d = d-d(:, 1);
    
    currPep.avgF = mean(f);
    currPep.stdF = std(f);
    currPep.avgD = mean(d);
    currPep.stdD = std(d);
    peps2(i) = currPep;
end

peps = peps2;

pep1 = peps(1);
pep2 = peps(2);
pep3 = peps(3);
pep4 = peps(4);
pep5 = peps(5);



%% Adhesion curve
figure();
hold on;
overtone = '7';
freqColors = winter(5);
dispColors = autumn(5);

yyaxis left;
plot(pep1.t, smooth(pep1.f(overtone), 7, 'sgolay', 3), '-', 'Color', freqColors(1, :), 'LineWidth', 1.5);
plot(pep2.t, smooth(pep2.f(overtone), 25, 'sgolay', 3), '-', 'Color', freqColors(2, :), 'LineWidth', 1.5);
plot(pep3.t, smooth(pep3.f(overtone), 7, 'sgolay', 3), '-', 'Color', freqColors(3, :), 'LineWidth', 1.5);
plot(pep4.t, smooth(pep4.f(overtone), 7, 'sgolay', 3), '-', 'Color', freqColors(4, :), 'LineWidth', 1.5);
plot(pep5.t, smooth(pep5.f(overtone), 7, 'sgolay', 3), '-', 'Color', freqColors(5, :), 'LineWidth', 1.5);

% set axis range, center frequency & dissipation axes around zero
% add axis titles
minX = min([pep1.t; pep2.t; pep3.t; pep4.t; pep5.t;]);
maxX = max([pep1.t; pep2.t; pep3.t; pep4.t; pep5.t;]);
xlabel('Time (h)');

% Frequency axis
minF = min([pep1.f(overtone); pep2.f(overtone); pep3.f(overtone); pep4.f(overtone); pep5.f(overtone);]);
maxF = max([pep1.f(overtone); pep2.f(overtone); pep3.f(overtone); pep4.f(overtone); pep5.f(overtone);]);
fAbsMax = max(abs([maxF minF]));
fSpacing = 0.05 * range([fAbsMax, -fAbsMax]);
axis([minX, maxX, -fAbsMax-fSpacing, fAbsMax+fSpacing]);
ylabel('Frequency (Hz)');


% Dissipation axis
yyaxis right;
plot(pep1.t, smooth(pep1.d(overtone), 7, 'sgolay', 3), '-', 'Color', dispColors(1, :), 'LineWidth', 1.5);
plot(pep2.t, smooth(pep2.d(overtone), 25, 'sgolay', 3), '-', 'Color', dispColors(2, :), 'LineWidth', 1.5);
plot(pep3.t, smooth(pep3.d(overtone), 7, 'sgolay', 3), '-', 'Color', dispColors(3, :), 'LineWidth', 1.5);
plot(pep4.t, smooth(pep4.d(overtone), 7, 'sgolay', 3), '-', 'Color', dispColors(4, :), 'LineWidth', 1.5);
plot(pep5.t, smooth(pep5.d(overtone), 7, 'sgolay', 3), '-', 'Color', dispColors(5, :), 'LineWidth', 1.5);

minD = min([pep1.d(overtone); pep2.d(overtone); pep3.d(overtone); pep4.d(overtone); pep5.d(overtone);]);
maxD = max([pep1.d(overtone); pep2.d(overtone); pep3.d(overtone); pep4.d(overtone); pep5.d(overtone);]);
dAbsMax = max(abs([maxD minD]));
dSpacing = 0.05 * range([dAbsMax, -dAbsMax]);
axis([minX, maxX, -dAbsMax-dSpacing, dAbsMax+dSpacing]);
ylabel('Dissipation (10^-^6)');

legend('Native Peptide Frequency', 'Peptide2 Frequency', 'Peptide3 Frequency', 'Peptide4 Frequency', 'Peptide5 Frequency',...
    'Native Peptide Dissipation', 'Peptide2 Dissipation', 'Peptide3 Dissipation', 'Peptide4 Dissipation', 'Peptide5 Dissipation');
title(['F/D ' overtone]);

set(gca, 'FontSize', 20);
set(gca, 'ycolor', 'k');


%% AVG Adhesion plot
figure();
hold on;
freqColors = winter(5);
dispColors = autumn(5);

yyaxis left;

plotWithErrorsSpaced(pep1.t', pep1.avgF, zeros(1, length(pep1.avgF)), pep1.stdF, 15,...
    struct('Color', freqColors(1, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', freqColors(1, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep2.t', pep2.avgF, zeros(1, length(pep2.avgF)), pep2.stdF, 15,...
    struct('Color', freqColors(2, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', freqColors(2, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep3.t', pep3.avgF, zeros(1, length(pep3.avgF)), pep3.stdF, 15,...
    struct('Color', freqColors(3, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', freqColors(3, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep4.t', pep4.avgF, zeros(1, length(pep4.avgF)), pep4.stdF, 15,...
    struct('Color', freqColors(4, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', freqColors(4, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep5.t', pep5.avgF, zeros(1, length(pep5.avgF)), pep5.stdF, 15,...
    struct('Color', freqColors(5, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', freqColors(5, :), 'MarkerSize', 4));

% set axis range, center frequency & dissipation axes around zero
% add axis titles
minX = min([pep1.t; pep2.t; pep3.t; pep4.t; pep5.t;]);
maxX = max([pep1.t; pep2.t; pep3.t; pep4.t; pep5.t;]);
xlabel('Time (h)');

% Frequency axis
minF = min([pep1.avgF pep2.avgF pep3.avgF pep4.avgF pep5.avgF]);
maxF = max([pep1.avgF pep2.avgF pep3.avgF pep4.avgF pep5.avgF]);
fAbsMax = max(abs([maxF minF]));
fSpacing = 0.05 * range([fAbsMax, -fAbsMax]);
axis([minX, maxX, -fAbsMax-fSpacing, fAbsMax+fSpacing]);
ylabel('Frequency (Hz)');


% Dissipation axis
yyaxis right;
plotWithErrorsSpaced(pep1.t', pep1.avgD, zeros(1, length(pep1.avgD)), pep1.stdD, 15,...
    struct('Color', dispColors(1, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', dispColors(1, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep2.t', pep2.avgD, zeros(1, length(pep2.avgD)), pep2.stdD, 15,...
    struct('Color', dispColors(2, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', dispColors(2, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep3.t', pep3.avgD, zeros(1, length(pep3.avgD)), pep3.stdD, 15,...
    struct('Color', dispColors(3, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', dispColors(3, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep4.t', pep4.avgD, zeros(1, length(pep4.avgD)), pep4.stdD, 15,...
    struct('Color', dispColors(4, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', dispColors(4, :), 'MarkerSize', 4));
plotWithErrorsSpaced(pep5.t', pep5.avgD, zeros(1, length(pep5.avgD)), pep5.stdD, 15,...
    struct('Color', dispColors(5, :), 'LineWidth', 1.5),...
    struct('Marker', 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', dispColors(5, :), 'MarkerSize', 4));

minD = min([pep1.avgD pep2.avgD pep3.avgD pep4.avgD pep5.avgD]);
maxD = max([pep1.avgD pep2.avgD pep3.avgD pep4.avgD pep5.avgD]);
dAbsMax = max(abs([maxD minD]));
dSpacing = 0.05 * range([dAbsMax, -dAbsMax]);
axis([minX, maxX, -dAbsMax-dSpacing, dAbsMax+dSpacing]);
ylabel('Dissipation (10^-^6)');

legend('Native Peptide Frequency', 'Peptide2 Frequency', 'Peptide3 Frequency', 'Peptide4 Frequency', 'Peptide5 Frequency',...
    'Native Peptide Dissipation', 'Peptide2 Dissipation', 'Peptide3 Dissipation', 'Peptide4 Dissipation', 'Peptide5 Dissipation');
title(['F/D ' overtone]);

set(gca, 'FontSize', 20);
set(gca, 'ycolor', 'k');


%% dF vs. dD
startAtTimes = [0.42 0.45 0.5 0.4538 0.4];
endAtTimes = [5 10 6 5 3.5];
figure();
hold on;
overtone = '9';



plot(abs(f), d, 'o');

endAt = find(pep2.t>endAtTimes(2), 1);
startAt = find(pep2.t>startAtTimes(2), 1);
d = smooth(pep2.d(overtone), 25, 'sgolay', 3);
d = d(startAt:endAt);
d = d-d(1);
f = smooth(pep2.f(overtone), 25, 'sgolay', 3);
f = f(startAt:endAt);
f = f-f(1);
plot(abs(f), d, 'o');

endAt = find(pep3.t>endAtTimes(3), 1);
startAt = find(pep3.t>startAtTimes(3), 1);
d = smooth(pep3.d(overtone), 7, 'sgolay', 3);
d = d(startAt:endAt);
d = d-d(1);
f = smooth(pep3.f(overtone), 7, 'sgolay', 3);
f = f(startAt:endAt);
f = f-f(1);
plot(abs(f), d, 'o');

endAt = find(pep4.t>endAtTimes(4), 1);
startAt = find(pep4.t>startAtTimes(4), 1);
d = smooth(pep4.d(overtone), 7, 'sgolay', 3);
d = d(startAt:endAt);
d = d-d(1);
f = smooth(pep4.f(overtone), 7, 'sgolay', 3);
f = f(startAt:endAt);
f = f-f(1);
plot(abs(f), d, 'o');

endAt = find(pep5.t>endAtTimes(5), 1);
startAt = find(pep5.t>startAtTimes(5), 1);
d = smooth(pep5.d(overtone), 7, 'sgolay', 3);
d = d(startAt:endAt);
d = d-d(1);
f = smooth(pep5.f(overtone), 7, 'sgolay', 3);
f = f(startAt:endAt);
f = f-f(1);
plot(abs(f), d, 'o');

legend('Native Peptide', 'Peptide2', 'Peptide3', 'Peptide4', 'Peptide5');
title(['F' overtone]);
ylabel('\DeltaD (10^-^6)');
xlabel('\DeltaF (Hz)');
set(gca, 'FontSize', 20);
axis([0 32 0 7.5]);