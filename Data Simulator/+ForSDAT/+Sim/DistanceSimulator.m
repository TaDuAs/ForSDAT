classdef DistanceSimulator < ForSDAT.Sim.ICurveDataSectionSimulator
    properties
        SimInfo ForSDAT.Sim.SimInfo;
    end
    
    methods
        function this = DistanceSimulator(simInfo)
            this.SimInfo = simInfo;
            
        end
        
        function [x, y, t] = simulateData(this, ~, ~, curve)
            tmax = this.SimInfo.ZLength / this.SimInfo.RetractVelocity;
            t = linspace(0, tmax, tmax*this.SimInfo.SamplingRate); % time vector, sec
            contactDomainLength = this.SimInfo.RelativeSetpoint / this.SimInfo.getCorrectedSpringConstant(); % X = F/k, nm
            contactDomainTiming = contactDomainLength / this.SimInfo.RetractVelocity; % sec
            curve.SimInfo.ContactPointIndex = find(t > contactDomainTiming, 1, 'first'); % sec

            x = t * this.SimInfo.RetractVelocity - contactDomainLength; % distance vector, nm
            y = zeros(size(x));
        end
    end
end

