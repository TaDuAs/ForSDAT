classdef SizeVsNoiseMethod < ForSDAT.Core.Ruptures.Thresholding.IThresholdMethod
    %SIZEVSNOISEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    methods

        function mask = apply(this, rsReRf, frc, dist, noiseAmp)
            mask = rsReRf(3, :) > 2*noiseAmp;
        end
    end
end

