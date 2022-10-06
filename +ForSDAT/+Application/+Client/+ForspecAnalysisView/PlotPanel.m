classdef PlotPanel < mvvm.view.ComponentView
    %PLOTPANEL Summary of this class goes here
    %   Detailed explanation goes here
  
    properties (GetAccess=public, SetAccess=protected)
        Controller ForSDAT.Application.ForceSpecAnalysisController;
        Axis matlab.graphics.axis.Axes;
        CurrentViewedTaskBinder mvvm.MessageBinder;
    end
    
    properties (Access=private)
        FDC_AnalyzedListener;
        CurrentProjectDataChangedListener;
    end
    
    methods
        function this = PlotPanel(parent, parentView, messenger, controller, bindingManager)
            this@mvvm.view.ComponentView(parent, 'OwnerView', parentView, 'Messenger', messenger, 'BindingManager', bindingManager);
            this.Controller = controller;
        end
        
        function delete(this)
            delete(this.FDC_AnalyzedListener);
            delete(this.CurrentProjectDataChangedListener);
            
            delete@mvvm.view.ComponentView(this);
        end
        
        function plot(this, ~, ~)
            this.Controller.plotLastAnalyzedCurve([], this.Axis);
        end
    end
    
    methods (Access=protected)
        
        function initializeComponents(this)
            container = this.getContainerHandle();
            container.BackgroundColor = 'w';
            
            this.Axis = axes(container, 'Position', [0.1 0.1 0.85 0.85]);
            
            % plot again after switching FDC
            this.FDC_AnalyzedListener = this.Messenger.register(ForSDAT.Application.AppMessages.FDC_Analyzed, @this.plot);
            this.CurrentProjectDataChangedListener = this.Messenger.register(ForSDAT.Application.AppMessages.CurrentProjectDataChanged, @this.plot);
            this.CurrentViewedTaskBinder = mvvm.MessageBinder('Project.CurrentViewedTask', ...
                @this.plot, this, 'BindingManager', this.BindingManager);
        end
    end
end

