import Simple.*;
import Simple.App.*;
import Simple.UI.*;
import ForSDAT.Application.*;
ForSDATApp.ensureAppLoaded();

%% setup simmulation
startRun = now;
stopSimulationFlag = false;
curvesNum = 20;
proggressBar = ConsoleProggressBar('FDC Simulation&Analysis & Analysis-Analysis & Analysis-Analysis-Monitoring...', curvesNum, 10, true);
deltaMeasuredForce = Simple.List(curvesNum);
deltaMeasuredForceInNoiseAmp = Simple.List(curvesNum);
deltaModeledForce = Simple.List(curvesNum);
deltaModeledForceInNoiseAmp = Simple.List(curvesNum);
mgr = Simple.IO.MXML.load([pwd '\Data Simulator\analysisManager.xml']);
mgr.init(Simple.IO.MXML.load([pwd '\Data Simulator\defaultSettings.xml']));
suppressPlotting = true;

%% Iterate simulation
for abc = 1:curvesNum
    
%     tic;
    
    errorFlag = false;
    keepSimInfoFlag = true;
    err = [];
    
    try
        %% Generate Data
%         tic;
        SimulateSingleCurve
%         tocmsg('Curve simulated');
    catch ex
        errorFlag = true;
        keepSimInfoFlag = false;
        err = ex;
        stopSimulationFlag = false;
    end

    if ~errorFlag
        try
            %% Analyze data
%             tic;
            data = mgr.analyze(fdc, 'retract');
            mgr.plotData(gcf, data, 'ChainFitTask');
%             tocmsg('Curve analized');
        catch ex
            errorFlag = true;
            err = ex;
            App.handleException(ex);
        end
    end

    if ~errorFlag
        try
            %% Analyze results
            AnalyzeSimulationAnalysisResults
        catch ex
            errorFlag = true;
            err = ex;
            App.handleException(ex);
        end
    end

    %% Save simulation-analysis-analysis results
    if errorFlag
        results.status = 'error';
        results.exception = getReport(err, 'extended');
        if keepSimInfoFlag
            results.fdc = fdc;
            results.simulation.info = simInfo;
        end
    end

    try
        currentTime = now;
        % this is to save this data cause i didn't implement for matrices yet
        if ~iscell(results.analysis.ChainFit.i)
            results.analysis.ChainFit.i = mat2cell(results.analysis.ChainFit.i,...
                ones(1, size(results.analysis.ChainFit.i, 1)), size(results.analysis.ChainFit.i, 2));
        end
        if ~iscell(results.analysis.Rupture.i)
        results.analysis.Rupture.i = mat2cell(results.analysis.Rupture.i,...
            ones(1, size(results.analysis.Rupture.i, 1)), size(results.analysis.Rupture.i, 2));
        end
        simulationResultsOutputFolder = [pwd '\..\SimulationResults\' datestr(startRun, 'yyyy-mm-dd') '\' results.status '\'];
        simulationResultsOutputFileName = ['SimulationResults_' datestr(currentTime, 'yyyy-mm-dd_HH.MM.SS.FFF') '.xml'];
        Simple.IO.MXML.save([simulationResultsOutputFolder simulationResultsOutputFileName], results);
    catch ex
        logPath = [pwd '\..\SimulationResults\' datestr(currentTime, 'yyyy-mm-dd') '\error\'];
        App.handleException('', err, logPath);
        App.handleException('', ex, logPath);
    end

    %% roundup loop
    proggressBar.reportProggress(1);
    
    if stopSimulationFlag
        break;
    end
end