classdef BlankModel < spec.models.Model
    properties
        Y;
    end
    
    methods
        function this = BlankModel(y)
            this.Y = y;
        end
        
        function this = optimize(this, ~, ~)
        end
        
        function y = calc(this, ~, ~)
            y = this.Y;
        end
        
        function y = doCalc(this, ~, ~)
            y = this.Y;
        end
    end
    
    methods (Access=protected)
        function validateParameterSet(~, ~)
            
        end
    end
end

