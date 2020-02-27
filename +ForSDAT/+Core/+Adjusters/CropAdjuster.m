classdef CropAdjuster < handle
    %CROPADJUSTER Summary of this class goes here
    %   Detailed explanation goes here
   
    properties
        left = 0;
        right = 0;
    end
    
    methods
        function name = name(this)
            name = 'Crop Curve';
        end
        
        function this = CropAdjuster(left, right)
            if nargin >= 1
                this.left = left;
            end
            if nargin >= 2
                this.right = right;
            end
        end
        
        function [z, f] = adjust(this, z, f)
            if this.left > 0
                z = gen.croparr(z, 1-this.left, 'end');
                f = gen.croparr(f, 1-this.left, 'end');
            end
            if this.right > 0
                z = gen.croparr(z, 1-this.right, 'start');
                f = gen.croparr(f, 1-this.right, 'start');
            end
        end
    end
    
end

