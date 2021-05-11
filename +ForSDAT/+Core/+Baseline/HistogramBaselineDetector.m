classdef HistogramBaselineDetector < ForSDAT.Core.Baseline.BaselineDetector
    %HISTOGRAMBASELINEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        binningMethod = 'sqrt';
        minimalBins = 15;
        gaussFitOpts = struct(...
            'fitR2Threshold', 0.5,...
            'useMatlabFit', true,...
            'order', 1);
        stdScore = 2;
        isBaselineTilted = false;
        
        % setup
        speed = [];
        samplingRate = [];
        
        % data manipulations
        minimalDistance = [];
        maximalDistance = [];
    end
    
    methods
        % ctor
        function this = HistogramBaselineDetector(binningMethod, fitR2Threshold, stdScore, gaussianOrder, minimalBins)
        % HistogramBaselineDetector ctor.
        % Varriables:
        %   binningMethod - method for bins calculation\numeric bins width
        %   fitR2Threshold - Specifies the threshold for the fit R^2 for
        %                    using the fit or a simple clculation
        %   stdScore - For calculating noise amplitude
        %   gaussianOrder - How many gaussians to fit to the histogram
        %   minimalBins - No matter what binning method is set, don't use
        %                 less bins than specified here
            if exist('binningMethod', 'var') && ~isempty(binningMethod)
                this.binningMethod = binningMethod;
            end
            if exist('minimalBins', 'var') && ~isempty(minimalBins)
                this.minimalBins = minimalBins;
            end
            
            if exist('fitR2Threshold', 'var') && ~isempty(fitR2Threshold)
                this.gaussFitOpts.fitR2Threshold = fitR2Threshold;
            end
            
            if exist('stdScore', 'var') && ~isempty(stdScore)
                this.stdScore = stdScore;
            end
            
            if exist('gaussianOrder', 'var') && ~isempty(gaussianOrder)
                this.gaussFitOpts.order = gaussianOrder;
            end
        end
        
        function init(this, settings)
            this.speed = settings.Measurement.Speed;
            this.samplingRate = settings.Measurement.SamplingRate;
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu] = detect(this, x, y)
        % Finds the baseline of the curve
        % Returns:
        %   baseline - the numeric value of the baseline
        %   noiseAmp - the evaluated amplitude of noise oscilations
        %   y - the force vector. unchanged by this method
        %   coefficients - the coefficients of the baseline polynomial fit
        %   s - standard error values
        %   mu - [avg, std]
        
            histModel = this.prepModel();
            
            useHistModeling = true;
            
            % handle tilted baseline
            if this.isBaselineTilted
                % if we are using > 1 gaussian series model, we should fit
                % the model to the histogram after subtracting the tilted
                % baseline
                useHistModeling = histModel.Order > 1;
                
                % use force plateau to extract tilted baseline
                [baseline, y, coefficients, stdev] = this.histPlateauLinFit(x, y);
            end
            
            % use gaussian fit to extract baseline
            if useHistModeling
                [~, yCropped] = this.cropData(x, y);
                statData = histool.stats(yCropped, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins, 'Model', histModel);

                % get distribution data from object
                baseline = statData.MPV;
                stdev = statData.StandardDeviation;
                amplitude = this.calcNormAmp(statData);

                % if the gaussian order is greater than 1 decide which gaussian
                % provides the best estimate for the baseline
                [baseline, ~, stdev] = this.getMostLikelyBaselineEstimation(y, baseline, amplitude, stdev);
                
                % this is a 0th order polynomial
                coefficients = baseline;
            end
            
            s = [];
            mu = {baseline, stdev};
            noiseAmp = this.stdScore * stdev;
        end
        
        function [h1, bins, freq, fitOutput] = plotHistogram(this, x, y)
            
            [~, yCropped] = this.cropData(x, y);
            histModel = this.prepModel();
            [statData, h] = histool.histdist(yCropped, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins, 'Model', histModel);
            
            h1 = h(1);
            bins = statData.BinEdges;
            freq = statData.Frequencies;
            
            % get distribution data from object
            baseline = statData.MPV;
            stdev = statData.StandardDeviation;
            amplitude = this.calcNormAmp(statData);
            goodness = statData.GoodnessOfFit;
            
            % if the gaussian order is greater than 1 decide which gaussian
            % provides the best estimate for the baseline
            [baseline, amplitude, stdev] = this.getMostLikelyBaselineEstimation(y, baseline, amplitude, stdev);
            
            hold on;
            
            % plot the baseline estimation
            plot(baseline, amplitudeForDisplay, 'rv', 'MarkerFaceColor', 'r');
            
            % prepare legends
            legendText = cell(1, this.gaussFitOpts.order + 2);
            legendText{1} = 'Force Histogram';
            for i = 1:this.gaussFitOpts.order
                legendText{i + 1} = ['Gaussian Fit #' num2str(i)];
            end
            legendText{end} = 'Most Prevalent Value - Baseline Evaluation';
            legend(legendText);
            hold off;
            
            if nargout >= 4
                fitOutput =[];
                fitOutput.baseline = baseline;
                fitOutput.stdev = stdev;
                fitOutput.amplitude = amplitude;
                fitOutput.goodness = goodness;
            end
        end
        
        function histModel = prepModel(this)
            gaussOrder = mvvm.getobj(this.gaussFitOpts, 'order', 1, 'nowarn');
            fitThreshold = mvvm.getobj(this.gaussFitOpts, 'fitR2Threshold', 0.5, 'nowarn');
            histModel = histool.fit.MultiModalGaussFitter('Order', gaussOrder, 'PlanBGoodnessThreshold', fitThreshold);
        end
        
        function amplitude = calcNormAmp(~, statData)
            % calculate normalized amplitudes
            pdfoo = statData.PDF{1};
            amplitude = pdfoo(statData.MPV);
            amplitude = amplitude / max(statData.Frequencies);
        end
        
        function [baseline, amplitude, stdev] = getMostLikelyBaselineEstimation(this, y, baseline, amplitude, stdev)
            
            if this.gaussFitOpts.order > 1
                % Solve the weird bug where the gaussians go berserk with
                % peaks outside the range, when that happens, flatten that
                % gaussian, which in practice is the equivalent of deleting
                % it
                amplitude(baseline < min(y) | baseline > max(y)) = 0;
                
                baselineGaussAmplitudeThreshold = baseline(amplitude >= 0.2 * max(amplitude));
                baselineGaussianIndex = find(baseline == max(baselineGaussAmplitudeThreshold));
                
                % for some reason, it could happen that all estimations are
                % identical. In that case, they will all pass the previous
                % step, resulting in multiple baselines which all have the
                % same value, this breaks the next steps though, so just
                % pick the first one, there should be only one either way
                %
                % like highlanders, there can be only one baseline
                %
                baseline = baseline(baselineGaussianIndex(1));
                stdev = stdev(baselineGaussianIndex(1));
            end
            
        end
        
        function [baseline, yOut, coefficients, sig] = histPlateauLinFit(this, x, y)
            % prepare histogram data
            [xCropped, yCropped] = this.cropData(x, y);
            statData = histool.stats(yCropped, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins);

            % find plateau
            avgFreq = mean(statData.Frequencies);
            stdFreq = std(statData.Frequencies);
            plateauThreshold = avgFreq + 1*stdFreq;
            
            % find the frequencies and force values in the plateau
            freqPlateau = statData.Frequencies(statData.Frequencies > plateauThreshold);
            forcePlateau = statData.BinEdges(statData.Frequencies > plateauThreshold);
            
            % prepare mask of the data that corresponds to the plateau
            plateauMask = yCropped >= min(forcePlateau) & yCropped <= max(forcePlateau);

            % backcalculate the expected distance vector which corresponds
            % to the sampled force values according to the scanner speed
            % and sampling rate under the assumption of constant scanner
            % speed and under the assumptions that the contribution of 
            % anything other than the baseline/force plateaus is minimal
            % also assume the slope is approximately uniform
            dx = this.speed*(freqPlateau/this.samplingRate);
            dy_dx = diff(forcePlateau)./dx(2:end);
            
            % start by estimating the baeline shift by the mean value of
            % the plateau
            baseline = mean(forcePlateau);
            slope = mean(dy_dx);

            % estimate tilted baseline with either positive or negative
            % slope for the plateau corresponding regions
            xPlateauRegion = xCropped(plateauMask);
            yPlateauRegion = yCropped(plateauMask);
            minX = xPlateauRegion(1);
            yTiltPos = (xPlateauRegion-minX)*slope + baseline;
            yTiltNeg = -(xPlateauRegion-minX)*slope + baseline;
            
            % calculate the residuals for both positive and negative 
            % baseline slopes
            posResiduals = yPlateauRegion - yTiltPos;
            negResiduals = yPlateauRegion - yTiltNeg;

            % determine the better fit according to the residuals RMS
            if rms(negResiduals) < rms(posResiduals)
                slope = -slope;
                
                % subtract the tilted baseline from the force data
                tiltedBaselineComplete = -(x-x(1))*slope + baseline;
                
                % calculate noise amplitude from the standard deviation of
                % the residuals
                realResiduals = negResiduals;
            else
                % subtract the tilted baseline from the force data
                tiltedBaselineComplete = (x-x(1))*slope + baseline;
                
                % calculate noise amplitude from the standard deviation of
                % the residuals
                realResiduals = posResiduals;
            end
            
            % return values
            yOut = y - tiltedBaselineComplete;
            sig = std(realResiduals);
            coefficients = [slope, baseline];
        end
    end
    
    methods (Access=private)
        function [x, y] = cropData(this, x, y)
            mask = [];
            if ~isempty(this.minimalDistance)
                mask = x >= this.minimalDistance;
            end
            if ~isempty(this.maximalDistance)
                mask2 = x <= this.maximalDistance;
                
                if isempty(mask)
                    mask = mask2;
                else
                    mask = mask & mask2;
                end
            end
            
            if ~isempty(mask)
                x = x(mask);
                y = y(mask);
            end
        end
    end
    
end

