classdef SimInfo < handle & matlab.mixin.SetGet
    %SIMINFO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Foom = Simple.Math.OOM.Pico;
        Doom = Simple.Math.OOM.Nano;
        SamplingRate = 1024;
        ZLength = 500;
        RetractVelocity = 0.4 * 10^3;
        RelativeSetpoint = 500;
        SpringConstant = 0.03;
        Sensitivity = 50;
    end
    
    methods
        function value = getCorrectedSpringConstant(this)
            value = this.SpringConstant * this.KoomFactor;
        end
        function value = KoomFactor(this)
            value = 10^(-(this.Foom-this.Doom));
        end
    end
    
    methods
        function this = SimInfo(varargin)
            set(this, varargin{:});
        end
    end
end

