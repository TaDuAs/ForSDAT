classdef CurveSimulator < handle
    %CURVESIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SimInfo ForSDAT.Sim.SimInfo;
        Simulators ForSDAT.Sim.ICurveDataSectionSimulator;
    end
    
    methods
        function this = CurveSimulator(simInfo, simulators)
            this.SimInfo = simInfo;
            this.Simulators = simulators;
        end
        
        function curve = simulate(this, xPos, yPos, curveIdx)
            curve = ForSDAT.Sim.SimulatedFDC();
            [x, y, t] = this.Simulators(1).simulateData([], [], curve);
            n = numel(this.Simulators);
            x(2:n, :) = zeros(n-1, size(x,2));
            y(2:n, :) = zeros(n-1, size(x,2));
            
            for i = 2:numel(this.Simulators)
                simulator = this.Simulators(i);
                [x(i, :), y(i, :)] = simulator.simulateData(t, x(1,:), curve);
            end
            
            curve.segments(1) = ForSDAT.Core.ForceDistanceSegment(...
                1, 'retract', ...
                this.SimInfo.SpringConstant, this.SimInfo.Sensitivity, ...
                sum(y, 1), sum(x, 1), t, xPos, yPos, curveIdx);
        end
    end
end

