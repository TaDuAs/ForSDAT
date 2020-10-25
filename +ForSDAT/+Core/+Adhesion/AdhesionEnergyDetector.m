classdef AdhesionEnergyDetector < ForSDAT.Core.Adhesion.ISectionDetector
    properties
        EOOM util.OOM = util.OOM.Atto;
        FOOM util.OOM = util.OOM.Pico;
        ZOOM util.OOM = util.OOM.Nano;
    end
    
    methods        
        function [adhesion, units] = detect(this, z, f, ruptureDistance)
            mask = this.getBoundsMask(z, f, ruptureDistance);            
            x = z(mask) * 10^(double(this.ZOOM));
            y = -(f(mask) * 10^(double(this.FOOM)));
            adhesion = trapz(x, y) * 10^(-double(this.EOOM));
            
            units = [this.EOOM.getPrefix() 'J'];
        end
        
        
        function init(this, settings)
            this.FOOM = mvvm.getobj(settings, 'FOOM', this.FOOM);
            this.ZOOM = mvvm.getobj(settings, 'ZOOM', this.ZOOM);
            
            % TODO: implement linker size window
%             if this.sectionLimitType == ForSDAT.Core.BoundingLimitTypes.LinkerBounds
%                 this.
%             end
        end
    end
end

