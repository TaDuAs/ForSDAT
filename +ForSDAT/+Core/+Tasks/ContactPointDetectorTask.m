classdef ContactPointDetectorTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %CONTACTPOINTDETECTORTASK Summary of this class goes here
    %   Detailed explanation goes here
        
    properties
        detector = [];
        shouldEstimateCantileverSpringConstant = false;
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'detector', 'xChannel', 'yChannel', 'segment', 'shouldEstimateCantileverSpringConstant'};
            defaultValues = {'detector', ForSDAT.Core.Contact.ContactPointDetector.empty(),...
                'xChannel', '', 'yChannel', '', 'segment', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Contact Point Detector';
        end
        
        function this = ContactPointDetectorTask(detector, xChannel, yChannel, segment, shouldEstimateCantileverSpringConstant)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.detector = detector;
            
            if exist('shouldEstimateCantileverSpringConstant', 'var') &&...
               ~isempty(shouldEstimateCantileverSpringConstant)
                this.shouldEstimateCantileverSpringConstant = shouldEstimateCantileverSpringConstant;
            end
        end
        
        function init(this, settings)
            if ismethod(this.detector, 'init')
                this.detector.init(settings);
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            
            [contact, ~, coefficients, s, mu] = this.detector.detect(x, y);
            
            data.Contact.i = find(x >= contact, 1, 'first');
            data.Contact.value = contact;
            data.Contact.coeff = coefficients;
            data.Contact.s = s;
            data.Contact.mu = mu;
            data.(this.xChannel) = x - contact;
            if this.shouldEstimateCantileverSpringConstant &&...
               (~isempty(coefficients ) && coefficients(1) ~= 0)
                data.Cantilever.springConstant = -coefficients(1);
                data.Cantilever.springConstantEstimated = true;
            end
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            
            if mvvm.getobj(extras, 'showOriginalData', false)
                dst = this.getOriginalChannelData(data, 'x');
                frc = this.getOriginalChannelData(data, 'y');
                baseline = zeros(1, length(dst)) + data.Baseline.value;
                contact = [data.Contact.value, data.Baseline.value];
            else
                dst = this.getChannelData(data, 'x');
                frc = this.getChannelData(data, 'y');
                baseline = zeros(1, length(dst));
                contact = [0, 0];
            end
            
            [x, y] = this.detector.getXYSegment(dst, frc);
            
            hold on;
            
            
            plotFlags = this.getPlotFlags(extras, 5);
            
            if plotFlags(2)
                plot(x, y, 'LineStyle', '-', 'Color', rgb('Red'), 'LineWidth', 2);
            end
            if plotFlags(3)
                plot(dst, baseline, 'k', 'LineWidth', 1);
            end
            if plotFlags(4)
                plot(dst, polyval([data.Contact.coeff(1), 0], dst), 'Color', rgb('Gold'), 'LineWidth', 1);
            end
            if plotFlags(5)
                plot(contact(1), contact(2), 'og', 'MarkerFaceColor', 'g');
            end
            
            hold off;
        end
    end
    
end

