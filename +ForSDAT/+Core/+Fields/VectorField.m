classdef VectorField < ForSDAT.Core.Fields.ForceDistanceField
    % this is the basic field type - time, distance, force, etc.
    properties
        Value;
    end
    
    methods
        function value = getv(this)
            value = this.Value;
        end
    end
end

