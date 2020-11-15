classdef AdhesionEnergyDetector < ForSDAT.Core.Adhesion.ISectionDetector
    properties
        EOOM util.OOM = util.OOM.Atto;
        FOOM util.OOM = util.OOM.Pico;
        ZOOM util.OOM = util.OOM.Nano;
        ignoreRepulsionForces = true;
    end
    
    methods        
        function [adhesion, units] = detect(this, z, f, ruptureDistance)
            % find the section of the data that corresponds to the bounding
            % method used
            mask = this.getBoundsMask(z, f, ruptureDistance);
            
            % get the relevant section
            % notice that the force vector is multiplied by -1 to
            % calculate a positive energy value
            x = z(mask) * 10^(double(this.ZOOM));
            y = -(f(mask) * 10^(double(this.FOOM)));
            
            if this.ignoreRepulsionForces
                % zero out all repulsion forces
                % repulsion forces are now negative
                y(y < 0) = 0;
            end
            
            % calculate energy using AUC
            adhesion = trapz(x, y) * 10^(-double(this.EOOM));
            units = [this.EOOM.getPrefix() 'J'];
        end
        
        
        function init(this, settings)
            this.FOOM = mvvm.getobj(settings, 'FOOM', this.FOOM);
            this.ZOOM = mvvm.getobj(settings, 'ZOOM', this.ZOOM);
        end
    end
end

