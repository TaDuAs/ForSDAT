classdef NonSpecificInteractionSimulator < ForSDAT.Sim.ICurveDataSectionSimulator & matlab.mixin.SetGet
    %NONSPECIFICINTERACTIONSIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SimInfo ForSDAT.Sim.SimInfo;
        MaxInteractions (1,1) double = 10;
        LoadingLengthMu (1,1) double = 20;
        LoadingLengthSig (1,1) double = 10;
        MaxRuptForce (1,1) double = 250;
        MinRuptForce (1,1) double = 50;
    end
    
    methods
        function this = NonSpecificInteractionSimulator(simInfo, varargin)
            this.SimInfo = simInfo;
            set(this, varargin{:});
        end
        
        function [xo, y, t] = simulateData(this, t, x, curve)
            xo = zeros(size(x));
            contactPointIndex = curve.SimInfo.ContactPointIndex;
            y = zeros(size(x));
                
            % Loading distance of non-specific interactions distributes normally
            nInteractions = ForSDAT.Sim.Randomizer.uniformInt(1, this.MaxInteractions);
            ruptForces = ForSDAT.Sim.Randomizer.uniform(nInteractions, [this.MinRuptForce, this.MaxRuptForce]);
            loadingLengths = ForSDAT.Sim.Randomizer.normal(nInteractions, this.LoadingLengthMu, this.LoadingLengthSig);
            lrs = ForSDAT.Sim.Randomizer.lr(nInteractions, this.SimInfo.SpringConstant, this.SimInfo.RetractVelocity);
            nResolvedInteractions = 0;
            nonSpecific.LastRuptureDistance = x(contactPointIndex);
            
            for i = 1:nInteractions
                if loadingLengths(i) < 0
                    continue;
                end
                
                curr = ForSDAT.Sim.WLCInteraction();
                curr.LoadingLength = loadingLengths(i);

                % Non-specific rupture force uniformly distributed between
                % specified values
                curr.RuptureForce = ruptForces(i);
                curr.RuptureSlope = lrs(i) / this.SimInfo.RetractVelocity;

                curr.RuptureDistance = loadingLengths(i) + x(contactPointIndex); % nm
                curr.LoadingDomainX = x(x <= curr.RuptureDistance & x >= x(contactPointIndex));
                curr.LoadingDomainX = [curr.LoadingDomainX - (curr.RuptureDistance - curr.LoadingLength) curr.RuptureDistance];
                
                currY = curr.calculate(x, curve);
                nResolvedInteractions = nResolvedInteractions + 1;

                % calculate interaction start-end indices
                curr.StartEndIndex = [contactPointIndex; numel(curr.LoadingDomainX) + contactPointIndex];

                % Add interaction to the list and to the non-specific interactions vector
                nonSpecific.Interactions(nResolvedInteractions) = curr;
                nonSpecific.LastRuptureDistance = max([nonSpecific.LastRuptureDistance, curr.RuptureDistance]);
                y = y + currY;
            end
            
            curve.SimInfo.NonSpecific = nonSpecific;
        end
    end
end

