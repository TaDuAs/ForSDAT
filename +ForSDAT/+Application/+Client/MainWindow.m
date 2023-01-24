classdef MainWindow < mvvm.view.MainAppView
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MainMenuControl ForSDAT.Application.Client.MainMenuPanel;
        
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
        end
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.MainAppView(this);
            
            this.Fig.WindowState = 'maximized';
            this.Fig.MenuBar = 'none';
            this.Fig.ToolBar = 'none';
            this.Fig.Tag = 'ForSDAT_Main_Window';
            
            this.MainMenuControl = ForSDAT.Application.Client.MainMenuPanel(this.Fig, this, this.App, this.ModelProvider, this.BindingManager);
            
            
        end
    end
    
    
end

