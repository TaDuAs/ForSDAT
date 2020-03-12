classdef ChainFit < handle
    %CHAINFIT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xshiftValue = 0;
        shouldShiftX = false;
    end
    
    methods
        function this = ChainFit(shouldShiftX)
            if exist('shouldShiftX', 'var') && ~isempty(shouldShiftX)
                this.shouldShiftX = shouldShiftX;
            end
        end
        
        function x = xshift(this, x)
            this.xshiftValue = -x(:, 1);
            x = x + this.xshiftValue;
        end
        
        function [func, isGoodFit, s, mu] = fit(this, x, y)
            if this.shouldShiftX
                x = this.xshift(x);
            end
            
            [func, isGoodFit, s, mu] = this.dofit(x, y);
            
            if this.shouldShiftX
                func = Simple.Math.Ex.Shift(func, this.xshiftValue);
            end
        end
        
        function [func, modelParams, isGoodFit, s, mu] = dofit(this, x, y)
            error('implement in derived class');
        end
        
        function [funcs, isGoodFit, s, mu] = fitAll(this, x, y, ruptureIdx)
            error('implement in derived class');
        end
    end
    
end

