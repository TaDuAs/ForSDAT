function statData = stats(x, varargin)
    options = parseHistogramInput(varargin);
    
    statData = histpac.HistStatData();
    
    % calculate histogram details
    statData.NBins = histpac.calcNBins(x(:), options.BinningMethod, options.MinimalBins);
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





