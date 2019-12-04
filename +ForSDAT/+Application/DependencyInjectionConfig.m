classdef DependencyInjectionConfig < handle 
    methods
        function configure(this, ioc)
            
            ioc.set('RootPath', @(app) app.RootPath, 'App');
            ioc.setPerSession('MFactory', @mfc.MFactory, '@IoCContainer', 'IoC');
            ioc.set('mxml.XmlSerializer', @mxml.XmlSerializer, '@Factory', 'MFactory');
            ioc.set('mxml.JsonSerializer', @mxml.JsonSerializer, '@Factory', 'MFactory');
            ioc.setSingleton('BindingManager', @mvvm.BindingManager.forceNewInstance);
            
            % gui
            ioc.set('MainView', @ForSDAT.Application.Client.MainWindow, 'App');
            
            % Simple framework
            
        end
    end
end

