classdef ExperimentRepositoryResultsArchive < lists.IDictionary
    
    properties
        Archive dao.IArchive = dao.ZipArchive.empty();
        DAO dao.FSOutputDataExporter = dao.MXmlDataExporter.empty();
    end
    
    methods
        function this = ExperimentRepositoryResultsArchive(dao, archive)
            this.DAO = dao;
            this.Archive = archive;
        end
    end
    
    methods % lists.IDictionary
        % adds a new item to the dictionary
        function add(this, key, value)
            this.setv(key, value);
        end
        
        % replaces all items in the dictionary with a new key-value set
        function setVector(~, ~, ~)
            throw(MException(...
                'ForSDAT:Application:Models:ExperimentRepositoryResultsArchive:ClearArchiveNotSupported',...
                'Clearing an ExperimentRepositoryResultsArchive is not supported'));
        end
        
        % clears the dictionary
        function clear(~)
            throw(MException(...
                'ForSDAT:Application:Models:ExperimentRepositoryResultsArchive:ClearArchiveNotSupported',...
                'Clearing an ExperimentRepositoryResultsArchive is not supported'));
        end
        
        % Gets all stored keys
        function keys = keys(this)
            keys = this.Archive.listFiles();
        end
        
        % Gets all stored values
        function items = values(this)
            % extract the archive
            tempFolder = this.Archive.extractAll();
            
            % get all files in the archive
            [~, ~, files] = this.Archive.listFiles(tempFolder, '**');
            
            % load and deserialize each file in the archive
            n = numel(files);
            items = cell(1, n);
            for i = 1:n
                items{i} = this.DAO.load(files{i});
            end
        end
        
        % Determines whether the cache stores a value with the specified
        % key
        function tf = isKey(this, key)
            tf = ismember(key, this.keys());
        end
    end
    
    methods % lists.ICollection
        function n = length(this)
            n = numel(this.keys());
        end
        
        function tf = isempty(this)
            tf = isempty(this.keys());
        end
        
        function s = size(this, dim)
            if nargin > 1
                s = size(this.keys(), dim);
            else
                s = size(this.keys());
            end
        end
        
        function value = getv(this, key)
            postfix = this.DAO.outputFilePostfix;
            if endsWith(key, ['.', postfix])
                fileArchiveName = key;
            else
                fileArchiveName = [key, '.', postfix];
            end
            
            fn = this.Archive.extractFile(fileArchiveName);
            value = this.DAO.load(fn);
        end
        
        function setv(this, key, value)
            % make zip archive extract its contents
            tempFolder = this.Archive.extractAll();
            
            % write the object to a temp file
            tempfilePath = fullfile(tempFolder, key);
            this.DAO.save(value, tempfilePath);
            
            % save the temp file with the archive
            this.Archive.putFile(tempfilePath);
        end
        
        function removeAt(~, ~)
            throw(MException(...
                'ForSDAT:Application:Models:ExperimentRepositoryResultsArchive:ClearArchiveNotSupported',...
                'Removing entries from an ExperimentRepositoryResultsArchive is not supported'));
        end
    end
end

