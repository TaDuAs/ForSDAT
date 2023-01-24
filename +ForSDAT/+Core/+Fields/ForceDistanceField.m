classdef (Abstract) ForceDistanceField
    properties (GetAccess=public, SetAccess=private)
        ID ForSDAT.Core.Fields.FieldID;
    end
    
    methods (Abstract)
        % Gets the current field value
        value = getv(this);
    end
    
    methods
        function type = getType(this)
            type = this.ID.Type;
        end
        
        function tf = checkType(this, type)
            tf = check(this.getType(), type);
        end
    end
end

