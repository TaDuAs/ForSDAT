classdef WLCSolutionFitter < ChainFit
    % Solves the WLC problem using force and stiffness.
    % The stiffness at the rupture event is guessed by fitting a polynom to
    % a short range next to the rupture event.
    
    properties
        T = Simple.Scientific.PhysicalConstants.RT;
        loadingRateFitRange = 0.2;
        polynomialOrder = 1;
    end
    
    methods
        function this = WLCSolutionFitter(T, loadingRateFitRange, polynomialOrder)
            this@ChainFit(false);
            
            if exist('T', 'var') && ~isempty(T)
                this.T = T;
            end
            if exist('loadingRateFitRange', 'var') && ~isempty(loadingRateFitRange)
                this.loadingRateFitRange = loadingRateFitRange;
            end
            if exist('polynomialOrder', 'var') && ~isempty(polynomialOrder)
                this.polynomialOrder = polynomialOrder;
            end
        end
        
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            import Simple.Math.*;
            
            % Crop x&y for stiffness guessing 
            if length(this.loadingRateFitRange) == 1
                loadRateGuessX = croparr(x, this.loadingRateFitRange, 'end');
                loadRateGuessY = croparr(y, this.loadingRateFitRange, 'end');
            else
                loadRateGuessX = croparr(x, this.loadingRateFitRange);
                loadRateGuessY = croparr(y, this.loadingRateFitRange);
            end
            if length(loadRateGuessX) < 2
                n = length(x);
                loadRateGuessX = croparr(x, [n-1, n]);
                loadRateGuessY = croparr(y, [n-1, n]);
            end

            % Fit polynom and derive it to guess stiffness
            ruptureDistance = x(end);
            ruptureForce = y(end);
            pol = epolyfit(loadRateGuessX, loadRateGuessY, this.polynomialOrder);
            der = polyder(pol);
            stiffness = polyval(der, ruptureDistance);

            % Solve the wlc problem according to the force, distance and
            % guessed stiffness at rupture
            [p, l] = wlc.PL(ruptureDistance, ruptureForce, stiffness, this.T);

            % Get the correct solution
            [~, p, l] = wlc.correctSolution(x, p, l);

            [p, l, gof, output] = wlc.fit(x, -y, double(real(p)), double(real(l)), this.T);
            
            % generate function
            kBT = Simple.Scientific.PhysicalConstants.kB * this.T;
            func = wlc.createExpretion(kBT, p, l);
            
            % fit output metadata
            isGoodFit = p > 0 && l > 0 && l >= x(end);
            s = gof.rsquare;
            mu = [];
        end
    end
    
end

