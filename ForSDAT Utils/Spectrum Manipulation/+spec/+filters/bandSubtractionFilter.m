function filter = bandSubtractionFilter(bandValues)
% bandSubtractionFilter generates a filter function handle that subtracts 
% a given value from each frequency band
%    
% filter = bandPassFilter(bands) - returns the bandsubtract filter which 
%   subtracts the given value from the aplitude of the frequencies 
%   specified in bands.
% Input:
%   bandValues - is a 2d matrix of size [n,3] where the first column  
%       represents the starting frequencies of each band to reduce and the 
%       second column represents the closing frequency of each band.
%       The third column represents the value to subtract from each band.
% Output:
%   filter - a filter function handle for use with filterSpectrum
%
% Written by TADA, HUJI 2020
% 
% see also:
% spec.filterSpectrum
% spec.filters.bandPassFilter
% spec.filters.bandRejectFilter
% spec.filters.bandIntensityFilter
% spec.filters.subtractionFilter
% spec.filters.reductionFilter
% spec.filters.backgroundFilter
%

    assert(isnumeric(bandValues) && size(bandValues, 2) == 3 && all(bandValues(:,1) < bandValues(:,2)),...
        'Specify bands as a 3 column matrix [startFrequency, endFrequency, subtractionValue] where each row represents a single band');
    
    function fixedSignal = bandFilterFunction(x, y, ~)
        [~, bandMaskPos, bandMaskNeg] = spec.filters.bandMask(bandValues(:, 1:2), x);
        
        fixedSignal = zeros(size(y));
        
        for i = 1:size(bandMaskPos, 1)
            value = bandValues(i,3);
            if isreal(value)
                value = complex(value, value);
            end
            
            fixedSignal(bandMaskPos(i, :)) =  complex(real(value), -imag(value));
            fixedSignal(bandMaskNeg(i, :)) =  value;
        end
    end

    filter = spec.filters.subtractionFilter('Filter', @bandFilterFunction, 'SignComp', 'zero');
end