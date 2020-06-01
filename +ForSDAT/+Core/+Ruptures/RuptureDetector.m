classdef RuptureDetector < handle & mfc.IDescriptor
    % RelevantStepsAnalyzer detects, analyzes and filters out irrelevant
    % rupture events in a force distance curve
    
    properties
        baselineDetector = [];
        stepSlopeDeviation = deg2rad(10);
        thresholdingMethods ForSDAT.Core.Ruptures.Thresholding.IThresholdMethod = ForSDAT.Core.Ruptures.Thresholding.SizeVsNoiseMethod.empty();
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'baselineDetector', 'stepSlopeDeviation'};
            defaultValues = {...
                'baselineDetector', ForSDAT.Core.Baseline.SimpleBaselineDetector.empty(), ...
                'stepSlopeDeviation', []};
        end
    end
    
    methods
        function this = RuptureDetector(a, b, slopeDevUnits)
            if isa(a, 'RelevantStepsAnalyzer')
                this.initFromStepsAnalyzer(a);
            elseif nargin < 2
                this.initialize(a, []);
            else
                if nargin < 3
                    this.initialize(a, b, 'radians');
                else
                    this.initialize(a, b, slopeDevUnits);
                end
            end
        end
        
        function initialize(this, baselineDetector, stepSlopeDeviation, slopeDevUnits)
            this.baselineDetector = baselineDetector;
            
            if ~isempty(stepSlopeDeviation)
                if strcmp(slopeDevUnits, 'radians')
                    this.stepSlopeDeviation = stepSlopeDeviation;
                else
                    this.stepSlopeDeviation = deg2rad(stepSlopeDeviation);
                end
            end
        end
        
        function initFromStepsAnalyzer(this, stepsAnalyzer)
            this.baselineDetector = stepsAnalyzer.baselineDetector;
            
            this.stepSlopeDeviation = deg2rad(getobj(...
                stepsAnalyzer.stepDetectionSettings,...
                'stepSlopeDeviation',...
                this.stepSlopeDeviation));
        end
        
        function [steps, derivative] = analyze(this, frc, dist, noiseAmp)
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
%             
%             % Remove noise related discontinuities
%             steps = steps(:, steps(3, :) > 2*noiseAmp);
%             
%             % Remove discontinuities in the contact domain
%             steps = steps(:, dist(steps(1, :)) > 0);

            % filter out steps according to applicable thresholding methods
            trueRuptures = true(1, size(steps, 2));
            for method = this.thresholdingMethods
                trueRuptures = trueRuptures & method.apply(steps, frc, dist, noiseAmp);
            end
            steps = steps(:, trueRuptures);
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
            steps = zeros(3, indicesNumber);
            
            % find step boundaries
            for i = 1 : indicesNumber
                % find step start
                stepStart = this.findStepBoundary(df, stepIndices(i), util.Direction.Backward);
                
                % find step end
                stepEnd = this.findStepBoundary(df, stepIndices(i), util.Direction.Forward);
                
                steps(:,i) = [stepStart;stepEnd;frc(stepEnd)-frc(stepStart)];
            end
            
            % Unique list...
            steps = unique(steps', 'rows', 'stable')';
        end
        
        function index = findStepBoundary(this, df, startAt, dir)
            % Step slope angle should be 90 degrees, but will always deviate.
            % this is the maximum deviation of step angle from 90 deg, in radians
            index = startAt;
            nextIndex = startAt;
            endAt = dir.lastPosition(df);
            rightAngle = pi()/2;
            
            while nextIndex ~= endAt &&...
                  rightAngle - util.slope2angle(df(nextIndex)) <= this.stepSlopeDeviation
                index = nextIndex;
                nextIndex = nextIndex + dir;
            end
            
            % Fixes the iteration bug caused by the fact that the
            % slope is calculated between two fields and not in a specific
            % position
            if dir == util.Direction.Forward
                index = nextIndex;
            end
        end
    end
    
end

