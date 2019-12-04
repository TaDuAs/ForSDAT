classdef AdhesionEnergyDetector < ForSDAT.Core.Adhesion.ISectionDetector
    properties
        EOOM Simple.Math.OOM = Simple.Math.OOM.Atto;
        FOOM Simple.Math.OOM = Simple.Math.OOM.Pico;
        ZOOM Simple.Math.OOM = Simple.Math.OOM.Nano;
    end
    
    methods        
        function [adhesion, units] = detect(this, z, f)
            mask = this.getLogicalIndex(z);
            
            x = z(mask) * 10^(double(this.ZOOM));
            y = -(f(mask) * 10^(double(this.FOOM)));
            adhesion = trapz(x, y) * 10^(-double(this.EOOM));
            
            units = [this.EOOM.getPrefix() 'J'];
        end
        
        function init(this, settings)
            this.FOOM = Simple.getobj(settings, 'measurement.FOOM', this.FOOM);
            this.ZOOM = Simple.getobj(settings, 'measurement.ZOOM', this.ZOOM);
        end
    end
end

