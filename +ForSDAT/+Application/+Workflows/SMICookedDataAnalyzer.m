classdef SMICookedDataAnalyzer < ForSDAT.Application.Workflows.CookedDataAnalyzer & mfc.IDescriptor
    % SMICookedDataAnalyzer implements the interface for analysing 
    properties
        DataAnalyzer;
    end
    
    methods (Hidden) % meta data
        
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        % 
        % ctor dependency rules:
        %   Extract from fields:
        %       Parameter name is the name of the property, with or without
        %       '&' prefix
        %   Hardcoded string: 
        %       Parameter starts with a '$' sign. For instance, parameter
        %       value '$Pikachu' is translated into a parameter value of
        %       'Pikachu', wheras parameter value '$$Pikachu' will be
        %       translated into '$Pikachu' when it is sent to the ctor
        %   Optional ctor parameter (key-value pairs):
        %       Parameter name starts with '@'
        %   Get parameter value from dependency injection:
        %       Parameter name starts with '%'
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'%AnalysisContext', 'DataAnalyzer'};
            defaultValues = {'DataAnalyzer', []};
        end
    end
    
    methods (Access=protected)
        function item = generateDataItemFromData(this, data, key)
            if isa(data, 'ForSDAT.Core.AnalyzedFDCData')
                item = data;
            else
                item = ForSDAT.Core.AnalyzedFDCData(...
                    data.SingleInteraction.modeledForce,...
                    data.SingleInteraction.ruptureDistance,...
                    data.SingleInteraction.slope,...
                    key,...
                    data.SingleInteraction.apparentLoadingRate,...
                    data.NoiseAmplitude,...
                    data.BatchPosition.x,...
                    data.BatchPosition.y,...
                    data.BatchPosition.i);
            end
        end
    end
    
    methods
        function this = SMICookedDataAnalyzer(context, dataAnalyzer)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer(context);
            
            this.DataAnalyzer = dataAnalyzer;
        end
        
        function output = wrapUpAndAnalyze(this)
            valuesCellArray = this.getDataList().values;
            values = [valuesCellArray{:}];
            
            % setup
            output = struct();
            output.batch = this.DataAccessor.BatchPath;
            output.binningMethod = this.DataAnalyzer.BinningMethod;
            output.minimalBins = this.DataAnalyzer.MinimalBins;
            output.fittingModel = this.DataAnalyzer.Model;
            output.speed = this.Settings.measurement.speed;
            output.gausFitR2Threshold = this.DataAnalyzer.FitR2Threshold;

            if isempty(values)
                output.mpf = [];
                output.mpfStd = [];
                output.mpfErr = [];
                output.lr = [];
                output.lrErr = [];
                return;
            end
            
            options = [];
            options.showHistogram = true;
            [mpf, mpfStd, mpfErr, lr, lrErr, returnedOpts] = this.DataAnalyzer.doYourThing([values.f], [values.z], [values.slope], this.Settings.measurement.speed, [values.lr], options);
            
            % results
            output.mpf = mpf;
            output.mpfStd = mpfStd;
            output.mpfErr = mpfErr;
            output.lr = lr;
            output.lrErr = lrErr;
            
            this.DataAccessor.saveResults(values, output);
        end

        function bool = examineCurveAnalysisResults(this, data)
        % Examine the analysis results of a single curve and determine
        % whether a single molecule interaction (SMI) was detected
            bool = Simple.getobj(data, 'SingleInteraction.didDetect', false);
        end
        
        function loadPreviouslyProcessedDataOutput(this, path)
        % Loads previously processed data
            importDetails.path = path;
            importDetails.keyField = 'file';
            loadPreviouslyProcessedDataOutput@ForSDAT.Application.Workflows.CookedDataAnalyzer(this, importDetails);
        end
    end
end

