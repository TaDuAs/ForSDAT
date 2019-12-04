classdef AnalyzerFactory < handle & mfc.IDescriptor
    %ANALYZERFACTORY generates AnalysisCore components
    % The inner function of this class is not the most efficient but it
    % utilizes the already established mxml package to generate new
    % instances from a config file instead of developing a new way to 
    % reliably duplicate each of these objects, and without needing to
    % escape the config file in any way. The config file is a regular mxml
    % file
    
    properties
        Serializer mxml.XmlSerializer;
        ConfigFilePath (1,:) char;
        App Simple.App.App;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'%MFactory', '%App', 'ConfigFilePath'};
            defaultValues = {};
        end
    end
    
    methods
        function this = AnalyzerFactory(factory, app, configFilePath)
            this.Serializer = mxml.XmlSerializer('Factory', factory);
            this.App = app;
            this.ConfigFilePath = configFilePath;
        end
        
        function task = buildTask(this, taskName)
            task = this.buildFromConfiguration(sprintf('tasks.%s.taskConfig', taskName));
        end
        
        function task = buildTaskProcessor(this, taskName, processorName)
            task = this.buildFromConfiguration(sprintf('tasks.%s.processors.%s', taskName, processorName));
        end
        
        function def = getAllDefinitions(this)
            def = this.getConfig();
        end
    end
    
    methods (Access=private)
        function cfg = getConfig(this)
            key = this.configPersistenceKey();
            
            if ~this.App.persistenceContainer.hasEntry(key)
%                 path = fileparts(which(class(this)));
%                 filename = fullfile(path, 'Defaults.xml');
                cfg = this.Serializer.load(this.ConfigFilePath);
                this.App.persistenceContainer.set(key, cfg);
            else
                cfg = this.App.persistenceContainer.get(key);
            end
        end
        
        function updateConfig(this, cfg)
            key = this.configPersistenceKey();
            this.App.persistenceContainer.set(key, cfg);
        end
        
        function key = configPersistenceKey(this)
            key = [class(this) '_Config'];
        end
        
        function item = buildFromConfiguration(this, name)
            config = this.getConfig();
            
            % get config xml from the config object
            xmlName = [name '_MXML'];
            xml = mvvm.getobj(config, xmlName);
            
            % if the config xml wasn't initialize
            if isempty(xml)
                % serialize the desired config object
                xml = this.Serializer.serialize(mvvm.getobj(config, name));
                config = mvvm.setobj(config, xmlName, xml);
                this.updateConfig(config);
            end
            
            item = this.Serializer.deserialize(xml);
        end
    end
end

