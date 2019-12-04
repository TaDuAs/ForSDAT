classdef PipelinePanel < handle
    %PIPELINEPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        App;
        FlowContainer;
        ScrollableContentContainer;
        FlowResizeListener;
        PipelineBinder;
    end
    
    methods
        function this = PipelinePanel(container, app)
            this.App = app;
            this.initializeComponents(container);
        end
        
        function delete(this)
            this.FlowResizeListener = [];
            delete(this.FlowContainer);
            this.FlowContainer = [];
            delete(this.ScrollableContentContainer);
            this.ScrollableContentContainer = [];
        end
    end
    
    methods (Access=protected)       
        
        function initializeComponents(this, container)
            this.ScrollableContentContainer = uix.ScrollingPanel(...
                'Parent', container,...
                'Position', [0 0 1 1], ...
                'BackgroundColor', 'White'); 
            
            this.FlowContainer = sui.FlowBox(...
                'Parent', this.ScrollableContentContainer,...
                'BasePosition', [0 0 1 1], ...
                'BackgroundColor', 'White', ...
                'Spacing', 5, ...
                'Padding', 15);
            
            this.PipelineBinder = mvvm.Repeater(...
                'rawAnalyzer.pipeline.list', ...
                this.FlowContainer,...
                ForSDAT.Application.Client.PipelineTaskTemplate(this.App));
            
            this.FlowResizeListener = this.FlowContainer.addlistener('SizeChanged', @this.onFlowResize);
            this.onFlowResize();
        end
        
        function onFlowResize(this, ~, ~)
            scrollSize = sui.getSize(this.FlowContainer, 'pixel');
            scroller = this.ScrollableContentContainer;

            if scrollSize(1) ~= scroller.Widths
                scroller.Widths = scrollSize(1);
            end
            if scrollSize(2) ~= scroller.Heights
                scroller.Heights = scrollSize(2);
            end
        end
    end
end

