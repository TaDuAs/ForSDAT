classdef PlotPanel < mvvm.view.ComponentView
    %PLOTPANEL Summary of this class goes here
    %   Detailed explanation goes here
  
    properties (GetAccess=public, SetAccess=protected)
        Controller ForSDAT.Application.ForceSpecAnalysisController;
        Axis matlab.graphics.axis.Axes;
    end
    
    methods
        function this = PlotPanel(parent, messenger, controller)
            this@mvvm.view.ComponentView(parent, 'Messenger', messenger);
            this.Controller = controller;
        end
        
        function plot(this)
            this.Controller.plotLastAnalyzedCurve('do something to get the current task', this.Axis);
        end
    end
    
    methods (Access=protected)
        
        function initializeComponents(this)
            this.Axis = axes(this.Container.getContainerHandle(), 'Position', [0 0 1 1]);
            
            % plot again after switching FDC
            this.Messenger.register('ForSDAT.Client.FDC_Analyzed', @this.plot);
        end
    end
end

