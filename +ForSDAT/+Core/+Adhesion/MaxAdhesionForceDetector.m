classdef MaxAdhesionForceDetector < ForSDAT.Core.Base.ISectionDetector
    methods        
        function [adhesion, pos] = detect(this, z, f, noiseAmp, ruptureDistance)
            mask = this.getBoundsMask(z, f, ruptureDistance);
            
            [adhesion, idx] = max(-f(mask));
            
            if adhesion < noiseAmp
                adhesion = 0;
                pos = [];
            else
                pos = z(idx + find(mask, 1, 'first'));
            end
        end
    end
end

