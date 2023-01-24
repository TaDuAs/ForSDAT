classdef ForSpecAnalysisView < mvvm.view.ComponentView & ForSDAT.Application.Client.AnalysisViewFacade.IAnalysisViewFacade
    
    properties
        MainContainer;
        HeaderPanel;
        FooterPanel;
        PipelinePanel ForSDAT.Application.Client.ForspecAnalysisView.PipelinePanel;
        MainInfoContainer;
        TopPanel uix.HBox;
        PlotPanel ForSDAT.Application.Client.ForspecAnalysisView.PlotPanel;
        EditPanel ForSDAT.Application.Client.ForspecAnalysisView.EditPanel;
        
        EditProjectButton;
        EditProjectCommand mvvm.Command = mvvm.Command.empty();
        
        ModelUpdatedByUserListener event.listener;
    end
    
    methods
        function this = ForSpecAnalysisView(parent, parentView, app, bindingManager, viewManager)
            this@mvvm.view.ComponentView(parent, 'OwnerView', parentView, 'App', app, ...
                'BindingManager', bindingManager, 'ViewManager', viewManager,...
                'ModelProvider', mvvm.providers.ControllerProvider('ForceSpecAnalysisController', app));
        end
    end
    
    methods (Access=protected)
        function init(this)
            init@mvvm.view.ComponentView(this);
            
            % link ocurrent window binders to the controller and current
            % session
            % Not using the views builtin ViewProviderMapping mechanism 
            % because the view this class can't access the session when
            % calling the base ctor.
%             this.ModelProviderMapping.ModelProvider = mvvm.providers.ControllerProvider('ForceSpecAnalysisController', this.App);
            
            % listen to model updates
            this.ModelUpdatedByUserListener = this.BindingManager.addlistener('modelUpdated', @this.onCongifEditedByUser);
        end
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.MainAppView(this);
            
            % layout of all panels from the top to the bottom
            this.MainContainer = uiextras.VBoxFlex('Parent', this.getContainerHandle(), ...
                'Units', 'norm', 'Position', [0 0 1 1], ...
                'Spacing', 5, 'Padding', 10, ...
                'BackgroundColor', 'White');
            
            % layout of the top panel (i.e edit project button and the
            % pipeline panel)
            this.TopPanel = uiextras.HBox('Parent', this.MainContainer,...
                'Spacing', 5, 'Padding', 5, ...
                'BackgroundColor', 'White');
            
            % prepare the edit project image button
            editProjImgPath = fullfile(this.App.ResourcePath, 'Tasks', 'Settings.png');
            editProjImg = sui.getIconCData(editProjImgPath, [255 255 255], [60, 60]);
            this.EditProjectButton = uicontrol('Style', 'pushbutton', 'Parent', this.TopPanel, ...
                'Units', 'pixels', ...
                'Position', [1 1 64 64],...
                'BackgroundColor', [1 1 1],...
                'CData', editProjImg);
            this.EditProjectCommand = mvvm.Command('editProject', this.EditProjectButton, 'Callback',...
                'BindingManager', this.BindingManager);
            
            % create the pipeline panel and align it after the edit project
            % button
            this.PipelinePanel = ForSDAT.Application.Client.ForspecAnalysisView.PipelinePanel(...
                this.TopPanel, this, this.App,...
                mvvm.providers.ControllerProvider('ProcessSetupController', this.App),... % model provider
                this.BindingManager,...
                'Id', 'ProcessPipelineContainer');
            
            this.TopPanel.Sizes = [64, -1];
            
            % this box holds the bottom panel - plotting and edit task
            % panels.
            this.MainInfoContainer = uiextras.HBoxFlex('Parent', this.MainContainer,...
                'Units', 'norm', ...
                'Spacing', 5, 'Padding', 0, ...
                'BackgroundColor', 'White',...
                'Tag', 'MainInfoContainer');
            set(this.MainContainer, 'Sizes', [100, -10]);
            
            controller = this.App.getController('ForceSpecAnalysisController');
            this.PlotPanel = ForSDAT.Application.Client.ForspecAnalysisView.PlotPanel(this.MainInfoContainer, this, this.Messenger, controller, this.BindingManager);
            this.PlotPanel.Id = 'PlotTaskPanel';
            this.EditPanel = ForSDAT.Application.Client.ForspecAnalysisView.EditPanel(...
                this.MainInfoContainer, this, this.Messenger, this.BindingManager, ...
                mvvm.providers.ControllerProvider('ProcessSetupController', this.App),... % model provider
                this.ViewManager, this.App.IocContainer.get('mxml.XmlSerializer'));
            this.EditPanel.Id = 'EditTaskPanel';
            
        end
    end
    
    methods (Access=private)
        function onCongifEditedByUser(this, ~, ~)
            controller = this.getModel();
            controller.analyzeCurve();
%             this.PlotPanel.plot();
        end
    end
end

