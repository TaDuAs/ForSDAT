classdef (Abstract) Model
    properties (Access=private)
        StartPosition_ double;
        Parameters_ double;
    end
    
    properties (Dependent)
        StartPosition double;
        Parameters double;
    end
    
    methods % Property accessors
        function this = set.StartPosition(this, value)
            this = this.setStartPosition(value);
        end
        function value = get.StartPosition(this)
           value = this.getStartPosition();
        end
        
        function this = set.Parameters(this, value)
            this = this.setParameters(value);
        end
        function value = get.Parameters(this)
           value = this.getParameters();
        end
    end
    
    methods
        function y = calc(this, x, b)
            if nargin < 3
                if isempty(this.Parameters)
                    error('Can''t calculate without parameter set. Either send parameter set or optimize first');
                end
                
                y = this.doCalc(x, this.Parameters);
            else
                y = this.doCalc(x, b);
            end
        end
        
        function this = optimize(this, x, y)
            rcfFoo = @(b) this.rcf(b, x, y);
            this.Parameters = fminsearch(rcfFoo, this.StartPosition);
        end
    end
    
    methods (Abstract)
        % Execute the model calculation
        y = doCalc(this, x, b);
    end
    
    methods (Abstract, Access=protected) 
        % Validate model parameter set
        validateParameterSet(this, paramSet)
    end
    
    methods (Hidden)
        function this = setStartPosition(this, value)
            this.validateParameterSet(value);
            this.StartPosition_ = value;
        end
        function value = getStartPosition(this)
            value = this.StartPosition_;
        end
        
        function this = setParameters(this, value)
            this.validateParameterSet(value);
            this.Parameters_ = value;
        end
        function value = getParameters(this)
            value = this.Parameters_;
        end
        
        function r = rcf(this, b, x, y) 
        % Calculate the residual cost function using the calculated value
        % of this model. By default use Residual Norm Cost Function.
            r = this.doCalculateRCF(y, this.calc(x, b));
        end
        
        function r = doCalculateRCF(this, y, y1)
        % Allow decorators to calculate the RCF function using the wrapped 
        % models RCF function
            
            % Residual Norm Cost Function
            r = norm(y - y1);
        end
    end
end

