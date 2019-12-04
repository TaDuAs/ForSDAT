classdef (Abstract) SimulatedInteraction < handle
    properties
        RuptureForce;
        RuptureSlope;
        LoadingLength;
        RuptureDistance;
        LoadingDomainX;
        StartEndIndex;
    end
    
    methods (Abstract)
        y = calculate(this, x)
        
        resolve(this)
    end
end

