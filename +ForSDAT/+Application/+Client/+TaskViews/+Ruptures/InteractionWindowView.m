classdef InteractionWindowView < mvvm.view.ComponentView
    methods
        function this = InteractionWindowView(parent, ownerView, varargin)
            this@mvvm.view.ComponentView(parent, 'OwnerView', ownerView, 'BoxType', @sui.FlowBox, varargin{:});
        end
    end
    methods (Access=protected)
        function initializeComponents(this)
            initializeComponents@mvvm.view.ComponentView(this);
            
            this.addChild(uicontrol('style', 'text', 'String', 'InteractionWindowView'));
        end
    end
end

