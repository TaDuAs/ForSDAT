classdef StepsDataAnalyzer < mfc.IDescriptor
    % Good at analyzing the rupture events data produced from a batch of
    % F-D curves.
    
    properties
        MinimalBins = [];
        BinningMethod = [];
        FitR2Threshold = [];
        Model = 'gauss';
        ModelFittingMode {mustBeMember(ModelFittingMode, {'data', 'frequencies'})} = 'data';
        Alpha = 0.05;
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'BinningMethod', 'MinimalBins', 'Model', 'FitR2Threshold', 'Alpha'};
            defaultValues = {...
                'BinningMethod', 'fd', ...
                'MinimalBins', 0,...
                'Model', '', ...
                'FitR2Threshold', [], ...
                'Alpha', []};
        end
    end
    
    methods
        function this = StepsDataAnalyzer(binningMethod, minimalBins, model, fitR2Threshold, confidenceIntervalAlphaValue)
            this.BinningMethod = binningMethod;
            this.MinimalBins = minimalBins;
            
            if exist('model', 'var') && ~isempty(model)
                this.Model = model;
            end
            
            if exist('fitR2Threshold', 'var') && ~isempty(fitR2Threshold)
                this.FitR2Threshold = fitR2Threshold;
            end
            
            if exist('confidenceIntervalAlphaValue', 'var') && ~isempty(confidenceIntervalAlphaValue)
                this.Alpha = confidenceIntervalAlphaValue;
            end
        end
        
        function [mpf, sigma, err, lr, lrErr, returnedOpts] = doYourThing(this, frc, dist, slope, speed, lrVector, options)

            
%             if ~exist('lrVector', 'var')
%                 lrVector = [];
%             end

            % yes we are ignoring the supplied loading rate vector and
            % recalculating it from the slope and speed
            lrVector = [];
            if ~exist('options', 'var')
                options = [];
            end
                        
            % fit multiple gauss peaks
            if startsWith(lower(this.Model), 'gauss')
                modelParams = {'PlanBGoodnessThreshold', this.FitR2Threshold, 'GetOnlyMaxMode', true};
            else
                modelParams = {'FittingMode', this.ModelFittingMode};
            end
            histoolParams = {'Model', this.Model, 'ModelParams', modelParams, 'BinningMethod', this.BinningMethod, 'MinimalBins', this.MinimalBins};
            
            % Show histogram if needed
            shouldPlot = mvvm.getobj(options, 'showHistogram', false, 'nowarn');
            plotOpt = mvvm.getobj(options, 'plotOptions', [], 'nowarn');
            if ~shouldPlot
                stats = histool.stats(frc, histoolParams);
            else
                plotIntoThisElement = mvvm.getobj(plotOpt, 'figure', [], 'nowarn');

                % plot histogram and perform statistical analyzis
                modelingOrder = this.getModelingMultiModalOrder();
                if modelingOrder > 1
                    pdfPlotIndex = 2:modelingOrder+1;
                else
                    pdfPlotIndex = 1;
                end
                
                [stats, guiHandle] = histool.histdist(frc, 'PlotTo', plotIntoThisElement, 'PlotPdfIndex', pdfPlotIndex, histoolParams{:});
            end
            
            % get mpf +/- error
            sigma = stats.StandardDeviation;
            err = util.econfi(stats.MPV, this.Alpha, sigma, numel(frc));
            [mpf, err] = util.roundError(stats.MPV, err);
            
            % Calculate the average loading rate & confidence interval
            lrVector = lrVector(~isnan(lrVector));
            if isempty(lrVector)
                lrVector = -1*slope(slope<0)*speed;
            end
            lr = mean(lrVector);
            lrErr = util.econfi(lrVector, this.Alpha);
            if isnumeric(lr) && ~isnan(lr) && ~isempty(lr)
                [lr, lrErr] = util.roundError(lr, lrErr);
            end
            
            returnedOpts = struct('fitGoodness', stats.GoodnessOfFit);
            
            if shouldPlot
                this.makePlotPresentable(mpf, err, lr, lrErr, numel(frc), plotOpt, guiHandle);
            end
        end
    end
    
    methods (Access=private)
        function makePlotPresentable(this, mpf, err, lr, lrErr, N, plotOpt, h)

            fig = ancestor(h(1), 'figure');
            ax = ancestor(h(1), 'axes');
            
            % make figure displayable
            xlabel(ax, 'Rupture Force Range (pN)', 'FontSize', 24);
            ylabel(ax, 'Frequency', 'FontSize', 24);
        
            detailsText = {...
                sprintf('MPF = %g±%g pN', mpf, err),...
                sprintf('L.R = %g±%g pN/sec', lr, lrErr),...
                sprintf('N = %d', N),...
                sprintf('Distribution = %s', this.Model)};

            % add details textbox
            this.createTextElement(fig, ax, detailsText);
            
            % add title to axes
            plotTitle = mvvm.getobj(plotOpt, 'title', '', 'nowarn');
            if ~isempty(plotTitle)
                title(ax, plotTitle);
            end
        end
        
        function createTextElement(this, fig, ax, text)
            % calculate position and size for the text element
            labelSize = [300, 160];
            margins = [5,5];
            absPos = sui.getAbsPos(ax);
            axSize = sui.getSize(ax, 'pixels');
            labelPos = absPos(1:2) + axSize - labelSize - margins;
            
            % create text element and add to the UI hierarchi
            if util.isUiFigure(fig)
                uilabel(fig, ...
                    'Text', text, ...
                    'FontSize', 20, ...
                    'BackgroundColor', [1 1 1], ...
                    'Position', [labelPos, labelSize],...
                    'tag', 'HistLabel');
            else
                hh = annotation(fig, 'textbox', ...
                    'String', text, ...
                    'FontSize', 20, ...
                    'BackgroundColor', [1 1 1], ...
                    'tag', 'HistLabel',...
                    'FitBoxToText','on');
                
                sui.setPos(hh, [labelPos, labelSize], 'pixels');
            end
        end
        
        function order = getModelingMultiModalOrder(this)
            order = 1;
            if startsWith(lower(this.Model), 'gauss')
                orderString = regexp(this.Model, '\d+$', 'match');
                if ~isempty(orderString)
                    order = str2double(orderString);
                end
            end
        end
    end
end

