classdef StepsDataAnalyzer < mfc.IDescriptor
    % Good at analyzing the rupture events data produced from a batch of
    % F-D curves.
    
    properties
        MinimalBins = [];
        BinningMethod = [];
        FitR2Threshold = [];
        Model = 'gauss';
        ModelFittingMode = 'data';
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
            if ~exist('lrVector', 'var')
                lrVector = [];
            end
            if ~exist('options', 'var')
                options = [];
            end
                        
            % fit multiple gauss peaks
            if startsWith(lower(this.Model), 'gauss')
                modelParams = {'PlanBGoodnessThreshold', this.FitR2Threshold};
            else
                modelParams = {'FittingMode', this.ModelFittingMode};
            end
            histoolParams = {'Model', this.Model, 'ModelParams', modelParams, 'BinningMethod', this.BinningMethod, 'MinimalBins', this.MinimalBins, };
            
            % Show histogram if needed
            shouldPlot = mvvm.getobj(options, 'showHistogram', false);
            plotOpt = mvvm.getobj(options, 'plotOptions', []);
            if ~shouldPlot
                stats = histool.stats(frc, histoolParams);
            else
                plotIntoThisElement = mvvm.getobj(plotOpt, 'figure', []);

                % plot histogram and perform statistical analyzis
                [stats, guiHandle] = histool.histdist(frc, 'PlotTo', plotIntoThisElement, histoolParams{:});
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
        
        function makePlotPresentable(this, mpf, err, lr, lrErr, N, plotOpt, h)

            fig = ancestor(h(1), 'figure');
            ax = ancestor(h(1), 'axes');
            
            % make figure displayable
            xlabel(ax, 'Rupture Force Range (pN)');
            ylabel(ax, 'Frequency');
        
            detailsText = {...
                sprintf('MPF = %d�%d pN', mpf, err),...
                sprintf('L.R = %d�%d nN/sec', lr, lrErr),...
                sprintf('N = %d', N)};

            % add details textbox
            this.createTextElement(fig, ax, detailsText);
            
            % add title to axes
            plotTitle = mvvm.getobj(plotOpt, 'title', '');
            if ~isempty(plotTitle)
                title(ax, plotTitle);
            end
        end
        
        function createTextElement(this, fig, ax, text)
            % calculate position and size for the text element
            labelSize = [280, 140];
            margins = [5,5];
            absPos = sui.getAbsPos(ax);
            axSize = sui.getSize(ax, 'pixels');
            labelPos = absPos(1:2) + axSize - labelSize - margins;
            
            % create text element and add to the UI hierarchi
            if util.isUiFigure(fig)
                uilabel(fig, ...
                    'Text', text, ...
                    'FontSize', 24, ...
                    'BackgroundColor', [1 1 1], ...
                    'Position', [labelPos, labelSize],...
                    'tag', 'HistLabel');
            else
                hh = annotation(fig, 'textbox', ...
                    'String', text, ...
                    'FontSize', 24, ...
                    'BackgroundColor', [1 1 1], ...
                    'tag', 'HistLabel');
                
                sui.setPos(hh, [labelPos, labelSize], 'pixels');
            end
        end
    end
end

