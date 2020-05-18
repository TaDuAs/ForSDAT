classdef Add < util.matex.Operator
    methods
        function this = Add(left, right)
            this@util.matex.Operator(left, right);
        end
    end
    
    methods (Access=protected)
        function value = operate(this, leftVal, rightVal)
        % value = f + g
            value = leftVal + rightVal;
        end
        
        function func = getOperatorDerivative(this, leftFunc, rightFunc)
        % d(f+g)/dx = df/dx + dg/dx
            func = util.matex.Add(leftFunc.derive(), rightFunc.derive());
        end
        
        function b = isCommutative(this)
        % Addition is commutative
            b = true;
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '+';
        end
    end
    
    methods
        function func = evaluate(this)
        % Used for expression reduction.
        % for instance: 0+X = X
            import util.matex.*;
            if this.left.equals(util.matex.Zero)
                func = this.right;
            elseif this.right.equals(util.matex.Zero)
                func = this.left;
            else
                func = this.evaluate@util.matex.Operator();
            end
        end
    end
end

