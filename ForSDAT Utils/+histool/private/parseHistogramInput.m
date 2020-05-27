function opt = parseHistogramInput(args, functionName)
% Parses the input to histool histogram plotting and calculation 
% functions.

    if numel(args) == 1 && isstruct(args{1})
        opt = args{1};
        return;
    end

    parser = inputParser();
    parser.FunctionName = functionName;
    parser.CaseSensitive = false;
    
    % Histogram generation options
    parser.addOptional('BinningMethod', 'fd', @validateBinningMethod);
    parser.addOptional('MinimalBins', 0, @gen.valid.mustBeFinitePositiveRealScalar);
    
    % Distribution fitting options
    parser.addOptional('Model', '', ...
        @(m) assert(isa(m, 'histool.fit.IHistogramFitter') || gen.isSingleString(m),...
                    'Model must be a name of a fittable probability distribution or an instance of histool.fit.IHistogramFitter'));
    parser.addOptional('ModelParams', {});
    
    % Plotting options
    parser.addOptional('PlotTo', [], ...
        @(h) assert(isnumeric(h) || isa(h, 'matlab.ui.Figure') || isa(h, 'matlab.graphics.axis.Axes') || isa(options.PlotTo, 'matlab.ui.control.UIAxes'),...
                    'PlotTo must be a valid figure or axes object'));
    parser.addOptional('ShowMPV', false, ...
        @(tf) assert(islogical(tf) && isscalar(tf), 'ShowMPV must be a logical scalar'));
    parser.addOptional('ShowSTD', false, ...
        @(tf) assert(islogical(tf) && isscalar(tf), 'ShowSTD must be a logical scalar'));
    parser.addOptional('PlotPdfIndex', [], ...
        @(idx) assert(islogical(idx) || isnumeric(idx), 'PlotPdfIndex must be a logical or numeric index'));
                
    parser.parse(args{:});
    
    opt = parser.Results;
    
    if gen.isSingleString(opt.Model) && ~strcmp(opt.Model, '')
        opt.Model = buildModel(opt);
    end
end