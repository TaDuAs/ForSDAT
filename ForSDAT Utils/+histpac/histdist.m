function [statData, h] = histdist(varargin)
    if isa(varargin{1}, 'matlab.ui.container.CanvasContainer')
        % first element is a ui element to plot into, so the second element
        % is the data vector
        x = varargin{2};
        args = ['PlotTo', varargin{1}, varargin(3:end)];
    else
        % first element is the data vector
        x = varargin{1};
        args = varargin(2:end);
    end
    
    options = parseHistogramInput(args);
    
    % calculate histogram details and statistics
    statData = histpac.extractStatData(x, options);
    
    % get axes to plot to
    ax = getAxes(options.PlotTo);
    
    % plot the histogram
    h(1) = histogram(ax, x(:), statData.BinEdges);
    
    % plot the distribution fit
    if statData.HasDistribution
        if statData.IsNormalized
            [x, y] = execPdf(statData.PDF, statData.BinEdges);
        else
            [x, y] = normalizePdf(statData.PDF, statData.BinEdges);
        end
        
        % plot the distribution
        isHoldOn = ishold(ax);
        hold(ax, 'on');
        h(2) = plot(ax, x, y, 'LineWidth', 2);
        
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