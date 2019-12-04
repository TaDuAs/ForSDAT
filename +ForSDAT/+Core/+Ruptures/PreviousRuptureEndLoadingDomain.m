classdef PreviousRuptureEndLoadingDomain < handle

    
    methods
        function this = PreviousRuptureEndLoadingDomain()
        end
        
        function startAt = detect(this, x, y, ruptures, contactPoint, offsetFactor, noiseAmp)
            startAt = [0 ruptures(1:end-1)];
        end
    end
end

