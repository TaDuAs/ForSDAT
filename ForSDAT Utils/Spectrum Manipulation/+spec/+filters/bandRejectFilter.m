function filter = bandRejectFilter(bands)
% bandRejectFilter generates a filter function handle that removes the
% specified frequencies
%    
% filter = bandRejectFilter(bands) - returns the bandreject filter using 
%   the given removed frequencies specified in bands.
% Input:
%   bands - is a 2d matrix of size [n,2] where the first column represents 
%   the starting frequencies of each band to reject and the second column 
%   represents the closing frequency of each band.
%
% Output:
%   filter - a filter function handle for use with filterSpectrum
%
% Written by TADA, HUJI 2020
% 
% see also:
% spec.filterSpectrum
% spec.filters.bandPassFilter
% spec.filters.bandIntensityFilter
% spec.filters.subtractionFilter
% spec.filters.reductionFilter
% spec.filters.backgroundFilter
%

    % validate inputs
    assert(isnumeric(bands) && size(bands, 2) == 2 && all(bands(:,1) < bands(:,2)),...
        'Specify bands as a 2 column matrix [startFrequency, endFrequency] where each row represents a single band');
    
    function fixedSignal = bandFilterFunction(x, y, ~)
        bandMask = spec.filters.bandMask(bands, x);
        
        fixedSignal = y;
        fixedSignal(bandMask) = 0;
    end

    filter = @bandFilterFunction;
end

