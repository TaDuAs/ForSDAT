classdef AdhesionEnergyDetector < ForSDAT.Core.Adhesion.ISectionDetector
    properties
        EOOM util.OOM = util.OOM.Atto;
        FOOM util.OOM = util.OOM.Pico;
        ZOOM util.OOM = util.OOM.Nano;
        
        areaLimitType ForSDAT.Core.BoundingLimitTypes = ForSDAT.Core.BoundingLimitTypes.Fixed;
    end
    
    methods        
        function [adhesion, units] = detect(this, z, f, ruptureDistance)
            mask = this.getBoundsMask(z, f, ruptureDistance);            
            x = z(mask) * 10^(double(this.ZOOM));
            y = -(f(mask) * 10^(double(this.FOOM)));
            adhesion = trapz(x, y) * 10^(-double(this.EOOM));
            
            units = [this.EOOM.getPrefix() 'J'];
        end
        
        function mask = getBoundsMask(this, z, f, ruptureDistance)
            switch this.areaLimitType
                case ForSDAT.Core.BoundingLimitTypes.Fixed
                    mask = this.getLogicalIndex(z);
                case ForSDAT.Core.BoundingLimitTypes.LastRupture
                    mask = z <= max(ruptureDistance);
                case ForSDAT.Core.BoundingLimitTypes.LinkerBounds
                    %TODO implement linker size window
                    throw(MException('ForSDAT:Core:Adhesion:AdhesionEnergyDetector:LinkerNotImplemented', 'ForSDAT.Core.BoundingLimitTypes.LinkerBounds functionality not implemented yet'));
                otherwise
                    mask = true(size(z));
            end
        end
        
        function init(this, settings)
            this.FOOM = mvvm.getobj(settings, 'measurement.FOOM', this.FOOM);
            this.ZOOM = mvvm.getobj(settings, 'measurement.ZOOM', this.ZOOM);
            
            % TODO: implement linker size window
%             if this.areaLimitType == ForSDAT.Core.BoundingLimitTypes.LinkerBounds
%                 this.
%             end
        end
    end
end

