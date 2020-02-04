classdef ForSDATApp < mvvm.GuiApp
    properties (GetAccess=public, SetAccess=protected)
        Mode (1,1) string {mustBeMember(Mode, ["gui", "console"])} = "console";
        DIConfig (1,1) ForSDAT.Application.DependencyInjectionConfig = ForSDAT.Application.DependencyInjectionConfig();
        MainView ForSDAT.Application.Client.MainWindow;
    end
    
    methods
        function this = ForSDATApp(mode)
            this@mvvm.GuiApp(IoC.Container.empty(),...
                'RootPath', fileparts(which('ForSDAT.Application.Client.MainWindow')), ...
                'ResourcePath', '/Resources', ...
                'Id', "ForSDAT",...
                'LogPath', '/Log');
            
            if nargin >= 1 && ~isempty(mode)
                this.Mode = lower(string(mode));
            end
        end
        
        function start(this)
            start@mvvm.GuiApp(this);
            cprintf('Comment', 'ForSDAT data analysis engine started successfully.\n');
        end
    end
    
    methods (Access=protected)
        function initConfig(this)
            this.initConfig@mvvm.GuiApp();
            
            % init dependency injection configuration
            this.DIConfig.configure(this.IocContainer);
            
            % Register data analysis controllers
            this.registerController(...
                appd.IoCControllerBuilder(...
                    'ForceSpecAnalysisController',...
                    IoC.ContainerGetter(this.IocContainer)));
                
            % Register data analysis controllers
            this.registerController(...
                appd.IoCControllerBuilder(...
                    'ProcessSetupController',...
                    IoC.ContainerGetter(this.IocContainer)));
        end
        
        function init(this)
            if strcmp(this.Mode, "gui")
                this.MainView = ForSDAT.Application.Client.MainWindow(this);
            end
        end
    end
    
    methods (Static)
        function app = ensureAppLoaded(mode)
            if nargin < 1; mode = ''; end
            
            function app = ctor()
                app = ForSDAT.Application.ForSDATApp(mode);
            end
            
            app = appd.AppManager.load("ForSDAT", @ctor);
            
            if nargin >= 1 && ~strcmp(app.Mode, mode)
                app.kill();
                app = appd.AppManager.load("ForSDAT", @ctor);
            end
        end
    end
end

