classdef DistanceCropAdjuster < handle
    %CROPADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
   
    properties
        maxDistance = -1;
    end
    
    methods
        function name = name(this)
            name = 'Crop Curve';
        end
        
        function this = DistanceCropAdjuster()
        end
        
        function [z, f] = adjust(this, z, f)
            if this.maxDistance > 0
                mask = z-z(1) <= this.maxDistance;
                z = z(mask);
                f = f(mask);
            end
        end
    end
    
end

