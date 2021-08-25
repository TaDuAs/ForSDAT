classdef LongWaveAdjustTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    properties
        adjuster = [];
    end
    
    methods % factory meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            
            %adjuster, xChannel, yChannel, segment, shouldAdjustOriginalData, shouldAffectOriginalData, outputXChannel, outputYChannel
            ctorParams = {...
                'adjuster', ...
                'xChannel', 'yChannel', 'segment'};
            defaultValues = {...
                'adjuster', [], ...
                'yChannel', [], ...
                'segment', []};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Oscillatory Baseline Adjuster';
        end
        
        function fieldIds = getGeneratedFields(this)
            fieldIds = ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.Miscellaneous, 'Fourier');
        end
        
        function this = LongWaveAdjustTask(adjuster, xChannel, yChannel, segment)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.adjuster = adjuster;
        end
        
        function init(this, settings)
            init@ForSDAT.Core.Tasks.PipelineDATask(this, settings);
            
            if ismethod(this.adjuster, 'init')
                this.adjuster.init(settings);
            end
        end
        
        function data = process(this, data)
            
            if ~isempty(this.adjuster.fitToSegmentId)
                fitSegData = this.getChannelData(data, this.adjuster.fitToSegmentId);
            else
                fitSegData = struct('Distance', this.getChannelData(data, 'x'), 'Force', this.getChannelData(data, 'y'));
            end
%             fixThisSegData = this.getChannelData(this.adjuster.fixSegmentId);
            
            k = data.Cantilever.springConstant;
            [f, waveFit, waveVector, waveVectorShift] = this.adjuster.adjust(this.getChannelData(data, 'y'), this.getChannelData(data, 'x'), fitSegData.Force, fitSegData.Distance, k);
            
            data.Force = f;
            data.Fourier.fit = waveFit;
            data.Fourier.vector = waveVector;
            data.Fourier.shift = waveVectorShift;
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            % If derived class doesn't implement this
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            
            hold on;
            
            plotFlags = this.getPlotFlags(extras, 4);
            
            if plotFlags(2)
                plot(data.retract.Distance, data.retract.Force - data.retract.Force(1) + data.Force(1), 'LineStyle', '-', 'LineWidth', 1, 'Color', rgb('Silver'));
            end
            if plotFlags(3)
                plot(data.extend.Distance, data.extend.Force - data.retract.Force(1) + data.Force(1), 'LineStyle', '-', 'LineWidth', 1, 'Color', rgb('Red'));
            end
            if plotFlags(4)
                plot(data.retract.Distance, data.Fourier.vector + data.Fourier.shift, 'LineStyle', '-', 'LineWidth', 2, 'Color', rgb('Gold'));
            end
            
            hold off;
        end
        
    end
    
end

