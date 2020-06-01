classdef AdjustmentTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %ADJUSTOOMTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetObservable)
        adjuster = [];
        shouldAdjustOriginalData (1,1) logical = false;
        shouldAffectOriginalData (1,1) logical = false;
        outputYChannel = [];
        outputXChannel = [];
    end
    
    methods % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            
            %adjuster, xChannel, yChannel, segment, shouldAdjustOriginalData, shouldAffectOriginalData, outputXChannel, outputYChannel
            ctorParams = {...
                'adjuster', ...
                'xChannel', 'yChannel', 'segment', ...
                'shouldAdjustOriginalData', 'shouldAffectOriginalData', ...
                'outputXChannel', 'outputYChannel'};
            defaultValues = {...
                'adjuster', [], ...
                'yChannel', [], ...
                'segment', [],...
                'shouldAdjustOriginalData', [],...
                'shouldAffectOriginalData', [], ...
                'outputXChannel', [], ...
                'outputYChannel', []};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = this.adjuster.name;
        end
        
        function this = AdjustmentTask(adjuster, xChannel, yChannel, segment, shouldAdjustOriginalData, shouldAffectOriginalData, outputXChannel, outputYChannel)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.adjuster = adjuster;
            if exist('shouldAdjustOriginalData', 'var') && ~isempty(shouldAdjustOriginalData)
                this.shouldAdjustOriginalData = shouldAdjustOriginalData;
            end
            if exist('shouldAffectOriginalData', 'var') && ~isempty(shouldAffectOriginalData)
                this.shouldAffectOriginalData = shouldAffectOriginalData;
            end
            if exist('outputYChannel', 'var') && ~isempty(outputYChannel)
                this.outputYChannel = outputYChannel;
            else
                this.outputYChannel = this.yChannel;
            end
            if exist('outputXChannel', 'var') && ~isempty(outputXChannel)
                this.outputXChannel = outputXChannel;
            else
                this.outputXChannel = this.xChannel;
            end
        end
        
        
        function data = process(this, data)
            if this.shouldAdjustOriginalData
                [z, f] = this.adjuster.adjust(...
                    this.getOriginalChannelData(data, 'x'), this.getOriginalChannelData(data, 'y'));
            else
                [z, f] = this.adjuster.adjust(this.getChannelData(data, 'x'), this.getChannelData(data, 'y'));
            end
            
            data.(this.outputYChannel) = f;
            data.(this.outputXChannel) = z;
            
            if this.shouldAffectOriginalData
                data = mvvm.setobj(data, [this.getSegment() '.' this.xChannel], z);
                data = mvvm.setobj(data, [this.getSegment() '.' this.yChannel], f);
            end
        end
        
        function init(this, settings)
            if ismethod(this.adjuster, 'init')
                this.adjuster.init(settings);
            end
        end
    end
    
end

