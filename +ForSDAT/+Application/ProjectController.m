classdef ProjectController < mvvm.AppController
    
    properties (Dependent, SetObservable)
        Project (1,1) ForSDAT.Application.Models.ForSpecProj;
    end
    
    properties (Access=protected)
        ignoreProjectUpdate = false;
        Serializer mxml.ISerializer = mxml.XmlSerializer.empty();
        currentProjectUpdatedListener;
    end
    
    methods % property accessors
        function set.Project(this, obj)
            prevObj = this.Project;
            
            if (isempty(obj) && ~isempty(prevObj)) || ...
               (~isempty(obj) && isempty(prevObj)) || ...
               (~isempty(obj) && ~isempty(obj) && ~eq(obj, prevObj))
                this.App.Context.set('CurrentProject', obj);
                this.notifyProjectChangeSystemwise();
            end
        end
        function obj = get.Project(this)
            obj = this.App.Context.get('CurrentProject');
        end
    end
    
    methods % ctor & dtor
        function this = ProjectController(serializer)
            this.Serializer = serializer;
        end
        
        function delete(this)
            this.Serializer = mxml.XmlSerializer.empty();
            delete(this.currentProjectUpdatedListener);
            
            delete@mvvm.AppController(this);
        end
    end
    
    methods % initialization
        function init(this, app)
            init@mvvm.AppController(this, app);
            if isempty(this.Project)
                this.startNewProject();
            end
            
            this.currentProjectUpdatedListener = this.App.Messenger.register(ForSDAT.Application.AppMessages.CurrentProjectUpdated, @this.onProjectUpdated);
        end
        
        function startNewProject(this)
            this.Project = ForSDAT.Application.Models.ForSpecProj(this.App.Context);
        end
        
        function setProject(this, project)
            if isa(project, 'ForSDAT.Application.Models.ForSpecProj')
                this.Project = project;
            else
                this.Project = this.Serializer.load(project);
            end
        end
    end
    
    methods
        function raiseResetProgressNotification(this, ~, e)
            message = mvvm.CancelEventPermissionMessage(ForSDAT.Application.AppMessages.CurrentProjectRequestProgressResetPermit, e);
            this.App.Messenger.send(message);
            
            % #TODO: handle this message in GUI
        end
        
        function notifyProjectChangeSystemwise(this)
            this.ignoreProjectUpdate = true;
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.CurrentProjectUpdated);
            
            this.ignoreProjectUpdate = false;
        end
        
        function onProjectUpdated(this, message)
            if ~this.ignoreProjectUpdate
                this.raiseProjectSetEvent();
            end
            
            % when loading project select the first task for editing and
            % viewing
            if ~isempty(this.Project) && ...
               ~isempty(this.Project.RawAnalyzer) &&...
               ~this.Project.RawAnalyzer.pipeline.isempty()
                this.Project.CurrentEditedTask = this.Project.RawAnalyzer.getTask(1);
                this.Project.CurrentViewedTask = this.Project.RawAnalyzer.getTask(1);
            end
           
        end
        
        function raiseProjectSetEvent(this)
            % this is a workaround to fire the post set event of the
            % project property
            this.Project = this.Project;
        end
        
        function notifyProjectDataChangeSystemwise(this)
            this.App.Messenger.send(ForSDAT.Application.AppMessages.CurrentProjectDataChanged);
        end
    end
end

