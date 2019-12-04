classdef ProcessSetupController < appd.AppController
    %ProcessSetupController is an API for generating an analysis process
    
    properties
        Factory ForSDAT.Application.Workflows.AnalyzerFactory;
        Serializer mxml.ISerializer = mxml.XmlSerializer.empty();
    end
    
    methods
        function this = ProcessSetupController(factory, serializer)
            this.Factory = factory;
            this.Serializer = serializer;
        end
        
        function task = newTask(this, taskName)
            task = this.Factory.buildTask(taskName);
        end
        
        function output = newTaskXml(this, taskName)
            task = this.newTask(taskName);
            output = this.Serializer.serialize(task);
        end
        
        function task = loadTaskDefinitions(this)
            task = [];
        end
        
        function output = loadTaskDefinitionsXml(this, taskName)
            task = this.loadTaskDefinitions(taskName);
            output = this.Serializer.serialize(task);
        end
    end
end

