import Simple.*;
import Simple.App.*;

% killapp
% startapp
% sk = App.startNewSession();
% session = App.loadSession(sk);
ctrl = App.current.getController('ForceSpecAnalysisController');

% batch = 'C:\Users\taldu\Desktop\Data for Analysis\Pep1 probe D rv=0.2';
% batch = 'C:\Users\taldu\Desktop\ManualProcessing';
% batch = 'C:\Users\taldu\Desktop\Data for Analysis\Pep1 probe D rv=0.2\03_smth_mov10_bsl_hist_nois_1.75_smi_mov150';
% batchSettings = [batch '\AnalysisSettings\'];
% 
% ctrl.setSettings([batchSettings 'defaultSettings.xml']);
% ctrl.setDataAccessor([batchSettings 'jpkDataLoader.xml']);
% ctrl.setRawAnalyzer([batchSettings 'analysisManager.xml']);
% ctrl.setCookedAnalyzer([batchSettings 'cookedAnalyzer.xml']);
% ctrl.setAnalyzedSegment('retract');

raw = ctrl.rawAnalyzer;
smi = raw.getTask('SMIFilterTask');
chain = raw.getTask('ChainFitTask');
rupt = raw.getTask('RuptureEventDetectorTask');
bsl = raw.getTask('BaselineDetectorTask');

%%
%ctrl.analyzeAutomatically();
[results, progress, workLeft] = ctrl.getAnalysisReport();
shouldContinueRunning = workLeft > 0;
data = ctrl.analyzeCurve();
batchPath = ctrl.dataAccessor.batchPath;
queue = ctrl.app.persistenceContainer.get('ForceSpecWF_dataQueue');
iterateJustOneMoreTime = false;

handleCurveDialogOptions = {'accept', 'reject', 'auto', 'stop', 'auto-decide', 'undo', 'reanalyze', 'false_negative', 'false_positive'};
while shouldContinueRunning
    
    [results, progress, workLeft] = ctrl.getAnalysisReport();
    shouldContinueRunning = workLeft > 0;
    
    shouldCopyFileElsewhere = false;
    smi.plotData(figure(1), data, struct('plotFlags', [true, false, true, true, true]));
    
    dlgWhatToDoWithThis = handleCurveDialogOptions{menu('What do you want to do with this curve?', handleCurveDialogOptions{:})};
    switch dlgWhatToDoWithThis
        case 'accept'
            data = ctrl.acceptAndNext();
        case 'reject'
            data = ctrl.rejectAndNext();
        case 'auto'
            ctrl.analyzeAutomatically();
            break;
        case 'stop'
            break;
        case 'auto-decide'
            data = ctrl.autoDecideAndNext();
        case 'undo'
            data = ctrl.undoLastDecision();
        case 'reanalyze'
            data = ctrl.analyzeCurve();
        case 'false_negative'
            shouldCopyFileElsewhere = true;
        case 'false_positive'
            shouldCopyFileElsewhere = true;
    end
    
    if shouldCopyFileElsewhere
        
        [~, curveName] = queue.peak();
        originalFile = [batchPath '\' curveName];
        whereTo = [batchPath '\' dlgWhatToDoWithThis '\'];
        destinationFile = [whereTo curveName];
        
        if ~exist(whereTo, 'dir')
            mkdir(whereTo);
        end

        if ~exist(destinationFile, 'file')
            [status, msg] = copyfile(originalFile, destinationFile, 'f');
        end
        
        data = ctrl.rejectAndNext();
    end
end

ctrl.wrapUpAndAnalyze();
cprintf('Comment', sprintf('\nAll Done\n'));