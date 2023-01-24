classdef PreviousRuptureEndLoadingDomain < handle

    
    methods
        function this = PreviousRuptureEndLoadingDomain()
        end
        
        function startAt = detect(this, x, y, ruptures, contactPoint, offsetFactor, noiseAmp)
            if isempty(ruptures)
                startAt = zeros(1, 0);
            else
                startAt = [0 ruptures(1, 1:end-1)];
            end
        end
    end
end

