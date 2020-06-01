classdef SmoothFit < spec.models.ModelDecorator
    % SmoothFit is a decorator for the Model class which smooths the signal
    % for Residual Cost calculation
    
    properties
        Params = {};
        Iterations = 1;
    end
    
    methods
        function this = SmoothFit(model, n, varargin)
            this@spec.models.ModelDecorator(model);
            
            if nargin >= 2 && ~isempty(n)
                this.Iterations = n;
            end
            
            if nargin >= 3
                this.Params = varargin;
            end
        end
        
        function this = optimize(this, x, y)
            this.Model = optimize@spec.models.ModelDecorator(this, x, this.smooth(y));
        end
        
        function y1 = smooth(this, y)
            % smooth the signal
            % repeat n times for an ultra smooth signal
            y1 = y;
            for i = 1:this.Iterations
                y1 = smooth(y1, this.Params{:});
            end
        end
    end
end

