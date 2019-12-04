classdef (Abstract) SMIFilter < handle
    
    properties
        angleDefiningSeparationFromContactDomain = 35;
    end
    
    methods
        function this = SMIFilter(angleDefiningSeparationFromContactDomain)
            if exist('angleDefiningSeparationFromContactDomain', 'var') && ~isempty(angleDefiningSeparationFromContactDomain)
                this.angleDefiningSeparationFromContactDomain = angleDefiningSeparationFromContactDomain;
            end
        end
    end
    
    methods (Access=protected)
        
        function flaggedRuptureEvents = setBasicFilters(this, frc, dist, ruptureEvents, prefilteredRuptures, noiseAmplitude, chainFitFunctions, modeledRuptureForce, contactDomainSlope)
            import Simple.Math.*;
            % add validity flag
            flaggedRuptureEvents = [ruptureEvents; ones(1, size(ruptureEvents, 2))];
 
            % meaning its not equal to [] (which is a signal for theres no pre-filter)
            if size(prefilteredRuptures, 1) > 0 
                % only the last interaction in the prefiltered ruptures
                if isempty(prefilteredRuptures)
                    i = 1;
                    flaggedRuptureEvents(end, :) = 0;
                else
                    [lastRupture, i] = max(prefilteredRuptures(2,:));
                    flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & flaggedRuptureEvents(2, :) == lastRupture;
                end
            else
                % only the last interaction
                [lastRupture, i] = max(flaggedRuptureEvents(2, :));
                flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & flaggedRuptureEvents(2,:) == lastRupture;
            end
            
            % keep only rupture forces with a "good" model (force higher
            % than noise)
            flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & modeledRuptureForce >= 2*noiseAmplitude;
            
            % in case there is only one interaction inside the linker
            % window, check the slope at the beginning of the interaction
            % loading domain. If it differs significantly from the contact
            % domain slope, we can determine it to be distinctly separate
            % from the contact domain, and thus a specific interaction.
            if size(flaggedRuptureEvents, 2) > 0 && flaggedRuptureEvents(end, i) && flaggedRuptureEvents(4, i) == 1
                func = chainFitFunctions(i);
                slope = func.derive().invoke(0);%dist(ruptureEvents(1, 1)));
                
                if abs(slope2angle(contactDomainSlope) - slope2angle(slope)) < deg2rad(abs(this.angleDefiningSeparationFromContactDomain))
                    flaggedRuptureEvents(end, i) = 0;
                end
            end
        end
        
        function [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = filterFlags(this, flaggedRuptureEvents)
            % Only keep the last flagged interaction
%             [~, i] = sortrows(flaggedRuptureEvents', [-4, -2]);
%             if isempty(i) || (flaggedRuptureEvents(4, i(1)) == 0)
%                 indexOfSpecificInteractionInRuptureEventsMatrix = [];
%                 lsRsRe = [];
%             else
%                 indexOfSpecificInteractionInRuptureEventsMatrix = i(1);
%                 lsRsRe = flaggedRuptureEvents(1:3, i(1));
%             end


            [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ForSDAT.Core.Ruptures.filterFlagsMatrix(flaggedRuptureEvents, 5, -2);
            lsRsRe(4,:) = [];
        end
    end
end

