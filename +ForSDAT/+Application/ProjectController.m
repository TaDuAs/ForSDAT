classdef ProjectController < mvvm.AppController
    %PROJECTCONTROLLER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Dependent, SetObservable)
        Project (1,1) ForSDAT.Application.Models.ForSpecProj;
    end
    
    properties (Access=protected)
        ignoreProjectUpdate;
    end
    
    methods % property accessors
        function set.Project(this, obj)
            prevObj = this.Project;
            
            if (numel(obj) ~= numel(prevObj)) || (~isempty(obj) && ~eq(obj, prevObj))
                this.App.Context.set('CurrentProject', obj);
                this.notifyProjectChangeSystemwise();
            end
        end
        function obj = get.Project(this)
            obj = this.App.Context.get('CurrentProject');
        end
    end
    
    methods % initialization
        function init(this, app)
            init@mvvm.AppController(this, app);
            if isempty(this.Project)
                this.startNewProject();
            end
            
            this.App.Messenger.register(ForSDAT.Application.AppMessages.CurrentProjectUpdated, @this.onProjectUpdated);
        end
        
        function startNewProject(this)
            this.Project = ForSDAT.Application.Models.ForSpecProj(this.App.Context);
        end
    end
    
    methods
        function notifyProjectChangeSystemwise(this)
            this.ignoreProjectUpdate = true;
            
            this.App.Messenger.send(ForSDAT.Application.AppMessages.CurrentProjectUpdated);
            
            this.ignoreProjectUpdate = false;
        end
        
        function onProjectUpdated(this, message)
            if ~this.ignoreProjectUpdate
                this.raiseProjectSetEvent();
            end
        end
        
        function raiseProjectSetEvent(this)
            % this is a workaround to fire the post set event of the
            % project property
            this.Project = this.Project;
        end
    end
end

