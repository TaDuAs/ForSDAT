classdef Product < util.matex.Series
    methods 
        function this = Product(elements)
            this@util.matex.Series(elements);
        end
    end
    
    methods (Access=protected)
        function func = getDerivative(this)
            n = numel(this.elements);
            derivatives = repmat(util.matex.Zero(), 1, n);
            
            for i = 1:n
                currElement = this.elements(i);
                derivatives(i) = util.matex.Product(...
                                    [...
                                        currElement.derive(),...
                                        this.elements([1:i-1, i+1:n])...
                                    ]);
            end
            
            func = util.matex.Sum(derivatives);
        end
        
        function value = accumulateValue(this, accumulation, currValue)
            value = accumulation * currValue;
        end
        
        function str = getOperatorStringRepresentation(this)
            str = '*';
        end
    end
end

