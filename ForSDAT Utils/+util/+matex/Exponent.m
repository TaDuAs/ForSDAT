classdef Exponent < util.matex.Power
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'expression'};
            defaultValues = {};
        end
    end
    
    methods
        function this = Exponent(expression)
            this@util.matex.Power(Scalar(exp(1)), expression);
        end
        
        function str = toString(this)
            str = ['e^' this.right().toString()];
        end
    end
    
    methods (Access=protected)
        % d(e^f)/dx = f'*e^f
        function func = getOperatorDerivative(this, leftFunc, rightFunc)
            func = util.matex.Multiply(this, rightFunc.derive());
        end
    end
end

