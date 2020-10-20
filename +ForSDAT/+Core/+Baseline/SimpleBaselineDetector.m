classdef SimpleBaselineDetector < ForSDAT.Core.Baseline.BaselineDetector
    %SIMPLEBASELINEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fragment = 0.1
        stdScore = 3;
        isBaselineTilted_value = false;
    end
    
    methods
        % ctor
        function this = SimpleBaselineDetector(fragment, stdScore, isBaselineTilted)
            if exist('fragment', 'var')
                this.fragment = fragment;
            end
            if exist('stdScore', 'var')
                this.stdScore = stdScore;
            end
            if exist('isBaselineTilted', 'var')
                this.isBaselineTilted_value = isBaselineTilted;
            end
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu] = detect(this, x, y)
        % Finds the baseline of the curve
        % Returns:
        %   baseline - the numeric value of the baseline
        %   y - the force vector, unchanged by this method
        %   noiseAmp - the evaluated amplitude of noise oscilations
        %   coefficients - the coefficients of the baseline polynomial fit
        %   s - standard error values
        %   mu - [avg, std]

            if length(this.fragment) == 1
                xSect = util.croparr(x, this.fragment, 'end');
                ySect = util.croparr(y, this.fragment, 'end');
            else
                xSect = util.croparr(x, this.fragment);
                ySect = util.croparr(y, this.fragment);
            end
            polyOrder = util.cond(this.isBaselineTilted, 1, 0);
            [coefficients, s, mu] = polyfit(xSect, ySect, polyOrder);
            baseline = coefficients(1);
            yDev = std(ySect - polyval(coefficients, xSect, [], mu));
            noiseAmp = this.stdScore * yDev;
            mu = {baseline, yDev};
        end
        
        function b = isBaselineTilted(this)
            b = this.isBaselineTilted_value;
        end
    end
end