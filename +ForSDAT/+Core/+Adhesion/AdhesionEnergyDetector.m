classdef AdhesionEnergyDetector < ForSDAT.Core.Base.ISectionDetector
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
            
            % #TODO: change this functionality
            if this.ignoreRepulsionForces
                mask = mask & f < 0;
            end
            
            % get the relevant section
            % notice that the force vector is multiplied by -1 to
            % calculate a positive energy value
            x = z(mask) * 10^(double(this.ZOOM));
            y = -(f(mask) * 10^(double(this.FOOM)));
            
            if numel(x) == 1
                onlyValidIndex = find(mask);
                if onlyValidIndex == 1
                    x = [];
                    y = [];
                else
                    x = [z(onlyValidIndex - 1), x];
                    y = [0, y];
                end
            end
            
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

