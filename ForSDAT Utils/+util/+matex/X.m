classdef X < util.matex.MathematicalExpression & mfc.IDescriptor
    properties
        parameterName = 'x'
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'parameterName'};
            defaultValues = {};
        end
    end
    
    methods
        function this = X(parameterName)
            if exist('parameterName', 'var') && ~isempty(parameterName)
                this.parameterName = parameterName;
            end
        end
        
        function value = invoke(this, args)
            value = args;
        end
        
        function str = toString(this)
            str = this.parameterName;
        end
    end
    
    methods (Access=protected)
        function func = getDerivative(this)
            func = util.matex.One;
        end
        
        function b = determineEquality(this, expression)
            b = isa(expression, 'util.matex.X');
        end
    end
end

