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
            ctorParams = {'%mxml.XmlSerializer'};
            defaultValues = {};
        end
    end
    
    methods
        function this = ExperimentRepositoryDAO(serializer)
            this.DAO = dao.MXmlDataExporter(serializer);
        end
    end
    
    methods
        function save(this, repo)
            this.DAO.save(repo, this.generateRepositoryFilePath(repo.Name));
        end
        
        function repo = load(this, name)
            filePath = this.generateRepositoryFilePath(name);
            
            if ~exist(filePath, 'file')
                repo = ForSDAT.Application.Models.ExperimentRepository.empty();
                return;
            end
            
            repo = this.DAO.load(filePath);
            
            % validate repository
            this.validateLoadedRepository(repo, filePath);
        end
        
        function repo = import(this, filePath)
            if ~exist(filePath, 'file') || ~any(regexp(filePath, filesep))
                filePath = this.generateRepositoryFilePath(filePath);
                if ~exist(filePath, 'file')
                    throw(MException('ForSDAT:ExperimentRepository:Import:FileMissing', 'The specified repository file path (%s) does not exist', filePath));
                end
            end
            
            % fetch from file
            repo = this.DAO.load(filePath);
            
            % validate repository
            this.validateLoadedRepository(repo, filePath);
        end
    end
    
    methods (Access=private)
        
        function path = generateRepositoryFilePath(this, name)
            path = fullfile(this.RepositoryPath, this.appendPostfixToPath(name));
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
    end
end

