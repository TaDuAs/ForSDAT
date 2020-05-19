classdef StepsDataAnalyzer < mfc.IDescriptor
    % Good at analyzing the rupture events data produced from a batch of
    % F-D curves.
    
    methods (Static)
        function [data, list] = supportedModels()
            persistent models;
            persistent modelsList;
            if isempty(models)
                models.gauss = 'gauss';
                models.gamma = 'gamma';
                models.weibull = 'weibull';
                modelsList = fields(models);
            end
            
            data = models;
            list = modelsList;
        end
        
        function isValid = isModelValid(model)
            [~, models] = ForSDAT.Core.StepsDataAnalyzer.supportedModels;
            isValid = any(cellfun(@any, regexp(model, strcat(models, '\d*'))));
        end
    end
    
    properties
        minimalBins = [];
        binningMethod = [];
        fitR2Threshold = [];
        model = ForSDAT.Core.StepsDataAnalyzer.supportedModels.gauss;
        alpha = 0.05;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'binningMethod', 'minimalBins', 'model', 'fitR2Threshold', 'alpha'};
            defaultValues = {...
                'binningMethod', [], ...
                'minimalBins', [],...
                'model', '', ...
                'fitR2Threshold', [], ...
                'alpha', []};
        end
    end
    
    methods
        function this = StepsDataAnalyzer(binningMethod, minimalBins, model, fitR2Threshold, confidenceIntervalAlphaValue)
            this.binningMethod = binningMethod;
            this.minimalBins = minimalBins;
            
            if exist('model', 'var') && ~isempty(model)
                if ~ForSDAT.Core.StepsDataAnalyzer.isModelValid(model)
                    [~, supportedModelsList] = ForSDAT.Core.StepsDataAnalyzer.supportedModels;
                    error(['Specified model ' model ' is invalid. Supported models: '...
                        cell2mat(supportedModelsList)]);
                end
                this.model = model;
            end
            
            if exist('fitR2Threshold', 'var') && ~isempty(fitR2Threshold)
                this.fitR2Threshold = fitR2Threshold;
            end
            
            if exist('confidenceIntervalAlphaValue', 'var') && ~isempty(confidenceIntervalAlphaValue)
                this.alpha = confidenceIntervalAlphaValue;
            end
        end
        
        function nbins = calcNBins(this, data, method, minimalBins)
            if nargin < 4 || isempty(minimalBins); minimalBins = 0; end
            
            if isnumeric(method)
                binterval = method;
                nbins = ceil(range(data)/binterval);
            elseif ischar(method) || isStringScalar(method)
                n = numel(data);

                % Calculate number of bins using the wanted method
                switch lower(char(method))
                    case 'sturges'
                        nbins = round(log(n) + 1);
                    case {'fd', 'freedman–diaconis', 'freedman diaconis'}
                        nbins = round(2 * iqr(data) / (n^(1/3)));
                    case {'sqrt', 'square root', 'square-root'}
                        nbins = round(sqrt(n));
                    otherwise
                        error(['Binning method ''' method ''' not supported']);
                end
            else
                throw(MException('ForSDAT:CookedDataAnalyzer:InvalidBinningMethod', ...
                    'Binning method should be either a numeric scalar specifying the bin size or one of {''sturges'', ''fd'', ''sqrt''}'));
            end
            
            % ensure at least minimal bins are set
            if nbins < minimalBins
                nbins = minimalBins;
            end
        end
        
        
        function [mpf, sigma, err, lr, lrErr, returnedOpts] = doYourThing(this, frc, dist, slope, speed, lrVector, options)
            if ~exist('lrVector', 'var')
                lrVector = [];
            end
            if ~exist('options', 'var')
                options = [];
            end
                        
            % Analyze the values using a histogram (not ploting yet...)
            [mpf, sigma, bins, pdf, goodness] = this.histogramAnaylzeValues(frc);
            err = util.econfi(mpf, this.alpha, sigma, numel(frc));
            [mpf, err] = util.roundError(mpf, err);
            
            % Calculate the average loading rate & confidence interval
            lrVector = lrVector(~isnan(lrVector));
            if isempty(lrVector)
                lrVector = -1*slope(slope<0)*speed;
            end
            lr = mean(lrVector);
            lrErr = util.econfi(lrVector, this.alpha);
            if isnumeric(lr) && ~isnan(lr) && ~isempty(lr)
                [lr, lrErr] = util.roundError(lr, lrErr);
            end
            
            % Show histogram if needed
            showHistogram = mvvm.getobj(options, 'showHistogram', false);
            if (showHistogram)
                plotOpt = mvvm.getobj(options, 'plotOptions', []);
                this.plotHistogram(dist, frc, bins, mpf, err, lr, lrErr, pdf, plotOpt);
            end
            
            returnedOpts = struct('fitGoodness', goodness);
        end
        
        function [mpv, sigma, bins, pdfoo, goodness] = histogramAnaylzeValues(this, y)
            if range(y) == 0
                error('The data range is 0, that means all values are exactly the same, which is impossible! Go check your data before you come back!')
            end
            
            % generate normal distribution fit
            % ** gives better values than normfit
            order = this.getModelOrder(this.model);
            fitOptions = struct(...
                'useMatlabFit', true,...
                'fitR2Threshold', this.fitR2Threshold,...
                'order', order);
            
            % calculate frequencies - the frequencies array supplied by the histogram
            % tool are unfortunately trimmed from zeroes in the ends of the array
            nbins = this.calcNBins(y, this.binningMethod, this.minimalBins);
            [freq, bins] = histcounts(y, nbins);
                
            % fit multiple gauss peaks
            if startsWith(lower(this.model), ForSDAT.Core.StepsDataAnalyzer.supportedModels.gauss) && order > 1
                [mpv, sigma, ~, goodness, gaussFit] = Simple.Math.Histool.calcGaussian(bins, freq, fitOptions);
                pdfoo = cell(1, order+1);
                pdfoo{1} = @(x) feval(gaussFit, x);
                for i = 1:order
                    pdfoo{i+1} = this.generateDistPdf(fittype('gauss1'), gaussFit.(['a' num2str(i)]), gaussFit.(['b' num2str(i)]), gaussFit.(['c' num2str(i)]));
                end
            else
                % fit any other distribution
                pd = fitdist(y(:), this.model);
                pdfoo = {@(x) pdf(pd, x)};
                binx = this.bins2x(bins);
                mpv = this.calcMode(pd, binx);
                sigma = std(pd);
                goodness = pd.ParameterCovariance;
            end
        end
        
        function plotHistogram(this, dist, frc, bins, mpf, err, lr, lrErr, pdfs, options)
            figureIndex = mvvm.getobj(options, 'figure', []);
            if isempty(figureIndex)
                figure();
            else
                figure(figureIndex);
            end
            
            h1 = histogram(frc, bins);

            % generate distribution plot
            [pdfX, pdfY] = this.normalizePdf(pdfs, bins);
            
            hold on;
            plot(pdfX, pdfY);

            % make figure displayable
            xlabel('Rupture Force Range [pN]');
            ylabel('Frequency');
            [displayMPF, displaySTD] = util.roundError(mpf, err);
            plotSubtitle = strcat('MPF=', num2str(displayMPF), '±', num2str(displaySTD), 'pN, L.R=',...
                num2str(lr), '±', num2str(lrErr), 'nN/sec, N=', num2str(length(frc)));

            hold off;

            plotTitle = mvvm.getobj(options, 'title', '');
            if iscell(plotTitle)
                plotTitle{length(plotTitle) + 1} = plotSubtitle;
            elseif ~isempty(plotTitle)
                plotTitle = {plotTitle, plotSubtitle};
            else
                plotTitle = plotSubtitle;
            end
            title(plotTitle);
        end
    end
    
    methods (Access=private)
        function pdf = generateGammaPDF(this, galpha, gtheta)
            function y = gammaDistPDF(x)
                y = gampdf(x, galpha, gtheta);
            end
            
            pdf = @gammaDistPDF;
        end
        
        function pdf = generateDistPdf(this, distFitType, varargin)
            fitobj = cfit(distFitType, varargin{:});
            pdf = @(x) feval(fitobj, x);
        end
    end
end

