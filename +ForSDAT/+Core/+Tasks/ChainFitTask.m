classdef ChainFitTask < ForSDAT.Core.Tasks.PipelineDATask & mfc.IDescriptor
    %CHAINFITTASK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        chainFitter;
        smoothingAdjuster = [];
        plotChainfitFromContactPoint = false;
        ruptureChannel = 'Rupture';
        fitAllAtOnce = false;
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'chainFitter', 'smoothingAdjuster', 'xChannel', 'yChannel', 'segment', 'ruptureChannel', 'plotChainfitFromContactPoint'};
            defaultValues = {...
                'chainFitter', ForSDAT.Core.Ruptures.WLCLoadFitter.empty(), ...
                'smoothingAdjuster', ForSDAT.Core.Adjusters.DataSmoothingAdjuster.empty(), ...
                'xChannel', '', 'yChannel', '', 'segment', '', 'ruptureChannel', '',...
                'plotChainfitFromContactPoint', false};
        end
    end
    
    methods
        function name = getTaskName(this)
            name = 'Chain Fit';
        end
        
        function fieldIds = getGeneratedFields(this)
            fieldIds = ForSDAT.Core.Fields.FieldID(ForSDAT.Core.Fields.FieldType.Model, 'ChainFit');
        end
        
        function this = ChainFitTask(chainFitter, smoothingAdjuster, xChannel, yChannel, segment, ruptureChannel, plotChainfitFromContactPoint)
            if ~exist('xChannel', 'var') || isempty(xChannel)
                xChannel = 'Distance';
            end
            if ~exist('yChannel', 'var') || isempty(yChannel)
                yChannel = 'Force';
            end
            this = this@ForSDAT.Core.Tasks.PipelineDATask(xChannel, yChannel, segment);
            this.chainFitter = chainFitter;
            if exist('smoothingAdjuster', 'var')
                this.smoothingAdjuster = smoothingAdjuster;
            end
            if exist('plotChainfitFromContactPoint', 'var') && ~isempty(plotChainfitFromContactPoint)
                this.plotChainfitFromContactPoint = plotChainfitFromContactPoint;
            end
            if exist('ruptureChannel', 'var') && ~isempty(ruptureChannel)
                this.ruptureChannel = ruptureChannel;
            end
        end
        
        function init(this, settings)
            init@ForSDAT.Core.Tasks.PipelineDATask(this, settings);
            
            if ismethod(this.chainFitter, 'init')
                this.chainFitter.init(settings);
            end
        end
        
        function data = process(this, data)
            x = this.getChannelData(data, 'x');
            y = this.getChannelData(data, 'y');
            if ~isempty(this.smoothingAdjuster)
                [~, y] = this.smoothingAdjuster.adjust(x, y);
            end
            rupt = this.getChannelData(data, this.ruptureChannel);
            
            nRuptures = size(rupt.i, 2);
            chainFitStruct = [];
            chainFitStruct.i = rupt.i([1,2], :);
            chainFitStruct.func = util.matex.Zero.empty(1, 0);
            chainFitStruct.ruptureForce = zeros(1, nRuptures);
            chainFitStruct.slope = zeros(1, nRuptures);
            chainFitStruct.apparentLoadingRate = zeros(1, nRuptures);
            chainFitStruct.originalRuptureIndex = rupt.originalRuptureIndex;
            
            if this.fitAllAtOnce
                chainFitStruct.func = this.chainFitter.fitAll(x, y, rupt.i(2, :));
                chainFitStruct.ruptureForce = zeros(1, nRuptures);
                chainFitStruct.slope = zeros(1, nRuptures);
                chainFitStruct.apparentLoadingRate = zeros(1, nRuptures);

                % calculate stuff
                for i = 1:nRuptures
                    rupturePoint = chainFitStruct.i(2, i);
                    func = chainFitStruct.func(i);
                    derivative = func.derive();
                    slope = derivative.invoke(x(rupturePoint));

                    % Save data
                    chainFitStruct.ruptureForce(i) = -func.invoke(-x(rupturePoint));
                    chainFitStruct.slope(i) = slope;
                    chainFitStruct.apparentLoadingRate(i) = -slope * data.Setup.retractSpeed;
                end
            else
                % fit ruptures one by one
                for i = 1:nRuptures
                    % prepare loading domain
                    xi = util.croparr(x, chainFitStruct.i(:, i)'); 
                    yi = util.croparr(y, chainFitStruct.i(:, i)'); 
                    rupturePoint = chainFitStruct.i(2, i);

                    if length(xi) > 2
                        % Chain fit
                        func = this.chainFitter.fit(xi, yi);
                        derivative = func.derive();
                        slope = derivative.invoke(x(rupturePoint));
                    else
                        func = util.matex.Zero();
                        slope = 0;
                    end

                    % Save data
                    chainFitStruct.func(i) = func;
                    chainFitStruct.ruptureForce(i) = -func.invoke(x(rupturePoint));
                    chainFitStruct.slope(i) = slope;
                    chainFitStruct.apparentLoadingRate(i) = -slope * data.Setup.retractSpeed;
                end
            end
            
            data.ChainFit = chainFitStruct;
        end
        
        function plotData(this, fig, data, extras)
            if nargin < 4
                extras = [];
            end
            plotData@ForSDAT.Core.Tasks.PipelineDATask(this, fig, data, extras);
            
            hold on;
            
            % plot rupture event chain loading start-end points
            dist = this.getChannelData(data, 'x');
            frc = this.getChannelData(data, 'y');
            plot(dist(data.ChainFit.i(1,:)), frc(data.ChainFit.i(1,:)), 'cs', 'MarkerFaceColor', 'c', 'MarkerSize', 13);
            plot(dist(data.ChainFit.i(2,:)), frc(data.ChainFit.i(2,:)), 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 13);

            % plot chain fits
            for i = 1:length(data.ChainFit.func)
                func = data.ChainFit.func(i);
                
%                 xi = croparr(dist, data.ChainFit.i(:, i)'); 
                if this.plotChainfitFromContactPoint
                    xi = util.croparr(dist, [data.Contact.i, data.ChainFit.i(2, i)]); 
                else
                    xi = util.croparr(dist, data.ChainFit.i(:, i)); 
                end
                plot(xi, func.invoke(xi), 'g', 'LineWidth', 2);
            end
            
            hold off;
        end
    end
    
end

