classdef AdhesionCookedDataAnalyzer < ForSDAT.Application.Workflows.CookedDataAnalyzer & mfc.IDescriptor
    % SMICookedDataAnalyzer implements the interface for analysing 
    properties
        dataAnalyzer;
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
            ctorParams = {'%AnalysisContext', '%ExperimentCollectionContext', 'ExperimentRepositoryDAO', 'dataAnalyzer'};
            defaultValues = {'dataAnalyzer', []};
        end
    end
    
    methods (Access=protected)
        function item = generateDataItemFromData(this, data, key)
            if isa(data, 'ForSDAT.Core.AnalyzedFDCData')
                item = data;
            else
                f = mvvm.getobj(data, 'AdhesionForce.Value', [], 'nowarn');
                z = mvvm.getobj(data, 'AdhesionForce.Position', [], 'nowarn');
                slope = [];
                item = ForSDAT.Core.AnalyzedFDCData(f, z, slope, key);
                
                item.noise = data.NoiseAmplitude;
                item.posx = data.BatchPosition.x;
                item.posy = data.BatchPosition.y;
                item.posi = data.BatchPosition.i;
                item.energy = mvvm.getobj(data, 'AdhesionEnergy.Value', [], 'nowarn');
            end
        end
    end
    
    methods
        function this = AdhesionCookedDataAnalyzer(analysisContext, repositoryContext, exRepoDAO, dataAnalyzer)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer(analysisContext, repositoryContext, exRepoDAO);
            
            if nargin >= 2 && ~isempty(dataAnalyzer)
                this.dataAnalyzer = dataAnalyzer;
            end
        end
        
        function results = doAnalysis(this, dataList)
            options = [];
            options.showHistogram = true;
            [mpf, mpfStd, mpfErr, lr, lrErr, returnedOpts] = this.dataAnalyzer.doYourThing([dataList.f], [dataList.z], [dataList.slope], this.Settings.Measurement.Speed, [dataList.lr], options);
            
            results = ForSDAT.Application.Models.ForsSpecExperimentResults();
            
            % results
            results.MostProbableForce = mpf;
            results.ForceStd = mpfStd;
            results.ForceErr = mpfErr;
            results.LoadingRate = lr;
            results.LoadingRateErr = lrErr;
            
            % setup
            results.BinningMethod = this.DataAnalyzer.BinningMethod;
            results.MinimalBins = this.DataAnalyzer.MinimalBins;
            results.FittingModel = this.DataAnalyzer.Model;
            results.Speed = this.Settings.Measurement.Speed;
            results.FitR2Threshold = this.DataAnalyzer.FitR2Threshold;
        end

        function bool = examineCurveAnalysisResults(this, data)
        % Examine the analysis results of a single curve and determine
        % whether adhesion event was detected
            bool = mvvm.getobj(data, 'AdhesionForce.AboveThreshold', false, 'nowarn');
        end
    end
end

