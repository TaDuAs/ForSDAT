classdef BaselineSimulator < ForSDAT.Sim.ICurveDataSectionSimulator
    properties
        SimInfo;
        MaxShift;
        MaxSlope;
        AllowPositiveSlope;
    end
    
    methods
        function this = BaselineSimulator(simInfo, maxShift, maxSlope, allowPositiveSlope)
            if nargin < 2 || isempty(maxShift); maxShift = 10000; end
            if nargin < 3 || isempty(maxSlope); maxSlope = 0; end
            if nargin < 4 || isempty(allowPositiveSlope); allowPositiveSlope = false; end
            this.SimInfo = simInfo;
            this.MaxShift = maxShift;
            this.MaxSlope = maxSlope;
            this.AllowPositiveSlope = allowPositiveSlope;
        end
        
        function [xo, y, t] = simulateData(this, t, x, curve)
            curve.SimInfo.BaselineShift = ForSDAT.Sim.Randomizer.uniform(1, this.MaxShift, true);
            curve.SimInfo.BaselineSlope = -1*Randomizer.uniform(1, this.MaxSlope, this.AllowPositiveSlope);
            y = x * curve.SimInfo.BaselineSlope + curve.SimInfo.BaselineShift;
            xo = zeros(size(x));
        end
    end
end

