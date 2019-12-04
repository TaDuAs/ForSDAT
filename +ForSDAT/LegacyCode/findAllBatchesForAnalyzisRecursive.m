function list = findAllBatchesForAnalyzisRecursive(folder)
    list = Simple.List(10, struct('name', ''));
   
    function doItRecursively(folder, list)
        subFolders = subdir(folder);
        for i = 1:length(subFolders)
            doItRecursively([folder '\' subFolders(i).name], list);
        end

        if ~isempty(dir([folder, '\forceBatchSettings.xml']))
            list.add(struct('name', folder));
        end
    end

    doItRecursively(folder, list);
    list = list.foreach(@(obj, i) obj.name, 2);
end

