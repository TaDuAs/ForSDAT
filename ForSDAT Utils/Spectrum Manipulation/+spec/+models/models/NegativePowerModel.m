classdef NegativePowerModel < spec.models.Model
    % NegativePowerModel models a power function with negative integer
    % powers of a set order.
    % The NegativePowerModel of order n is given by the expression:
    %   y = a + 1/sum(bi * x^i), where i is 0..n
    % order 1 is a hyperbola: y = a+1/(bx+c)

    properties (Access=private)
        Order_ (1,1) double = 1;
        Shifts_ (2,1) double = [0;0];
    end
    properties (Dependent)
        Order (1,1) double;
        
        % y/x shifts of the center of the power function
        Shifts (2,1) double;
    end
    
    properties
        EnableShiftFitting (1,1) logical = true;
    end
    
    methods 
        function this = set.Order(this, value)
            this.Order_ = value;
            this.updateStartPosition();
        end
        function value = get.Order(this)
            value = this.Order_;
        end
        
        function this = set.Shifts(this, value)
            this.Shifts_ = value;
            if this.EnableShiftFitting
                this.updateStartPosition();
            end
        end
        function value = get.Shifts(this)
            value = this.Shifts_;
        end
    end
    
    methods
        function this = NegativePowerModel(order, shifts)
            if nargin >= 1 && ~isempty(order)
                this.Order = order;
            end
            
            if nargin >= 2 && ~isempty(shifts)
                this.Shifts = shifts;
            end
        end
        
        function y = doCalc(this, x, b)
            if this.EnableShiftFitting
                % y = b(1) + 1/(b(2) + b(3)*x + b(4)*x^2 + ...
                y = b(1) + (1 ./ polyval(flip(b(2:end)), x));
            else
                % y = b(1) + 1/(b(2) + b(3)*x + b(4)*x^2 + ...
                y = this.Shifts(1) + (1 ./ (this.Shifts(2) + polyval(flip(b), x)));
            end
        end
    end
    
    methods (Access=protected)
        function this = updateStartPosition(this)
            startAt = ones(this.Order, 1);
            
            if this.EnableShiftFitting
                startAt = vertcat(this.Shifts(:), startAt);
            end
            
            this.StartPosition = startAt;
        end
        function validateParameterSet(this, paramSet)
            if this.EnableShiftFitting
                n = this.Order + 2;
            else
                n = this.Order;
            end
            assert(iscolumn(paramSet) && numel(paramSet) == n,...
                'Parameter set must be a column vector of size %d', n);
        end
    end
end

