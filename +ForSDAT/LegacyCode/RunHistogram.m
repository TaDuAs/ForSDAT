import Simple.*;
import Simple.UI.*;

%% prepare setup
settupPath = 
app = ForSDAT.Application.startconsole();
[~, session] = app.startSession();
controller = session.getController('ForceSpecAnalysisController');
controller.setCookedAnalyzer();

%% Load Data File
if ~exist('pathName', 'var') || isempty(pathName) || ~ischar(pathName)
    pathName = [pwd '\..\Reches Lab Share\TADA\Results\Force Spectroscopy\'];
end
pathName = [pathName '*.*'];
[fileName,pathName,filterIndex] = uigetfile(pathName, 'Open Processed Data File');

if not(fileName)
    display('You really should choose a processed data file');
    return;
end

if ~exist('plotTitle', 'var')
    plotTitle = {'', ''};
end
plotTitle = dlgInputValues(...
    {'Plot Title:', 'Batch Name:'},... % Fields titles
    plotTitle,...                      % Default values
    {'string', 'string'},...           % Field data types
    'Enter Titles',...                 % Dialogue title
    1);                                % number of lines per input

% read file
filePath = [pathName fileName];
if any(regexp(filePath, '.+\.xml$'))
    serializer = app.IocContainer.get('mxml.XmlSerializer');
    data = serializer.load(filePath);
    metadata = data.meta;
    data = data.data;
%     steps = Simple.List(data, length(data), Simple.IO.MXML.newempty(data(1)));
    
    distances = [data.z];
    forces = [data.f];
    slope = arrayfun(@(obj) cond(isempty(obj.slope), NaN, obj.slope), data);
    lrArr = arrayfun(@(obj) cond(isempty(obj.lr), NaN, obj.lr), data);
    
%     try
%         stepsFD = steps.foreach(@(obj, i) [obj.z; obj.f; obj.slope; cond(isempty(obj.lr), NaN, obj.lr)], 3).vector;
%         slope = stepsFD(3,:);
%         lrArr = stepsFD(4,:);
%     catch ex
%         stepsFD = steps.foreach(@(obj, i) [obj.z; obj.f], 3).vector;
%         slope = zeros(1, size(stepsFD, 2));
%         lrArr = [];
%     end
%     distances = stepsFD(1,:);
%     forces = stepsFD(2,:);
else
%     M = tdfread(filePath, 'tab');
    M = readtable(filePath);

    if any(regexp(filePath, '.+\-steps.*'))
        % adjust force to pN
        forces = M.Step_Height_0x5BN0x5D .* 10^12;
        distances = M.Step_Position_0x5Bm0x5D .* 10^9;
        slope = zeros(1, length(forces));
        lrArr = [];
    elseif any(regexp(filePath, '.+\-chainfits.*'))
        % adjust force to pN
        forces = M.Breaking_Force_0x5BN0x5D .* 10^12;
        distances = M.X_Max_0x5Bm0x5D .* 10^9;
        slope = zeros(1, length(forces));
        lrArr = M.Critical_Loading_Rate_0x5BN0x2Fs0x5D .* 10^9;
    end
end

%% Set options & analyze
inputOptionFieldNames = {'Retract Speed:','Bin Size\Binning Method:','Gaussian Fit R2 Threshold:','Fitting Model:'};
if ~exist('RunHistogram_inputOptionsValues', 'var') || isempty(RunHistogram_inputOptionsValues)
    RunHistogram_inputOptionsValues = {0.8, 'fd', 0.6, 'gamma'};
end
inputOptionsDataTypes = {'double', 'double|string', 'double', 'string'};
RunHistogram_inputOptionsValues = dlgInputValues(...
    inputOptionFieldNames,... % Fields titles
    RunHistogram_inputOptionsValues,...    % Default values
    inputOptionsDataTypes,... % Field data types
    'Process Input',...       % Dialogue title
    1);                       % number of lines per input

speed = RunHistogram_inputOptionsValues{1};
binningMethod = RunHistogram_inputOptionsValues{2};
histogramGausFitR2Threshold = RunHistogram_inputOptionsValues{3};
fittingModel = RunHistogram_inputOptionsValues{4};



settings = MainSMFSDA.loadSettings(MainSMFSDA.loadSettingsMethods.default);

plotTool = StepsDataAnalyzer(binningMethod, settings.dataAnalysis.minimalBinsNumber, fittingModel, histogramGausFitR2Threshold);
plotOptions = struct('title', {plotTitle});
options = struct(...
    'showHistogram', true,...
    'binsInterval', binningMethod,...
    'fitR2Threshold', histogramGausFitR2Threshold,...
    'model', fittingModel,...
    'plotOptions', plotOptions);

[mpf, mpfStd, mpfErr, lr, lrErr, returnedOpts] = plotTool.doYourThing(forces, distances, slope, speed, lrArr, options);

output.mpf = mpf;
output.mpfStd = mpfStd;
output.mpfErr = mpfErr;

output.lr = lr;
output.lrErr = lrErr;
output.batch = plotTitle{2};
output.settings.binning = binningMethod;
output.settings.fitting = fittingModel;
output.settings.speed = speed;
output.settings.gausFitR2Threshold = histogramGausFitR2Threshold;

