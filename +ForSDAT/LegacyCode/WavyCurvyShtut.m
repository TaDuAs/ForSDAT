import Simple.*;
import Simple.UI.*;

folderPath = [pwd '\Data Analyzer\Data Files\Wavy Curvy'];

% Prepare everything
dataFileList = dir([folderPath '\*.txt']);
parser = ForceDistanceCurveParser();
longwaveDisruptionFix = LongWaveDisturbanceAdjuster({0.8, 'end'}, 1);
linker = Simple.Scientific.PEG(5000);% - Chemistry.Mw([Chemistry.Groups.COONHS, Chemistry.Groups.NHFmoc])); % PEG Mw = 5000Da - sidegroups Mw
peptide = Simple.Scientific.Peptide('SVSVGMKPSPRP');
rupturePositionError = 20; % nm
dataAdjuster = FDCurveOOMAdjuster(Simple.Math.OOM.Pico, Simple.Math.OOM.Nano);
baselineDetector = CompositeBaselineDetector(SimpleBaselineDetector(0.05), HistogramBaselineDetector(10));
stepFilter = SingleInteractionStepPicker(linker.backboneLength, rupturePositionError, peptide.backboneLength);
curveAnalyzer = ForceDistanceCurveAnalyzer(stepFilter, baselineDetector, dataAdjuster);
curveAnalyzisOptions = struct('smooth', true);
steps = Simple.List(200, AnalyzedFDCData.empty);
failed = {};

curvesNum = length(dataFileList);
onAlertProggress = @(prog) display(['So far, ' num2str(steps.length()) ' specific interactions were evaluated.']);
proggressBar = ConsoleProggressBar('FDC parsing & analysis', curvesNum, 10, true, [], onAlertProggress);

% Set options
inputOptionFieldNames = {...
    'Retract Speed:',...
    'Parse Seegments:',...
    'Retract Segment Index:',...
    'Bin Size\Binning Method:',...
    'Gaussian Fit R2 Threshold:'};
if ~exist('inputOptionsValues', 'var') || isempty(inputOptionsValues)
    inputOptionsValues = {0.8, 1, 1, 'fd', 0.6};
end
inputOptionsDataTypes = {'double', 'double', 'double', 'double|string', 'double'};
inputOptionsValues = dlgInputValues(...
    inputOptionFieldNames,... % Fields titles
    inputOptionsValues,...    % Default values
    inputOptionsDataTypes,... % Field data types
    'Process Input',...       % Dialogue title
    1);                       % number of lines per input

speed = inputOptionsValues{1};
parseSegmentIndices = inputOptionsValues{2};
retractSegmentIndex = inputOptionsValues{3};
binningMethod = inputOptionsValues{4};
histogramGausFitR2Threshold = inputOptionsValues{5};

for i = 1:curvesNum
    dataFileMetadata = dataFileList(i);

    fileName = [folderPath '\' dataFileMetadata.name];
    
    try
        % Parse FDC
        fdc = parser.parseJpkTextFile(fileName, parseSegmentIndices);
        
        % flip approach segment
        segment = fdc.segments(1);
        segment.force = fliplr(segment.force);
        segment.distance = fliplr(segment.distance);
        
        % Fix longwave disturbance
        longwaveDisruptionFix.adjust(retractSegmentIndex, fdc);
        
        % Analyze FDC
        [frc, dst, stepHeight, stepDist, stepSlope, data] = ...
            curveAnalyzer.analyze(fdc, retractSegmentIndex, curveAnalyzisOptions);
        
        % Save FDC with valid rupture events, and the ruptures of course
        if any(stepHeight)
            steps.add(AnalyzedFDCData(stepHeight, stepDist, stepSlope, dataFileMetadata.name));
        end

        % Plot curve when debugging
        [frc1, dst1] = curveAnalyzer.analyze(fdc, 1, curveAnalyzisOptions);
        figure();
        plot(fdc.segments(1).distance,fdc.segments(1).force,fdc.segments(2).distance,fdc.segments(2).force);
        legend('Approach', 'Retract');
        title('Untouched');
        figure();
        hold on;
        plot(dst1, frc1, dst, frc);
        if ~isempty(data.unfilteredSteps)
            plot(dst(data.unfilteredSteps(1,:)), frc(data.unfilteredSteps(1,:)), 'bs', 'MarkerFaceColor', 'b');
            plot(dst(data.unfilteredSteps(2,:)), frc(data.unfilteredSteps(2,:)), 'cs', 'MarkerFaceColor', 'c');
            plot(dst, zeros(1,length(dst))+data.noiseAmp, 'black');
            plot(dst, zeros(1,length(dst))-data.noiseAmp, 'black');
        end
        minX = min(dst) - 20;
        maxX = max(dst) + 20;
        minY = min(frc) - 50;
        maxY = max(frc) + 50;
        axis([minX maxX minY maxY]);
        xlabel('Distance [nm]'); ylabel('Force [pN]');
        grid('on');
        legend('Approach', 'Retract', 'Detected Rupture Start', 'Detected Rupture End', 'Noise');
        title({dataFileMetadata.name});
        hold off;
    catch ex
        failed{length(failed)+1} = dataFileMetadata.name;
        Simple.App.App.handleException(['Couldnt analyze force curve: ', fileName], ex);
    end
    
    proggressBar.reportProggress(1);
end
