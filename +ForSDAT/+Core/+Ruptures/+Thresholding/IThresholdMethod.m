classdef (Abstract) IThresholdMethod < matlab.mixin.Heterogeneous
    %ITHRESHOLDMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Abstract)
        % Applies a thresholding method to the list of rupture events
        % specified in rsReRf
        % rsReRf : [rupture start index; rupture end index; rupture force]
        mask = apply(this, rsReRf, frc, dist, noiseAmp);
    end
end

