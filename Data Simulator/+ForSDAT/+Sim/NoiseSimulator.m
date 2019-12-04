classdef NoiseSimulator < ForSDAT.Sim.ICurveDataSectionSimulator
    %NOISESIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SimInfo ForSDAT.Sim.SimInfo;
        NoiseAmpMu (1,1) double;
        NoiseAmpSigma (1,1) double;
    end
    
    methods
        function this = NoiseSimulator(simInfo, mu, sig)
            if nargin < 2 || isempty(mu); mu = 0.075 * simInfo.RelativeSetpoint; end
            if nargin < 3 || isempty(sig); sig = mu / 3; end
            
            this.SimInfo = simInfo;
            this.NoiseAmpMu = mu;
            this.NoiseAmpSigma = sig;
        end
        
        function [xo, y, t] = simulateData(this, t, x, curve)
            curve.SimInfo.NoiseAmp = ForSDAT.Sim.Randomizer.normal(1, this.NoiseAmpMu, this.NoiseAmpSigma);
            
            y = ForSDAT.Sim.Randomizer.uniform(size(x), curve.SimInfo.NoiseAmp);
            xo = zeros(size(x));
        end
    end
end

