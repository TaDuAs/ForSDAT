classdef Subtract < util.matex.Operator
    methods
        function this = Subtract(left, right)
            this@util.matex.Operator(left, right);
        end
    end
    
    methods (Access=protected)
        % value = f - g
        function value = operate(this, leftVal, rightVal)
            value = leftVal - rightVal;
        end
        
        % d(f-g)/dx = df/dx - dg/dx
        function func = getOperatorDerivative(this, leftFunc, rightFunc)
            func = util.matex.Subtract(leftFunc.derive(), rightFunc.derive());
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '-';
        end
    end
    
    methods
        function func = evaluate(this)
        % Used for expression reduction.
        % for instance: X-0 = X;
        % Don't do anything in the case of 0-X. Because 0-X = -X = Minus(X)
        % And Minus operator is implemented using Subtract(Zero,Expression)
            if this.right.equals(util.matex.Zero)
                func = this.left;
            else
                func = this.evaluate@util.matex.Operator();
            end
        end
    end
end

