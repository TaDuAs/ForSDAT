classdef AdhesionEnergyTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    properties
        detector;
        rupturesChannel = 'Rupture';
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'detector', 'xChannel', 'yChannel', 'segment'};
            defaultValues = {'detector', ForSDAT.Core.Adhesion.AdhesionEnergyDetector.empty(),...
                'xChannel', '', 'yChannel', '', 'segment', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Adhesion Energy';
        end
        
        function this = AdhesionEnergyTask(detector, xChannel, yChannel, segment)
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
            ruptureDist = this.getRuptureDistances(data);
            
            [adhEnergy, units] = this.detector.detect(z, f, ruptureDist);
            
            data.AdhesionEnergy.Value = adhEnergy;
            data.AdhesionEnergy.Units = units;
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            plotFlags = Simple.getobj(extras, 'plotFlags', [true, true]);
            
            hold on;
            
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            ruptureDist = this.getRuptureDistances(data);
            areaMask = y < 0 & this.detector.getBoundsMask(x, y, ruptureDist);
            
            % plot curve picking analysis
            if plotFlags(2)
                area(x(areaMask), y(areaMask), 'LineStyle', 'none', 'FaceAlpha', 0.3, 'ShowBaseLine', 'off');
            end 
            
            hold off;
        end
        
        function ruptureDist = getRuptureDistances(this, data)
            ruptures = this.getChannelData(data, this.rupturesChannel, false);
            if ~isempty(ruptures)
                ruptureDist = ruptures.distance;
            else
                ruptureDist = 0;
            end
        end
        
        function init(this, settings)
            if ismethod(this.detector, 'init')
                this.detector.init(settings);
            end
        end
    end
end

