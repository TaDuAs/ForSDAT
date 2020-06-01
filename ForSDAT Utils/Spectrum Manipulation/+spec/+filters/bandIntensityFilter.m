function filter = bandIntensityFilter(bandIntensities, intensity)
% bandIntensityFilter generates a filter function handle that changes the 
% intensity of frequency bands by a multiplier
%    
% filter = bandPassFilter(bands) - returns the bandintensity filter which 
%   multiplies the given frequencies specified in bands by a multiplier.
% Input:
%   bandIntensities - is a 2d matrix of size [n,3] where the first column  
%   	represents the starting frequencies of each band to amplify/reduce 
%       and the second column represents the closing frequency of each band.
%       The third column represents the intensity multiplier to apply to
%       each band. Use intensity between 0 and 1 to reduce band intensity
%       and intensity greater than 1 to amplify band intensity
% Output:
%   filter - a filter function handle for use with filterSpectrum
%
% filter = bandPassFilter(bands, intensity) - also takes an intensity
%   multiplier.
% Input:
%   intensity - A positive scalaar value to apply to all bands.
%
% Written by TADA, HUJI 2020
% 
% see also:
% spec.filterSpectrum
% spec.filters.bandPassFilter
% spec.filters.bandRejectFilter
% spec.filters.subtractionFilter
% spec.filters.reductionFilter
% spec.filters.backgroundFilter
%

    if nargin >= 2 && ~isempty(intensity)
        bandIntensities(:, 3) = intensity;
    end
    assert(isnumeric(bandIntensities) && size(bandIntensities, 2) == 3 && all(bandIntensities(:,1) < bandIntensities(:,2)),...
        'Specify bands as a 3 column matrix [startFrequency, endFrequency, intensityMultiplier] where each row represents a single band');
    
    function fixedSignal = bandFilterFunction(x, y, ~)
        [~, bandMask] = spec.filters.bandMask(bandIntensities(:, 1:2), x);
        
        fixedSignal = y;
        
        for i = 1:size(bandMask,1)
            fixedSignal(bandMask(i, :)) = bandIntensities(i,3) * fixedSignal(bandMask(i, :));
        end
    end

    filter = @bandFilterFunction;
end

