classdef Multiply < util.matex.Operator
    methods
        function this = Multiply(left, right)
            this@util.matex.Operator(left, right);
        end
    end
    
    methods (Access=protected)
        % value = f * g
        function value = operate(this, leftVal, rightVal)
            value = leftVal.*rightVal;
        end
        
        % d(f*g)/dx = (df/dx)*g + f*(dg/dx)
        function func = getOperatorDerivative(this, leftFunc, rightFunc)
            import util.matex.*;
            func = Add(...
                Multiply(leftFunc.derive(), rightFunc),...
                Multiply(leftFunc, rightFunc.derive()));
        end
        
        function b = isCommutative(this)
        % Multiplication is commutative
            b = true;
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '*';
        end
    end
    
    methods
        function func = evaluate(this)
        % Used for expression reduction.
        % for instance: 1*X = X; 0*X = 0; you get the idea
            lex = this.left;
            rex = this.right;
        
            if lex.equals(util.matex.Zero) || rex.equals(util.matex.Zero)
                func = util.matex.Zero;
            elseif lex.equals(util.matex.One)
                func = rex;
            elseif rex.equals(util.matex.One)
                func = lex;
            else
                func = this.evaluate@util.matex.Operator();
            end
        end
    end
end