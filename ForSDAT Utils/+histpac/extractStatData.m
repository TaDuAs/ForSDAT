function statData = extractStatData(x, varargin)
    options = parseHistogramInput(varargin);
    
    statData = histpac.HistStatData();
    
    % calculate histogram details
    statData.NBins = histpac.calcNBins(x(:), options.BinningMethod, options.MinimalBins);
    [statData.Frequencies, statData.BinEdges] = histcounts(y, nbins);
    
    % fit distribution to data/histogram
    if ~isempty(options.Model)
        [statData.MPV, statData.StandardDeviation, statData.PDF, statData.GoodnessOfFit] = ...
            options.Model.fit(x(:), statData.BinEdges, statData.Frequencies);
        statData.HasDistribution = true;
    end
end





