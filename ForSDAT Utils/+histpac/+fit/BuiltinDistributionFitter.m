classdef BuiltinDistributionFitter < histpac.fit.IHistogramFitter
    
    properties
        DistributionName char {gen.valid.mustBeTextualScalar(DistributionName)} = 'normal';
        FittingMode char {mustBeMember(FittingMode, {'data', 'frequencies'})} = 'data';
    end
    
    methods
        function [mpv, sigma, pdfoo, goodness] = fit(this, y, bins, freq)
            % fit builtin distributions
            if strcmp(this.FittingMode, 'frequencies')
                pd = fitdist(bins(:), this.DistributionName, ones(numel(bins), 1), freq(:));
            else
                pd = fitdist(y(:), this.DistributionName);
            end
            
            % prepare probability distribution function
            pdfoo = {@(x) pdf(pd, x)};
            
            % prepare 
            mpv = histpac.mode(pd, bins);
            sigma = std(pd);
            goodness = pd.ParameterCovariance;
        end
    end
end

