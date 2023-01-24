classdef SmootingSMIView < mvvm.view.ComponentView
    methods
        function this = SmootingSMIView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            this.addChild(uicontrol('style', 'text', 'String', 'SmootingSMIView'));
        end
    end
end

