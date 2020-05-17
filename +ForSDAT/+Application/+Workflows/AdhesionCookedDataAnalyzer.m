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
            ctorParams = {'%AnalysisContext', 'dataAnalyzer'};
            defaultValues = {'dataAnalyzer', []};
        end
    end
    
    methods (Access=protected)
        function item = generateDataItemFromData(this, data, key)
            if isa(data, 'ForSDAT.Core.AnalyzedFDCData')
                item = data;
            else
                f = Simple.getobj(data, 'AdhesionForce.Value');
                z = Simple.getobj(data, 'AdhesionForce.Position');
                slope = [];
                item = ForSDAT.Core.AnalyzedFDCData(f, z, slope, key);
                
                item.noise = data.NoiseAmplitude;
                item.posx = data.BatchPosition.x;
                item.posy = data.BatchPosition.y;
                item.posi = data.BatchPosition.i;
                item.energy = Simple.getobj(data, 'AdhesionEnergy.Value');
            end
        end
    end
    
    methods
        function this = AdhesionCookedDataAnalyzer(context, dataAnalyzer)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer(context);
            
            if nargin >= 2 && ~iempty(dataAnalyzer)
                this.dataAnalyzer = dataAnalyzer;
            end
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
        % whether adhesion event was detected
            bool = Simple.getobj(data, 'AdhesionForce.AboveThreshold', false);
        end
        
        function loadPreviouslyProcessedDataOutput(this, path)
        % Loads previously processed data
            importDetails.path = path;
            importDetails.keyField = 'file';
            loadPreviouslyProcessedDataOutput@ForSDAT.Application.Workflows.CookedDataAnalyzer(this, importDetails);
        end
    end
end

