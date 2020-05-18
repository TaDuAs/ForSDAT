classdef Series < util.matex.MathematicalExpression & mfc.IDescriptor
    properties
        elements = [];
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'elements'};
            defaultValues = {};
        end
    end
    
    methods 
        function this = Series(elements)
            this.elements = elements;
        end
        
        function value = invoke(this, args)
            value = zeros(1, length(args));
            for i = 1:length(this.elements)
                value = this.accumulateValue(value, this.elements(i).invoke(args));
            end
        end
        
        function str = toString(this)
            str = '(';
            operator = this.getOperatorStringRepresentation();
            for i = 1:length(this.elements)
                if i > 1
                    str = [str operator this.elements(i).toString()];
                else
                    str = [str this.elements(i).toString()];
                end
            end
            str = [str ')'];
        end
    end
    
    methods (Abstract, Access=protected)
        value = accumulateValue(this, accumulation, currValue);
        
        str = getOperatorStringRepresentation(this);
    end
end

