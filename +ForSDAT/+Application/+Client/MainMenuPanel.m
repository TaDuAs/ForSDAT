classdef MainMenuPanel < mvvm.view.ComponentView
    %MAINMENUPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access=private)
        
        % file menu
        FileMenu;
        NewProjectMenuItem;
        NewProjectCommand mvvm.Command;
        
    end
    
    methods
        function this = MainMenuPanel(parent, ownerView, app, modelProvider, bindingManager)
            this@mvvm.view.ComponentView(parent,...
                    'OwnerView', ownerView,...
                    'App', app,...
                    'ModelProvider', modelProvider,...
                    'BindingManager', bindingManager)
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.FileMenu = uimenu(this.Fig, 'Text', '&File');
            this.NewProjectMenuItem = uimenu(this.FileMenu, 'Text', '&New Project');
            this.NewProjectCommand = mvvm.Command('startNewProject', this.NewProjectMenuItem, 'Action',...
                'BindingManager', this.BindingManager);
        end
    end
end

