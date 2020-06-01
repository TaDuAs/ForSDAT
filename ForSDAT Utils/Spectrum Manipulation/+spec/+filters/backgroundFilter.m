function filter = backgroundFilter(n, span, method)
% backgroundFilter generates a filter function that evaluates the 
% background of a signal by iteratively smoothing out the positive/negative
% peaks. This approach is mostly useful when the signal displays distinct 
% sharp peaks and valleys.
% 
% Input:
% n     -   An integer scalar representing the number of peak-find/smoothing
%           cycles to repeat. default: 1.
% span  -   An integer scalar representing the size of window arround the
%           peak used for smoothing. default: 1
% method -  A function handle to execute the smoothing operation.
%           default: @mean
% 
% Output:
% filter -  A filter function handle with the expected signature:
%           function fixedSignal = foo(x, y, model)
%           * Here the use of a closure allows the filter function handle 
%             to use the smoothing configuration passed to backgroundFilter
%
% Written by TADA, HUJI 2020.
%
% see also:
% spec.filterSpectrum
% spec.filters.subtractionFilter
% spec.filters.reductionFilter
% spec.filters.bandPassFilter
% spec.filters.bandRejectFilter
% spec.filters.bandIntensityFilter
%

    % default values decleration
    if nargin < 1 || isempty(n); n = 1; end
    if nargin < 2 || isempty(span); span = 1; end
    if nargin < 3 || isempty(method); method = @mean; end
    
    % input validation
    assert(isPositiveIntegerValuedNumeric(n),...
        'number of peak smoothing iterations must be a real positive integer scalar');
    assert(isPositiveIntegerValuedNumeric(span),...
        'peak smoothing window size must be a real positive integer scalar');
    assert(isa(method, 'function_handle'), ...
        'method must be a function handle');
    
    % Filter function for filterSpectrum with the expected
    % signature:
    % function fixedSignal = foo(x, y, model)
    % here no model is required and the x vector is not necessary
    function bg = smoothPeaksFilterFunction(~, y, ~)
        y1 = y(:);
        bg = y1;
        
        % execute n find-peak/smoothing cycles
        for i = 1:n
            % Find the positive and negative peaks in the signal
            % The absolute value of the signal is used to find both
            % positive and negative peaks at one go.
            [~, pi] = findpeaks(abs(y1), 'MinPeakHeight', 0);
            
            % calculate the start/end indices of the smoothing window
            % arround each peak
            smoothWindows = [max(1, pi(:)-span), min(numel(y1), pi(:)+span)];
    
            % iterate through all peak indices
            for j = 1:numel(pi)
                currIdx = pi(j);
                
                % Create an index for the current smoothing window, exclude
                % the peak index for maximal smoothing
                windowIdx = [smoothWindows(j, 1):currIdx-1,currIdx+1: smoothWindows(j, 1)];
                
                % Get the values of the current window
                windowValues = y1(windowIdx);
                
                % set the new smoothed value of the peak by applying the
                % smoothing function to the values
                bg(currIdx) = method(windowValues);
            end
            
            % set the fixed signal for the next find-peak/smoothing cycle
            y1 = bg;
        end
    end

    % return the filter function handle closure.
    filter = @smoothPeaksFilterFunction;
end
