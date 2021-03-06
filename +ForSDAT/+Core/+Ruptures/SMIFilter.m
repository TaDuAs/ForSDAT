classdef (Abstract) SMIFilter < handle
    
    properties
        angleDefiningSeparationFromContactDomain = 45;
        filterType char {mustBeMember(filterType, {'all', 'last'})} = 'last';
    end
    
    methods
        function this = SMIFilter(angleDefiningSeparationFromContactDomain, filterType)
            if nargin >= 1 && ~isempty(angleDefiningSeparationFromContactDomain)
                this.angleDefiningSeparationFromContactDomain = angleDefiningSeparationFromContactDomain;
            end
            
            if nargin >= 2 && ~isempty(filterType)
                this.filterType = filterType;
            end
        end
    end
    
    methods (Access=protected)
        
        function flaggedRuptureEvents = setBasicFilters(this, frc, dist, ruptureEvents, prefilteredRuptures, noiseAmplitude, chainFitFunctions, modeledRuptureForce, contactDomainSlope)
            % add validity flag
            flaggedRuptureEvents = [ruptureEvents; ones(1, size(ruptureEvents, 2))];
 
            % meaning its not equal to [] (which is a signal for theres no pre-filter)
            if size(prefilteredRuptures, 1) > 0 
                if isempty(prefilteredRuptures)
                    i = 1;
                    flaggedRuptureEvents(end, :) = 0;
                else
                    if strcmp(this.filterType, 'last')
                        % only the last interaction in the prefiltered ruptures
                        [lastRupture, i] = max(prefilteredRuptures(2,:));
                        flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & flaggedRuptureEvents(2, :) == lastRupture;
                    end
                end
            elseif strcmp(this.filterType, 'last')
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
                
                v1 = [1, contactDomainSlope];
                v2 = [1, slope];
                
                % ignore vector directions, calculate relative angle
                % between both lines
                a1 = mod(atan2( det([v1;v2;]) , dot(v1,v2) ), pi );
                angleDiffFromContactDomain = abs((a1>pi/2)*pi-a1);
                if angleDiffFromContactDomain < deg2rad(abs(this.angleDefiningSeparationFromContactDomain))
                    flaggedRuptureEvents(end, i) = 0;
                end
                
%                 if abs(slope2angle(contactDomainSlope) - slope2angle(slope)) < deg2rad(abs(this.angleDefiningSeparationFromContactDomain))
%                     flaggedRuptureEvents(end, i) = 0;
%                 end
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

