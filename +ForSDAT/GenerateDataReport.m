folderPath = [pwd '\..\Reches Lab Share\TADA\Results\Force Spectroscopy\'];
batches = findAllBatchesForAnalyzisRecursive(folderPath);
batchesNum = length(batches);

reportData = Simple.List(20, struct(...
    'batchPath', '',...
    'analyzedStepsCount', 0, ...
    'successfullInteractionRate', 0,...
    'mpf', [], ...
    'mpfStd', [], ...
    'lr', [], ...
    'remark', '',...
    'error', ''));

%%
for i = 1:batchesNum
    currBatch = batches{i};

    subFolders = fliplr(subdir(currBatch));
    for j = 1:length(subFolders)
        currSubFolder = accessarr(subFolders, j);
        if strcmp(currSubFolder.name(1:length('processed')), 'processed')
            dataFile = [currBatch '\' currSubFolder.name '\processedSteps.xml'];
            [data, meta] = Simple.IO.MXML.load(dataFile);
            
            n = length(data);
            N = length(dir([currBatch '\*.txt']));
            meta.successfullInteractionRate = n/N*100;
            
            reportData.add(struct(...
                'batchPath', currBatch,...
                'analyzedStepsCount', n,...
                'successfullInteractionRate', meta.successfullInteractionRate,...
                'mpf', getobj(meta, 'mpf', []),...
                'mpfStd', getobj(meta, 'mpfSTD', []),...
                'lr', getobj(meta, 'lr', []),...
                'remark', 'Analysis was successful.',...
                'error', ''));
            
            Simple.IO.MXML.save(dataFile, data, meta);
            
            break;
        end		
    end
end

endTime = datestr(now, 'YYYY-mm-dd.HH.MM.SS.FFF');
reportPath = [folderPath '\report_' endTime '.xml'];
Simple.IO.MXML.save(reportPath, reportData.vector());