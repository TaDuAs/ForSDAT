function [x, y] = execPdf(pdfs, bins)    
    % calculate x vector with small intervals
    x = bins2x(bins);

    % calculate y vectors
    y = cell2mat(cellfun(@(pdfoo) pdfoo(x), pdfs, 'UniformOutput', false));
end

