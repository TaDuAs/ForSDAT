classdef Sum < util.matex.Series
    methods 
        function this = Sum(elements)
            this@util.matex.Series(elements);
        end
    end
    
    methods (Access=protected)
        function func = getDerivative(this)
            n = numel(this.elements);
            derivatives = repmat(util.matex.Zero(), 1, n);
            
            for i = 1:n
                currEl = this.elements(i);
                derivatives(i) = currEl.derive();
            end
            
            func = Sum(derivatives);
        end
        
        function value = accumulateValue(this, accumulation, currValue)
            value = accumulation + currValue;
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '+';
        end
    end
end

