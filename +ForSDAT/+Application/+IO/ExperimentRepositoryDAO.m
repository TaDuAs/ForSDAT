classdef ExperimentRepositoryDAO < dao.IExImportDAO & mfc.IDescriptor
    % ExperimentRepositoryDAO is a data access object dedicated to
    % accessing backed up experiment repositories
    % 
    % see also:
    %   ForSDAT.Application.Models.ExperimentRepository
    %   ForSDAT.Application.Workflows.CookedDataAnalyzer
    
    properties
        RepositoryPath;
        DAO dao.FSOutputDataExporter = dao.MXmlDataExporter.empty();
        DataSetDAO dao.FSOutputDataExporter = dao.TableDataExporter.empty();
    end
    
    
    methods (Hidden) % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        % 
        % ctor dependency rules:
        %   Extract from fields:
        %       Parameter name is the name of the property, with or without
        %       '&' prefix
        %   Hardcoded string: 
        %       Parameter starts with a '$' sign. For instance, parameter
        %       value '$Pikachu' is translated into a parameter value of
        %       'Pikachu', wheras parameter value '$$Pikachu' will be
        %       translated into '$Pikachu' when it is sent to the ctor
        %   Optional ctor parameter (key-value pairs):
        %       Parameter name starts with '@'
        %   Get parameter value from dependency injection:
        %       Parameter name starts with '%'
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'%ExperimentRepositoryExporter', '%csvTableExporter'};
            defaultValues = {};
        end
    end
    
    methods
        function this = ExperimentRepositoryDAO(repoDAO, dsDAO)
            this.DAO = repoDAO;
            this.DataSetDAO = dsDAO;
        end
    end
    
    methods
        function save(this, repo)
            this.DAO.save(repo, this.generateRepositoryFilePath(repo.Name));
        end
        
        function repo = loadOrCreate(this, name)
            repo = this.load(name);
            
            if repo.isemptyHandle()
                repo = this.create(name);
            end
        end
        
        function repo = create(this, name)
            % Creates a new experiment repository and an accompanying 
            % results archive. If an experiment repository with the given
            % name already exists, an exception is thrown.
            filePath = this.generateRepositoryFilePath(name);
            
            if exist(filePath, 'file')
                throw(MException('ForSDAT:Application:IO:ExperimentRepositoryDAO:RepositoryNameAlreadyExists', ...
                    'Can''t create a new repository with the name %s. A repository with this name already exists.', name));
            else
                repo = ForSDAT.Application.Models.ExperimentRepository(name);
                
                % validate repository
                this.validateLoadedRepository(repo, filePath);

                % generate batch results archive
                fileArchive = dao.ZipArchive(this.generateRepositoryArchivePath(name), this.RepositoryPath);
                repoArchive = ForSDAT.Application.Models.ExperimentRepositoryResultsArchive(this.DAO, fileArchive);
                repo.setResultsArchive(repoArchive);
                
                % save the new repository
                this.save(repo);
            end
        end
        
        function repo = load(this, name)
            % loads an experiment repository from ForSDATs default location
            % When no repository exists, an empty repository is generated.
            filePath = this.generateRepositoryFilePath(name);
            
            if ~exist(filePath, 'file')
                repo = ForSDAT.Application.Models.ExperimentRepository.empty();
            else
                % load repository from file
                repo = this.DAO.load(filePath);
            
                % validate repository
                this.validateLoadedRepository(repo, filePath);

                % generate batch results archive
                fileArchive = dao.ZipArchive(this.generateRepositoryArchivePath(name), this.RepositoryPath);
                repoArchive = ForSDAT.Application.Models.ExperimentRepositoryResultsArchive(this.DAO, fileArchive);
                repo.setResultsArchive(repoArchive);
            end
        end
        
        function repo = import(this, filePath)
            if ~exist(filePath, 'file') || ~any(regexp(filePath, filesep))
                filePath = this.generateRepositoryFilePath(filePath);
                if ~exist(filePath, 'file')
                    throw(MException('ForSDAT:ExperimentRepository:Import:FileMissing', 'The specified repository file path (%s) does not exist', filePath));
                end
            end
            
            % determine forein repository name
            [path, name] = fileparts(filePath);
            
            % backup local repository if one with the same name exists
            localRepoPath = this.generateRepositoryFilePath(name);
            backupName = strcat('bkup_', gen.guid(), '_', name);
            if exist(localRepoPath, 'file')
                bkupRepoPath = this.generateRepositoryFilePath(backupName);
                [status, msg] = movefile(localRepoPath, bkupRepoPath, 'f');
                this.assertBackupSuccess(status, msg);
            end
            
            % backup local repository results archive if one exists
            localRepoArchivePath = this.generateRepositoryArchivePath(name);
            if exist(localRepoArchivePath, 'file')
                bkupRepoArchivePath = this.generateRepositoryArchivePath(backupName);
                [status, msg] = movefile(localRepoArchivePath, bkupRepoArchivePath, 'f');
                this.assertBackupSuccess(status, msg);
            end
            
            % import the repository
            [status, msg] = copyfile(filePath, localRepoPath);
            this.assertImportFileSuccess(status, msg);
            
            % import results archive if one exists
            expectedForeinRepoArchivePath = fullfile(path, strcat(name, '.zip'));
            [status, msg] = copyfile(expectedForeinRepoArchivePath, localRepoArchivePath);
            this.assertImportFileSuccess(status, msg);
            
            % load the repository - hope for the best.
            repo = this.load(name);
        end
        
        function saveFullRepositoryDataSet(this, repo, ds)
            this.DataSetDAO.save(ds, [], this.generateRepositoryFullDataSetFilePath(repo));
        end
        
        function ds = loadFullRepositoryDataSet(this, repo)
            [doesExist, path] = this.doesFullRepositoryDataSetExist(repo);
            if doesExist
                ds = this.DataSetDAO.load(path);
            else
                ds = table();
            end
        end
        
        function [tf, path] = doesFullRepositoryDataSetExist(this, repo)
            path = this.generateRepositoryFullDataSetFilePath(repo);
            
            tf = exist(path, 'file');
        end
        
        function deleteFullRepositoryDataSet(this, repo)
            [doesExist, path] = this.doesFullRepositoryDataSetExist(repo);
            if doesExist
                delete(path);
            end
        end
    end
    
    methods (Access=private)
        
        function path = generateRepositoryFilePath(this, name)
            path = fullfile(this.RepositoryPath, this.appendPostfixToPath(name));
        end
        
        function path = generateRepositoryFullDataSetFilePath(this, repo)
            if isa(repo, 'ForSDAT.Application.Models.ExperimentRepository')
                name = repo.Name;
            elseif gen.isSingleString(repo)
                name = repo;
            else
                throw(MException('ForSDAT:Application:IO:ExperimentRepositoryDAO:InvalidNameType',...
                                 'Experiment repository or experiment repository name expected'));
            end
            
            path = fullfile(this.RepositoryPath, [char(name), '_fullDS', '.', this.DataSetDAO.outputFilePostfix()]);
        end
        
        function path = generateRepositoryArchivePath(this, name)
            path = fullfile(this.RepositoryPath, [char(name), '.zip']);
        end
        
        function path = appendPostfixToPath(this, path)          
            if ~any(regexp(path, '\.[a-zA-Z]{1,4}$'))
                path = [path, '.', this.DAO.outputFilePostfix()];
            end
        end
        
        function validateLoadedRepository(~, repo, path)
            if ~isa(repo, 'ForSDAT.Application.Models.ExperimentRepository')
                throw(MException('ForSDAT:ExperimentRepository:Load:InvalidType', 'Can''t load experiment repository from file. Wrong data type. file path: %s', path));
            end
        end
        
        function assertBackupSuccess(~, status, message)
            if ~status
                throw(MException('ForSDAT:Application:IO:ExperimentRepositoryBackupFailure', ...
                                 strcat('Cannot backup existing experiment repository before importing foreign one. ', message)));
            end
        end
        
        function assertImportFileSuccess(~, status, message)
            if ~status
                throw(MException('ForSDAT:Application:IO:ExperimentRepositoryImportFailure', ...
                                 strcat('Cannot import foreign experiment repository. ', message)));
            end
        end
    end
end

