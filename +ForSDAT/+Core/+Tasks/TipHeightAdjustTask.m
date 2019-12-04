classdef TipHeightAdjustTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %TIPHEIGHTADJUSTTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        adjuster = [];
        shouldEstimateCantileverSpringConstant = false;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'adjuster', 'shouldEstimateCantileverSpringConstant', 'xChannel', 'yChannel', 'segment'};
            defaultValues = {...
                'adjuster', ForSDAT.Core.Adjusters.TipHeightAdjuster.empty(), ...
                'shouldEstimateCantileverSpringConstant', false, ...
                'xChannel', '', 'yChannel', '', 'segment', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Tip Height Adjuster';
        end
        
        function this = TipHeightAdjustTask(adjuster, shouldEstimateCantileverSpringConstant, xChannel, yChannel, segment)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.adjuster = adjuster;
            this.shouldEstimateCantileverSpringConstant = shouldEstimateCantileverSpringConstant;
        end
        
        function init(this, settings)
            if ismethod(this.adjuster, 'init')
                this.adjuster.init(settings);
            end
        end
        
        function data = process(this, data)
            z = this.getChannelData(data, 'x');
            f = this.getChannelData(data, 'y');
            k = data.Cantilever.springConstant;
            [z, ~] = this.adjuster.adjust(z, f, k, data.Cantilever.springConstantEstimated);
            
            data.FixedDistance = z;
        end
        
        function plotData(this, fig, data, extras)
            % If derived class doesn't implement this
            figure(fig);
            plot(data.FixedDistance, data.Force);
            this.setPlotAxes(data.FixedDistance, data.Force);
        end
    end
    
end

