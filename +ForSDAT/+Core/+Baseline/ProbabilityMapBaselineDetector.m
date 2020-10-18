classdef ProbabilityMapBaselineDetector < BaselineDetector
    %PROBABILITYMAPBASELINEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xBinningMethod = 'sqrt';
        yBinningMethod = 'sqrt';
        minimalBins = 25;
        stdScore = 0.25;
        probabilityThresholdStdScore = 0.5;
    end
    
    methods
        % ctor
        function this = ProbabilityMapBaselineDetector(xBinningMethod, yBinningMethod, probabilityThresholdStdScore, stdScore, minimalBins)
        % HistogramBaselineDetector ctor.
        % Varriables:
        %   xBinningMethod -
        %       method for x axis bins calculation\numeric bins width
        %   yBinningMethod -
        %       method for y axis bins calculation\numeric bins width
        %   probabilityThresholdStdScore -
        %       For calculating threshold of baseline related bins
        %   stdScore - For calculating noise amplitude
        %   minimalBins - No matter what binning method is set, don't use
        %                 less bins than specified here
            if exist('xBinningMethod', 'var') && ~isempty(xBinningMethod)
                this.xBinningMethod = xBinningMethod;
            end
            if exist('yBinningMethod', 'var') && ~isempty(yBinningMethod)
                this.yBinningMethod = yBinningMethod;
            else
                this.yBinningMethod = this.xBinningMethod;
            end
            if exist('minimalBins', 'var') && ~isempty(minimalBins)
                this.minimalBins = minimalBins;
            end
            if exist('stdScore', 'var') && ~isempty(stdScore)
                this.stdScore = stdScore;
            end
            if exist('probabilityThresholdStdScore', 'var') && ~isempty(probabilityThresholdStdScore)
                this.probabilityThresholdStdScore = probabilityThresholdStdScore;
            end
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu, extras] = detect(this, x, y)
        % Finds the baseline of the curve by generating a probability map
        % of the x-y values and fitting the regression line of the most
        % probable points
        % Returns:
        %   baseline - the numeric value of the baseline
        %   noiseAmp - the evaluated amplitude of noise oscilations
        %   y - the force vector. unchanged by this method
        %   coefficients - the coefficients of the baseline polynomial fit
        %   s - standard error values
        %   mu - [avg, std]
        %   extras - extra data regarding the calculation
            import util.Math.*;
            
            % generate probability map
            [xBins, ~, ~] = Histool.calcBins(x, this.xBinningMethod, this.minimalBins);
            [yBins, ~, ~] = Histool.calcBins(y, this.yBinningMethod, this.minimalBins);
            [probabilityMap, binCenters] = hist3([x' y'], 'Edges', {xBins yBins});
            
            % find most probable points
            nonZeroFrequencies = probabilityMap(probabilityMap > 0);
            avgNZF = mean(nonZeroFrequencies);
            stdNZF = std(nonZeroFrequencies);
            probabilityThreshold = avgNZF + this.probabilityThresholdStdScore*stdNZF;
            MPP = (probabilityMap > probabilityThreshold); % Most Probable Points
            
            % fit the reggression line
            [xMppIndices, yMppIndices] = ind2sub(size(probabilityMap), find(MPP));
            xValuesForFit = binCenters{1};
            yValuesForFit = binCenters{2};
            [baseline, s, ~] = Simple.Math.epolyfit(xValuesForFit(xMppIndices), yValuesForFit(yMppIndices), 1);
            coefficients = baseline;
            
            % calculate deviations
            devRMS = this.calcRMSDeviation(baseline, probabilityMap, MPP, xValuesForFit, yValuesForFit);
            
            % return values
            noiseAmp = this.stdScore*devRMS;
            mu = {baseline, devRMS};
            extras.MppIndices.x = xMppIndices;
            extras.MppIndices.y = yMppIndices;
            extras.bins.x = xBins;
            extras.bins.y = yBins;
        end
        
        function s = calcRMSDeviation(this, baseline, probabilityMap, MPP, xValues, yValues)
            % Calculates the RMS of the deviation from the baseline valule
            % only for the most probable X values (present in MPP) in order
            % to avoid calculating the deviation of peaks and contact
            % domain
            import Simple.Math.*;
            sumDevSQR = 0;
            sumFreq = 0;
            for i = 1:length(xValues)
                colMPP = MPP(i, :);

                % If for the current x value there were calculated MPP
                % values, include these values in RMS calculation
                if sum(colMPP) > 0
                    colProbMap = probabilityMap(i, :);
                    sumDevSQR = sumDevSQR + sum((abs((yValues-polyval(baseline, xValues(i))) .* colProbMap)).^2);
                    sumFreq = sumFreq + sum(colProbMap);
                end
            end
            
            s = sqrt(sumDevSQR / sumFreq);
        end
        
        function plotHistogram(this, x, y, fig1, splot1, fig2, splot2)
            
            import Simple.Math.*;
            [baseline, y, noiseAmp, coefficients, s, mu, extras] = this.detect(x, y);
            [xBins, ~, ~] = Histool.calcBins(x, this.xBinningMethod, this.minimalBins);
            [yBins, ~, ~] = Histool.calcBins(y, this.yBinningMethod, this.minimalBins);
            bins = {xBins yBins};

            if exist('fig1', 'var') && ~isempty(fig1)
                figure(fig1);
            end
            if exist('splot1', 'var') && ~isempty(splot1)
                subplot(splot1);
            end
            hist3([x' y'], 'Edges', bins);
            set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
            view(2);

            if exist('fig2', 'var') && ~isempty(fig2)
                figure(fig2);
            end
            if exist('splot2', 'var') && ~isempty(splot2)
                subplot(splot2);
            end
            if (~exist('fig2', 'var') || isempty(fig2)) && (~exist('splot2', 'var') || isempty(splot2))
                hold on;
            end

            xRegressionValues = extras.bins.x(extras.MppIndices.x);
            yRegressionValues = extras.bins.y(extras.MppIndices.y);

            hist3([xRegressionValues' yRegressionValues'], 'Edges', bins);
            set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
            hold on;


            plot3(xRegressionValues , polyval(baseline, xRegressionValues),...
                  ones(1, length(xRegressionValues)),...%zeros(1, length(xIndices))+max(probabilityMap(:)),...
                  'LineWidth', 3, 'Color', 'r');

            view(2);
            
            hold off;

        end
        
        function b = isBaselineTilted(this)
            % The probability map generates a linear estimate of the
            % baseline regardless of whether baseline tilt is reported or
            % not. Therefore, the analysis manager should handle this as a
            % tilted baseline
            b = true;
        end
    end
    
end

