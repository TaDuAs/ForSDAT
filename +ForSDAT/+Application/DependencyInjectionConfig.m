classdef DependencyInjectionConfig < handle 
    methods
        function configure(this, ioc)
            % Application configuration
            ioc.set('RootPath', @(app) app.RootPath, 'App');
            ioc.setPerSession('MFactory', @mfc.MFactory, '@IoCContainer', 'IoC');
            ioc.set('mxml.XmlSerializer', @mxml.XmlSerializer, '@Factory', 'MFactory');
            ioc.set('mxml.JsonSerializer', @mxml.JsonSerializer, '@Factory', 'MFactory');
            ioc.set('mxml.GenericSerializer', @mxml.FileFormatSerializer, ...
                {'xml', 'json'}, ...
                IoC.Injectable(["mxml.XmlSerializer", "mxml.JsonSerializer"]), ...
                '@Factory', 'MFactory');
            ioc.set('AnalysisContext', @(ses) ses.Context, 'Session');
            ioc.set('AppContext', @(app) app.Context, 'App');
            ioc.set('AnalyzerConfigFilePath', @(app) fullfile(app.ResourcePath, 'Settings', 'Defaults.xml'), 'App');
            
            % Simple framework
            ioc.setSingleton('BindingManager', @mvvm.BindingManager);
            
            % controllers
            ioc.setSingleton('AnalyzerFactory', @ForSDAT.Application.Workflows.AnalyzerFactory, 'mxml.XmlSerializer', 'AppContext', 'AnalyzerConfigFilePath');
            ioc.setPerSession('ForceSpecAnalysisController', @ForSDAT.Application.ForceSpecAnalysisController, 'mxml.GenericSerializer');
            ioc.setPerSession('ProcessSetupController', @ForSDAT.Application.ProcessSetupController, 'AnalyzerFactory', 'mxml.GenericSerializer');
            
            % configuration
            ioc.set('NoiseAnomally', @this.getNoiseAnomally, 'Session');
            ioc.set('NoiseAnomallyFetcher', @IoC.DependencyFetcher, 'IoC', '$NoiseAnomally');
            
            % ForSDAT Core
            
            % gui
            ioc.set('MainView', @ForSDAT.Application.Client.MainWindow, 'App', 'BindingManager', 'ViewManager');
            
            % Edit-Task Sub Views
            ioc.set('OOM Adjuster View', @ForSDAT.Application.Client.TaskViews.OOMAdjusterView, groot());
        end
    end
    
    methods (Access=private)
        function anomally = getNoiseAnomally(this, app)
            ctrl = app.getController('ForceSpecAnalysisController');
            anomally = ctrl.project.Settings.measurement.noiseAnomally;
        end
    end
end

