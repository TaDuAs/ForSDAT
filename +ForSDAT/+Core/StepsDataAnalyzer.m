classdef StepsDataAnalyzer < mfc.IDescriptorStruct
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
        function [mpf, sigma, err, lr, lrErr, returnedOpts] = doYourThing(this, frc, dist, slope, speed, lrVector, options)
            if ~exist('lrVector', 'var')
                lrVector = [];
            end
            if ~exist('options', 'var')
                options = [];
            end
            
            import Simple.Math.*;
            
            % Analyze the values using a histogram (not ploting yet...)
            [mpf, sigma, bins, amplitude, pdf, goodness] = this.histogramAnaylzeValues(frc);
            err = econfi(mpf, this.alpha, sigma, length(frc));
            [mpf, err] = roundError(mpf, err);
            
            % Calculate the average loading rate & confidence interval
            lrVector = lrVector(~isnan(lrVector));
            if isempty(lrVector)
                lrVector = -1*slope(slope<0)*speed;
            end
            lr = mean(lrVector);
            lrErr = econfi(lrVector, this.alpha);
            if isnumeric(lr) && ~isnan(lr) && ~isempty(lr)
                [lr, lrErr] = roundError(lr, lrErr);
            end
            
            % Show histogram if needed
            showHistogram = Simple.getobj(options, 'showHistogram', false);
            if (showHistogram)
                plotOpt = Simple.getobj(options, 'plotOptions', []);
                this.plotHistogram(dist, frc, bins, mpf, err, lr, lrErr, amplitude, pdf, plotOpt);
            end
            
            returnedOpts = struct('amp', amplitude, 'fitGoodness', goodness);
        end
        
        function [mpv, std, bins, amplitude, pdf, goodness] = histogramAnaylzeValues(this, y)
            import Simple.*;
            import Simple.Math.*;
            [bins, binterval, ~] = Histool.calcBins(y, this.binningMethod, this.minimalBins);
            
            if binterval == 0
                error('Halo! The data range is 0, that means all values are exactly the same, which is impossible! Go check your data before you come back!')
            end
            
            
            % calculate frequencies - the frequencies array supplied by the histogram
            % tool are unfortunately trimmed from zeroes in the ends of the array
            freq = Histool.calcFrequencies(y, bins);
            
            % generate normal distribution fit
            % ** gives better values than normfit
            order = this.getModelOrder(this.model);
            fitOptions = struct(...
                'useMatlabFit', true,...
                'fitR2Threshold', this.fitR2Threshold,...
                'order', order);
            
            if startsWith(lower(this.model), ForSDAT.Core.StepsDataAnalyzer.supportedModels.gauss)
                [mpv, std, amplitude, goodness, gaussFit] = Histool.calcGaussian(bins, freq, fitOptions);
                pdf = cell(1, order+1);
                pdf{1} = @(x) feval(gaussFit, x);
                for i = 1:order
                    pdf{i+1} = this.generateDistPdf(fittype('gauss1'), gaussFit.(['a' num2str(i)]), gaussFit.(['b' num2str(i)]), gaussFit.(['c' num2str(i)]));
                end
            elseif strcmpi(this.model, ForSDAT.Core.StepsDataAnalyzer.supportedModels.gamma)
                [mpv, std, gammaParams, goodness] = Histool.fitGamma(bins, freq, fitOptions);
                gpdf = this.generateGammaPDF(gammaParams.alpha, gammaParams.theta);
                amplitude = max(gpdf(mpv));
                pdf = {gpdf};
            else
%                 [pdca,gn,gl] = fitdist(x, this.model)
                throw(MException('ForSDAT:Core:StepsDataAnalyzer:InvalidModelFitting', 'Model %s is not supported. use either gauss (with order) or gamma (without order).', this.model));
            end
        end
        
        function plotHistogram(~, dist, frc, bins, mpf, err, lr, lrErr, amplitude, pdf, options)
            import Simple.*;
            import Simple.Math.*;
            figureIndex = getobj(options, 'figure', []);
            if isempty(figureIndex)
                figure();
            else
                figure(figureIndex);
            end
            
            h1 = histogram(frc, bins);
%             h1.Normalization = 'probability';

            % generate gauss plot
            pdfX = linspace(min(bins),max(bins),1000)';
            pdfY = cell2mat(cellfun(@(pdfFoo) pdfFoo(pdfX), pdf, 'UniformOutput', false));% * (max(h1.Values)) / max(amplitude));

            hold on;
            plot(pdfX, pdfY);

            % make figure displayable
            xlabel('Rupture Force Range [pN]');
            ylabel('Probability');
            [displayMPF, displaySTD] = roundError(mpf, err);
            plotSubtitle = strcat('MPF=', num2str(displayMPF), '±', num2str(displaySTD), 'pN, L.R=',...
                num2str(lr), '±', num2str(lrErr), 'nN/sec, N=', num2str(length(frc)));

            hold off;

            plotTitle = getobj(options, 'title', '');
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
        
        function order = getModelOrder(this, model)
            sorder = regexp(model, '\d*$', 'match');
            if isempty(sorder)
                order = 1;
            else
                order = str2double(sorder);
                if numel(order) ~= 1 || ~isPositiveIntegerValuedNumeric(order)
                    throw(MException('ForSDAT:Core:StepsDataAnalyzer:InvalidModelOrder', ...
                        'Model fitting order must be a positive integer'));
                end
            end
        end
    end
end

