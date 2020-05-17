classdef ProcessSetupController < ForSDAT.Application.ProjectController
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
        
        function viewAndEditTask(this, task)
            this.editTask(task);
            this.viewTask(task);
        end
        
        function editTask(this, task)
            % notify that the edited task is changing
            message = mvvm.RelayMessage(ForSDAT.Application.AppMessages.PreEditedTaskChange, task);
            this.App.Messenger.send(message);
            
            this.Project.CurrentEditedTask = task;
        end
        
        function viewTask(this, task)
            this.Project.CurrentViewedTask = task;
        end
        
        function removeTask(this, taskId)
            this.Project.RawAnalyzer.pipeline.removeAt(taskId);
        end
    end
end

