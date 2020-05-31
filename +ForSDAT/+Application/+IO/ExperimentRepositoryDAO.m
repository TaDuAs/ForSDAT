classdef ExperimentRepositoryDAO < dao.IExImportDAO & mfc.IDescriptor
    %EXPERIMENTREPOSITORYDAO Summary of this class goes here
    %   Detailed explanation goes here
    
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
            repo = this.DAO.load(this.generateRepositoryFilePath(name));
        end
        
        function path = generateRepositoryFilePath(this, name)
            path = fullfile(this.RepositoryPath, [name, '.', this.DAO.outputFilePostfix()]);
        end
    end
end

