classdef RelevantStepsAnalyzer < handle
    % RelevantStepsAnalyzer detects, analyzes and filters out irrelevant
    % rupture events in a force distance curve
    
    properties
        baselineDetector = [];
        stepsFilter = [];
        stepDetectionSettings = [];
        stepFilteringSettings = [];
        loadFitter = [];
    end
    
    methods
        function this = RelevantStepsAnalyzer(baselineDetector, loadFitter, stepsFilter, stepDetectionSettings, stepFilteringSettings)
            this.baselineDetector = baselineDetector;
            this.loadFitter = loadFitter;
            
            if exist('stepsFilter', 'var')
                this.stepsFilter = stepsFilter;
            end
            
            if exist('stepDetectionSettings', 'var')
                this.stepDetectionSettings = stepDetectionSettings;
            end
            
            if exist('stepFilteringSettings', 'var')
                this.stepFilteringSettings = stepFilteringSettings;
            end
        end
        
        function [stepHeight, stepDist, stepStiffness, supplementaryData] =...
            analyze(this, frc, dist, noiseAmp)
        % Detects rupture events and analyzes them, while filtering out
        % irrelevant steps, according to noise, slope, and provided filter
        % Returns:
        %   stepHeight: The calculated force of all the relevant steps
        %   stepDist: The distance at which the rupture occured for all
        %             relevant steps
        %   stepStiffness: The calculated stiffness (step slope) of each
        %                  relevant step
        %   steps: [step_start_indices; step_end_indices] matrix
        %   supplementaryData: Contains extra data about the detection and
        %                      fitting opperations
        
            [steps, derivative] = this.detectRuptureEvents(frc, dist);
            
            % Keep for supplementary data
            supplementaryData.unfilteredSteps = steps;
            supplementaryData.derivative = derivative;
            
            % Analyze all rupture events
            [stepHeight, stepDist, stepStiffness, steps, stepSlopeFitting] = ...
                this.analyzeAndFilterSteps(frc, dist, steps, noiseAmp);
            
            % Keep for supplementary 
            supplementaryData.steps = steps;
            supplementaryData.slopeFitting = stepSlopeFitting;
        end
    end
    
    methods (Access = private)
        
        function [steps, derivative] = detectRuptureEvents(this, frc, dist)
        % Detects all interaction rupture events in the curve using wavelet
        % transformation and focuses them on the force distance curve.
        % Returns:
        %   rupture event indices
        %   wavelet transform data
        
            deltaF = [diff(frc) 0];
            deltaF(end) = deltaF(end - 1);
            deltaD = [diff(dist), 0];
            deltaD(end) = deltaD(end - 1);
            df = deltaF./deltaD;
            derivative = df;
            
            % find steps
            [~, ~, dfNoiseAmp, ~, ~, ~] = this.baselineDetector.detect(dist, df);
            [~, stepIndices] = findpeaks(df, 'MinPeakHeight', dfNoiseAmp);
            indicesNumber = length(stepIndices);
            steps = zeros(2, indicesNumber);
            
            % find step boundaries
            for i = 1 : indicesNumber
                % find step start
                stepStart = this.findStepBoundary(df, stepIndices(i), Direction.Backward);
                
                % find step end
                stepEnd = this.findStepBoundary(df, stepIndices(i), Direction.Forward);
                
                steps(:,i) = [stepStart;stepEnd];
            end
            
            % Unique list...
            steps = unique(steps', 'rows', 'stable')';
        end
        
        function index = findStepBoundary(this, df, startAt, dir)
            % Step slope angle should be 90 degrees, but will always deviate.
            % this is the maximum deviation of step angle from 90 deg, in radians
            stepSlopeRange = deg2rad(mvvm.getobj(this.stepDetectionSettings, 'stepSlopeDeviation', 10));
            
            index = startAt;
            nextIndex = startAt;
            endAt = dir.lastPosition(df);
            rightAngle = pi()/2;
            
            while nextIndex ~= endAt &&...
                  rightAngle - util.slope2angle(df(nextIndex)) <= stepSlopeRange
                index = nextIndex;
                nextIndex = nextIndex + dir;
            end
            
            % Fixes the iteration bug caused by the fact that the
            % slope is calculated between two fields and not in a specific
            % position
            if dir == Direction.Forward
                index = nextIndex;
            end
        end
        
        function [stepHeight, stepDist, stepSlope, steps, slopeFitting] =...
            analyzeAndFilterSteps(this, frc, dist, steps, noiseAmp)
        % Analyzes interaction rupture events. Finds the relevant rupture
        % events and calculates their force.
        % Returns:
        %   Rupture force
        %   Rupture distance
        
            stepHeight = [];
            stepDist = [];
            stepSlope = [];
            interactions = Simple.List(length(steps), [0;0;0]);
            contactPoint = find(dist <= 0, 1, 'last');
            prevStep = [1 contactPoint];
            prevStepEnd = contactPoint;
            slopeFitting = Simple.List(length(steps), struct('model',[],'s',[],'mu',[],'range',[]));
            minimalStepSlopeFittingPoints = 10;
            
            for i = 1:size(steps,2)
                currStep = steps(:,i);
                currStepForce = abs(frc(currStep(1)) - frc(currStep(2)));
                
                % Find the index of the last force measured in the noise
                % domain - "Basline Contact"
                lastBslContact = find(abs(frc(prevStepEnd:currStep(1))) <= noiseAmp, 1, 'last' ) + prevStepEnd;
                
                % Determine if should continue iteration
                if ~isempty(this.stepsFilter) &&...
                   this.stepsFilter.shouldStopIteration(frc, dist, currStep, i, prevStep, lastBslContact, noiseAmp)
                    break;
                end
                
                % Remove all steps which are on the oom of the noise domain
                if currStepForce <= 2*noiseAmp
                    % DONT SET PREVIOUS STEP TO CURRENT STEP!
                    % This step is considered noise and shouldn't affect 
                    % the next step's analyzis in any way!
                    continue;
                end

                % Remove all steps in the contact domain
                if dist(currStep(1)) <= 0
                    % DONT SET PREVIOUS STEP TO CURRENT STEP!
                    % This step is considered noise and shouldn't affect 
                    % the next step's analyzis in any way!
                    continue;
                end

                % Detect noise anomalies
                if ~isempty(lastBslContact) &&...
                   (currStep(1) - lastBslContact) <= minimalStepSlopeFittingPoints
                    % DONT SET PREVIOUS STEP TO CURRENT STEP!
                    % This step is considered noise and shouldn't affect 
                    % the next step's analyzis in any way!
                    continue;
                end

                % Fit stiffnes\loading rate
                startSlopeFitting = prevStepEnd;%max([lastBslContact, prevStepEnd]);
                if (currStep(1) - startSlopeFitting >= minimalStepSlopeFittingPoints)
                    % Get the fit function to the current step's force
                    % loading domain (prior to rupture)
                    try
                        [loadFunc, isLoadFitGood, loadFuncErr, loadFuncAvgStd] = this.loadFitter.fit(...
                            croparr(dist, [startSlopeFitting, currStep(1)]),...
                            croparr(frc, [startSlopeFitting, currStep(1)]));

                        % Get the slope at the rupture point
                        loadDifferentialFunc = loadFunc.derive();
                        df = loadDifferentialFunc.invoke(dist(currStep(1)));
                    catch ex
                       df = NaN;
                       isLoadFitGood = false;
                    end
%                     figure();
%                     dist2 = croparr(dist, [startSlopeFitting, currStep(1)]);
%                     plot(dist, frc,...
%                          dist2, croparr(frc, [startSlopeFitting, currStep(1)]),...
%                          dist2, loadFunc.invoke(dist2),...
%                          dist2, loadDifferentialFunc.invoke(dist2));
%                     legend('fdc', 'force trace', 'wlc fit', 'stiffness');
                else
                    df = NaN;
                    isLoadFitGood = false;
                end
                
                % Don't account for steps with a positive slope.
                % Don't account for steps where the load function at rupture is far from the actual measured value
%                 isIrelevantLoadFit = abs(loadFunc.invoke(currStep(1)) - currStepForce) > abs(currStepForce);
                if ~isLoadFitGood || isnan(df) %|| isIrelevantLoadFit
                    % Step shouldn't be accounted for, but should affect
                    % next step analyzis
                    prevStep = currStep;
                    prevStepEnd = prevStep(2);
                    continue;
                end

                % Relevant steps picking
                if ~isempty(this.stepsFilter)
                    % Validate step
                    [isValidStep, shouldBreak] = ...
                        this.stepsFilter.validateSingleStep(frc, dist, currStep, i, prevStep, lastBslContact, noiseAmp);
                    
                    if shouldBreak
                        break;
                    elseif ~isValidStep
                        % Step shouldn't be accounted for, but should affect
                        % next step analyzis
                        prevStep = currStep;
                        prevStepEnd = prevStep(2);
                        continue;
                    end
                end
                
                % If all is well keep current step and move to the next one
                prevStep = currStep;
                prevStepEnd = prevStep(2);
                interactions.add([currStep; df]);
                slopeFitting.add(...
                    struct('model', loadFunc,...
                           's', loadFuncErr,...
                           'mu', loadFuncAvgStd,...
                           'range', [startSlopeFitting currStep(1)]));
            end
            
            steps = interactions.vector;
            slopeFitting = slopeFitting.vector;
            if any(steps)
                if ~isempty(this.stepsFilter)
                    [steps, slopeFitting] = this.stepsFilter.filterFinalSteps(steps, slopeFitting);
                end
                stepDist = dist(steps(1, :));
                stepHeight = frc(steps(2, :)) - frc(steps(1, :));
                stepSlope = steps(3, :);
            end
        end
%         
%         function [stepHeight, stepDist, steps] = analyzeRupturesOld(this, frc, dist, steps, noiseAmp, options)
%         % Analyzes interaction rupture events. Finds the relevant rupture
%         % events and calculates their force.
%         % Returns:
%         %   Rupture force
%         %   Rupture distance
%         
%             % Remove all steps which are on the oom of the noise domain
%             steps(:, abs(frc(steps(1, :)) - frc(steps(2, :))) <= 2*noiseAmp) = 0;
%             steps = [steps(1, steps(1,:) ~= 0); steps(2, steps(2,:) ~= 0)];
% 
%             % Remove all steps in the contact domain
%             steps(dist(steps) <= 0) = 0;
%             steps = [steps(1, steps(1,:) ~= 0); steps(2, steps(2,:) ~= 0)];
% 
%             % Relevant steps picking
%             if ~isempty(this.stepsFilter)
%                 steps = this.stepsFilter.filterSteps(frc, dist, steps, noiseAmp);
%             end
% 
%             % Get step data
%             if isempty(steps)
%                 stepDist = [];
%                 stepHeight = [];
%             else
%                 stepDist = dist(steps(1,:));
%                 stepHeight = abs(frc(steps(1,:)) - frc(steps(2,:)));% - noiseAmp;
%             end
%         end
        
    end
    
end

