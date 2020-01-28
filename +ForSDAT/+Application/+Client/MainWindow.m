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
        function this = MainWindow(app)
            this@mvvm.view.MainAppView(app, 'FigType', mvvm.view.FigureType.Classic);
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.MainAppView(this);
            
            % link ocurrent window biners to the controller and current
            % session
            mvvm.BindingManager.setModProv(this.Fig,...
                mvvm.providers.ControllerProvider('ForceSpecAnalysisController', this.Session));
            
%             sui.jframe(this.Fig, 0, 'Maximized', 1);
            this.Fig.WindowState = 'maximized';
            
            % layout of all panels from the top to the bottom
            this.MainContainer = uiextras.VBoxFlex('Parent', this.Fig,...
                'Units', 'norm', 'Position', [0 0 1 1], ...
                'Spacing', 5, 'Padding', 10, ...
                'BackgroundColor', 'White');
            
            this.PipelinePanel = ForSDAT.Application.Client.PipelinePanel(this.MainContainer, this.Session);
            this.MainInfoContainer = uiextras.HBoxFlex('Parent', this.MainContainer,...
                'Units', 'norm', ...
                'Spacing', 5, 'Padding', 10, ...
                'BackgroundColor', 'White');
            
            set(this.MainContainer, 'Sizes', [100 -10]);
            
            controller = this.Session.getController('ForceSpecAnalysisController');
            this.PlotPanel = ForSDAT.Application.Client.PlotPanel(this.MainInfoContainer, this.Messenger, controller);
            this.EditPanel = ForSDAT.Application.Client.EditPanel(this.MainInfoContainer);
            
        end
    end
end

