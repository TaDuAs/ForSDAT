classdef (Abstract) ICookedResultValidator < handle & matlab.mixin.Heterogeneous
    methods (Abstract)
        [isvalid, msg] = validate(this, results);
    end
end

