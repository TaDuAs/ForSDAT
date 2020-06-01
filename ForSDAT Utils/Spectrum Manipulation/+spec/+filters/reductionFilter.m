function filter = reductionFilter(intensity, varargin)
% reductionFilter() generates a filter function handle that reduces the  
% intensity of model or filter generated data from within y data.
%   
% filter = reductionFilter() - returns the reduction filter which
%   expects a model to generate data to subtract from the signal.
%
% filter = subtractionFilter([Name, Value]) - Optional input configuration
%   specified as Name-Value pairs of parameters
%
% Name-Value parameters:
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
% spec.filters.subtractionFilter
% spec.filters.backgroundFilter
% spec.filters.bandPassFilter
% spec.filters.bandRejectFilter
% spec.filters.bandIntensityFilter
%

    setup = parseConfig(varargin);
    assert(isscalar(intensity) && intensity > 0 && intensity < 1, 'Intensity must be a positive scalar between 0 and 1');
    
    function fixedSignal = subtractionFilterFunction(x, y, model)
        if isa(model, 'spec.models.Model')
            fixedSignal = y - intensity*model.calc(x);
        else
            spec.filters.validateFilterFunction(model, 2, ...
                'subtractionFilter filter function expects either a model which implements spec.models.Model, or a filter function handle with the signature: function fixed = filter(x,y)');
            fixedSignal = y - intensity*model(x, y);
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
    parser.FunctionName = 'spec.filters.reductionFilter';
    parser.CaseSensitive = false;
    
    parser.addOptional('Filter', function_handle.empty(), ...
        @(f) spec.filters.validateFilterFunction(f, 2, ...
                    'Filter must b a function handle with the signature function fixedSignal = filter(x, y)'));
                
    parser.parse(args{:});
    
    setup = parser.Results;
end