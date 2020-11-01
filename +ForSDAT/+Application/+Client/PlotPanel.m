classdef PlotPanel < mvvm.view.ComponentView
    %PLOTPANEL Summary of this class goes here
    %   Detailed explanation goes here
  
    properties (GetAccess=public, SetAccess=protected)
        Controller ForSDAT.Application.ForceSpecAnalysisController;
        Axis matlab.graphics.axis.Axes;
    end
    
    methods
        function this = PlotPanel(parent, parentView, messenger, controller, bindingManager)
            this@mvvm.view.ComponentView(parent, 'OwnerView', parentView, 'Messenger', messenger, 'BindingManager', bindingManager);
            this.Controller = controller;
        end
        
        function plot(this)
            this.Controller.plotLastAnalyzedCurve([], this.Axis);
        end
    end
    
    methods (Access=protected)
        
        function initializeComponents(this)
            this.Axis = axes(this.ContainerBox.getContainerHandle(), 'Position', [0 0 1 1]);
            
            % plot again after switching FDC
            this.Messenger.register('ForSDAT.Client.FDC_Analyzed', @this.plot);
        end
    end
end

