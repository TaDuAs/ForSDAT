classdef PipelineDATask < Simple.PipelineTask
    %PIPELINETASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        yChannel = '';
        xChannel = '';
        segment = '';
        name;
    end
    
    methods % Property accessors
        function name = get.name(this)
            name = this.getTaskName();
        end
    end
    
    methods (Abstract)
        name = getTaskName(this);
    end
    
    methods
        function this = PipelineDATask(xChannel, yChannel, segment)
            this = this@Simple.PipelineTask();
            this.xChannel = xChannel;
            this.yChannel = yChannel;
            this.segment = segment;
        end
        
        function data = process(this, data)
            % Must implement this method in derived class
            error('not implemented task');
        end
        
        function focusPlot(this, sp)
            % If derived class doesn't implement this
            if isa(sp, 'matlab.ui.Figure') || isnumeric(sp)
                figure(sp);
            elseif isa(sp, 'matlab.graphics.axis.Axes')
                subplot(sp);
            else
                throw(MException('Simple:PipelineTask:plotData:InvalidSubPlotOrFigure', 'subplot must be either a figure or an axes object'));
            end
        end
        
        function plotData(this, sp, data, extras)
            this.focusPlot(sp);
            if nargin < 4
                extras = [];
            end
            if Simple.getobj(extras, 'showOriginalData', false)
                x = this.getChannelData(data, [this.getSegment '.' this.getXChannel()]);
                y = this.getChannelData(data, [this.getSegment '.' this.getYChannel()]);
            else
                x = [];
                y = [];
            end
            if isempty(x)
                x = this.getChannelData(data, 'x');
            end
            if isempty(y)
                y = this.getChannelData(data, 'y');
            end
            plotFlags = this.getPlotFlags(extras, 1);
            if plotFlags(1)
                plot(x, y);
            end
            this.setPlotAxes(x, y);
        end
        
        function [rangeX, rangeY] = getPlotAxesBounds(this, x, y)
            deltaY = range(y)*0.075;
            rangeY = [min(y)-deltaY, max(y)+deltaY];
            deltaX = range(x)*0.015;
            rangeX = [min(x)-deltaX, max(x)+deltaX];
        end
        
        function [rangeX, rangeY] = setPlotAxes(this, x, y)
            [rangeX, rangeY] = this.getPlotAxesBounds(x, y);
            axis([rangeX rangeY]);
        end
        
        function chnl = getXChannel(this)
            chnl = this.xChannel;
        end
        
        function chnl = getYChannel(this)
            chnl = this.yChannel;
        end
        
        function segment = getSegment(this)
            segment = this.segment;
        end
        
        function chnlData = getChannelData(this, data, channel)
            channel = this.checkForXYChannels(channel);
            
            chnlData = Simple.getobj(data, channel);
            if isempty(chnlData)
                error(['Channel ' channel ' doesn''t exist']);
            end
        end
        
        function chnlData = getOriginalChannelData(this, data, channel)
            channel = this.checkForXYChannels(channel);
            chnlData = this.getChannelData(data, [this.getSegment() '.' channel]);
        end
        
        function channel = checkForXYChannels(this, channel)
            switch channel
                case 'x'
                    channel = this.getXChannel();
                case 'y'
                    channel = this.getYChannel();
            end
        end
        
        function plotFlags = getPlotFlags(this, extras, nplots)
            plotFlags = Simple.getobj(extras, 'plotFlags', true(1, nplots));
            if ~islogical(plotFlags)
                error('plotFlags parameter must be an array of booleans');
            end
            specifiedPlots = length(plotFlags);
            if specifiedPlots < nplots
                plotFlags = [plotFlags, true(1, nplots - specifiedPlots)];
            end
        end
    end
    
end

