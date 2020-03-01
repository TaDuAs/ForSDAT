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
            
            % Simple framework
            ioc.setSingleton('BindingManager', @mvvm.BindingManager.forceNewInstance);
            
            % controllers
            ioc.set('ForceSpecAnalysisController', @ForSDAT.Application.ForceSpecAnalysisController, 'mxml.GenericSerializer');
            ioc.set('ProcessSetupController', @ForSDAT.Application.ProcessSetupController, 'MFactory', 'mxml.GenericSerializer');
            
            % configuration
            ioc.set('NoiseAnomally', @this.getNoiseAnomally, 'Session');
            ioc.set('NoiseAnomallyFetcher', @IoC.DependencyFetcher, 'IoC', '$NoiseAnomally');
            
            % ForSDAT Core
            
            % gui
            ioc.set('MainView', @ForSDAT.Application.Client.MainWindow, 'App');
        end
    end
    
    methods (Access=private)
        function anomally = getNoiseAnomally(this, app)
            ctrl = app.getController('ForceSpecAnalysisController');
            anomally = ctrl.settings.measurement.noiseAnomally;
        end
    end
end

