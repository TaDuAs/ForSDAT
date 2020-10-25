classdef ContactPointDetector < handle
    %CONTACTPOINTDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fragment = 0.025;
        iterativeApproachR2Threshold = 0.985;
        isSorftSurface = false;
    end
    
    methods
        
        function this = ContactPointDetector(fragment, iterativeApproachR2Threshold, isSorftSurface)
            if exist('fragment', 'var')
                this.fragment = fragment;
            end
            if exist('iterativeApproachR2Threshold', 'var')
                this.iterativeApproachR2Threshold = iterativeApproachR2Threshold;
            end
            if exist('isSorftSurface', 'var')
                this.isSorftSurface = isSorftSurface;
            end
        end
        
        function [contact, x, coefficients, s, msd] = detect(this, x, y, baseline)
        % Find the contact point of the curve by finding the point of
        % contact between the baseline and the contact linear extrapolation
        % Returns:
        %   contact - the numeric value of the surface contact point
        %   x - the x varriable, after adjustment if any was done
        %   coefficients - the coefficients of the contact force polynomial fit
        %   s - standard error values
        %   msd - mean and standard deviation of the residuals {mean, std}
            
            if ~exist('baseline', 'var')
                baseline = [0 0];
            end
            
            if this.isSorftSurface
                contact = findSoftSurfaceContactPoint(this, x, y, baseline);
                coefficients = [];
                s = [];
                msd = {0 0}; 
            else
                [contact, coefficients, s, msd] = findHardSurfaceContactPoint(this, x, y, baseline);
            end
        end
        
        
        function [x1, y1] = getXYSegment(this, x, y)
            if length(this.fragment) == 2
                x1 = util.croparr(x, this.fragment);
                y1 = util.croparr(y, this.fragment);
            else
                x1 = util.croparr(x, this.fragment, 'start');
                y1 = util.croparr(y, this.fragment, 'start');
            end
        end
    end
    
    methods (Access=private)
        
        function [contact, coefficients, s, msd] = findHardSurfaceContactPoint(this, x, y, baseline)
            % Fit 1st order polynom to the beginning of the curve
            [xSeg, ySeg] = this.getXYSegment(x, y);
            [coefficients, s] = polyfit(xSeg, ySeg, 1);
            R2 = util.getFitR2(ySeg, s);
            
            if (R2 > this.iterativeApproachR2Threshold)
                % pad shorter coefficients array with zeros
                coeffLength = length(coefficients);
                bslLength = length(baseline);
                if coeffLength > bslLength
                    baseline = [zeros(1,coeffLength-bslLength) baseline];
                elseif coeffLength < bslLength
                    coefficients = [zeros(1,bslLength-coeffLength) coefficients];
                end
                contact = -(coefficients(2)-baseline(2))/(coefficients(1)-baseline(1));
                residuals = polyval(coefficients, xSeg, s) - ySeg;
                msd = {mean(residuals), std(residuals)};
            else
                % Bug fix for curves with extremely noisy contact domain
                bsl = baseline(length(baseline));
                [contact, coefficients] = this.findSoftSurfaceContactPoint(x, y, bsl);
                msd = {0, 0};
            end
        end
        
        function [contact, coefficients] = findSoftSurfaceContactPoint(this, x, y, baseline)
            i = 1;
            while i < length(x) && y(i) > baseline
                i = i+1;
            end
            contact = x(i);
            a = (baseline - y(1))/(contact - x(1));
            b = y(1) - a*x(1);
            coefficients = [a, b];
        end
    end
    
end

