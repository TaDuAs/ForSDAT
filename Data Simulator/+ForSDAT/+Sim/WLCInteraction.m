classdef WLCInteraction < ForSDAT.Sim.SimulatedInteraction
    properties
        PersistenceLength;
        ContourLength;
    end
    
    methods
        function resolve(this)
            [p, l] = util.wlc.PL(...
                this.RuptureDistance, this.RuptureForce, this.RuptureSlope);
            [~, this.PersistenceLength, this.ContourLength] = util.wlc.correctSolution(...
                this.LoadingDomainX, p, l);
            
        end
        
        function [y, wlcY] = calculate(this, x, curve)
            if isempty(this.PersistenceLength) || isempty(this.ContourLength)
                this.resolve();
            end
            
            contactPointIndex = curve.SimInfo.ContactPointIndex;
            wlcY = util.wlc.F(this.LoadingDomainX, this.PersistenceLength, this.ContourLength);
            y = -[zeros(1, contactPointIndex), wlcY, zeros(1, numel(x) - numel(this.LoadingDomainX) - contactPointIndex)];
        end
    end
end

