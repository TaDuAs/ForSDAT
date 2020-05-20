classdef BuiltinDistributionFitter < histpac.fit.IHistogramFitter & matlab.mixin.SetGet
    
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
                pd = fitdist(bins(:), this.DistributionName, ones(numel(bins), 1), freq(:));
            else
                pd = fitdist(y(:), this.DistributionName);
            end
            
            % prepare probability distribution function
            normalizedPDF = {@(x) pdf(pd, x)};
            
            % prepare 
            mpv = histpac.mode(pd, bins);
            sigma = std(pd);
            goodness = pd.ParameterCovariance;
        end
    end
end

