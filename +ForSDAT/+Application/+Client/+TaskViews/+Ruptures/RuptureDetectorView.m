classdef RuptureDetectorView < mvvm.view.ComponentView
    methods
        function this = RuptureDetectorView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    
    methods (Access=protected)
        function initializeComponents(this)
            this.addChild(uicontrol('style', 'text', 'String', 'RuptureDetectorView'));
        end
    end
end

