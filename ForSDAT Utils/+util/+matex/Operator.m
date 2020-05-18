classdef (Abstract) Operator < util.matex.MathematicalExpression & mfc.IDescriptor
    properties
        leftExpression;
        rightExpression;
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'leftExpression', 'rightExpression'};
            defaultValues = {};
        end
    end
    
    methods
        function this = Operator(left, right)
            if ~this.validateExpression(left) || ~this.validateExpression(left)
                error('Both expressions for a util.matex.Operator must be valid util.matex.MathematicalExpression instances');
            end
            this.leftExpression = left.evaluate();
            this.rightExpression = right.evaluate();
        end
        
        function value = invoke(this, args)
            value = this.operate(this.left.invoke(args), this.right.invoke(args));
        end
        
        function func = left(this)
            func = this.leftExpression;
        end
        
        function func = right(this)
            func = this.rightExpression;
        end
        
        function str = toString(this)
            str = ['(' this.left().toString() this.getOperatorStringRepresentation() this.right().toString() ')'];
        end
        
        function func = evaluate(this)
            if isa(this.right, 'util.matex.Scalar') && isa(this.left, 'util.matex.Scalar')
                func = util.matex.Scalar(this.invoke(0));
            else
                func = this.evaluate@util.matex.MathematicalExpression();
            end
        end
    end
    
    methods (Access=protected)
        function b = determineEquality(this, expression)
        % Recursively compares both operator expressions for type and expression
            if ~isa(expression, class(this)) && ~isa(this, class(expression)) 
                b = false;
                return;
            end
            
            b = this.right.equals(expression.right) && this.left.equals(expression.left);

            % Comutativity allows for left-right switching, as in addition
            if ~b && this.isCommutative
                b = this.left.equals(expression.right) && this.right.equals(expression.left);
            end
        end
        
        function func = getDerivative(this)
            func = this.getOperatorDerivative(this.left, this.right);
        end
        
        function b = isCommutative(this)
            b = false;
        end
    end
        
    methods (Abstract, Access=protected)
        value = operate(this, leftValue, rightValue);
        
        func = getOperatorDerivative(this, leftFunc, rightFunc);
        
        str = getOperatorStringRepresentation(this);
    end
    
end

