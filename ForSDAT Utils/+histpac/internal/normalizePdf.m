function [x, y] = normalizePdf(pdfs, bins)
    if ~iscell(pdfs); pdfs = {pdfs}; end

    % calculate normalization factor
    binsize = bins(2)-bins(1);
    normFactor = numel(bins) * binsize;

    % prepare x & y vector for all ditribution functions
    [x, y] = execPdf(pdfs, bins);
    
    % multiply y vectors by normalization factor
    y = y * normFactor;
end
