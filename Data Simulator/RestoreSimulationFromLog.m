import Simple.*;
import Simple.App.*;
import Simple.UI.*;

ForSDATApp.ensureAppLoaded();

logFile = '';
if ~exist('restoreSimulation_pathName', 'var') || isempty(restoreSimulation_pathName) || ~ischar(restoreSimulation_pathName)
    restoreSimulation_pathName = [pwd '\..\SimulationResults\'];
    restoration_files = dir([restoreSimulation_pathName '*.xml']);
    restoration_files = {restoration_files.name};
    currentRestoreFileIndex = 0;
    previousFolder = restoreSimulation_pathName;
end
dlgResult = questdlg('Restore next file?', 'Simulation Result Restoration', 'Yes', 'No', 'Yes-All', 'Yes');

if strcmp(dlgResult, 'No')
    restoreSimulation_pathName = [restoreSimulation_pathName '*.xml'];
    [fileName, restoreSimulation_pathName, ~] = uigetfile(restoreSimulation_pathName, 'Open Processed Data File');
    
    if not(fileName)
        disp('You really should choose a processed data file');
        restoreSimulation_pathName = previousFolder;
        return;
    end
    if ~strcmp(restoreSimulation_pathName, previousFolder)
        restoration_files = dir([restoreSimulation_pathName '*.xml']);
        restoration_files = {restoration_files.name};
        currentRestoreFileIndex = 0;
        previousFolder = restoreSimulation_pathName;
    end
    currentRestoreFileIndex = find(strcmp(restoration_files, fileName));
    if isempty(currentRestoreFileIndex)
        currentRestoreFileIndex = 0;
    end
end
runRestorationOnce = true;

while currentRestoreFileIndex <= length(restoration_files) && (runRestorationOnce || strcmp(dlgResult, 'Yes-All'))
    if ~strcmp(dlgResult, 'No')
        currentRestoreFileIndex = currentRestoreFileIndex+1;
    
        if currentRestoreFileIndex <= length(restoration_files)
            fileName = restoration_files{currentRestoreFileIndex};
        else
            cprintf('UnterminatedStrings', 'Ran through all simulations in this folder already...\n');
            return;
        end
    end
    results = Simple.IO.MXML.load([restoreSimulation_pathName fileName]);


    simInfo = results.simulation.info;
    fdc = results.fdc;
    fdc.segments(1).distance = simInfo.data.d * 10^-9;
    specific = results.simulation.info.specificInteraction;
    nonSpecific = results.simulation.info.nonSpecificInteractions;
    data = results.analysis;
    noiseAmplitude = simInfo.data.noiseAmp;
    errorFlag = false;
    keepSimInfoFlag = true;
    err = [];
    curvesNum = 1000;
    startRun = now;
    stopSimulationFlag = false;
    deltaMeasuredForce = Simple.List(curvesNum);
    deltaMeasuredForceInNoiseAmp = Simple.List(curvesNum);
    deltaModeledForce = Simple.List(curvesNum);
    deltaModeledForceInNoiseAmp = Simple.List(curvesNum);
    mgr = Simple.IO.MXML.load([pwd '\Data Simulator\analysisManager.xml']);

    %% Analyze data
    tic;

    data = mgr.analyze(fdc, 'retract');
    mgr.plotData(figure(1), data);
    title(restoration_files{currentRestoreFileIndex});


    tocmsg('Simulation restored');

    %%
    AnalyzeSimulationAnalysisResults

    tocmsg('Simulation analized');

    %%
    PlotAllInteractions
    fdc.plotCurve(figure(4));
    mgr.plotData(figure(5), data, 'ChainFitTask');
    movegui(figure(3), 'northeast');
    movegui(figure(2), 'south');
    movegui(figure(1), 'southwest');
    movegui(figure(5), 'southeast');
    movegui(figure(4), 'north');
    
    %% Decide what to do with this curve
    handleCurveDialogOptions = {'true_positive', 'false_positive', 'true_negative', 'false_negative', 'nothing', 'nothing_and_stop'};
    dlgWhatToDoWithThis = handleCurveDialogOptions{menu('What do you want to do with this curve?', handleCurveDialogOptions{:})};
    if strcmp(dlgWhatToDoWithThis, 'nothing_and_stop')
        return;
    elseif ~strcmp(dlgWhatToDoWithThis, 'nothing')
        newStatusFolder = [restoreSimulation_pathName dlgWhatToDoWithThis '-manual\'];
        if ~exist(newStatusFolder, 'dir')
            mkdir(newStatusFolder);
        end
        movefile([restoreSimulation_pathName '\' fileName], [newStatusFolder fileName]);
    end

    runRestorationOnce = false;
end

