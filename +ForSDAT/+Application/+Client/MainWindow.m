classdef MainWindow < mvvm.view.MainAppView
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MainContainer;
        HeaderPanel;
        FooterPanel;
        PipelinePanel ForSDAT.Application.Client.PipelinePanel;
        MainInfoContainer;
        PlotPanel ForSDAT.Application.Client.PlotPanel;
        EditPanel ForSDAT.Application.Client.EditPanel;
        
        ModelUpdatedByUserListener event.listener;
    end
    
    methods
        function this = MainWindow(app, bindingManager, viewManager)
            this@mvvm.view.MainAppView(app, ...
                'FigType', mvvm.view.FigureType.Classic, ...
                'BindingManager', bindingManager,...
                'ViewManager', viewManager);
        end
    end
    
    methods (Access=protected)
        function init(this)
            init@mvvm.view.MainAppView(this);
            
            % link ocurrent window binders to the controller and current
            % session
            % Not using the views builtin ViewProviderMapping mechanism 
            % because the view this class can't access the session when
            % calling the base ctor.
            this.ModelProviderMapping.ModelProvider = mvvm.providers.ControllerProvider('ForceSpecAnalysisController', this.Session);
            
            % listen to model updates
            this.ModelUpdatedByUserListener = this.BindingManager.addlistener('modelUpdated', @this.onCongifEditedByUser);
        end
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.MainAppView(this);
            
            this.Fig.WindowState = 'maximized';
            this.Fig.MenuBar = 'none';
            this.Fig.ToolBar = 'none';
            this.Fig.Tag = 'ForSDAT_Main_Window';
            
            % layout of all panels from the top to the bottom
            this.MainContainer = uiextras.VBoxFlex('Parent', this.Fig,...
                'Units', 'norm', 'Position', [0 0 1 1], ...
                'Spacing', 5, 'Padding', 10, ...
                'BackgroundColor', 'White');
            
            this.PipelinePanel = ForSDAT.Application.Client.PipelinePanel(...
                this.MainContainer, this, this.Session,...
                mvvm.providers.ControllerProvider('ProcessSetupController', this.Session),... % model provider
                this.BindingManager,...
                'Id', 'ProcessPipelineContainer');
            
            this.MainInfoContainer = uiextras.HBoxFlex('Parent', this.MainContainer,...
                'Units', 'norm', ...
                'Spacing', 5, 'Padding', 0, ...
                'BackgroundColor', 'White',...
                'Tag', 'MainInfoContainer');
            
            set(this.MainContainer, 'Sizes', [100, -10]);
            
            controller = this.Session.getController('ForceSpecAnalysisController');
            this.PlotPanel = ForSDAT.Application.Client.PlotPanel(this.MainInfoContainer, this, this.Messenger, controller, this.BindingManager);
            this.PlotPanel.Id = 'PlotTaskPanel';
            this.EditPanel = ForSDAT.Application.Client.EditPanel(...
                this.MainInfoContainer, this, this.Messenger, this.BindingManager, ...
                mvvm.providers.ControllerProvider('ProcessSetupController', this.Session),... % model provider
                this.ViewManager, this.Session.IocContainer.get('mxml.XmlSerializer'));
            this.EditPanel.Id = 'EditTaskPanel';
            
        end
    end
    
    methods (Access=private)
        function onCongifEditedByUser(this, ~, ~)
            controller = this.getModel();
            controller.analyzeCurve();
            this.PlotPanel.plot();
        end
    end
end

