classdef SmoothingSMIFilter < ForSDAT.Core.Ruptures.SMIFilter & mfc.IDescriptor
    
    properties
        baselineDetector;
        smoothingAdjuster;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'baselineDetector', 'smoothingAdjuster', 'angleDefiningSeparationFromContactDomain', 'filterType'};
            defaultValues = {...
                'baselineDetector', ForSDAT.Core.Baseline.SimpleBaselineDetector.empty(), ...
                'smoothingAdjuster', ForSDAT.Core.Adjusters.DataSmoothingAdjuster.empty(),...
                'angleDefiningSeparationFromContactDomain', [],...
                'filterType', []};
        end
    end
    
    methods
        
        function this = SmoothingSMIFilter(baselineDetector, smoothingAdjuster, angleDefiningSeparationFromContactDomain, filterType)
            this@ForSDAT.Core.Ruptures.SMIFilter(angleDefiningSeparationFromContactDomain, filterType);
            
            this.baselineDetector = baselineDetector;
            this.smoothingAdjuster = smoothingAdjuster;
        end
        
        function [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ...
                filter(this, frc, dist, secDist, ruptureEvents, prefilteredRuptures,...
                noiseAmplitude, baselineThreshold, chainFitFunctions, modeledRuptureForce, contactDomainSlope)
        % Finds the rupture event representing the specific interaction and
        % filter out the irrelevants.
        % Filtering is performed by applying a strong smoothing to the
        % force data, then affiliating each rupture event to a specific
        % smoothed-data-force-peak.
        % A rupture event may only be considered a specific interaction if
        % no other rupture events are affiliated to the same smoothed-peak.
        %   lsRsRe - Interaction data indices the indices of the
        %       interaction in the data vector as follows:
        %       [loading start (Ls); Rupture start (Rs); Rupture end (Re)]
        %   indexOfSpecificInteractionInRuptureEventsMatrix - The index of
        %       the specific interaction in the specified detected ruptures
        %       vector
    
            % Apply interaction window filter
            flaggedRuptureEvents = this.setBasicFilters(frc, dist, ruptureEvents, prefilteredRuptures, noiseAmplitude, chainFitFunctions, modeledRuptureForce, contactDomainSlope);

            % Affiliate each rupture events to the relevant smoothed peak
            % Secondary distance is used only for the smoothing, why? cause
            % it doesn't handle the wierd tilting in "fixed" curve distance
            % when fixing the distance with an out-dated spring constant
            [rspa, smoothedPeakLocs] = this.findRuptureEventSmoothedPeakAffiliation(frc, secDist, flaggedRuptureEvents, noiseAmplitude);
            
            % Count the number of rupture events affiliated to each smoohed peak
            ruptureEventsPerPeak = sum(bsxfun(@eq, smoothedPeakLocs, rspa'), 1);
            
            % Set the flag to false if more than one rupture event is
            % affiliated to the same smoothed peak
            flaggedRuptureEvents(end, :) = flaggedRuptureEvents(end, :) & ismember(rspa, smoothedPeakLocs(ruptureEventsPerPeak == 1));
            
            % rupture event ends in noise domain, or is the last rupture
            % event. This is crucial because if the rupture event doesn't
            % reach the noise domain, it means it is most likely
            % superpositioned with the following interactions. The last
            % rupture event however has no following interactions and
            % therefore if it does not reach the noise domain it is most
            % likely due to noise and other interference....
            flaggedRuptureEvents(end, 1:(end-1)) = flaggedRuptureEvents(end, 1:(end-1)) & -frc(flaggedRuptureEvents(3, 1:(end-1))) <= noiseAmplitude;
            
            % Keep only the last rupture which survived the filters
            [lsRsRe, indexOfSpecificInteractionInRuptureEventsMatrix] = ForSDAT.Core.Ruptures.filterFlagsMatrix(flaggedRuptureEvents, 5, -2);%this.filterFlags(flaggedRuptureEvents);
        end
        
        function plotAnalysis(this, frc, dist, secDist, ruptureEvents, filteredRuptures, noiseAmplitude, baselineThreshold, chainFitFunctions, contactDomainSlope, plotArea)            
            % Perform the smoothin using the secondary distance due to the
            % weird tilting of curves with "fixed" distance, when fixing
            % the distance with an out-dated spring constant
            [sf, ~, peakLocs, valleyLocs] = this.smoothAndFindPeaks(frc, secDist, ruptureEvents, noiseAmplitude);
            
            if any(plotArea)
                areaColors = jet(length(valleyLocs)-1);
                colorIndex = Simple.rearangeArray(fliplr(1:length(valleyLocs)-1), 'alt');
                
                % area under curve
                for i = 1:length(plotArea)
                    if plotArea(i)
                        idx = valleyLocs(i):valleyLocs(i+1);
                        area(dist(idx), frc(idx), 'LineStyle', 'none', 'FaceAlpha', 0.3, 'FaceColor', areaColors(colorIndex(i),:), 'ShowBaseLine', 'off');
                    end
                end
            end

            % Plot with distance rather than secondary distance so that the
            % peaks are correlated with the curve and the ruptures
            plot(dist, sf, 'LineStyle', '-', 'LineWidth', 1.5, 'Color', rgb('Gold'));
            plot(dist(ruptureEvents(2, :)), frc(ruptureEvents(2, :)), 'v', 'MarkerEdgeColor', rgb('Green'), 'MarkerFaceColor', rgb('Green'));
            plot(dist(valleyLocs), sf(valleyLocs), 's', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'k');
            plot(dist(peakLocs), sf(peakLocs), 'o', 'MarkerEdgeColor', rgb('Red'), 'MarkerFaceColor', rgb('Red'));
        end
    end
    
    methods (Access=public)
        function [sf, sfNoiseAmp, peakLocs, valleyLocs] = smoothAndFindPeaks(this, frc, dist, ruptureEvents, noiseAmp)
            
            % Apply mega-smoothing to force and detect the noise amplitude
            % of that
            [~, sf] = this.smoothingAdjuster.adjust(dist, frc);
            [~, ~, sfNoiseAmp, ~, ~, ~] = this.baselineDetector.detect(dist, sf);
            
            % find peaks and valleys of the super smoothed curve
            [~, peakLocs] = findpeaks(-sf, 'MinPeakHeight', sfNoiseAmp, 'MinPeakProminence', sfNoiseAmp);
            [~, valleyLocs] = findpeaks(sf, 'MinPeakProminence', sfNoiseAmp);
            
            % If the ruptures are too small or to sharp they will be
            % ignored by the smoothing method
            % To prevent the situation where there are ruptures, but no
            % smoothed peaks, a smoothed peak is artificially generated in
            % the locaiton of the biggest rupture event
            if isempty(peakLocs) && ~isempty(ruptureEvents)
                [~, biggestRupturePeakIndex] = min(frc(ruptureEvents(2,:)));
                peakLocs = ruptureEvents(2,biggestRupturePeakIndex);
            end
            
            % Add artificial valleys when ruptures end in the noise domain
            % and when ruptures start loading at the noise domain
            ruptureStarts = ruptureEvents(2,:);
            ruptureEnds = ruptureEvents(3,:);
            if any(ruptureEnds)
                lastRuptureEndsHere = ruptureEnds(end);
            else
                lastRuptureEndsHere = 1;
            end
            loadingStarts = ruptureEvents(1,:);
            ruptureEndArtificialValleys = this.generateArtificialValleys(frc, dist, valleyLocs, peakLocs, ruptureStarts, ruptureEnds(frc(ruptureEnds) >= -noiseAmp));
            loadingStartArtificialValleys = this.generateArtificialValleys(frc, dist, valleyLocs, peakLocs, ruptureStarts, loadingStarts(frc(loadingStarts) >= -noiseAmp));
            valleyLocs = unique(sort([valleyLocs, ruptureEndArtificialValleys, loadingStartArtificialValleys]));
            
            % If added new valleys, probably should complement them with
            % new peaks as well.
            % Add an artificial peak between every two valleys adjacent 
            % that are not separated by a peak
            for i = 2:length(valleyLocs)
                prevValleyLoc = valleyLocs(i-1);
                currPeakLoc = valleyLocs(i);
                
                % Stop iterating when passed the last rupture event.
                % No one cares about the peaks and valleys of the smoothed 
                % force beyond the last interaction
                if prevValleyLoc > lastRuptureEndsHere
                    break;
                end
                
                if ~any(peakLocs(peakLocs >= prevValleyLoc & peakLocs <= currPeakLoc))
                    % It't not going to reallocate this array many times
                    % and its a very small vector either way.
                    % We don't know ahead of iteration how many of these
                    % we're gonna get and a self-allocating list is an
                    % over-kill for this one.
                    % I know what I'm doing so don't worry about it.
                    % TADA.
                    [~, newPeakLoc] = min(sf(prevValleyLoc+1:currPeakLoc-1));
                    peakLocs = [peakLocs newPeakLoc + prevValleyLoc];
                end
            end
        end
        
        function artificialValleys = generateArtificialValleys(this, frc, dist, valleyLocs, peakLocs, ruptureStarts, reasonVector)
            artificialValleys = ones(1, length(reasonVector)) * -1;
            lastIndex = length(frc);
            for i = 1:length(reasonVector)
                % if there are any ruptures that start between this rupture
                % end and the next smoothed valley location
                % or if this is the before the first peak
                try
                if any(reasonVector(i) < peakLocs(1) | (ruptureStarts > reasonVector(i) & ruptureStarts < min([find(valleyLocs > reasonVector(i), 1, 'first') lastIndex])))
                    artificialValleys(i) = reasonVector(i);
                end
                catch ex
                    disp(getReport(ex));
                end
            end
            artificialValleys(artificialValleys == -1) = [];
        end
        
        function [rspa, peakLocs] = findRuptureEventSmoothedPeakAffiliation(this, frc, dist, flaggedRuptureEvents, noiseAmp)
            [~, ~, peakLocs, valleyLocs] = this.smoothAndFindPeaks(frc, dist, flaggedRuptureEvents(1:3,:), noiseAmp);
            
            % distance between each rupture and each peak
            drp = bsxfun(@minus, flaggedRuptureEvents(2,:), peakLocs');
            
            % distance between each rupture and each valley
            drv = bsxfun(@minus, flaggedRuptureEvents(2,:), valleyLocs');
            
            % Rupture-SmoothedPeak-Affiliations
            rspa = zeros(1, size(flaggedRuptureEvents, 2));

            % Didn't find a way to vectorize the whole calculation yet...
            for i = 1:size(flaggedRuptureEvents, 2)
                [~, closestPeaksIdx]  = sort(abs(drp(:, i)));
                [~, closestValleysIdx] = sort(abs(drv(:, i)));
                
                for j = 1:length(closestPeaksIdx)
                    ruptureBelongsToThisPeak = true;
                    currPeakLoc = peakLocs(closestPeaksIdx(j));
                    currPeakLocDelta = drp(closestPeaksIdx(j), i);
                    for k = 1:length(closestValleysIdx)
                        currValleyLocDelta = drv(closestValleysIdx(k), i);
                        if (currValleyLocDelta < currPeakLocDelta && currValleyLocDelta > 0) ||...
                           (currValleyLocDelta > currPeakLocDelta && currValleyLocDelta < 0)
                            % There is a valey between the rupture event and the smoothed peak.
                            % Therefore, this rupture doesn't belong to this smoothed peak.
                            % Go on to the next smoothed peak
                            ruptureBelongsToThisPeak = false;
                            break;
                        end
                    end
                    
                    % If the current rupture belongs to this smoothed peak,
                    % set Rupture-SmoothedPeak-Affiliation and stop iteration
                    if ruptureBelongsToThisPeak
                        rspa(i) = currPeakLoc;
                        break;
                    end
                end
            end
        end
    end
    
end

