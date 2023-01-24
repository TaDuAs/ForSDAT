classdef CompositeBaselineView < mvvm.view.ComponentView
    properties
        Frame sui.ViewSwitch
    end
    
    methods
        function this = CompositeBaselineView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.addChild(uicontrol('style', 'text', 'String', 'CompositeBaselineView'));
        end
    end
end
