classdef DistanceSmoothingAdjuster
    %DISTANCESMOOTHINGADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function this = DistanceSmoothingAdjuster()
        end
        
        function [z, f] = adjust(this, z, f)
            z = sort(z);
        end
    end
end

