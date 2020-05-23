function y = overlayPdValuesOnHistogram(y, bins, N)
% overlayPdValuesOnHistogram normalizes pdf values to the area of a
% histogram in order to plot them on top of histogram.

    % calculate histogram area to normalize pdf values and overlay them on
    % top of the histogram
    binsize = bins(2)-bins(1);
    normFactor = N * binsize;
    
    % multiply y vectors by normalization factor
    y = y * normFactor;
end

