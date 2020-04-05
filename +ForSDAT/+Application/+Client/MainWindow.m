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
    end
    
    methods
        function this = MainWindow(app, bindingManager)
            this@mvvm.view.MainAppView(app, ...
                'FigType', mvvm.view.FigureType.Classic, ...
                'BindingManager', bindingManager);
        end
    end
    
    methods (Access=protected)
        function init(this)
            init@mvvm.view.MainAppView(this);
            
            % link ocurrent window biners to the controller and current
            % session
            % Not using the ViewProviderMapping mechanism because the
            % is initialized in a later stage tahn construction
            this.BindingManager.setModelProvider(this.Fig,...
                mvvm.providers.ControllerProvider('ForceSpecAnalysisController', this.Session));
        end
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.MainAppView(this);
            
            this.Fig.WindowState = 'maximized';
            this.Fig.MenuBar = 'none';
            this.Fig.ToolBar = 'none';
            
            % layout of all panels from the top to the bottom
            this.MainContainer = uiextras.VBoxFlex('Parent', this.Fig,...
                'Units', 'norm', 'Position', [0 0 1 1], ...
                'Spacing', 5, 'Padding', 10, ...
                'BackgroundColor', 'White');
            
            this.PipelinePanel = ForSDAT.Application.Client.PipelinePanel(...
                this.MainContainer, this, this.Session);
            
            this.MainInfoContainer = uiextras.HBoxFlex('Parent', this.MainContainer,...
                'Units', 'norm', ...
                'Spacing', 5, 'Padding', 0, ...
                'BackgroundColor', 'White');
            
            set(this.MainContainer, 'Sizes', [100, -10]);
            
            controller = this.Session.getController('ForceSpecAnalysisController');
            this.PlotPanel = ForSDAT.Application.Client.PlotPanel(this.MainInfoContainer, this, this.Messenger, controller, this.BindingManager);
            this.EditPanel = ForSDAT.Application.Client.EditPanel(this.MainInfoContainer, this, this.Messenger, this.BindingManager);
            
        end
    end
end

