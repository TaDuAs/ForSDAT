classdef ContactDomainSimulator < ForSDAT.Sim.ICurveDataSectionSimulator
    properties
        SimInfo ForSDAT.Sim.SimInfo;
        MaxShift;
        DecayFactor;
    end
    
    methods
        function this = ContactDomainSimulator(simInfo, maxShift, decayFactor)
            if nargin < 2 || isempty(maxShift); maxShift = 10000; end
            if nargin < 3 || isempty(decayFactor); decayFactor = 0; end
            this.SimInfo = simInfo;
            this.MaxShift = maxShift;
            this.DecayFactor = decayFactor;
        end
        
        function [xo, y, t] = simulateData(this, t, x, curve)
            curve.SimInfo.ContactPointShift = Randomizer.uniform(1, 10000, true);
            
            contactPointIndex = curve.SimInfo.ContactPointIndex;
%             contactDomainDecayFactor = -this.DecayFactor * this.SimInfo.getCorrectedSpringConstant();
            y = -[x(1:contactPointIndex) zeros(1, length(x)-contactPointIndex)] * this.SimInfo.getCorrectedSpringConstant();%...
            xo = repmat(curve.SimInfo.ContactPointShift, size(x));
            
            % Contact Domain: exponentially decaying hookean interaction is
            % disabled
%                 .* exp(contactDomainDecayFactor*(x + x(contactPointIndex)));
        end
    end
end

