function [h, statData] = plotHistogram(x, varargin)
    options = parseHistogramInput(varargin);
    
    % calculate histogram details and statistics
    statData = histpac.extractStatData(x, options);
    
    % get axes to plot to
    ax = getAxes(options.PlotTo);
    
    % plot the histogram
    h(1) = histogram(ax, x(:), statData.BinEdges);
    
    % plot the distribution fit
    if statData.HasDistribution
        x = bins2x(statData.BinEdges);
        y = statData.PDF(x);
        
        % plot the distribution
        h(2) = plot(ax, x, y, 'LineWidth', 2);
    end
end

function ax = getAxes(plotTo)
    if isempty(plotTo)
        ax = gca();
    else
        if isa(plotTo, 'matlab.graphics.axis.Axes') || isa(plotTo, 'matlab.ui.control.UIAxes')
            ax = plotTo;
        elseif isa(plotTo, 'matlab.ui.Figure')
            if ~matlab.ui.internal.isUIFigure(plotTo)
                ax = gca(plotTo);
            else
                ax = findobj(plotTo, 'type', 'axes');
                if isempty(ax)
                    ax = uiaxes(fig);
                else
                    ax = ax(1);
                end
            end
        else
            % this should never happen as there is validation in the
            % parsing method, so an exception was already raised
            error('This error should not occure... theres a bug in input parsing')
        end
    end
end