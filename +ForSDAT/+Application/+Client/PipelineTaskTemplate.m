classdef PipelineTaskTemplate < mvvm.ITemplate
    %PIPELINETASKTEMPLATE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ResourcePath;
        ViewTaskImage;
        EditTaskImage;
    end
    
    methods
        function this = PipelineTaskTemplate(resourcesPath)
            this.ResourcePath = resourcesPath;
            this.ViewTaskImage = imread(fullfile(resourcesPath, 'Tasks', 'display.png'));
            this.EditTaskImage = imread(fullfile(resourcesPath, 'Tasks', 'edit.png'));
        end
        function h = build(this, scope, container)
            task = scope.getModel();
            h.box = uipanel('Parent', container, 'Units', 'pixels', 'Position', [1 1 112 64]);
            
            taskImg = imread(fullfile(this.ResourcePath, 'Tasks', [task.name '.png']));
            h.taskButton = uicontrol('Style', 'button', 'Parent', h.box, 'Units', 'pixels', ...
                'Position', [1 1 64 64],...
                'CData', taskImg);
            h.showAllCmd = mvvm.Command('viewAndEditTask', h.taskButton, 'Callback',...
                'Params', { scope });
            
            h.editTask = uicontrol('Style', 'button', 'Parent', h.box, 'Units', 'pixels',...
                'Position', [64 32 48 32],...
                'CData', this.EditTaskImage);
            h.editTaskCmd = mvvm.Command('editTask', h.editTask, 'Callback',...
                'Params', { scope });
            
            h.viewTask = uicontrol('Style', 'button', 'Parent', h.box, 'Units', 'pixels',...
                'Position', [64 32 48 1],...
                'CData', this.ViewTaskImage);
            h.viewTaskCmd = mvvm.Command('viewTask', h.viewTask, 'Callback',...
                'Params', { scope });
        end
        
        function teardown(this, scope, container, h)
            delete(h.showAllCmd);
            delete(h.taskButton);
            delete(h.editTaskCmd);
            delete(h.editTask);
            delete(h.viewTaskCmd);
            delete(h.viewTask);
        end
    end
end

