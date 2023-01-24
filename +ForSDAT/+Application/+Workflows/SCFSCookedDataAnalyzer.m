classdef SCFSCookedDataAnalyzer < ForSDAT.Application.Workflows.CookedDataAnalyzer & mfc.IDescriptor
    % SCFSCookedDataAnalyzer implements the interface for analysing
    % "cooked" single cell force spectroscopy curves
    
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
            ctorParams = {'%AnalysisContext', '%ExperimentCollectionContext', '%ExperimentRepositoryDAO'};
            defaultValues = {};
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
 
                % extract single detachment events info
                ruptures = mvvm.getobj(data, 'Rupture', [], 'nowarn');
                if ~isempty(ruptures)
                    item.ruptureForce = ruptures.force;
                    item.ruptureDistance = ruptures.distance;
                    item.nRuptures = numel(ruptures.distance);
                    item.maxAdhesionDistance = max(ruptures.distance);
                end
            end
        end 
    end
    
    methods
        function this = SCFSCookedDataAnalyzer(analysisContext, repositoryContext, exRepoDAO)
            this@ForSDAT.Application.Workflows.CookedDataAnalyzer(analysisContext, repositoryContext, exRepoDAO);
        end
        
        function results = doAnalysis(this, dataList)
            options = [];
            options.showHistogram = true;
            
            results = ForSDAT.Application.Models.SCFSExperimentResults();
            
            % results
            results.MaxAdhesionForce = ForSDAT.Application.Models.MeanValue([dataList.f]);
            results.MaxAdhesionDistance = ForSDAT.Application.Models.MeanValue([dataList.z]);
            results.DetachmentWork = ForSDAT.Application.Models.MeanValue([dataList.energy]);
            results.NRuptures = ForSDAT.Application.Models.MeanValue([dataList.nRuptures]);
            results.RuptureForce = ForSDAT.Application.Models.MeanValue([dataList.ruptureForce]);
            results.MaxRuptureDistance = ForSDAT.Application.Models.MeanValue([dataList.maxAdhesionDistance]);
            
            avgInterRuptDistance = arrayfun(@(x) mean(diff(x.ruptureDistance)), dataList);
            results.InterRuptureDistance = ForSDAT.Application.Models.MeanValue(avgInterRuptDistance);
            
            % lists
            results.RuptureForceList = [dataList.ruptureForce];
            results.RuptureDistanceList = [dataList.ruptureDistance];
        end

        function bool = examineCurveAnalysisResults(this, data)
        % Examine the analysis results of a single curve and determine
        % whether adhesion event was detected
%             bool = mvvm.getobj(data, 'AdhesionForce.AboveThreshold', false, 'nowarn');
            bool = true;
        end
    end
    
    % reporting
    methods
        function t = allocateResultsTable(this, n)
            if nargin < 2; n = 0; end
            
            varnames = {'Repository', 'ExperimentId', 'CurveId', 'PosX',   'PosY',   'PosIndex', 'MaxAdhesionForce', 'MaxAdhesionDistance', 'DetachmentWork', 'NRuptures', 'MeanRuptureForce', 'MaxRuptureDistance', 'MeanInterRuptureDistance'};
            vartypes = {'string',     'string',       'string',  'double', 'double', 'int32',    'double',           'double',              'double',         'int32',     'double',           'double',             'double'};
            
            t = table('Size', [n, numel(varnames)], 'VariableTypes', vartypes, 'VariableNames', varnames);
        end
    end
    
    methods (Access=protected)
        function t = extractDataOfInterest(this, dataList)
            t = this.allocateResultsTable(numel(dataList));
            
            % extract relevant data from the data list
            for i = 1:numel(dataList)
                item = dataList(i);
                if ~isempty(item.file)
                    t{i, 'CurveId'} = string(item.file);
                end
                if ~isempty(item.posx)
                    t{i, 'PosX'} = item.posx;
                end
                if ~isempty(item.posy)
                    t{i, 'PosY'} = item.posy;
                end
                if ~isempty(item.f)
                    t{i, 'MaxAdhesionForce'} = item.f;
                end
                if ~isempty(item.z)
                    t{i, 'MaxAdhesionDistance'} = item.z;
                end
                if ~isempty(item.energy)
                    t{i, 'DetachmentWork'} = item.energy;
                end
                if ~isempty(item.nRuptures)
                    t{i, 'NRuptures'} = item.nRuptures;
                end
                if ~isempty(item.maxAdhesionDistance)
                    t{i, 'MaxRuptureDistance'} = item.maxAdhesionDistance;
                end
                if ~isempty(item.maxAdhesionDistance)
                    t{i, 'MeanRuptureForce'} = mean(item.ruptureForce);
                end
                if ~isempty(item.maxAdhesionDistance)
                    t{i, 'MeanInterRuptureDistance'} = mean(diff(item.ruptureDistance));
                end
            end
        end
    end
    
end

