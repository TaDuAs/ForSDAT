classdef (Abstract) IHistogramFitter < handle
    methods
        [mpv, stdev, pdfoo, goodness] = fit(fitter, x, bins, freq);
        tf = isNormalized(fitter);
    end
end

