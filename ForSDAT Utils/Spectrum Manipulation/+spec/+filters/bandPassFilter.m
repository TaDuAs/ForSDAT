function filter = bandPassFilter(bands)
% bandPassFilter generates a filter function handle that only passes the
% required frequencies
%    
% filter = bandPassFilter(bands) - returns the bandpass filter using the
%   given allowed frequencies specified in bands.
% Input:
%   bands - is a 2d matrix of size [n,2] where the first column represents 
%   the starting frequencies of each band to pass and the second column 
%   represents the closing frequency of each band.
%
% Output:
%   filter - a filter function handle for use with filterSpectrum
%
% Written by TADA, HUJI 2020
% 
% see also:
% spec.filterSpectrum
% spec.filters.bandRejectFilter
% spec.filters.bandIntensityFilter
% spec.filters.subtractionFilter
% spec.filters.reductionFilter
% spec.filters.backgroundFilter
%

    % validate input
    assert(isnumeric(bands) && size(bands, 2) == 2 && all(bands(:,1) < bands(:,2)),...
        'Specify bands as a 2 column matrix [startFrequency, endFrequency] where each row represents a single band');
    
    function fixedSignal = bandPassFunction(x, y, ~)
        % get a mask for current bands
        bandMask = spec.filters.bandMask(bands, x);
        
        fixedSignal = y;
        
        % remove all frequencies outside the specified bands
        fixedSignal(~bandMask) = 0;
    end

    filter = @bandPassFunction;
end

