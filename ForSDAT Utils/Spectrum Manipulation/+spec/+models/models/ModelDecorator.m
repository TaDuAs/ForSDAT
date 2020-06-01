classdef ModelDecorator < spec.models.Model
    %MODELDECORATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Model spec.models.Model = spec.models.PolynomialModel.empty();
    end
    
    methods
        function this = ModelDecorator(model)
            %MODELDECORATOR Construct an instance of this class
            %   Detailed explanation goes here
            this.Model = model;
        end
        
        function y = doCalc(this, x, b)
        % execute wraped model calculation
            y = this.Model.calc(x, b);
        end
        
        function this = optimize(this, x, y)
            this.Model = this.Model.optimize(x, y);
        end
        
    end
    
    methods (Hidden)
        function this = setStartPosition(this, value)
            this.Model = this.Model.setStartPosition(value);
        end
        function value = getStartPosition(this)
            value = this.Model.getStartPosition();
        end
        
        function this = setParameters(this, value)
            this.Model = this.Model.setParameters(value);
        end
        function value = getParameters(this)
            value = this.Model.getParameters();
        end
        
        function r = doCalculateRCF(this, y, y1) 
        % Use wraped models rcf calculation but use this
            r = this.Model.doCalculateRCF(y, y1);
        end
    end
    
    methods (Access=protected)
        function validateParameterSet(this, paramSet)
            % do nothing
        end
    end
end

