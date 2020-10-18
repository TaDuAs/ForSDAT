classdef NoiseOffsetLoadingDomainDetector < handle
    % This class detects the loading domain for each rupture event
    % by mapping the segments bellow the specified baseline offset factor
    % and then fine-tuning by mapping the domains bellow the noise amplitude
    
    properties
        noiseAnomallySpecs = [];
    end
    
    methods
        function this = NoiseOffsetLoadingDomainDetector()
        end
        
        function init(this, settings)
            this.noiseAnomallySpecs = settings.NoiseAnomally;
        end
        
        function startAt = detect(this, x, y, ruptures, contactPoint, offsetFactor, noiseAmp)
            [~, n] = size(ruptures);
            startAt = zeros(1, n);
            prevEventEnd = contactPoint;
            
            for i = 1:n
                currEventStart = ruptures(1, i);
                
                %----------------------------------------------------------
                % Find the last index were the measured force was below the
                % baseline offset factor
                lastIndexBelowOffsetFactor = find(abs(y(prevEventEnd:currEventStart)) <= offsetFactor, 1, 'last' ) + prevEventEnd - 1;
                
                %----------------------------------------------------------
                % Now find the last index prior to the "lastBslContact" in
                % which the measured force surpassed the baseline offset
                % factor if no such index exists, take the index were the
                % previous rupture event ended. IGNORE NOISE ANOMALLIES
                shouldGoOnFineTuning = true;
                frontBoundary = lastIndexBelowOffsetFactor;
                firstBslContact = lastIndexBelowOffsetFactor;
                
                pj = [];
                pk = [];
                while shouldGoOnFineTuning
                    lastIndexAboveOffsetFactor = find(abs(y(prevEventEnd:frontBoundary)) > offsetFactor+2*noiseAmp, 1, 'last') + prevEventEnd - 1;
                    
                    if isempty(lastIndexAboveOffsetFactor)
                        lastIndexAboveOffsetFactor = prevEventEnd;
                        if isempty(firstBslContact)
                            firstBslContact = prevEventEnd;
                        end
                    else
                        firstBslContact = lastIndexAboveOffsetFactor + 1;
                    end
                    
                    for j = lastIndexAboveOffsetFactor:lastIndexBelowOffsetFactor
                        if y(j) >= -offsetFactor
                            break;
                        end
                    end
                    
                    if lastIndexAboveOffsetFactor == prevEventEnd
                        % New baseline contact point will be used in case
                        % the previously detected one makes this rupture a
                        % noise anomally, or if the measured force is lower
                        % or equal to the previously found point
                        if ~isempty(j) && firstBslContact > j && y(j) >= -offsetFactor && ...
                           (y(j) <= y(firstBslContact) || (currEventStart - firstBslContact) < this.noiseAnomallySpecs.DataPoints)
                            firstBslContact = j;
                        end
                    
                        break;
                    end
                    
                    % determine if current "peak" is a noise anomally
                    for k = fliplr(prevEventEnd:lastIndexAboveOffsetFactor)
                        if y(k) >= -offsetFactor
                            break;
                        end
                    end
                    
                    % The bsl contact would be the first time the force is 
                    % above the baseline offset factor in the range between 
                    % the detected "peak" and the rupture
                    firstBslContact = j;
                    
                    if (j - k) > this.noiseAnomallySpecs.DataPoints
                        % If this "peak" is not a noise anomally, stop
                        % iterating and continue to fine tuning
                        break;
                    else
                        % if this "peak" is a noise anomally, skip it and
                        % go on to find the next time that the force is
                        % below the baseline offset factor, if it exists
                        frontBoundary = k;
                    end

                    % ************** Endless Loop Bug Fix *****************
                    % This patch prevents the wierd occasional endless loop
                    % caused when for some reason j and k don't change in
                    % the iteration. If J and K both keep their value over
                    % two iterations, stop iterating.
                    jChanged = true;
                    if ~isempty(pj) && pj == j
                        jChanged = false;
                    else
                        pj = j;
                    end
                    kChanged = true;
                    if ~isempty(pk) && pk == k
                        kChanged = false;
                    else
                        pk = k;
                    end
                    shouldGoOnFineTuning = shouldGoOnFineTuning && (jChanged || kChanged);
                end

                %----------------------------------------------------------
                % Now fine-tune to check if the measured force went bellow
                % noise level, taking into account only the last segment of
                % the "offset-baseline" were the measeured force
                % actually reached the baseline.

                % find domains around baseline values
                fineTune = find(abs(y(lastIndexAboveOffsetFactor:lastIndexBelowOffsetFactor)) <= noiseAmp) + lastIndexAboveOffsetFactor - 1;

                % find separaions between these domains, and only take the
                % last one
                dFineTune = diff(fineTune);
                lastSegmentBelowNoiseAmp = fineTune(find(dFineTune > this.noiseAnomallySpecs.DataPoints, 1, 'last') + 1);
                if ~isempty(lastSegmentBelowNoiseAmp)
                    firstBslContact = lastSegmentBelowNoiseAmp;
                elseif ~isempty(fineTune)
                    firstBslContact = fineTune(1);
                end
                
                %----------------------------------------------------------
                % 
                startAt(i) = firstBslContact;
                prevEventEnd = ruptures(2, i);
            end
        end
    end
    
end

