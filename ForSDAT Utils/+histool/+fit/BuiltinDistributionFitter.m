classdef BuiltinDistributionFitter < histool.fit.IHistogramFitter & matlab.mixin.SetGet
% histool.fit.BuiltinDistributionFitter is a fitter object for fitting
% builtin fittable probability distributions using the fitdist function
% The default behaviour is to fit the normal distribution to the data set.
%
% Fitting modes - data, frequencies
    
    properties
        DistributionName char {gen.valid.mustBeTextualScalar(DistributionName)} = 'normal';
        FittingMode char {mustBeMember(FittingMode, {'data', 'frequencies'})} = 'data';
    end
    
    methods
        function this = BuiltinDistributionFitter(varargin)
            this.set(varargin{:});
        end
        
        function tf = isNormalized(~)
            tf = false;
        end
        
        function [mpv, sigma, normalizedPDF, goodness] = fit(this, y, bins, freq)
            % fit builtin distributions
            if strcmp(this.FittingMode, 'frequencies')
                xbins = bins(1:numel(freq)) + (diff(bins) / 2);
                pd = fitdist(xbins(:), this.DistributionName, 'Censoring', zeros(numel(freq), 1), 'Frequency', freq(:));
            else
                pd = fitdist(y(:), this.DistributionName);
            end
            
            % prepare probability distribution function
            normalizedPDF = {@(x) pdf(pd, x)};
            
            % prepare 
            mpv = histool.mode(pd, bins);
            sigma = std(pd);
            if isfield(pd, 'ParameterCovariance')
                goodness = pd.ParameterCovariance;
            else
                goodness = zeros(2, 2);
            end
        end
    end
end

