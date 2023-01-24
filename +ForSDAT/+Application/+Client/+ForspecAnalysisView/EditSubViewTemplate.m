classdef EditSubViewTemplate < mvvm.ITemplate
    properties
        OwnerView mvvm.view.IView = mvvm.view.Window.empty();
        ViewManager mvvm.view.IViewManager = mvvm.view.ViewManager.empty();
    end
    
    methods
        function this = EditSubViewTemplate(parentView, viewManager)
            this.OwnerView = parentView;
            this.ViewManager = viewManager;
        end
        
        function h = build(this, scope, container)
            h = struct();
            
            task = scope.getModel();
            
            function sh = showHideCurrentTaskAdaptation(model)
                if eq(model, task)
                    sh = 'on';
                else
                    sh = 'off';
                end
            end
            
            h.view = this.ViewManager.start([task.name, ' View'], '#1', container, '@OwnerView', this.OwnerView);
            h.showHideBinder = mvvm.AdaptationBinder('Project.CurrentEditedTask', h.view.getContainerHandle(), 'Visible', ...
                @showHideCurrentTaskAdaptation);
        end
        
        function teardown(this, scope, container, h)
            delete(h.showHideBinder);
            delete(h.view);
        end
    end
end

