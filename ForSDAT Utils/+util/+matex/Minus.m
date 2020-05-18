classdef Minus < util.matex.Subtract
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'rightExpression'};
            defaultValues = {};
        end
    end
    
    methods
        function this = Minus(expression)
            this@util.matex.Subtract(util.matex.Zero(), expression);
        end
        
        function str = toString(this)
            str = ['-' this.right().toString()];
        end
    end
    
end

