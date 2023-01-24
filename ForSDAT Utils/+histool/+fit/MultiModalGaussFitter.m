classdef MultiModalGaussFitter < histool.fit.IHistogramFitter & matlab.mixin.SetGet
    
    properties
        Order (1, 1) uint8 {mustBeFinite(Order), mustBePositive(Order), mustBeLessThan(Order, 9), mustBeNonNan(Order), mustBeReal(Order)} = 1;
        PlanBGoodnessThreshold = 0.7;
        GetOnlyMaxMode = false;
    end
    
    methods
        function this = MultiModalGaussFitter(varargin)
            if ~isempty(varargin)
                this.set(varargin{:});
            end
        end
        
        function tf = isNormalized(~)
            tf = true;
        end
        
        function [mpv, sigma, pdfunc, goodness] = fit(this, y, bins, freq)
        % Fits a gaussian series to a given histogram (raw data is ignored)
        % Parameters:
        %   y    - ignored
        %   bins - data bins
        %   freq - frequencies in each bin
        % Returns:
        %   mpv         - Most prevalent value
        %   sigma       - Standard deviation
        %   pdfunc      - A cell array of function handles that represent
        %                 the gaussian series. The first element is the
        %                 entire series distribution function and all
        %                 subsequent handles are the distribution functions
        %                 of a single element in the gaussian series
        %   goodness    - Determines the goodness of fit
        
            [mpv, sigma, goodness, gaussFit] = this.fitGaussianSeries(bins, freq);
            
            order = this.Order;
            
            % This distribution function represents the gaussian series as
            % a whole
            pdfunc = cell(1, order+1);
            pdfunc{1} = @(x) feval(gaussFit, x);
            
            % This will generate a separate distribution function for each
            % element of the gaussian series
            for i = 1:order
                pdfunc{i+1} = this.generateDistPdf(fittype('gauss1'), gaussFit.(['a' num2str(i)]), gaussFit.(['b' num2str(i)]), gaussFit.(['c' num2str(i)]));
            end
            
            % if necessary choose the absolute mode (one with highest amplitude)
            if this.GetOnlyMaxMode
                foo = pdfunc{1};
                amps = foo(mpv(:));
                [~, idxMaxMode] = max(amps);
                mpv = mpv(idxMaxMode);
                sigma = sigma(idxMaxMode);
            end
        end
    end
    
    methods (Access=private)
        function [mpv, sigma, goodness, gaussFit] = fitGaussianSeries(this, bins, freq)
        % Calculates a gaussian series fit to a histogram
        % Parameters:
        %   bins - data bins
        %   freq - frequencies in each bin
        % Returns:
        %   mpv         - Most prevalent value
        %   sigma       - Standard deviation
        %   goodness    - Determines the goodness of fit
        %   gaussFit    - Gaussian cfit object
            
            % prepare bin centers vector to serve as x axis values
            binWidths = diff(bins);
            x = bins(1:end-1) + binWidths * 0.5;
            
            % fit gaussian series
            if this.Order == 1 
                [mpv, sigma, goodness, gaussFit] = this.doFitFirstOrder(x, freq);
            else % order > 1
                [mpv, sigma, goodness, gaussFit] = this.doFitHigherOrder(x, freq);
            end
        end
        
        function [mpv, sigma, goodness, gaussFit] = doFitHigherOrder(this, x, freq)
        % Fits a gaussian series of order > 1 to a histogram
        % Parameters:
        %   x       - histogram bin centers
        %   freq    - frequencies in each bin
        % Returns:
        %   mpv         - Most prevalent value
        %   sigma       - Standard deviation
        %   goodness    - Determines the goodness of fit
        %   gaussFit    - Gaussian cfit object
        
            order = this.Order;
            mpv = zeros(1, order);
            sigma = zeros(1, order);

            % Fit gaussian to histogram bars
            [upper, lower] = this.prepareFitBounds(order, x, freq);
            [fittingParams, fitModel] = this.prepareGaussFitOptions(order, upper, lower); 
            [gaussFit, goodness] = fit(x(:), freq(:), fitModel, fittingParams);

            % When the fitted model is rubbish, fit again without
            % upper/lower bounds and let matlab decide alone.
            % The fitting may have out of bounds values, but sometimes
            % the overall fit is better.
            if goodness.rsquare < this.PlanBGoodnessThreshold
                [gaussFitNoBounds, goodnessNoBounds] = fit(x(:), freq(:), fitModel);

                % If the no-bounds fit is better, use it instead
                if goodnessNoBounds.rsquare > goodness.rsquare
                    gaussFit = gaussFitNoBounds;
                    goodness = goodnessNoBounds;
                end
            end

            % Extract fitted values
            for i = 1:order
                level = num2str(i);
                mpv(i) = gaussFit.(['b' level]);
                sigma(i) = gaussFit.(['c' level]);
            end
        end
        
        function [mpv, sigma, goodness, gaussFit] = doFitFirstOrder(this, x, freq)
        % Fits a 1st order gaussian series to a histogram
        % Parameters:
        %   x       - histogram bin centers
        %   freq    - frequencies in each bin
        % Returns:
        %   mpv         - Most prevalent value
        %   sigma       - Standard deviation
        %   goodness    - Determines the goodness of fit
        %   gaussFit    - Gaussian cfit object
        
            % Fit using basic normal distribution
            n = sum(freq);
            probability = freq/n;
            mpv = sum(x.*probability);
            sigma = sqrt(sum(((x-mpv).^2).*probability));

            % Get fit data
            amplitude = 1/(sigma*sqrt(2*pi));
            goodness = [];

            % generate gaussian distribution fit
            % ** gives better values than normfit, normfit uses a similar
            %    calculation as above.
            % Fit gaussian to histogram bars
            [upper, lower] = this.prepareFitBounds(1, x, freq);
            [fittingParams, fitModel] = this.prepareGaussFitOptions(1, upper, lower, [amplitude, mpv, sigma]); 
            [gaussFit, goodness] = fit(x(:), freq(:), fitModel, fittingParams);

            if goodness.rsquare >= this.PlanBGoodnessThreshold
                % Get fit data
                mpv = gaussFit.b1;
                sigma = abs(gaussFit.c1);
            end
        end
        
        function [fitOpt, fitModel] = prepareGaussFitOptions(this, order, upper, lower, start)
        % Prepares fitting options for the gaussian series model
        
            nameValue = {'Upper', upper, 'Lower', lower};
            if nargin >= 5
                nameValue = [nameValue, {'Start', start}];
            end
            fitModel = ['gauss' num2str(order)];
            fitOpt = fitoptions(fitModel, nameValue{:});
        end
        
        function [upper, lower] = prepareFitBounds(this, order, x, y)
        % Prepares lower and upper limits for the gaussian series model
        % parameter fitting
        
            maxX = max(x);
            maxY = max(y)*2;
            minX = min(x);
            minY = 0;
            upper = repmat([maxY, maxX, maxX-minX], 1, order);
            lower = repmat([minY, minX, 0], 1, order);
        end
        
        function pdf = generateDistPdf(~, distFitType, varargin)
            fitobj = cfit(distFitType, varargin{:});
            pdf = @(x) feval(fitobj, x);
        end
    end
end

