classdef PipelinePanel < mvvm.view.ComponentView & sui.IRedrawSuppressable
    %PIPELINEPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        FlowContainer sui.FlowBox;
        ScrollableContentContainer uix.ScrollingPanel;
        FlowResizeListener event.listener;
        PipelineBinder mvvm.Repeater;
        ResourcePath string;
        
        pipelineBinderEventListeners event.listener;
    end
    
    methods
        function this = PipelinePanel(parent, ownerView, app, modelProvider, bindingManager, varargin)
            this@mvvm.view.ComponentView(parent,...
                    'OwnerView', ownerView,...
                    'App', app,...
                    'ModelProvider', modelProvider,...
                    'BindingManager', bindingManager,...
                    varargin{:});
                
            this.ResourcePath = app.ResourcePath;
        end
        
        function delete(this)
            delete(this.FlowResizeListener);
            this.FlowResizeListener = event.listener.empty();
            delete(this.FlowContainer);
            this.FlowContainer = sui.FlowBox.empty();
            delete(this.ScrollableContentContainer);
            this.ScrollableContentContainer = uix.ScrollingPanel.empty();
            delete(this.pipelineBinderEventListeners);
            this.pipelineBinderEventListeners = event.listener.empty();
        end
    end
    
    methods (Access=protected)       
        
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.ScrollableContentContainer = uix.ScrollingPanel(...
                'Parent', this.ContainerBox.getContainerHandle(),...
                'Position', [0 0 1 1], ...
                'BackgroundColor', 'White'); 
            
            this.FlowContainer = sui.FlowBox(...
                'Parent', this.ScrollableContentContainer,...
                'BasePosition', [0 0 sui.getSize(uix.ScrollingPanel, 'pixels')], ...
                'BackgroundColor', 'White', ...
                'Spacing', 5, ...
                'Padding', 15);
            this.FlowContainer.suppressDraw();
            
            this.PipelineBinder = mvvm.Repeater(...
                'Project.RawAnalyzer.pipeline', ...
                this.FlowContainer,...
                ForSDAT.Application.Client.PipelineTaskTemplate(this.ResourcePath, this.ModelProviderMapping.ModelProvider),...
                'BindingManager', this.BindingManager,...
                'ModelProvider', this.ModelProviderMapping.ModelProvider);
            this.pipelineBinderEventListeners(1) = addlistener(this.PipelineBinder, 'binding', @this.suppressDraw);
            this.pipelineBinderEventListeners(2) = addlistener(this.PipelineBinder, 'postBind', @this.startDrawing);
            
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
    
    % sui.IRedrawSuppressable
    methods (Access=protected)
        function setDirty(this)
            this.redraw();
        end
    end
    % sui.IRedrawable
    methods (Access=protected)
        function redraw(this)
            pipelineSize = sui.getSize(this.ScrollableContentContainer, 'pixels') - [20, 0];
            this.FlowContainer.BasePosition = [0 0 pipelineSize];
            this.FlowContainer.startDrawing();
        end
    end
    
    methods
        function suppressDraw(this, ~, ~)
            suppressDraw@sui.IRedrawSuppressable(this);
            
            this.FlowContainer.suppressDraw();
        end
        
        function startDrawing(this, ~, ~)
            startDrawing@sui.IRedrawSuppressable(this);
        end
    end
end

