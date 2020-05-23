function [x, y] = normalizePdf(pdfs, bins, N)
    if ~iscell(pdfs); pdfs = {pdfs}; end

    % prepare x & y vector for all ditribution functions
    [x, y] = execPdf(pdfs, bins);
    
    % normalize pdf values to the histogram
    y = overlayPdValuesOnHistogram(y, bins, N);
end
