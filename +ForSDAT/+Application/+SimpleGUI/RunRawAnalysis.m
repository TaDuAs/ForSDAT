function varargout = RunRawAnalysis(varargin)
% RunRawAnalysis MATLAB code for RunRawAnalysis.fig
%      RunRawAnalysis, by itself, creates a new RunRawAnalysis or raises the existing
%      singleton*.
%
%      H = RunRawAnalysis returns the handle to a new RunRawAnalysis or the handle to
%      the existing singleton*.
%
%      RunRawAnalysis('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RunRawAnalysis.M with the given input arguments.
%
%      RunRawAnalysis('Property','Value',...) creates a new RunRawAnalysis or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RunRawAnalysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RunRawAnalysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RunRawAnalysis

% Last Modified by GUIDE v2.5 15-Aug-2018 11:44:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RunRawAnalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @RunRawAnalysis_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before RunRawAnalysis is made visible.
function RunRawAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RunRawAnalysis (see VARARGIN)
ForSDAT.Application.ForSDATApp.ensureAppLoaded();

% Choose default command line output for RunRawAnalysis
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes RunRawAnalysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RunRawAnalysis_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)

% --- Executes on button press in run.
function run_Callback(hObject, eventdata, handles)
% hObject    handle to run (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

app = get_app();
ctrl = app.getController('ForceSpecAnalysisController');
ctrl.setAnalyzedSegment('retract');

isSetupOK = true;

isSetupOK = isSetupOK && setConfigElement(handles.rawAnalyzerConfig, @(config) ctrl.setRawAnalyzer(config));
isSetupOK = isSetupOK && setConfigElement(handles.cookedAnalyzerConfig, @(config) ctrl.setCookedAnalyzer(config));
isSetupOK = isSetupOK && setConfigElement(handles.dataAccessConfig, @(config) ctrl.setDataAccessor(config));
isSetupOK = isSetupOK && setConfigElement(handles.settingsConfigFile, @(config) ctrl.setSettings(config));

if isSetupOK
    batchPath = strip(get(handles.batchFolder,'String'));
    if ~isempty(batchPath)
        ctrl.dataAccessor.batchPath = batchPath;
    end
    
    batchanalysis;
end


% --- Executes on button press in runHistogram.
function runHistogram_Callback(hObject, eventdata, handles)
% hObject    handle to runHistogram (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
persistent sk;
if isempty(sk)
    sk = Simple.App.App.startNewSession();
end
session = Simple.App.App.loadSession(sk);
ctrl = session.getController('ForceSpecAnalysisController');

isSetupOK = true;

resultsFilePath = get(handles.histResultsFilePath, 'String');
if ~exist(resultsFilePath, 'file')
    set(handles.histResultsFilePath, 'Background', rgb('Red'));
    isSetupOK = false;
end

importExportTypes = get(handles.dataExportImportType, 'String');
selectedImportExportType = importExportTypes{get(handles.dataExportImportType, 'Value')};
switch selectedImportExportType
    case 'MXML'
        exporter = MXmlDataExporter();
    case 'Delimiter Separated Values'
        exporter = DelimiterValuesDataExporter();
    case 'JPK Delimiter Export'
        exporter = JpkDelimiterValuesExporterImporter();
end
resultsFolder = resultsFilePath(1:find(resultsFilePath == '\', 1, 'Last'));
ctrl.setDataAccessor(MXmlDataAccessor(exporter, resultsFolder));
ctrl.setSettings();

isSetupOK = isSetupOK && setConfigElement(handles.histCookedAnalyzer, @(config) ctrl.setCookedAnalyzer(config));

binningMethodsList = get(handles.histBinningMethod, 'String');
selectedBinningMethodIndex = get(handles.histBinningMethod, 'Value');
if selectedBinningMethodIndex < length(binningMethodsList)
    selectedBinningMethod = binningMethodsList{selectedBinningMethodIndex};
else
    selectedBinningMethod = str2double(get(handles.histBinSize, 'String'));
    if isinf(selectedBinningMethod) || isnan(selectedBinningMethod) || isempty(selectedBinningMethod) || selectedBinningMethod < 0
        set(handles.histBinSize, 'Background', rgb('Red'));
        isSetupOK = false;
    else
        set(handles.histBinSize, 'Background', rgb('White'));
    end
end
ctrl.cookedAnalyzer.dataAnalyzer.binningMethod = selectedBinningMethod;

histFittingModelsList = get(handles.histogramFitModel, 'String');
ctrl.cookedAnalyzer.dataAnalyzer.model = histFittingModelsList{get(handles.histogramFitModel, 'Value')};

if isSetupOK
    ctrl.runPreviouslyCookedAnalysis(resultsFilePath);
end

function isValid = setConfigElement(element, setMethod)
if ischar(element)
    configPath = element;
else
    configPath = get(element,'String');
end
if isempty(regexp(configPath, '^[a-zA-Z]\:\\', 'ONCE'))
    configPath = [pwd '\' configPath];
end

try
    setMethod(configPath);
    if isa(element, 'UIControl')
        set(element, 'Background', rgb('White'));
    end
    isValid = true;
catch ex
    if isa(element, 'UIControl')
        set(element, 'Background', rgb('Red'));
    end
    isValid = false;
    Simple.App.App.handleException(ex);
end

function rawAnalyzerConfig_Callback(hObject, eventdata, handles)
% hObject    handle to rawAnalyzerConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function rawAnalyzerConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rawAnalyzerConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseRawAnalyzer.
function browseRawAnalyzer_Callback(hObject, eventdata, handles)
% hObject    handle to browseRawAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filePath = browseFile(get(handles.rawAnalyzerConfig, 'String'), 'Browse Raw Data Analyzer');
set(handles.rawAnalyzerConfig, 'String', filePath);


function cookedAnalyzerConfig_Callback(hObject, eventdata, handles)
% hObject    handle to cookedAnalyzerConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function cookedAnalyzerConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cookedAnalyzerConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseCookedAnalyzer.
function browseCookedAnalyzer_Callback(hObject, eventdata, handles)
% hObject    handle to browseCookedAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filePath = browseFile(get(handles.cookedAnalyzerConfig, 'String'), 'Browse Cooked Data Analyzer');
set(handles.cookedAnalyzerConfig, 'String', filePath);


function dataAccessConfig_Callback(hObject, eventdata, handles)
% hObject    handle to dataAccessConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function dataAccessConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataAccessConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
    

% --- Executes on button press in browseDataAccessor.
function browseDataAccessor_Callback(hObject, eventdata, handles)
% hObject    handle to browseDataAccessor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filePath = browseFile(get(handles.dataAccessConfig, 'String'), 'Browse Data Accessor');
set(handles.dataAccessConfig, 'String', filePath);


function settingsConfigFile_Callback(hObject, eventdata, handles)
% hObject    handle to settingsConfigFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function settingsConfigFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to settingsConfigFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseSettingsConfigFile.
function browseSettingsConfigFile_Callback(hObject, eventdata, handles)
% hObject    handle to browseSettingsConfigFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filePath = browseFile(get(handles.settingsConfigFile, 'String'), 'Browse Settings Config File');
set(handles.settingsConfigFile, 'String', filePath);


function batchFolder_Callback(hObject, eventdata, handles)
% hObject    handle to batchFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of batchFolder as text
%        str2double(get(hObject,'String')) returns contents of batchFolder as a double


% --- Executes during object creation, after setting all properties.
function batchFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to batchFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseBatchFolder.
function browseBatchFolder_Callback(hObject, eventdata, handles)
% hObject    handle to browseBatchFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folderPath = uigetdir(get(handles.batchFolder, 'String'), 'Open F-D Curves Batch');
if ~isempty(folderPath) && ~(length(folderPath) == 1 && folderPath == 0)
    set(handles.batchFolder, 'String', folderPath);
end

function filePath = browseFile(path, label)
newPath = path(1:find(path == '\', 1, 'Last'));
if isempty(newPath) || isempty(regexp(newPath, '^[a-zA-Z]\:\\'))
    newPath = [pwd '\' newPath];
end

if newPath(end) ~= '\'
    newPath = [newPath '\'];
end

newPath = [newPath '*.*'];
[fileName,newPath,~] = uigetfile(newPath, label);
if isempty(fileName) || (length(fileName) == 1 && fileName == 0)
    filePath = path;
else
    filePath = [newPath, fileName];
end



function histCookedAnalyzer_Callback(hObject, eventdata, handles)
% hObject    handle to histCookedAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histCookedAnalyzer as text
%        str2double(get(hObject,'String')) returns contents of histCookedAnalyzer as a double


% --- Executes during object creation, after setting all properties.
function histCookedAnalyzer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histCookedAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseHistCookedAnalyzer.
function browseHistCookedAnalyzer_Callback(hObject, eventdata, handles)
% hObject    handle to browseHistCookedAnalyzer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filePath = browseFile(get(handles.histCookedAnalyzer, 'String'), 'Browse Cooked Data Analyzer');
set(handles.histCookedAnalyzer, 'String', filePath);

% --- Executes on selection change in dataExportImportType.
function dataExportImportType_Callback(hObject, eventdata, handles)
% hObject    handle to dataExportImportType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dataExportImportType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataExportImportType


% --- Executes during object creation, after setting all properties.
function dataExportImportType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataExportImportType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in histogramFitModel.
function histogramFitModel_Callback(hObject, eventdata, handles)
% hObject    handle to histogramFitModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns histogramFitModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from histogramFitModel


% --- Executes during object creation, after setting all properties.
function histogramFitModel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histogramFitModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function histResultsFilePath_Callback(hObject, eventdata, handles)
% hObject    handle to histResultsFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histResultsFilePath as text
%        str2double(get(hObject,'String')) returns contents of histResultsFilePath as a double


% --- Executes during object creation, after setting all properties.
function histResultsFilePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histResultsFilePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browseHistResultsFile.
function browseHistResultsFile_Callback(hObject, eventdata, handles)
% hObject    handle to browseHistResultsFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filePath = browseFile(get(handles.histResultsFilePath, 'String'), 'Browse Cooked Data Analyzer');
set(handles.histResultsFilePath, 'String', filePath);

% --- Executes on selection change in histBinningMethod.
function histBinningMethod_Callback(hObject, eventdata, handles)
% hObject    handle to histBinningMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = get(hObject, 'Value');
if value == length(get(hObject, 'String')) % specific bin size is the last option
    set(handles.histBinSize, 'Enable', 'on');
else
    set(handles.histBinSize, 'Enable', 'off');
end
% Hints: contents = cellstr(get(hObject,'String')) returns histBinningMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from histBinningMethod


% --- Executes during object creation, after setting all properties.
function histBinningMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histBinningMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function histBinSize_Callback(hObject, eventdata, handles)
% hObject    handle to histBinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of histBinSize as text
%        str2double(get(hObject,'String')) returns contents of histBinSize as a double


% --- Executes during object creation, after setting all properties.
function histBinSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histBinSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function app = get_app()
    app = appd.AppManager.load('ForSDAT', @ForSDAT.Application.ForSDATApp);