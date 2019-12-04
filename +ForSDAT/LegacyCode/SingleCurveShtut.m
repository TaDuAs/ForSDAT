settings = MainSMFSDA.loadSettings(MainSMFSDA.loadSettingsMethods.prompt);
[parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();

mgr = Simple.IO.MXML.load([pwd '\Data Analyzer\analysisManager.xml']);


if ~exist('folderPath', 'var') || isempty(folderPath)
    folderPath = [pwd '\Data Analyzer\Data Files'];
end

%%
[file, folderPath, ~] = uigetfile([folderPath '\*.txt'], 'Choose Single Force-Distance Curve Data File');
fdc = parser.parseJpkTextFile([folderPath '\' file], settings.parser.parseSegmentIndices);

data = mgr.analyze(fdc, 'retract');
figure(1);
set(gcf, 'Position', [0, 50, 734, 596]);
set(gca, 'FontSize', 20);
xlabel('Distance (nm)', 'FontSize', 22);
ylabel('Force (nN)', 'FontSize', 22);
hold on;
plot(data.Distance, data.Force / 1000, 'LineStyle', '-', 'LineWidth', 2);
% [frc, dst, stepHeight, stepDist, stepSlope, data, fdc] = ...
%     MainSMFSDA.analyzeCurve([folderPath '\' file], parser, longWaveDisturbanceAdjuster, curveAnalyzer);

% MainSMFSDA.debugPlotCurve(file, [], frc, dst, data, fdc, curveAnalyzer);

%%
% figure(2);
% hold on;
% plot(dst, frc / 1000, 'LineStyle', '-', 'LineWidth', 2);%, 'Color', 'k');
% xlim([-100, 1000]);
% ylim([-0.600, 0.8]);
% set(gca, 'FontSize', 20);
% xlabel('Distance (nm)', 'FontSize', 25);
% ylabel('Force (nN)', 'FontSize', 25);
% % % x = 1:1000;
% % % y = [(x(1:30)-10).*-4 -60 -20 0 0 0 0 0 (x(38:53)-38).*-3.7 zeros(1, 1000-53)] + rand(1,1000)*0.5;
% % % 
% % % fdc = ForceDistanceCurve();
% % % fdc.segments = [struct('force', y, 'distance', x)];
% % % anlz = ForceDistanceCurveAnalyzer();
% % % [frc, dist, stepHeight, stepDistance, data] = anlz.analyze(fdc, 1);
% % % 
% % % figure();
% % % hold on;
% % % 
% % % plot(dist,frc);
% % % plot(dist(data.steps(1,:)), frc(data.steps(1,:)), 'gv', 'MarkerFaceColor', 'g');
% % % plot(dist(data.steps(2,:)), frc(data.steps(2,:)), 'rv', 'MarkerFaceColor', 'r');
% % % 
% % % hold off;
% % % 
% % % 
% % % Testrun
% % % dirName = [pwd '..\Reches Lab Share\TADA\Testrun'];
% % %
% % % Analyzed on rutile
% % % dirName = [pwd '..\Reches Lab Share\TADA\Already Processed\Peptide 1 on Rutile\2016-05-19 Probe D Ret.Speed=0.8'];
% % %
% % % Autoanalyzed on rutile
% % % dirName = [pwd '..\Reches Lab Share\TADA\Already Processed\Peptide 1 on Rutile - Autoanalyzis'];
% % %
% % % Mica
% % % dirName = [pwd '..\Reches Lab Share\TADA\Peptide 1 on Mica\2016-04-14 Probe D RetSPD=0.8'];
% % % 
% % % fileName = 'force-save-2016.04.14-13.45.44.974.txt';
% % %
% % % Wavy Curvy
% % dirName = [pwd '..\Reches Lab Share\TADA\Peptide 1 on HAp QCM Sensor\2016-07-21 Probe D V=0.4 Delay=1sec'];
% % fileName = 'force-save-2016.07.21-14.44.49.054.txt';
% % 
% % % Initialize
% % settings = MainSMFSDA.loadSettings(true);
% % [parser, longWaveDisturbanceAdjuster, curveAnalyzer] = MainSMFSDA.initialize();
% % 
% % fdc = parser.parseJpkTextFile([dirName '\' fileName], [1,2]);
% % approach = fdc.segments(1);
% % approach.distance = fliplr(approach.distance);
% % approach.force = fliplr(approach.force);
% % [frcApproach, dstApproach, stepHeightApproach, stepDistApproach, stepSlopeApproach, dataApproach] =...
% %     curveAnalyzer.analyze(fdc, 1);
% % [frc, dst, stepHeight, stepDist, stepSlope, data] = curveAnalyzer.analyze(fdc, 2);
% % figure();
% % hold on;
% % grid on;
% % plot(dstApproach,frcApproach);
% % plot(dst,frc);
% % if ~isempty(data.unfilteredSteps)
% %     plot(dst(data.unfilteredSteps(1,:)), frc(data.unfilteredSteps(1,:)), 'bs', 'MarkerFaceColor', 'b');
% %     plot(dst(data.unfilteredSteps(2,:)), frc(data.unfilteredSteps(2,:)), 'cs', 'MarkerFaceColor', 'c');    
% %     if ~isempty(data.steps)
% %         plot(dst(data.steps(1,:)), frc(data.steps(1,:)), 'gv', 'MarkerFaceColor', 'g');
% %         plot(dst(data.steps(2,:)), frc(data.steps(2,:)), 'rv', 'MarkerFaceColor', 'r');
% %     else
% %         plot(dst,zeros(1,length(dst))+data.noiseAmp,dst,zeros(1,length(dst))-data.noiseAmp);
% %     end
% % end
% % 
% % hold off;