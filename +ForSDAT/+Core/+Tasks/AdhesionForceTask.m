classdef AdhesionForceTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    properties
        detector;
        threshold (1,1) double = 0;
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'detector', 'xChannel', 'yChannel', 'segment'};
            defaultValues = {'detector', ForSDAT.Core.Adhesion.MaxAdhesionForceDetector.empty(),...
                'xChannel', '', 'yChannel', '', 'segment', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Adhesion Force';
        end
        
        function this = AdhesionForceTask(detector, xChannel, yChannel, segment)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.detector = detector;
        end
        
        function data = process(this, data)
            z = this.getChannelData(data, 'x');
            f = this.getChannelData(data, 'y');
            noiseAmp = data.NoiseAmplitude;
            
            [adhForce, pos] = this.detector.detect(z, f, noiseAmp);
            
            data.AdhesionForce.Value = adhForce;
            data.AdhesionForce.Position = pos;
            data.AdhesionForce.AboveThreshold = adhForce > this.threshold;
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            plotFlags = mvvm.getobj(extras, 'plotFlags', [true, true]);
            
            hold on;
            
            % plot curve picking analysis
            if plotFlags(2) && data.AdhesionForce.AboveThreshold
                scatter(data.AdhesionForce.Position, -data.AdhesionForce.Value, 'filled', 'Marker', 'o');
            end 
            
            hold off;
        end
        
        function init(this, settings)
            if ismethod(this.detector, 'init')
                this.detector.init(settings);
            end
        end
    end
end

