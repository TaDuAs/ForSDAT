classdef SingleInteractionStepPicker < handle
    %
    
    properties
        startAt;
        endAt;
    end
    
    methods
        function this = SingleInteractionStepPicker(range, rangeError, moleculeLength)
            if length(range) == 1
                % linker length
                this.startAt = range - rangeError;
                this.endAt = range + rangeError + moleculeLength;
            elseif length(range) == 2
                % interaction distance bounds
                this.startAt = range(1);
                this.endAt = range(2);
            else
                % all range
                this.startAt = 0;
                this.endAt = -1;
            end
        end
        
        function steps = filterSteps(this, frc, dist, steps, noiseAmp)
            relevantSteps = Simple.List(size(steps,2), zeros(size(steps,1),1));

            for i = 1:size(steps,2)
                prevStep = [];
                if (i > 1)
                    prevStep = steps(:,i-1);
                end
                
                % Validate current step
                if this.validateSingleStep(frc, dist, steps(:,i), i, prevStep, noiseAmp)
                    relevantSteps.add(steps(:,i));
                end
            end

            steps = relevantSteps.vector;
        end
        
        function stopIteration = shouldStopIteration(...
                this, frc, dist, step, stepIndex, prevStep, lastBslContact, noiseAmp)
            stepDist = dist(step(1));
            if stepDist > this.endAt
                stopIteration = true;
            else
                stopIteration = false;
            end
        end
        
        function [valid, stopIteration] = validateSingleStep(...
                this, frc, dist, step, stepIndex, prevStep, lastBslContact, noiseAmp)
            stopIteration = false;
            contactPoint = find(dist <= 0, 1, 'last');
            if isempty(prevStep)
                if isempty(contactPoint)
                    valid = false;
                    return;
                end
                prevStep = [1 contactPoint];
            end
            
            stepStart = step(1);
            stepEnd = step(2);
            prevStepEnd = prevStep(2);

            % ignore steps outside the interaction range
            stepDist = dist(stepStart);
            if stepDist < this.startAt
                % before the interaction range, continue to next step
                valid = false;
                return;
            elseif this.endAt > -1 && stepDist > this.endAt
                % after the interaction range, stop iterating
                valid = false;
                stopIteration = true;
                return;
            end

            % ignore steps that end below the noise domain
            % bsl-noiseAmp < Noise Domain < bsl+noiseAmp, were bsl=0
            stepForceEnd = frc(stepEnd);
            if stepForceEnd < -noiseAmp
                valid = false;
                return;
            end
            
            % Handle a rare case where there is no non-specific interaction
            if prevStepEnd == contactPoint
                % First step may or may not be a non-specific interaction
                df = diff(frc(1:stepStart)) ;
                df2 = diff(df);
                inflection = find(df2 == 0, 1, 'last');

                % if there is an inflection point between the step and
                % the contact point and the inflection is located in
                % the noise domain, then this is a solid specific
                % interaction. otherwise, it must be disregarded for
                % being a non-specific interaction
                if isempty(inflection) || ...
                   inflection <= prevStepEnd || ...
                   abs(frc(inflection)) > noiseAmp
                    valid = false;
                    return;
                end
            elseif isempty(lastBslContact) || lastBslContact < prevStepEnd
                % if the last step didn't reach the noise domain -
                % ignore current step
                valid = false;
                return;
            end

            % if we made it this far, guess this step is genuine
            valid = true;
        end
        
        function [steps, slopeFitting] = filterFinalSteps(~, steps, slopeFitting)
        % Only take the last relevant step as this is a single molecule
        % interaction
            steps = steps(:, size(steps,2));
            slopeFitting = slopeFitting(:, size(slopeFitting,2));
        end
    end
    
end

