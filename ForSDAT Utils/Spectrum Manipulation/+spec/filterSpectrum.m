function [filteredSignal, ampSpec, f_half] = filterSpectrum(x, Fs, filter, varargin)
% filterSpectrum applies fourier space filtration to a given signal.
% 
% filteredSignal = filterSpectrum(x, Fs, filter)
%   applies a given filter to the signal x and returns the filtered signal
% Input:
%   x - measured signal
%   Fs - Sampling frequency (Hz)
%   filter - a function handle with the signature
%            function fixedSignal = filter(f, y, metadataStruct, [model/filter])
%            where f is a column vector of frequencies, y is a column
%            vector of the frequency space representation of the signal x
%            and metadataStruct is a structure containing some details
%            about the signal and its fourier space representation.
% Output:
%   filteredSignal - The signal after applying the given filter in fourier
%                    space and executing the inverse fourier transform.
%      
% [filteredSignal, ampSpec, f_half] = filterSpectrum(x, Fs, filter)
%   also returns the post filter amplitude spectrum and corresponding 
%   frequencies.
% Output:
%   ampSpec - the ampliude spectrum of filteredSignal
%   f_half - the frequency vector corresponding to ampSpec
%
% [filteredSignal, _] = filterSpectrum(x, Fs, filter, [Name, Value])
%   also takes in optional configuration paramenters as name-value pairs
%
% Name-Value optional parametrs:
% Model - A fitting model object implementing the spec.models.Model 
%   abstract class. The given model is optimized using the given signal and 
%   is passed on to the filter function.
% StartPosition - A parameter set to pass to the model as a start point for
%   model optimization. This parameter is only applicable when a model is
%   also supplied.
%
% Written by TADA, HUJI 2020
%
% See also:
%   spec.filters.bandPassFilter
%   spec.filters.bandRejectFilter
%   spec.filters.bandIntensityFilter
%   spec.filters.reductionFilter
%   spec.filters.subtractionFilter
%   spec.filters.spectrumSubtractionFilter
%   spec.filters.backgroundFilter
%

    % parse optional parameters
    setup = parseConfig(varargin);
    model = setup.Model;

    % calculate aplitude spectrum
    [~, f_half, f, Y] = spec.spectrum(x, Fs);
    
    % Use column vectors
    Yc = Y(:);
    fc = f(:);
    
    % prep some meta data needed for some filters
    N = length(x) ;
    N_fastest = spec.findNFastest(N);
    
    % 
    % Spectrum modeling
    %
    if ~setup.UseOptimization
        % use a mock model when not using optimization
        model = spec.models.BlankModel(Yc);
    else
        %
        % Fit in fourier space
        %
        model = model.optimize(fc, Yc);
    end
    
    %
    % apply filter
    %
    filtY = filter(fc, Yc, model);
    
    %
    % build amplitude spectrum of the filtered signal
    %
    ampSpec = spec.fft2ampSpec(filtY, N, N_fastest);
    
    % generate filtered signal using inverse fourier transform 
    filteredSignal = ifft(filtY) ;
    imFiltSignal = max(imag(filteredSignal)) ;
    
    % validate filtered signal
    % if we messed uo the signal with one of the filters, it will most
    % likely come back as a complex number
    if imFiltSignal ~= 0
        warning('spec:filterSpectrum:ImaginaryNonZero', 'imaginary part of the new signal should be zero: %d', imFiltSignal);
        filteredSignal = real(filteredSignal);
    end
end

function setup = parseConfig(args)
    parser = inputParser();
    parser.FunctionName = 'spec.filterSpectrum';
    parser.CaseSensitive = false;
    
    parser.addOptional('Model', spec.models.BlankModel.empty(), ...
        @(m) assert(isa(m, 'spec.models.Model') && ~isempty(m), ...
                    'Model must implement spec.models.Model'));
    parser.addOptional('StartPosition', []);
                
    parser.parse(args{:});
    
    setup = parser.Results;
    setup.UseOptimization = ~isempty(setup.Model);
    if ~isempty(setup.StartPosition)
        setup.Model.StartPosition = setup.StartPosition;
    end
end