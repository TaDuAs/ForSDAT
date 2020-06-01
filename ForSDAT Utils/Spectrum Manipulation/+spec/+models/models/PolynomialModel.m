classdef PolynomialModel < spec.models.Model
    % PolynomialModel models a polynomial function with of a set order.
        
    properties (GetAccess=public, SetAccess=private)
        Order (1,1) double = 1;
    end
    
    methods
        function this = PolynomialModel(order)
            if nargin >= 1 && ~isempty(order)
                this.Order = order;
            end
            
            this.StartPosition = ones(this.Order + 1, 1);
        end
        
        function y = doCalc(this, x, b)
            y = polyval(b, x);
        end
    end
    
    methods (Access=protected)
        function validateParameterSet(this, paramSet)
            n = this.Order + 1;
            assert(iscolumn(paramSet) && numel(paramSet) == n,...
                'Parameter set must be a column vector of size %d', n);
        end
    end
end

