classdef WLCInteraction < ForSDAT.Sim.SimulatedInteraction
    properties
        PersistenceLength;
        ContourLength;
    end
    
    methods
        function resolve(this)
            [p, l] = Simple.Math.wlc.PL(...
                this.RuptureDistance, this.RuptureForce, this.RuptureSlope);
            [~, this.PersistenceLength, this.ContourLength] = Simple.Math.wlc.correctSolution(...
                this.LoadingDomainX, p, l);
            
        end
        
        function [y, wlcY] = calculate(this, x, curve)
            if isempty(this.PersistenceLength) || isempty(this.ContourLength)
                this.resolve();
            end
            
            contactPointIndex = curve.SimInfo.ContactPointIndex;
            wlcY = Simple.Math.wlc.F(this.LoadingDomainX, this.PersistenceLength, this.ContourLength);
            y = -[zeros(1, contactPointIndex), wlcY, zeros(1, numel(x) - numel(this.LoadingDomainX) - contactPointIndex)];
        end
    end
end

