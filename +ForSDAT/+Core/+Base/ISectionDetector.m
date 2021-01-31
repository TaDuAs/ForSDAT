classdef (Abstract) ISectionDetector < handle
    properties
        zBounds (1,2) = [-inf, inf];
        
        sectionLimitType ForSDAT.Core.BoundingLimitTypes = ForSDAT.Core.BoundingLimitTypes.Fixed;
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
        
        function mask = getBoundsMask(this, z, f, ruptureDistance)
            switch this.sectionLimitType
                case ForSDAT.Core.BoundingLimitTypes.Fixed
                    mask = this.getLogicalIndex(z);
                case ForSDAT.Core.BoundingLimitTypes.LastRupture
                    if isempty(ruptureDistance)
                        mask = false(size(z));
                    else
                        mask = z <= max(ruptureDistance);
                    end
                case ForSDAT.Core.BoundingLimitTypes.LinkerBounds
                    %TODO implement linker size window
                    throw(MException('ForSDAT:Core:SectionDetector:LinkerNotImplemented', 'ForSDAT.Core.BoundingLimitTypes.LinkerBounds functionality not implemented yet'));
                otherwise
                    mask = true(size(z));
            end
        end
    end
end

