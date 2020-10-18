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
            ctorParams = {'%AnalysisContext', '%ExperimentCollectionContext', 'ExperimentRepositoryDAO', 'DataAnalyzer'};
            defaultValues = {'ExperimentRepositoryDAO', ForSDAT.Application.IO.ExperimentRepositoryDAO.empty(), 'DataAnalyzer', []};
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
        function this = SMICookedDataAnalyzer(analysisContext, repositoryContext, expRepoDAO, dataAnalyzer)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer(analysisContext, repositoryContext, expRepoDAO);
            
            this.DataAnalyzer = dataAnalyzer;
        end
        
        function results = doAnalysis(this, dataList)
            % setup
            results = ForSDAT.Application.Models.ForsSpecExperimentResults();
            results.BinningMethod = this.DataAnalyzer.BinningMethod;
            results.MinimalBins = this.DataAnalyzer.MinimalBins;
            results.FittingModel = this.DataAnalyzer.Model;
            results.Speed = this.Settings.Measurement.Speed;
            results.FitR2Threshold = this.DataAnalyzer.FitR2Threshold;

            if isempty(dataList)
                results.MostProbableForce = [];
                results.ForceStd = [];
                results.ForceErr = [];
                results.LoadingRate = [];
                results.LoadingRateErr = [];
                return;
            end
            
            options = [];
            options.showHistogram = true;
            [mpf, mpfStd, mpfErr, lr, lrErr, returnedOpts] = this.DataAnalyzer.doYourThing([dataList.f], [dataList.z], [dataList.slope], this.Settings.Measurement.Speed, [dataList.lr], options);
            
            % results
            results.MostProbableForce = mpf;
            results.ForceStd = mpfStd;
            results.ForceErr = mpfErr;
            results.LoadingRate = lr;
            results.LoadingRateErr = lrErr;
        end

        function bool = examineCurveAnalysisResults(this, data)
        % Examine the analysis results of a single curve and determine
        % whether a single molecule interaction (SMI) was detected
            bool = mvvm.getobj(data, 'SingleInteraction.didDetect', false, 'nowarn');
        end
        
        function experimentId = loadPreviouslyProcessedDataOutput(this, path)
        % Loads previously processed data
            importDetails.path = path;
            importDetails.keyField = 'file';
            experimentId = loadPreviouslyProcessedDataOutput@ForSDAT.Application.Workflows.CookedDataAnalyzer(this, importDetails);
        end
    end
end

