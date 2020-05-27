function [statData, h] = histdist(varargin)
% histool.histdist plots a histogram and does some statistical analysis
%
% [statData, h] = histdist(x)
%   generates a freedman–diaconis histogram for the specified data set
% Input:
%   x - data set
% Output: 
%   statData - histogram analysis data object (histool.HistStatData)
%   h - a vector of graphical handles of all plotted graphs
%
% [___] = histdist(x, Name, Value)
%   also takes in additional options specified as one or more Name-Value
%   pairs.
% 
% [___] = histdist(ax, ___)
%   also takes in an axes or uiaxes object to plot into
% Input:
%   ax - axes or uiaxes object to plot into
%
% [___] = histdist(fig, ___)
%   also takes in a figure or uifigure object to plot into
% Input:
%   fig - figure or uifigure object to plot into. If no axes/uiaxes object
%         populates the specified figure, one is created within the figure.
% 
% Name-Value Arguments
%   BinningMethod - Specifies the method to use for determining the number
%                   histogram bins or the bin width to use.
%                   see histool.calcNBins for details. Default = 'freedman–diaconis'
%   MinimalBins   - Numeric scalar representing the minimal number of bins
%                   to calculate. Default = 0
%   Model - The distribution to fit to the data or a fitter object
%           implementing histool.fit.IHistogramFitter.
%           Supported values:
%               any fittable distribution supported by fitdist using histool.fit.BuiltinDistributionFitter
%               'gauss' - a gaussian series of order 1 using histool.fit.MultiModalGaussFitter
%               'gaussN' ('gauss1'..'gauss8') - a gaussian series of order N using histool.fit.MultiModalGaussFitter
%               an object which implements the histool.fit.IHistogramFitter abstract class
%         * When a model is passed into histool.histdist, the fit
%           distribution is also plotted in top of the histogram.
%   ModelParams - a cell array of variables to pass to the fitter when it
%                 is constructed. use this when specifying the model name.
%                 For 'gauss'/'gaussN' models see list of histool.fit.MultiModalGaussFitter properties
%                 For builtin matlab distributions see list of histool.fit.BuiltinDistributionFitter properties
%   PlotTo - UI element to plot into (accepts axes, uiaxes, figure, uifigure, figure id)
%            same as specifying the axes/figure using the first variable:
%            histdist(ax, ___)
%            histdist(fig, ___)
%            also supports numeric figure id which is not supported by the
%            first variable overloads
%   ShowMPV - A logical scalar which determines wheter to plot the most
%             probable/prevalent value (mode) on top of the plotted 
%             histogram. Only applicable when a model is specifeid.
%   ShowSTD - A logical scalar which determines wheter to plot the standard 
%             deviation on top of the plotted histogram as two vertical
%             lines. Only applicable when a model is specifeid.
%   plotPdfIndex - The linear/logical indices of the distribution functions
%                  to plot from those calculated by the model.
%
% Author - TADA, 2020
% 
% See also
% histool.stats
% histool.mode
% histool.calcNBins
% histool.supportedBinningMethods
%

    if isa(varargin{1}, 'matlab.ui.container.CanvasContainer')
        % first element is a ui element to plot into, so the second element
        % is the data vector
        x = varargin{2};
        args = [{'PlotTo', varargin{1}}, varargin(3:end)];
    else
        % first element is the data vector
        x = varargin{1};
        args = varargin(2:end);
    end
    
    options = parseHistogramInput(args, 'histool.histdist');
    N = numel(x); % sample size
    
    % calculate histogram details and statistics
    statData = histool.stats(x, options);
    
    % get axes to plot to
    ax = getAxes(options.PlotTo);
    
    % plot the histogram
    h(1) = histogram(ax, x(:), statData.BinEdges);
    
    % plot the distribution fit
    if statData.HasDistribution
        % prepare pdfs for plotting
        if iscell(statData.PDF)
            pdfs = statData.PDF;
        else
            pdfs = {statData.PDF};
        end
        if ~isempty(options.PlotPdfIndex)
            pdfs = pdfs(options.PlotPdfIndex);
            mus = statData.MPV(options.PlotPdfIndex);
        end
        
        % get pdf data for plotting
        if statData.IsNormalized
            [distX, distY] = execPdf(pdfs, statData.BinEdges);
        else
            [distX, distY] = normalizePdf(pdfs, statData.BinEdges, N);
        end
        
        % plot the distribution
        isHoldOn = ishold(ax);
        hold(ax, 'on');
        h(2:size(distY, 2)+1) = plot(ax, distX, distY, 'LineWidth', 2);
        
        % plot the most probable value (mode)
        if options.ShowMPV
            foo = pdfs{1};
            mu = mus(1);
            mpvY = foo(mu);
            if ~statData.IsNormalized
                mpvY = overlayPdValuesOnHistogram(mpvY, statData.BinEdges, numel(x));
            end
            
            h(numel(h)+1) = plot(ax, mu, mpvY, 'o', 'LineWidth', 2);
        end
        
        % plot the standard deviation boundaries
        if options.ShowSTD
            sig = statData.StandardDeviation(1);
            mu = statData.MPV(1);
            verticalYs = ylim(ax);
            
            h(numel(h)+1) = plot(ax, [mu-sig; mu-sig], verticalYs(:), 'k--');
            h(numel(h)+1) = plot(ax, [mu+sig; mu+sig], verticalYs(:), 'k--');
        end
        
        % switch off the hold status of the axes if it was off before
        if ~isHoldOn
            hold(ax, 'off');
        end
    end
end

function ax = getAxes(plotTo)
    if isempty(plotTo)
        ax = gca();
    elseif isnumeric(plotTo)
        % if the user sent a figure id, use classic figure and then use gca
        % to get the active axes or populate the figure with an axes object
        fig = figure(plotTo);
        ax = gca(fig);
    elseif isa(plotTo, 'matlab.graphics.axis.Axes') || isa(plotTo, 'matlab.ui.control.UIAxes')
        % if the user sent an axes or uiaxes object, use that
        ax = plotTo;
    elseif util.isUiFigure(plotTo)
        % with uifigure, try to find a uiaxes object
        ax = findobj(plotTo, 'type', 'axes');
        if isempty(ax)
            % if none exist, generate a new axes object
            ax = uiaxes(plotTo);
        else
            % use the available uiaxes from the specified figure
            ax = ax(1);
        end
    elseif isa(plotTo, 'matlab.ui.Figure')
        % with classic figure, use gca, which will generate an axes
        % object if none exist
        ax = gca(plotTo);
    else
        % this should never happen as there is validation in the
        % parsing method, so an exception was already raised
        error('This error should not occur... theres a bug in input parsing')
    end
end