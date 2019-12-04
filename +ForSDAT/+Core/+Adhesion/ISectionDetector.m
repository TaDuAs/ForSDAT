classdef (Abstract) ISectionDetector < handle
    properties
        zBounds (1,2) = [-inf, inf];
    end
    
    methods
        function this = ISectionDetector(minZ, maxZ)
            if nargin >= 1
                this.zBounds(1) = minZ;
                if nargin >= 2 
                    this.zBounds(2) = maxZ;
                end
            end
        end
    
        function mask = getLogicalIndex(this, z)
            mask = z >= this.zBounds(1) & z <= this.zBounds(2);
        end
    end
end

