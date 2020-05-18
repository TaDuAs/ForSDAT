classdef Scalar < util.matex.MathematicalExpression & mfc.IDescriptor
    properties
        scalar;
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'scalar'};
            defaultValues = {};
        end
    end
    
    methods
        function this = Scalar(scalar)
            this.scalar = scalar;
        end
        
        function value = invoke(this, args)
            value = zeros(1, length(args)) + this.scalar;
        end
        
        function b = equals(this, expression)
            if isnumeric(expression)
                b = this.scalar == expression;
            else
                b = this.equals@util.matex.MathematicalExpression(expression);
            end
        end
        
        function str = toString(this)
            str = num2str(this.scalar);
        end
    end
    
    methods (Access=protected)
        % d(scalar)/dx = 0
        function func = getDerivative(this)
            func = util.matex.Zero();
        end
        
        function b = determineEquality(this, expression)
            if isa(expression, 'util.matex.Scalar')
                b = this.scalar == expression.scalar;
            else
                b = this.determineEquality@util.matex.MathematicalExpression(expression);
            end
        end
    end
end

