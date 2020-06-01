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
            statData = histool.stats(y, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins, 'Model', histModel);
            
            % get distribution data from object
            baseline = statData.MPV;
            stdev = statData.StandardDeviation;
            amplitude = this.calcNormAmp(statData);
            
            % if the gaussian order is greater than 1 decide which gaussian
            % provides the best estimate for the baseline
            [baseline, amplitude, stdev] = this.getMostLikelyBaselineEstimation(y, baseline, amplitude, stdev);
            
            s = [];
            mu = {baseline, stdev};
            coefficients = baseline;
            noiseAmp = this.stdScore * stdev;
        end
        
        function [h1, bins, freq, fitOutput] = plotHistogram(this, x, y)
            
            histModel = this.prepModel();
            [statData, h] = histool.histdist(y, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins, 'Model', histModel);
            
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
                baseline = baseline(baselineGaussianIndex);
                stdev = stdev(baselineGaussianIndex);
            end
            
        end
    end
    
end

