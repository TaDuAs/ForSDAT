function [mask, varargout] = bandMask(bands, x)
% bandMask generates a logical index corresponding to N fourier space 
% frequencies with delta df.
% 
% mask = bandMask(bands, N, df, Nfastest)
% Input:
%   bands -     a nx2 matrix, the first column represents the low frequency 
%               of each band, and the second column the high frequency of 
%               each band
%   N -         The number of frequencies (positive and negative) in the
%               frequency vector
%   df -        Frequency delta
%   Nfastest -  The number of positive frequencies
% Output:
%   mask - The logical index which corresponds to the given bands
%
% [mask, maskPerBand] = bandMask(bands, N, df, Nfastest)
%   Also returns a per-band logical index
% Output:
%   maskPerBand - nxN matrix representing n logical indices of size 1xN,
%                 each corresponds to a specific band
%
% [mask, maskPerBandPos, maskPerBandNeg] = bandMask(bands, N, df, Nfastest)
%   Also returns a seperate per-band logical index for the negative and
%   positive parts of the amplitude spectrum
% Output:
%   maskPerBandPos - nxN matrix representing n logical indices of size 1xN,
%                    each corresponds to the positive part of a specific 
%                    band
%   maskPerBandNeg - nxN matrix representing n logical indices of size 1xN,
%                    each corresponds to the negative part of a specific
%                    band
%
% Written by TADA, Huji 2020
% 
    
    % preallocate logical indices
    N = numel(x);
    mask = false(1, N);
    if nargout == 2
        maskPerBand = false(size(bands, 1), N);
    elseif nargout == 3
        maskPerBandPos = false(size(bands, 1), N);
        maskPerBandNeg = false(size(bands, 1), N);
    elseif nargout > 3
        error('Too many output arguments');
    end
    
    % iterate through all bands to prepare the mask
    for i = 1:size(bands, 1)
        % find indices corresponding to current band frequencies
        posMask = x >= bands(i, 1) & x <= bands(i, 2);
        negMask = x >= -bands(i, 2) & x <= -bands(i, 1);

        % prep the logical index, mark the indices true
        mask(posMask) = true;
        mask(negMask) = true;
        
        if nargout == 2
            % if a per band index is required, prep the current band mask
            maskPerBand(i, posMask) = true;
            maskPerBand(i, negMask) = true;
        elseif nargout == 3
            maskPerBandPos(posMask) = true;
            maskPerBandNeg(negMask) = true;
        end
    end
    
    if nargout == 2
        varargout = {maskPerBand};
    elseif nargout == 3
        varargout = {maskPerBandPos, maskPerBandNeg};
    end
end

%{
Deprecated version

function [mask, varargout] = bandMask(bands, N, df, Nfastest)
% bandMask generates a logical index corresponding to N fourier space 
% frequencies with delta df.
% 
% mask = bandMask(bands, N, df, Nfastest)
% Input:
%   bands -     a nx2 matrix, the first column represents the low frequency 
%               of each band, and the second column the high frequency of 
%               each band
%   N -         The number of frequencies (positive and negative) in the
%               frequency vector
%   df -        Frequency delta
%   Nfastest -  The number of positive frequencies
% Output:
%   mask - The logical index which corresponds to the given bands
%
% [mask, maskPerBand] = bandMask(bands, N, df, Nfastest)
%   Also returns a per-band logical index
% Output:
%   maskPerBand - nxN matrix representing n logical indices of size 1xN,
%                 each corresponds to a specific band
%
% [mask, maskPerBandPos, maskPerBandNeg] = bandMask(bands, N, df, Nfastest)
%   Also returns a seperate per-band logical index for the negative and
%   positive parts of the amplitude spectrum
% Output:
%   maskPerBandPos - nxN matrix representing n logical indices of size 1xN,
%                    each corresponds to the positive part of a specific 
%                    band
%   maskPerBandNeg - nxN matrix representing n logical indices of size 1xN,
%                    each corresponds to the negative part of a specific
%                    band
%
% Written by TADA, Huji 2020
% 
    
    % preallocate logical indices
    if nargout == 2
        maskPerBand = false(size(bands, 1), N);
    elseif nargout == 3
        maskPerBandPos = false(size(bands, 1), N);
        maskPerBandNeg = false(size(bands, 1), N);
    elseif nargout > 3
        error('Too many output arguments');
    end
    mask = false(1, N);
    
    % iterate through all bands to prepare the mask
    for i = 1:size(bands, 1)
        % find indices corresponding to current band frequencies
        posBounds = [max(1, ceil(bands(i, 1)/df)), min(floor(bands(i, 2)/df), Nfastest)];
        negBounds = flip(N - posBounds + 2);

        % The numeric indices for the current band
        idxPos = posBounds(1):posBounds(2);
        idxNeg = max(Nfastest+1, negBounds(1)):min(N, negBounds(2));
        
        % prep the logical index, mark the indices true
        mask(idxPos) = true;
        mask(idxNeg) = true;
        
        if nargout == 2
            % if a per band index is required, prep the current band mask
            maskPerBand(i, idxPos) = true;
            maskPerBand(i, idxNeg) = true;
        elseif nargout == 3
            maskPerBandPos(idxPos) = true;
            maskPerBandNeg(idxNeg) = true;
        end
    end
    
    if nargout == 2
        varargout = {maskPerBand};
    elseif nargout == 3
        varargout = {maskPerBandPos, maskPerBandNeg};
    end
end


%}
