classdef InteractionWindowTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %INTERACTIONWINDOWTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filter;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'filter', 'xChannel', 'yChannel', 'segment'};
            defaultValues = {...
                'filter', ForSDAT.Core.Ruptures.InteractionWindowSMIFilter.empty(), ...
                'xChannel', '', 'yChannel', '', 'segment', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Interaction Window';
        end
        
        function fieldIds = getGeneratedFields(this)
            fieldIds = ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.Rupture, 'RuptureWindow');
        end
        
        function this = InteractionWindowTask(filter, xChannel, yChannel, segment)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.filter = filter;
        end
        
        function init(this, settings)
            if ismethod(this.filter, 'init')
                this.filter.init(settings);
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            
            [events, indexOfSpecificInteractionInRuptureEventsMatrix] =...
                this.filter.filter(y, x, data.Rupture.i, data.NoiseAmplitude, data.BaselineOffsetFactor);
            
            data = ForSDAT.Core.Tasks.buildRuptureOutputStructure(data, 'RuptureWindow', x,...
                events, data.Rupture.force(indexOfSpecificInteractionInRuptureEventsMatrix),...
                indexOfSpecificInteractionInRuptureEventsMatrix, data.Rupture.derivative);
            data.RuptureWindow.window = [this.filter.startAt, this.filter.endAt];
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            
            hold on;
            
            % plot rupture event start-end points
            dist = this.getChannelData(data, 'x');
            frc = this.getChannelData(data, 'y');
            
            plotFlags = mvvm.getobj(extras, 'plotFlags', [false true true true]);
            if ~islogical(plotFlags) || length(plotFlags) ~= 4
                error('Rupture plotting is determined by the flags vector, which determines what to plot as follows [FDC, ruptureStartPoint, ruptureEndPoint, interactionWindow]');
            end
            
            % Rupture start
            if plotFlags(2)
                plot(dist(data.RuptureWindow.i(1,:)), frc(data.Rupture.i(1,:)), 'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
            end
            
            % Rupture end
            if plotFlags(3)
                plot(dist(data.RuptureWindow.i(2,:)), frc(data.Rupture.i(2,:)), 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
            end
            
            % Interaction window
            if plotFlags(4)
                plot([data.RuptureWindow.window(1), data.RuptureWindow.window(1)], [max(frc) min(frc)], 'r');
                plot([data.RuptureWindow.window(2), data.RuptureWindow.window(2)], [max(frc) min(frc)], 'r');
            end

            hold off;
        end
    end
end

