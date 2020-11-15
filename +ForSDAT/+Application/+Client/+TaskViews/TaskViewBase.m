classdef TaskViewBase < mvvm.view.ComponentView
    properties
        ExtraChannels;
        ExtraChannelTypes;
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.TaskChannelControl = uix.BoxPanel();
            this.addChild(this.TaskChannelControl);
        end
    end
end

