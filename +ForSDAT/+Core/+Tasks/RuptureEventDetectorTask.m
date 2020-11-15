classdef RuptureEventDetectorTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %RUPTUREEVENTDETECTORTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetObservable)
        outputXChannel = '';
        ruptureDetector;
        loadingDomainDetector;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'ruptureDetector', 'xChannel', 'yChannel', 'segment', 'loadingDomainDetector'};
            defaultValues = {...
                'ruptureDetector', ForSDAT.Core.Ruptures.RuptureDetector.empty(), ...
                'xChannel', '', 'yChannel', '', 'segment', '', ...
                'loadingDomainDetector', ForSDAT.Core.Ruptures.PreviousRuptureEndLoadingDomain.empty()};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Rupture Detector';
        end
        
        function fieldIds = getGeneratedFields(this)
            fieldIds = ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.Rupture, 'Rupture');
        end
        
        function this = RuptureEventDetectorTask(ruptureDetector, xChannel, yChannel, segment, loadingDomainDetector)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.ruptureDetector = ruptureDetector;
            
            if exist('loadingDomainDetector', 'var') && ~isempty(loadingDomainDetector)
                this.loadingDomainDetector = loadingDomainDetector;
            else
                this.loadingDomainDetector = ForSDAT.Core.Ruptures.PreviousRuptureEndLoadingDomain();
            end
        end
        
        function init(this, settings)
            if ismethod(this.ruptureDetector, 'init')
                this.ruptureDetector.init(settings);
            end
            if ismethod(this.loadingDomainDetector, 'init')
                this.loadingDomainDetector.init(settings);
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            
            % Detect rupture events
            [events, derivative] = this.ruptureDetector.analyze(y, x, data.NoiseAmplitude);
            
            % Detect loading start point for each rupture event
            loadingDomainStartIndices = this.loadingDomainDetector.detect(...
                x, y, ...
                events, data.Contact.i,...
                data.BaselineOffsetFactor, data.NoiseAmplitude);
            
            % rebuild rupture index matrix as follows: [loadingStart; ruptureStart; ruptureEnd]
            lsRsRe = [loadingDomainStartIndices; events([1,2], :)];
            
            % replace distance by fixed distance if needed
            if ~isempty(this.outputXChannel)
                x = this.getChannelData(data,this.outputXChannel);
            end
            
            % Build output data struct
            data = ForSDAT.Core.Tasks.buildRuptureOutputStructure(data, 'Rupture', x, lsRsRe, events(3,:), 1:size(events, 2), derivative);
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
            
            plotFlags = mvvm.getobj(extras, 'plotFlags', [false true true true true]);
            if ~islogical(plotFlags) || length(plotFlags) ~= 5
                error('Rupture plotting is determined by the flags vector, which determines what to plot as follows [FDC, loadingStartPoint, ruptureStartPoint, ruptureEndPoint, force-derivative]');
            end
            
            if plotFlags(2)
                plot(dist(data.Rupture.i(1,:)), frc(data.Rupture.i(1,:)), 'cs', 'MarkerFaceColor', 'c', 'MarkerSize', 7);
            end
            if plotFlags(3)
                plot(dist(data.Rupture.i(2,:)), frc(data.Rupture.i(2,:)), 'gs', 'MarkerFaceColor', 'g', 'MarkerSize', 7);
            end
            if plotFlags(4)
                plot(dist(data.Rupture.i(3,:)), frc(data.Rupture.i(3,:)), 'rs', 'MarkerFaceColor', 'r', 'MarkerSize', 7);
            end

            % plot derivative
            if plotFlags(5) && exist('yyaxis')
                yyaxis right;
                plot(dist, data.Rupture.derivative);
                yyaxis left;
            end
            
            hold off;
        end
        
        function clearPlot(this, h)
            ax = sui.gca(h);
            yyaxis(ax, 'right');
            cla(ax);
            yyaxis(ax, 'left');
            cla(ax);
        end
    end
end

