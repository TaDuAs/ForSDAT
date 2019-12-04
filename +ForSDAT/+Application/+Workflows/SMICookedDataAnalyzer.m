classdef SMICookedDataAnalyzer < ForSDAT.Application.Workflows.CookedDataAnalyzer
    % SMICookedDataAnalyzer implements the interface for analysing 
    properties
        dataAnalyzer;
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
        function this = SMICookedDataAnalyzer(dataAnalyzer)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer();
            
            this.dataAnalyzer = dataAnalyzer;
        end
        
        function output = wrapUpAndAnalyze(this)
            valuesCellArray = this.getDataList().values;
            values = [valuesCellArray{:}];
            options = [];
            options.showHistogram = true;
            [mpf, mpfStd, mpfErr, lr, lrErr, returnedOpts] = this.dataAnalyzer.doYourThing([values.f], [values.z], [values.slope], this.settings.measurement.speed, [values.lr], options);
            
            output = [];
            
            % results
            output.mpf = mpf;
            output.mpfStd = mpfStd;
            output.mpfErr = mpfErr;
            output.lr = lr;
            output.lrErr = lrErr;
            
            % setup
            output.batch = this.dataAccessor.batchPath;
            output.binningMethod = this.dataAnalyzer.binningMethod;
            output.minimalBins = this.dataAnalyzer.minimalBins;
            output.fittingModel = this.dataAnalyzer.model;
            output.speed = this.settings.measurement.speed;
            output.gausFitR2Threshold = this.dataAnalyzer.fitR2Threshold;

            this.dataAccessor.saveResults(values, output);
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

