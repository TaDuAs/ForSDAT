classdef TipHeightAdjusterView < mvvm.view.ComponentView
    methods
        function this = TipHeightAdjusterView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.addChild(uicontrol('style', 'text', 'String', 'TipHeightAdjusterView'));
        end
    end
end
