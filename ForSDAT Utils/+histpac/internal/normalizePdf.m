function [x, y] = normalizePdf(pdfs, bins)
    if ~iscell(pdfs); pdfs = {pdfs}; end

    % calculate normalization factor
    binsize = bins(2)-bins(1);
    normFactor = numel(bins) * binsize;

    % calculate x vector
    x = bins2x(bins);

    % calculate y vectors
    y = cell2mat(cellfun(@(pdfoo) pdfoo(x), pdfs, 'UniformOutput', false));

    % multiply y vectors by normalization factor
    y = y * normFactor;
end
