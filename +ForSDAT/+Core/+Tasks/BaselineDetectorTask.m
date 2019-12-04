classdef BaselineDetectorTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %BASELINEDETECTORTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        detector = [];
        baselineOffsetFactorMultiplier;
        applyToYChannels = {};
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'detector', 'baselineOffsetFactorMultiplier', 'xChannel', 'yChannel', 'segment', 'applyToYChannels'};
            defaultValues = {...
                'detector', ForSDAT.Core.Baseline.BaselineDetector.empty(), ...
                'baselineOffsetFactorMultiplier', [], ...
                'xChannel', '', 'yChannel', '', 'segment', '', ...
                'applyToYChannels', {}};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Baseline';
        end
        
        function this = BaselineDetectorTask(detector, baselineOffsetFactorMultiplier, xChannel, yChannel, segment, applyToYChannels)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            
            if nargin >= 1
                this.detector = detector;
            end
            
            if nargin >= 2
                this.baselineOffsetFactorMultiplier = baselineOffsetFactorMultiplier;
            end
            
            if exist('applyToYChannels', 'var')
                this.applyToYChannels = applyToYChannels;
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            
            [baseline, ~, noiseAmp, coefficients, s, mu] = this.detector.detect(x, y);
            
            data.Baseline.value = baseline;
            data.Baseline.coeff = coefficients;
            data.Baseline.s = s;
            data.Baseline.mu = mu;
            data.NoiseAmplitude = noiseAmp;
            data.BaselineOffsetFactor = this.baselineOffsetFactorMultiplier * noiseAmp;
            
            if this.detector.isBaselineTilted
                deltaBsl = polyval(coefficients, x);
            else
                deltaBsl = baseline;
            end
            data.(this.yChannel) = y - deltaBsl;
            for ich = 1:length(this.applyToYChannels)
                currChannel = this.applyToYChannels{ich};
                
                % this will validate the channel, if the channel is
                % misspelled or something will give a proper exception
                currChannelData = this.getChannelData(data, currChannel);
                
                % update channel data
                data.(currChannel) = currChannelData - deltaBsl;
            end
        end
        
        function init(this, settings)
            if ismethod(this.detector, 'init')
                this.detector.init(settings);
            end
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            
            hold on;
            
            if Simple.getobj(extras, 'showOriginalData', false)
                x = this.getOriginalChannelData(data, 'x');
                baseline = zeros(1, length(x)) + data.Baseline.value;
            else
                x = this.getChannelData(data, 'x');
                baseline = zeros(1, length(x));
            end
            
            plotFlags = this.getPlotFlags(extras, 4);
            if plotFlags(2)
                plot(x, baseline, 'k', 'LineWidth', 2);
            end
            
            if plotFlags(3)
                plot(x, baseline + data.NoiseAmplitude, 'Color', rgb('Red'), 'LineWidth', 2, 'LineStyle', '--');
                plot(x, baseline - data.NoiseAmplitude, 'Color', rgb('Red'), 'LineWidth', 2, 'LineStyle', '--');
            end
            
            if plotFlags(4)
                plot(x, baseline - data.BaselineOffsetFactor, 'Color', rgb('ForestGreen'), 'LineWidth', 2, 'LineStyle', ':');
            end
            hold off;
        end
    end
    
end

