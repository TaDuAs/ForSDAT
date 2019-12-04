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
        
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            [p, s, mu] = Simple.Math.epolyfit(x, y, this.order);
            func = Polynomial(p);
            
            % Determine if the fit was good
            isGoodFit = true;
            if ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, p, s, mu);
            end
        end
        
        function isGood = evaluateFitQuality(this, func, s, mu)
            isGood = true;
            if ~isempty(this.constraintsFunc)
                isGood = this.constraintsFunc(func, s, mu);
            end
        end
    end
    
end

