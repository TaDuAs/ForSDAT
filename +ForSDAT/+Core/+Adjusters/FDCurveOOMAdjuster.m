classdef FDCurveOOMAdjuster < handle
    % Adjusts force-distance data to the desired OOM
    
    properties (SetObservable)
        FOOM;
        ZOOM;
    end
    
    methods
        function name = name(this)
            name = 'OOM Adjuster';
        end
        
        function this = FDCurveOOMAdjuster(FOOM, ZOOM)
            if nargin >= 1
                this.FOOM = FOOM;
            end
            if nargin >= 2
                this.ZOOM = ZOOM;
            end
        end
        
        function [z, f] = adjust(this, z, f)
            f = f * 10^-this.FOOM;
            z = z * 10^-this.ZOOM;
        end
        
        function init(this, settings)
            this.FOOM = mvvm.getobj(settings, 'FOOM', this.FOOM);
            this.ZOOM = mvvm.getobj(settings, 'ZOOM', this.ZOOM);
        end
    end
    
end

