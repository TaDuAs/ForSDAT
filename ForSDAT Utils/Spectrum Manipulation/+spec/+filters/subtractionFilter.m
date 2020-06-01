function filter = subtractionFilter(varargin)
% subtractionFilter() generates a filter function handle that subtracts 
% model or filter generated data from the y signal.
% filter signature:
%   
% filter = subtractionFilter() - returns the subtraction filter which
%   expects a model to generate data to subtract from the signal.
%
% filter = subtractionFilter([Name, Value]) - Optional input configuration
%   specified as Name-Value pairs of parameters
%
% Name-Value parameters:
%
% SignComp: Sign compensation strategy - a method for compensating for
%           values that change sign due to the subtraction.
%           * Absolute compensation: will change to the absolute value
%             ("abs", "absolute")
%           * Inversion compensation: will invert values with inverted sign
%             back to their original sign ("inver", "-")
%           * Zero compensation: will replace values with inverted sign by 
%             zero (zero", "0")
%           If no strategy is specified, or if sent an empty string, no
%           compensation will be used and the values will remain inverted
%           in sign
% 
% Filter:   A filter function handle to use instead of the default model 
%           supplied by filterSpectrum.
%           The filter function should have the signature
%           function fixedSignal = filter(x, y)
%
% Written by TADA, HUJI 2020
% 
% see also:
% spec.filterSpectrum
% spec.filters.reductionFilter
% spec.filters.backgroundFilter
% spec.filters.bandPassFilter
% spec.filters.bandRejectFilter
% spec.filters.bandIntensityFilter
%

    setup = parseConfig(varargin);
    
    signComp = setup.SignComp;
    signCompStrategies = signCompensationStrategies(false);
    
    function fixedSignal = subtractionFilterFunction(x, y, model)
        if isa(model, 'spec.models.Model')
            fixedSignal = y - model.calc(x);
        else
            spec.filters.validateFilterFunction(model, 2,...
                'subtractionFilter filter function expects either a model which implements spec.models.Model, or a filter function handle with the signature: function fixed = filter(x,y)');
            fixedSignal = y - model(x, y);
        end
        
        if ~isempty(signComp)
            realInvertMask = sign(real(fixedSignal)) ~= sign(real(y(:)));
            imagInvertMask = signIm(fixedSignal) ~= signIm(y(:));
            switch lower(char(signComp))
                case signCompStrategies.abs
                    fixedSignal(invertMask) = abs(fixedSignal(invertMask));
                case signCompStrategies.zero
                    fixedSignal(realInvertMask) = imag(fixedSignal(realInvertMask))*1i;
                    fixedSignal(imagInvertMask) = real(fixedSignal(imagInvertMask));
                case signCompStrategies.invert
                    fixedSignal(realInvertMask) = -conj(fixedSignal(realInvertMask));
                    fixedSignal(imagInvertMask) = conj(fixedSignal(imagInvertMask));
            end
        end
    end
    
    if isempty(setup.Filter)
        filter = @subtractionFilterFunction;
    else
        filter = spec.filters.wraperFilter(@subtractionFilterFunction, setup.Filter);
    end
end

function setup = parseConfig(args)
% Parses the input to reductionFilter function into reduction filter
% configuration. This will allow further configurations to be added in the
% future without having to do a thorough refactor

    parser = inputParser();
    parser.FunctionName = 'spec.filters.subtractionFilter';
    parser.CaseSensitive = false;
    
    signCompStrategies = signCompensationStrategies(true);
    parser.addOptional('SignComp', '', ...
        @(s) assert(ismember(s, [{''}, signCompStrategies]), ...
                    'SignComp only accepts values of {''%s''}', strjoin(signCompStrategies, ''', ''')));
    parser.addOptional('Filter', function_handle.empty(), ...
        @(f) spec.filters.validateFilterFunction(f, 2, ...
                    'Filter must b a function handle with the signature function fixedSignal = filter(x, y)'));
                
    parser.parse(args{:});
    
    setup = parser.Results;
end

function strategies = signCompensationStrategies(asList)
% Generate list of supported startegies (as keys) for compensating inverted
% values caused by subtraction.
%
% Input:
% asList - a logical scalar flag determining whether to return as struct of
%          startegy keys or as a full list of supported keys representing
%          strategies

    s = struct('abs', {{'abs', 'absolute'}}, 'zero', {{'zero', '0'}}, 'invert', {{'invert', '-'}});
    if asList
        strategies = {};
        strategyFields = fieldnames(s);
        for field = strategyFields(:)'
            curr = s.(field{1});
            strategies = [strategies curr];
        end
    else
        strategies = s;
    end
end