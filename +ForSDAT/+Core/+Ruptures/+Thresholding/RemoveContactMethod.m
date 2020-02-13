classdef RemoveContactMethod < ForSDAT.Core.Ruptures.Thresholding.IThresholdMethod
    %SIZEVSNOISEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    methods

        function mask = apply(this, rsReRf, frc, dist, noiseAmp)
            mask = dist(rsReRf(1, :)) > 0;
        end
    end
end

