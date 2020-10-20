%
% At the end of process, the the histogram is displayed by default, but can
% be configured to not show.
% ** Don't expect a nice histogram in this example, there are only 9 curves
%    in the example batch of which only 4 show a specific interaction
%
% Notice the output folder showing up uder the data folder once the process
% job is done.
% The output folder contains the results export file (in this example as
% .xml but can also export as .csv)
% The DataAccessor can be configured to also copy the accepted curves
% into the processed folder, in order to show force profiles of the
% specific interaction for your paper figure. 
% 
% You can also examine the experiment repository file under "Repos" folder
% this would be the file name: Example01.xml
% it should contain this example experiment results at the end of the
% processing
% 

% start ForSDAT application
app = ForSDAT.Application.ForSDATApp.ensureAppLoaded('console');
util.disableWarnings();

% determine whether to oversee the results
supervise = true;

% start session and activate controller
[~, session] = app.startSession();
controller = session.getController('ForceSpecAnalysisController');
controller.setProject(gen.localPath('ExampleProject.xml'));
controller.AnalyzedSegment = 'retract';

% cofigure data accessor to save accepted curves in the processed folder
% This could also be configured in the config file ofcourse
%
% controller.Project.DataAccessor.SaveAcceptedItems = true;

% set experiments repository folder
% this folder will contain the experiment repositories saved as text files
controller.Project.CookedAnalyzer.ExperimentRepositoryDAO.RepositoryPath = gen.localPath('Repos');

% If using the same project for different experiment collections (i.e. different molecules, treatments, etc.),
% set the experiment repository name programmatically
%
% controller.Project.ExperimentCollectionName = 'Example01';

% set analyzed batch path
% this could also be defined in the config file, but this way is safer,
% more versatile, better.
controller.Project.DataAccessor.BatchPath = gen.localPath('Data');

% this could be derived from batch folder name if the data is organized in
% a meaningfull way
controller.Project.RunningExperimentId = 'Example01';

% start analysis
controller.start();

if ~supervise
    % perform analysis automatically
    controller.analyzeAutomatically();
else
    % oversee automatic analysis
    rawAnalyzer = controller.Project.RawAnalyzer;
    visTaskList = [rawAnalyzer.getTask('SMIFilterTask'),...
        rawAnalyzer.getTask('RuptureEventDetectorTask')];
    analyzeHApSMFSBatchManualSupervision(controller, visTaskList);
end

% this will generate the histogram and save results to the experiment
% repository
histFig = figure(3);
clf(histFig);
results = controller.wrapUpAndAnalyze();


function analyzeHApSMFSBatchManualSupervision(controller, visTaskList)
    % check if work is done on this batch
    [results, progress, workLeft] = controller.getAnalysisReport();
    shouldContinueRunning = workLeft > 0;
    
    % perform raw analysis on current curve in the queue
    data = controller.analyzeCurve();
    
    % check if the curve was accepted
    isCurveAccepted = controller.discloseDecision();

    handleCurveDialogOptions = {'accept', 'reject', 'auto-decide', 'undo', 'export_curve', 'finish automatically', 'stop'};
    while shouldContinueRunning

        [results, progress, workLeft] = controller.getAnalysisReport();
        shouldContinueRunning = workLeft > 0;

        mainFig = figure(1);
        clf(mainFig);
        visTaskList(1).plotData(mainFig, data, struct('plotFlags', [true, false, true, true, true]));
        
        if isCurveAccepted
            set(mainFig, 'Color', [0, 150, 0]/255);
        else
            set(mainFig, 'Color', [204, 51, 0]/255);
        end
        
        % display all visualization tasks
        for visTskIdx = 2:numel(visTaskList)
            visTskFig = figure(visTskIdx);
            clf(visTskFig);
            visTaskList(visTskIdx).plotData(visTskFig, data);
        end

        dlgWhatToDoWithThis = handleCurveDialogOptions{menu('What do you want to do with this curve?', handleCurveDialogOptions{:})};
        switch dlgWhatToDoWithThis
            case 'accept'
                data = controller.acceptAndNext();
                isCurveAccepted = controller.discloseDecision();
            case 'reject'
                data = controller.rejectAndNext();
                isCurveAccepted = controller.discloseDecision();
            case 'finish automatically'
                controller.analyzeAutomatically();
                break;
            case 'stop'
                break;
            case 'auto-decide'
                data = controller.autoDecideAndNext();
                isCurveAccepted = controller.discloseDecision();
            case 'undo'
                data = controller.undoLastDecision();
                isCurveAccepted = controller.discloseDecision();
            case 'export_curve'
                % export the curve elsewhere
                exportCurve(controller);
                
                % reanalyze the curve
                data = controller.analyzeCurve();
                isCurveAccepted = controller.discloseDecision();
        end
    end

    util.cprintf('Comment', sprintf('\nAll Done\n'));
end

function exportCurve(controller)
%TODO: Add export functionality to the controller

    % this is cheating...
    % but we know ForSDATs inner workings so we can cheat
    queue = controller.App.Context.get('ForSDAT.Application.Workflows.ForceSpecWF_dataQueue');
    [~, curveName] = queue.peak();
    
    % copy this file
    batchPath = controller.Project.DataAccessor.BatchPath;
    originalFile = fullfile(batchPath, curveName);
    
    % let the user choose where to save the curve
    destinationFile = uiputfile(curveName, 'Export Curve');
    if ~(ischar(destinationFile) || isstring(destinationFile)) || isempty(destinationFile)
        return;
    end

    % copy the exported curve to the new location
    [status, msg] = copyfile(originalFile, destinationFile, 'f');
end