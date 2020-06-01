classdef FourierSeriesModel < spec.models.Model
    % FourierSeriesModel represents a fourier series optimization model
    % y = a0 + a1*sin(x*w) + b1*cos(x*w) + [ai*sin(x*w) + bi*cos(x*w)...]
    % where a0, a1..n, b1..n and w are optimization parameters and n is the
    % order of the series.
    
    properties (Access=private)
        Order_ = 1;
    end
    
    properties (Dependent)
        Order (1,1) {mustBePositive(Order), mustBeInteger(Order), mustBeFinite(Order)};
    end
    
    properties
        % X-values representing the window for fitting
        Window = {'start', 'end'};
    end
    
    methods % property accessors
        function this = set.Order(this, value)
            this.Order_ = value;
        end
        
        function value = get.Order(this)
            value = this.Order_;
        end
        
        function this = set.Window(this, value)
            rules = 'Window must be a two element array of numeric positive integers or ''end'' in the second element';
            assert(numel(value) == 2, rules);
            if iscell(value)
                first = value{1};
                second = value{2};
            else
                first = value(1);
                second = value(2);
            end
            
            assert((isnumeric(first) && isscalar(first) && isfinite(first)) || ...
                ((isStringScalar(first) || (ischar(first) && isrow(first))) && strcmp(first, 'start')), rules);
            assert((isnumeric(second) && isscalar(second) && isfinite(second)) || ...
                ((isStringScalar(second) || (ischar(second) && isrow(second))) && strcmp(second, 'end')), rules);
            
            this.Window = {first, second};
        end
    end
    
    methods
        function this = set(this, varargin)
            for i = 1:2:numel(varargin)
                fieldName = varargin{i};
                if ~(isStringScalar(fieldName) || ...
                   (ischar(fieldName) && isrow(fieldName))) ||...
                   ~isprop(this, fieldName)
                    error('FourierSeriesModel has no field with name "%s"', fieldName);
                end
                
                this.(fieldName) = varargin{i+1};
            end
        end
        
        function this = FourierSeriesModel(varargin)
            this = this.set(varargin{:});
            this.StartPosition = rand(this.Order*2 + 2, 1);
        end
        
        function this = optimize(this, x, y)
            if isempty(this.StartPosition)
                [xw, yw] = this.cropXY(x, y);
                this.StartPosition = [mean(y); repmat(0.5*range(yw), 2*this.Order, 1); 2*pi/range(xw)];
            end
            
            this = optimize@spec.models.Model(this, x, y);
        end
        
        % Execute the model calculation
        function y = doCalc(this, x, b)
            y = zeros(size(x)) + b(1);
            
            % frequency
            w = b(end);
            
            for i = 1:this.Order
                ai = b(i*2);
                bi = b(i*2+1);
                y = y + ai*sin(w*i*x) + bi*cos(w*i*x);
            end
        end
        
        function r = rcf(this, b, x, y) 
        % Calculate the residual cost function using the cropped data.
            [xc, yc] = this.cropXY(x, y);
            
            r = rcf@spec.models.Model(this, b, xc, yc);
        end
    end
    
    methods (Access=protected) 
        % Validate model parameter set
        function validateParameterSet(this, paramSet)
            
            n = this.Order * 2 + 2;
            assert(iscolumn(paramSet) && numel(paramSet) == n,...
                'Parameter set must be a column vector of size 2*Order + 2 (%d)', n);
        end
        
        function [xc, yc] = cropXY(this, x, y)
            windowMask = this.getWindowMask(x);
            xc = x(windowMask);
            yc = y(windowMask);
        end
        
        function mask = getWindowMask(this, x)
            first = this.Window{1};
            second = this.Window{2};
            
            mask = true(size(x));
            
            if isnumeric(first)
                mask = mask & x >= first;
            end
              
            if isnumeric(second)
                mask = mask & x <= second;
            end
        end
    end
    
end

