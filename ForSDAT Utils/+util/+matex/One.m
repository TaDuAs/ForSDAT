classdef One < util.matex.Scalar
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {};
            defaultValues = {};
        end
    end
    
    methods
        function this = One()
            this@util.matex.Scalar(1);
        end
    end
end