classdef BaselineThresholdSMIFilter < ForSDAT.Core.Ruptures.SMIFilter
    
    methods
        function this = BaselineThresholdSMIFilter(angleDefiningSeparationFromContactDomain)
            this@ForSDAT.Core.Ruptures.SMIFilter(angleDefiningSeparationFromContactDomain);
        end
        
        function [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ...
                filter(this, frc, dist, secDist, ruptureEvents, prefilteredRuptures, noiseAmplitude, baselineThreshold, chainFitFunctions, modeledRuptureForce, contactDomainSlope)
        % Finds the rupture event representing the specific interaction and
        % filter out the irrelevants.
        %   lsRsRe - Interaction data indices the indices of the
        %       interaction in the data vector as follows:
        %       [loading start (Ls); Rupture start (Rs); Rupture end (Re)]
        %   indexOfSpecificInteractionInRuptureEventsMatrix - The index of
        %       the specific interaction in the specified detected ruptures
        %       vector
        % ** secondary distance is not needed by this filter, its only here
        % for the unity of the API
        
            % Apply interaction window filter
            flaggedRuptureEvents = this.setBasicFilters(frc, dist, ruptureEvents, prefilteredRuptures, noiseAmplitude, chainFitFunctions, modeledRuptureForce, contactDomainSlope);
            
            % Step ends below baseline-shift factor
            flaggedRuptureEvents(4, :) = flaggedRuptureEvents(4, :) & -frc(flaggedRuptureEvents(3, :)) <= baselineThreshold;
            
            % Interaction starts loading below baseline-shift factor
            flaggedRuptureEvents(4, :) = flaggedRuptureEvents(4, :) & -frc(flaggedRuptureEvents(1, :)) <= baselineThreshold;
            
            % keep the last interaction which follows all the criteria
            [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ForSDAT.Core.Ruptures.filterFlagsMatrix(flaggedRuptureEvents, 4, -2); %this.filterflags(flaggedRuptureEvents);
            
        end
        
        function plotAnalysis(this, frc, dist, secDist, ruptureEvents, filteredRuptures, noiseAmplitude, baselineThreshold, chainFitFunctions, contactDomainSlope)
            plot(dist, zeros(1, length(x)) -baselineThreshold, 'r');
        end
    end
    
end

