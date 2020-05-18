classdef Zero < util.matex.Scalar
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {};
            defaultValues = {};
        end
    end
    
    methods
        function this = Zero()
            this@util.matex.Scalar(0);
        end
    end
end