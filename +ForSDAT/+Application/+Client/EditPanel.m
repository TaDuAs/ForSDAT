classdef EditPanel < mvvm.view.ComponentView
    %EDITPANEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function this = EditPanel(parent, parentView, messenger, bindingManager)
            this@mvvm.view.ComponentView(parent, 'OwnerView', parentView, 'Messenger', messenger, 'BindingManager', bindingManager);
        end
    end
end

