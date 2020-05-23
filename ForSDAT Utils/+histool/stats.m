function statData = stats(x, varargin)
% histool.stats performs statistical analysis of dataset using histogram
% calculations and distribution fitting.
%
% statData = stats(x)
%   calculates a freedman–diaconis histogram for the specified data set
% Input:
%   x - data set
% Output: 
%   statData - histogram analysis data object (histool.HistStatData)
%
% statData = histdist(x, Name, Value)
%   also takes in additional options specified as one or more Name-Value
%   pairs.
% 
% Name-Value Arguments
%   BinningMethod - Specifies the method to use for determining the number
%                   histogram bins or the bin width to use.
%                   see histool.calcNBins for details. Default = 'freedman–diaconis'
%   MinimalBins   - Numeric scalar representing the minimal number of bins
%                   to calculate. Default = 0
%   Model - The distribution to fit to the data or a fitter object
%           implementing histool.fit.IHistogramFitter.
%           Supported values:
%               any fittable distribution supported by fitdist using histool.fit.BuiltinDistributionFitter
%               'gauss' - a gaussian series of order 1 using histool.fit.MultiModalGaussFitter
%               'gaussN' ('gauss1'..'gauss8') - a gaussian series of order N using histool.fit.MultiModalGaussFitter
%               an object which implements the histool.fit.IHistogramFitter abstract class
%         * When a model is passed into histool.histdist, the fit
%           distribution is also plotted in top of the histogram.
%   ModelParams - a cell array of variables to pass to the fitter when it
%                 is constructed. use this when specifying the model name.
%                 For 'gauss'/'gaussN' models see list of histool.fit.MultiModalGaussFitter properties
%                 For builtin matlab distributions see list of histool.fit.BuiltinDistributionFitter properties
% 
% Author - TADA, 2020
% 
% See also
% histool.histdist
% histool.mode
% histool.calcNBins
% histool.supportedBinningMethods
%

    options = parseHistogramInput(varargin, 'histool.stats');
    
    statData = histool.HistStatData();
    
    % calculate histogram details
    statData.NBins = histool.calcNBins(x(:), options.BinningMethod, options.MinimalBins);
    [statData.Frequencies, statData.BinEdges] = histcounts(x, statData.NBins);
    
    % fit distribution to data/histogram
    model = options.Model;
    if ~isempty(model)
        [statData.MPV, statData.StandardDeviation, statData.PDF, statData.GoodnessOfFit] = ...
            model.fit(x(:), statData.BinEdges, statData.Frequencies);
        statData.HasDistribution = true;
        statData.IsNormalized = model.isNormalized();
    end
end





