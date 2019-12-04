classdef MaxAdhesionForceDetector < ForSDAT.Core.Adhesion.ISectionDetector
    methods        
        function [adhesion, pos] = detect(this, z, f, noiseAmp)
            mask = this.getLogicalIndex(z);
            
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

