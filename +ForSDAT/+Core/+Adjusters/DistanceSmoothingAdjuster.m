classdef DistanceSmoothingAdjuster < handle
    %DISTANCESMOOTHINGADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function this = DistanceSmoothingAdjuster()
        end
        
        function [z, f] = adjust(this, z, f)
            z = sort(z);
        end
        
        function name = name(this)
            name = 'Distance Smoothing';
        end
    end
end

