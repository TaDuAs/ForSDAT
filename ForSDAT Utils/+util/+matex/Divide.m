classdef Divide < util.matex.Operator
    methods
        function this = Divide(left, right)
            this@util.matex.Operator(left, right);
        end
    end
    
    methods (Access=protected)
        % value = f / g
        function value = operate(this, leftVal, rightVal)
            value = leftVal./rightVal;
        end
        
        % d(f/g)/dx = ((df/dx)*g - f*(dg/dx))/(g^2)
        function func = getOperatorDerivative(this, leftFunc, rightFunc)
            import util.matex.*;
            func = Divide(...
                Subtract(...
                    Multiply(leftFunc.derive(), rightFunc),...
                    Multiply(leftFunc, rightFunc.derive())),...
                Power(rightFunc, Scalar(2)));
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '/';
        end
    end
    
    methods
        function func = evaluate(this)
        % Used for expression reduction.
        % for instance: X/1 = X; 0/X = 0;
            if this.left.equals(util.matex.Zero)
                func = util.matex.Zero;
            elseif this.right.equals(util.matex.One)
                func = this.left;
            else
                func = this.evaluate@util.matex.Operator();
            end
        end
    end
end