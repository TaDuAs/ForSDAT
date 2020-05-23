classdef HistStatData
% HistStatData - Histogram analysis data object

    properties
        %
        % Calculated histogram properties
        %
        
        % Number of bins in the histogram
        NBins;
        
        % The edges of the histogram bins
        BinEdges;
        
        % The counts of each histogram bin
        Frequencies;
        
        
        
        
        %
        % Distribution modeling
        %
        
        % a logical scalar which determines whether a distrigution was fit
        % to the dataset
        HasDistribution = false;
        
        % Determines whether the fitting model requires post fitting
        % normalization of the probability distribution function.
        % When the pdf isn't a REAL probability distribution function (i.e
        % an optimization result rather than a distribution object), no
        % normalization is required, and the fitter should specify that
        IsNormalized = false;
        
        % The most probable/prevalent value of the distribution (mode)
        MPV;
        
        % Standard deviation of the distribution
        StandardDeviation;
        
        % A cell array of function handles for calculating distribution
        % values
        PDF;
        
        % The goodness of fit of distribution fitting
        GoodnessOfFit;
    end
end

