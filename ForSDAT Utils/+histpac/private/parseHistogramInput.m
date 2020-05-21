function opt = parseHistogramInput(args)
% Parses the input to histpac histogram plotting and calculation 
% functions.

    if numel(args) == 1 && isstruct(args{1})
        opt = args{1};
        return;
    end

    parser = inputParser();
    parser.FunctionName = 'histpac.calcHistogram';
    parser.CaseSensitive = false;
    
    % Histogram generation options
    parser.addOptional('BinningMethod', 'fd', @validateBinningMethod);
    parser.addOptional('MinimalBins', 0, @gen.valid.mustBeFinitePositiveRealScalar);
    
    % Distribution fitting options
    parser.addOptional('Model', '', ...
        @(m) assert(isa(m, 'histpac.fit.IHistogramFitter') || gen.isSingleString(m),...
                    'Model must be a name of a fittable probability distribution or an instance of histpac.fit.IHistogramFitter'));
    parser.addOptional('ModelParams', {});
    
    % Plotting options
    parser.addOptional('PlotTo', [], ...
        @(h) assert(isnumeric(h) || isa(h, 'matlab.ui.Figure') || isa(h, 'matlab.graphics.axis.Axes') || isa(options.PlotTo, 'matlab.ui.control.UIAxes'),...
                    'PlotTo must be a valid figure or axes object'));
                
    parser.parse(args{:});
    
    opt = parser.Results;
    
    if gen.isSingleString(opt.Model)
        opt.Model = buildModel(opt);
    end
end