classdef ForceDistanceCurveAnalysisManager < handle
    properties
        baselineDetector = [];
        contactDetector = [];
        stepsAnalyzer = [];
        dataAdjuster = [];
        smoothingAdjuster = [];
    end
    
    methods
        function this = ForceDistanceCurveAnalysisManager(...
                baselineDetector, contactDetector, stepsAnalyzer, dataAdjuster, smoothingAdjuster)
            this.baselineDetector = baselineDetector;
            this.contactDetector = contactDetector;
            this.stepsAnalyzer = stepsAnalyzer;
            
            if exist('dataAdjuster', 'var')
                this.dataAdjuster = dataAdjuster;
            end
            if exist('smoothingAdjuster', 'var')
                this.smoothingAdjuster = smoothingAdjuster;
            end
        end
        
        function [frc, dist, stepHeight, stepDistance, stepStiffness, moreInfo] = analyze(this, curve, segmentId)
            segment = curve.getSegment(segmentId);
            
            % Get segment data
            frc = [segment.force];
            dist = [segment.distance];
            
            % Adjust data OOM
            if ~isempty(this.dataAdjuster)
                [dist, frc] = this.dataAdjuster.adjust(dist, frc);
            end
            
            % Smooth signal
            frc = this.smoothCurve(frc, dist);
            
            % Find baseline
            [bsl, frc, noiseAmp, bslCoeff, ~, bslAvgStd] = this.findBaseline(dist, frc);
            bslStd = bslAvgStd{2};
            
            % Find contact point
            [contact, dist, contactCoeff, ~, contactAvgStd] = this.findContactPoint(dist, frc, bslCoeff);
            
            % Adjust curve to baseline & contact
            if this.baselineDetector.isBaselineTilted
                frc = frc - polyval(bslCoeff, dist);
            else
                frc = frc - bsl;
            end
            dist = dist - contact;
            
            % Detect, Analyze and Filter all rupture events
            [stepHeight, stepDistance, stepStiffness, stepsSupplementaryData] = ...
                this.stepsAnalyzer.analyze(frc, dist, noiseAmp);
            
            % return the extra stuff not really needed outside for debug
            moreInfo.steps = stepsSupplementaryData.steps;
            moreInfo.stepsSlopeFittingData = stepsSupplementaryData.slopeFitting;
            moreInfo.unfilteredSteps = stepsSupplementaryData.unfilteredSteps;
            moreInfo.derivative = stepsSupplementaryData.derivative;
            moreInfo.noiseAmp = noiseAmp;
            moreInfo.baseline = struct(...
                'coeff', bslCoeff, ...
                'pos', bsl, ...
                'avg', bslAvgStd{1}, ...
                'std', bslStd);
            moreInfo.contact = struct(...
                'coeff', contactCoeff,...
                'pos', contact,...
                'avg', contactAvgStd{1},...
                'std', contactAvgStd{2});
        end
        
        function smoothed = smoothCurve(this, f, z)
            if ~isempty(this.smoothingAdjuster)
                [~, smoothed] = this.smoothingAdjuster.adjust(z, f);
            else
                smoothed = f;
            end
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu] = findBaseline(this, x, y)
        % Finds the baseline of the curve
        % Returns:
        %   baseline - the numeric value of the baseline
        %   coefficients - the coefficients of the baseline polynomial fit
        %   s - standard error values
        %   mu - [avg, std]
            [baseline, y, noiseAmp, coefficients, s, mu] = this.baselineDetector.detect(x, y);
        end
        
        function [contact, x, coefficients, s, mu] = findContactPoint(this, x, y, baseline)
        % Find the contact point of the curve by finding the point of
        % contact between the baseline and the contact linear extrapolation
        % Returns:
        %   contact - the numeric value of the surface contact point
        %   x - the x varriable, after adjustment if any was done
        %   coefficients - the coefficients of the contact force polynomial fit
        %   s - standard error values
        %   mu - [avg, std]
            [contact, x, coefficients, s, mu] = this.contactDetector.detect(x, y, baseline);
        end
    end
end

