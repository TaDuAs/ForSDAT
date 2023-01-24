classdef PolynomialLoadFitter < ChainFit
    %POLYNOMIALLOADFITTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        order = [];
        constraintsFunc = [];
    end
    
    methods
        function this = PolynomialLoadFitter(order, constraintsFunction)
            this.order = order;
            
            if exist('constraintsFunction', 'var')
                this.constraintsFunc = constraintsFunction;
            end
        end
        
        function [func, isGoodFit, s, msd] = dofit(this, x, y)
            [p, s] = polyfit(x, y, this.order);
            func = util.matex.Polynomial(p);
            
            estimateY = polyval(p, x, s);
            residues = y - estimateY;
            msd = [mean(residues), std(residues)];
            
            % Determine if the fit was good
            isGoodFit = true;
            if ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, p, s, msd);
            end
        end
        
        function isGood = evaluateFitQuality(this, func, s, msd)
            isGood = true;
            if ~isempty(this.constraintsFunc)
                isGood = this.constraintsFunc(func, s, msd);
            end
        end
    end
    
end

