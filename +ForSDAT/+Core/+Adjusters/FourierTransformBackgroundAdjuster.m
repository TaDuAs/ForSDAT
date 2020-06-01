classdef FourierTransformBackgroundAdjuster < handle
    %FOURIERTRANSFORMBACKGROUNDADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SmoothingCycles = 100;
        Span = 1;
        Method = @mean;
    end
    
    methods
        function [fFixed, fourierFit, waveFVector, shift] = adjust(this, fToFix, zToFix, fFit, zFit, k)
        % Adjusts long-wavelength disturbances to the baseline
        
            % Fit wave function
            bgFilter = spec.filters.backgroundFilter(this.SmoothingCycles, this.Span, this.Method);
            spec.filterSpectrum(

            fFixed = fToFix - waveFVector;
        end
        
        function waveFVector = calcWaveVector(this, z, fourierFit)
            waveFVector = zeros(1, length(z));
            for i = 1:this.fourierSeriesOrder
                a = fourierFit.(['a' num2str(i)]);
                b = fourierFit.(['b' num2str(i)]);
                waveFVector = waveFVector + a*cos(i*z*fourierFit.w) + b*sin(i*z*fourierFit.w);
            end
        end
    end 
end

