classdef OscillatingBaselineSimulator < ForSDAT.Sim.ICurveDataSectionSimulator & matlab.mixin.SetGet
    properties
        SimInfo;
        WaveFunction function_handle = @sin;
        Wavelength = 500;
        Phase = 0;
        MaxAmpliture = 50;
    end
    
    methods
        function this = OscillatingBaselineSimulator(simInfo, varargin)
            this.SimInfo = simInfo;
            set(this, varargin{:});
        end
        
        function [xo, y, t] = simulateData(this, t, x, curve)
            curve.SimInfo.BaselineWave = ForSDAT.Sim.Randomizer.uniform(1, this.MaxShift, true);
            curve.SimInfo.BaselineSlope = -1*Randomizer.uniform(1, this.MaxSlope, this.AllowPositiveSlope);
            y = x * curve.SimInfo.BaselineSlope + curve.SimInfo.BaselineShift;
            xo = zeros(size(x));
        end
    end
end

