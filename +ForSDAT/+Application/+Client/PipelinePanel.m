classdef PipelinePanel < mvvm.view.ComponentView
    %PIPELINEPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FlowContainer;
        ScrollableContentContainer;
        FlowResizeListener;
        PipelineBinder;
    end
    
    methods
        function this = PipelinePanel(parent, app, varargin)
            this@mvvm.view.ComponentView(parent, 'App', app, varargin{:});
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
        
        function init(this)
            init@mvvm.view.ComponentView(this);
        end
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.ScrollableContentContainer = uix.ScrollingPanel(...
                'Parent', this.Parent.getContainerHandle(),...
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
                ForSDAT.Application.Client.PipelineTaskTemplate(this.App.ResourcePath));
            
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

