if ~exist('lastFolderPath', 'var') || isempty(lastFolderPath)
    lastFolderPath = [pwd '\..\Reches Lab Share\TADA\'];
end

% Choose batch folder
folderPath = uigetdir(lastFolderPath, 'Open JPK F-D Curve Batch');

if isempty(folderPath) || (length(folderPath) == 1 && folderPath == 0)
    display('You really should choose a folder...');
    return;
end

lastFolderPath = folderPath;

MainSMFSDA.analyzeFDCurveBatch(folderPath, MainSMFSDA.loadSettingsMethods.prompt, false, true);