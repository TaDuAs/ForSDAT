classdef SMIFilterTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor

    
    properties
        filter;
        secondaryXChannel;
        ruptureChannel;
        prefilteredRuptureChannel;
        contactChannel = 'Contact';
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'filter', 'xChannel', 'yChannel', 'segment', 'secondaryXChannel', 'ruptureChannel', 'prefilteredRuptureChannel'};
            defaultValues = {...
                'filter', ForSDAT.Core.Ruptures.SmoothingSMIFilter.empty(), ...
                'xChannel', '', 'yChannel', '', 'segment', '', ...
                'secondaryXChannel', '', 'ruptureChannel', '', 'prefilteredRuptureChannel', ''};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Specific Interaction Detector';
        end
        
        function fieldIds = getGeneratedFields(this)
            fieldIds = [...
                ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.SMI, 'SingleInteraction'),...
                ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.DecisionFlag, 'SmiDecision')];
        end
        
        function this = SMIFilterTask(filter, xChannel, yChannel, segment, secondaryXChannel, ruptureChannel, prefilteredRuptureChannel)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.filter = filter;
            if nargin >= 4 && ~isempty(secondaryXChannel)
                this.secondaryXChannel = secondaryXChannel;
            else
                this.secondaryXChannel = xChannel;
            end
            
            if exist('ruptureChannel', 'var') && ~isempty(ruptureChannel)
                this.ruptureChannel = ruptureChannel;
            else
                this.ruptureChannel = 'Rupture';
            end
            
            if exist('prefilteredRuptureChannel', 'var') && ~isempty(prefilteredRuptureChannel)
                this.prefilteredRuptureChannel = prefilteredRuptureChannel;
            end
        end
        
        function init(this, settings)
            init@ForSDAT.Core.Tasks.PipelineDATask(this, settings);

            if ismethod(this.filter, 'init')
                this.filter.init(settings);
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            secX = this.getChannelData(data, this.secondaryXChannel);
            rupt = this.getChannelData(data, this.ruptureChannel);
            if ~isempty(this.prefilteredRuptureChannel)
                filteredRupturesStruct = this.getChannelData(data, this.prefilteredRuptureChannel);
                filteredRuptures = filteredRupturesStruct.i;
            else
                filteredRuptures = [];
            end
            
            modeledItems = struct();
            modeledItems.func = util.matex.Zero.empty(1,0);
            for i = 1:size(rupt.i, 2)
                modeledItems.func(i) = util.matex.Zero();
            end
            for i = 1:length(data.ChainFit.originalRuptureIndex)
                j = data.ChainFit.originalRuptureIndex(i);
                modeledItems.func(j) = data.ChainFit.func(i);
            end
            modeledItems.ruptureForce = zeros(1, size(rupt.i, 2));
            modeledItems.ruptureForce(data.ChainFit.originalRuptureIndex) = data.ChainFit.ruptureForce;
            
            contactInfo = this.getChannelData(data, this.contactChannel);
            
            [lsRsRe, i] = this.filter.filter(y, x, secX,...
                [rupt.i; rupt.originalRuptureIndex],...
                filteredRuptures,...
                data.NoiseAmplitude,...
                data.BaselineOffsetFactor,...
                modeledItems.func,...
                modeledItems.ruptureForce,...
                contactInfo.coeff(1));
            
            singleInteraction = struct();
            singleInteraction.didDetect = ~isempty(i);
            if singleInteraction.didDetect
                singleInteraction.i = lsRsRe(1:3,:);
                singleInteraction.detectedRuptureIndex = i;
                originalRuptIndex = rupt.originalRuptureIndex(i);
                chainFitI = find(data.ChainFit.originalRuptureIndex == originalRuptIndex);
                singleInteraction.measuredForce = rupt.force(i);
                singleInteraction.modeledForce = data.ChainFit.ruptureForce(chainFitI);
                singleInteraction.ruptureDistance = x(rupt.i(2, i));
                singleInteraction.slope = data.ChainFit.slope(chainFitI);
                singleInteraction.apparentLoadingRate = data.ChainFit.apparentLoadingRate(chainFitI);
            else
                singleInteraction.i = zeros(4,0);
                singleInteraction.detectedRuptureIndex = [];
                singleInteraction.measuredForce = [];
                singleInteraction.modeledForce = [];
                singleInteraction.ruptureDistance = [];
                singleInteraction.slope = [];
                singleInteraction.apparentLoadingRate = [];
            end
            data.SingleInteraction = singleInteraction;
            data.SmiDecision = struct();
            data.SmiDecision.Flag = singleInteraction.didDetect;
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            plotFlags = mvvm.getobj(extras, 'plotFlags', [false, true, true, false, false, true], 'nowarn');
            if length(plotFlags) == 5
                plotFlags = [plotFlags true];
            end
            if ~islogical(plotFlags) || length(plotFlags) ~= 6
                error('SMI-Filter plotting is determined by the flags column vector, which determines what to plot as follows [FDC, measuredForce, modeledForce, analysisDetails, interactionWindow]');
            end
            hold on;
            
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            secX = this.getChannelData(data, this.secondaryXChannel);
            rupt = this.getChannelData(data, this.ruptureChannel);
            if ~isempty(this.prefilteredRuptureChannel)
                filteredRuptures = this.getChannelData(data, this.prefilteredRuptureChannel);
                filteredRuptures = filteredRuptures.i;
            else
                filteredRuptures = [];
            end
            
            % plot SMI rupture force
            if data.SingleInteraction.didDetect
                % plot measured force
                if plotFlags(2)
                    plot(x(data.SingleInteraction.i(2)), -data.SingleInteraction.measuredForce, 'v', 'MarkerEdgeColor', 'b', 'MarkerFaceColor', 'b', 'MarkerSize', 6);
                end
                
                % Plot modeled force
                if plotFlags(3) 
                    plot(x(data.SingleInteraction.i(2)), -data.SingleInteraction.modeledForce, 'v', 'MarkerEdgeColor', 'g', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
                    xi = x(data.Contact.i:data.SingleInteraction.i(2));
                    funci = data.ChainFit.func(data.SingleInteraction.detectedRuptureIndex);
                    plot(xi, funci.invoke(xi), 'LineStyle', '-', 'Color', 'r', 'LineWidth', 2);
                end
            end
            
            % plot curve picking analysis
            if ~data.SingleInteraction.didDetect || plotFlags(4)
                this.filter.plotAnalysis(y, x, secX,...
                    rupt.i,...
                    filteredRuptures,...
                    data.NoiseAmplitude,...
                    data.BaselineOffsetFactor,...
                    data.ChainFit.func,...
                    data.Contact.coeff(1),...
                    mvvm.getobj(extras, 'plotAreas', [], 'nowarn'));
            end 
            
            % Plot interaction window
            if isfield(data, 'RuptureWindow') && (plotFlags(5) || (~data.SingleInteraction.didDetect && plotFlags(6)))
                plot([data.RuptureWindow.window(1), data.RuptureWindow.window(1)], [max(y) min(y)], 'r');
                plot([data.RuptureWindow.window(2), data.RuptureWindow.window(2)], [max(y) min(y)], 'r');
            end
            
            hold off;
        end
    end
    
end

