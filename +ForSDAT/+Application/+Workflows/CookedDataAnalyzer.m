classdef (Abstract) CookedDataAnalyzer < handle
    % CookedDataAnalyzer is a base class for cooked data analyzers.
    % Cooked data analyzers saves and analyzes the processed raw data and
    % manage experminet repository for post-processing the results of 
    % multiple experiments, such as Bell-Evans plot etc.
    % 
    % * Cooked data as opposed to raw data
    
        
    % 
    % Current running analysis properties
    %
    properties (GetAccess=public, SetAccess=private)
        % The context for saving persistence of current running analysis
        AnalysisContext mvvm.AppContext;
        
        % The data access object for managing of current running analysis
        DataAccessor dao.DataAccessor = dao.MXmlDataAccessor.empty();
        
        % The setup settings of the current running analysis
        Settings;
        
        % The Id of the currently analyzed experiment/force-curve-batch
        RunningExperimentId;
        
        % The batch info of current analyzed experiment
        CurrentBatchInfo ForSDAT.Application.Models.BatchInfo;
    end
    
    %
    % Experiments Repository properties
    %
    properties (GetAccess=public, SetAccess=private)
        % The context for saving Experiment Repository persistence
        RepositoryContext mvvm.AppContext;
        
        % This data access object is in charge of managing backing up and
        % fetching the experiments repository to/from file system
        ExperimentRepositoryDAO ForSDAT.Application.IO.ExperimentRepositoryDAO = ForSDAT.Application.IO.ExperimentRepositoryDAO.empty();
        
        % Listener to experiments repository change events, initiates
        % backup operation
        ExperimentRepositoryListener;
    end
    properties (Dependent, GetAccess=public, SetAccess=private)
        % Gets the experiments repository
        % Experiments repository is continously backed up to file to ensure
        % data consistency
        ExpetimentRepository ForSDAT.Application.Models.ExperimentRepository;
    end
        
    % 
    % Post Analysis proeprties
    %
    properties (GetAccess=public, SetAccess=private)
        % List of post processing validators
        % A processed batch is validated using these validators before
        % being added to the experiments repository
        ResultsValidators ForSDAT.Application.Workflows.CRV.ICookedResultValidator ...
            = ForSDAT.Application.Workflows.CRV.SuccessRateValidator.empty();
    end
    
    methods % property accessors
        function repo = get.ExpetimentRepository(this)
            key = 'CookedData_ExperimentResultsRepository';
            if this.RepositoryContext.isKey(key)
                repo = this.RepositoryContext.get(key);
            else
                repo = [];
            end
        end
        
        function set.ExpetimentRepository(this, repo)
            key = 'CookedData_ExperimentResultsRepository';
            if ~isempty(this.ExperimentRepositoryListener)
                delete(this.ExperimentRepositoryListener)
            end
            
            this.RepositoryContext.set(key, repo);
            this.ExperimentRepositoryListener = addlistener(repo, 'collectionChanged', @this.onRepositoryUpdated);
        end
    end
    
    methods
        function this = CookedDataAnalyzer(analysisContext, repositoryContext, exRepoDAO)
            this.AnalysisContext = analysisContext;
            this.RepositoryContext = repositoryContext;
            this.ExperimentRepositoryDAO = exRepoDAO;
        end
        
        function this = init(this, dataAccessor, settings, experimentId, experimentRepoName)
            this.DataAccessor = dataAccessor;
            this.Settings = settings;
            this.RunningExperimentId = experimentId;
            
            % switch experiments results repository
            if nargin >= 5 && ~isempty(experimentRepoName) && ...
                    (isempty(this.ExpetimentRepository) || ~strcmp(experimentRepoName, this.ExpetimentRepository.Name))
                try
                    repo = this.ExperimentRepositoryDAO.load(experimentRepoName);    
                catch ex
                    disp(getReport(ex));
                    repo = [];
                end
                
                % if the file is missing or is empty or is corrupted
                if builtin('isempty', repo) || ~isa(repo, 'ForSDAT.Application.Models.ExperimentRepository')
                    this.ExpetimentRepository = ForSDAT.Application.Models.ExperimentRepository(experimentRepoName);
                    this.ExperimentRepositoryDAO.save(this.ExpetimentRepository);
                end
            end
        end
        
        function onRepositoryUpdated(this, repo, ~)
            this.ExperimentRepositoryDAO.save(repo);
        end
        
        function [results, keys] = getAcceptedResults(this)
        % Gets the list of accepted data
        % results - returns the list of accepted data items
        % keys - returns the list of data-item identifiers
            
            map = this.getDataList();
            results = map.values;
            if nargout >= 2
                keys = map.keys;
            end
        end
        
        function acceptData(this, data, curveKey)
        % Accept data item - it passed processing
            
            this.addToDataList(data, curveKey);
        end
        
        function rejectData(this, curveKey) 
        % Reject data item - it doesn't pass processing
            if this.doesListContain(curveKey)
                this.removeFromList(curveKey);
            end
        end
        
        function revertDecision(this, curveKey)
        % If was accepted revert that decision
            this.rejectData(curveKey);
        end
        
        function experimentId = loadPreviouslyProcessedDataOutput(this, importDetails)
        % Loads previously processed data
            this.clearDataList();
            [data, results] = this.DataAccessor.importResults(importDetails);
            this.CurrentBatchInfo = results.BatchInfo;
            this.RunningExperimentId = results.Id;
            
            experimentId = results.Id;
            
            for i = 1:length(data)
                this.addToDataList(data(i), data(i).(importDetails.keyField));
            end
        end
        
        function startFresh(this, batchInfo)
            this.CurrentBatchInfo = batchInfo;
            this.clearDataList();
        end
        
        function results = wrapUpAndAnalyze(this)
            valuesCellArray = this.getDataList().values;
            dataList = [valuesCellArray{:}];
            
            % perform cooked analysis
            results = this.doAnalysis(dataList);
            
            % add experiment meta data to results
            results.Id = this.RunningExperimentId;
            results.BatchInfo = this.CurrentBatchInfo;
            
            % save the results of the experiment
            this.DataAccessor.saveResults(dataList, results);
            
            % validate experiment results before adding to repository
            isvalid = true;
            for i = 1:numel(this.ResultsValidators)
                validator = this.ResultsValidators(i);
                [isvalid, rejectionMsg] = validator.validate(this, dataList, results);
                if ~isvalid
                    break;
                end
            end
            
            % if the results are valid add them to the experiments
            % repository
            if isvalid
                this.addExperimentToRepository(results);
            else
                % otherwise, raise a warning with the rejection message
                warningMessage = ['Experiment (', results.Id, ') results rejected due to: ', strrep(rejectionMsg, '%', '%%')];
                warning('ForSDAT:CookedDataAnalyzer:ResultsRejected', warningMessage);
            end
        end
        
        function [chi, koff, p, R2] = bellEvansPlot(this, fig, varargin)
            % Plots the Bell-Evans curve for a set of MPFs and LRs
            % Returns:
            %   chi - Energy barrier distance [?]
            %   koff - Dissosiation rate [Hz]
            %   p - Bell-Evans regression curve coefficients
            %   R2 - coefficient of determination - R squared
            % Bell-Evans model:
            %   F = (kB*T/X)*ln(Xr/kB*T*koff)
            %   where F is the MPF
            %         kB is boltzmans constant
            %         T is the temperature
            %         X is the distance of the energy barrier needed to be
            %                  overcome for unbinding to occur allong the
            %                  direction of applied force
            %         r is the apparent loading rate
            %         koff is the rate of dissosiation at equilibrium
            %
            
            data = [this.ExpetimentRepository.values{:}];
            lr = vertcat(data.LoadingRate);
            lrErr = vertcat(data.LoadingRateErr);
            mpf = vertcat(data.MostProbableForce);
            mpfErr = vertcat(data.ForceErr);
            
            if nargin < 3
                varagin = {'Marker', 'o',...
                    'MarkerFaceColor', 'b',...
                    'MarkerEdgeColor', 'b',...
                    'LineStyle', 'none'};
            end
            
            % Calculate reggression
            x = log(lr);
            xErr = lrErr./lr;
            
            [p, S] = polyfit(x, mpf, 1);
            R2 = 1 - (S.normr/norm(mpf - mean(mpf)))^2;
            
            if nargin < 2 || isempty(fig)
                fig = gcf();
            else
                fig = figure(fig);
            end
            errorbar(x, mpf, mpfErr, mpfErr, xErr, xErr, varagin{:});
            
            hold on;
            regY = polyval(p, x);
            plot(x, regY);
            
            slope = p(1); % KBT/chi
            intersect = p(2);
            secondParameter = intersect/slope; % ln(chi/KBT*Koff)
            T = 298; % RT in K
            heatEnergy = chemo.PhysicalConstants.kB*T;% KBT in J
            chi = heatEnergy/slope; % in Angstoms
            koff = exp(-secondParameter)/slope;
            
            % Create xlabel
            xlabel({'ln(r)'}, 'FontSize', 24);

            % Create ylabel
            ylabel({'MPF (pN)'}, 'FontSize', 24);

            % Create textbox
            textbox = annotation(fig,'textbox',...
                [0.15 0.72 0.20 0.19],...
                'String',{['R^2=' num2str(round(R2, 4))],...
                          ['\chi_\beta=' num2str(round(chi, 2)), char(197)],...
                          ['k_o_f_f=' num2str(round(koff*1000, 2)) '�10^-^3Hz']},...
                'FitBoxToText','on',...
                'FontSize', 18);
        end
    end
    
    methods (Access=protected)
        
        function addExperimentToRepository(this, experiment)
            repo = this.ExpetimentRepository;
            
            repo.setv(experiment.Id, experiment);
        end
        
        function list = getDataList(this)
            % Gets the data list from the context
            % If it is not initialized yet, create a new one
            listRepKey = [class(this) '_DataList'];
            if ~this.AnalysisContext.hasEntry(listRepKey)
                list = this.createDataListInstance();
                this.AnalysisContext.set(listRepKey, list);
            else
                list = this.AnalysisContext.get(listRepKey);
            end
        end
        
        function list = createDataListInstance(this)
            % Creates a new instance of the data list. If overriding this
            % to return something other than containers.Map, make sure to
            % override the addToDataList and removeFromList methods as well
            % to implement according to the desired data structure
            list = containers.Map();
        end
        
        function addToDataList(this, data, key)
            % Adds a new data item or overrides an existing one in the data
            % list
            map = this.getDataList();
            map(key) = this.generateDataItemFromData(data, key);
        end
        
        function tf = doesListContain(this, key)
            map = this.getDataList();
            tf = map.isKey(key);
        end
        
        function removeFromList(this, key)
            % Removes a data item from the data list
            this.getDataList().remove(key);
        end
        
        function clearDataList(this)
            % Removes all data from the data list
            map = this.getDataList();
            map.remove(map.keys);
        end
        
        
    end
    
    methods (Abstract, Access=protected)
        % Override in derived class to generate a data item from data
        % recieved from the data analyzer
        dataItem = generateDataItemFromData(this, data, key)
    end
    
    methods (Abstract)
        % Analyze the batch results
        results = doAnalysis(this, dataList)
        
        % Examine the analysis results of a single curve and determine
        % whether should accept or reject it.
        bool = examineCurveAnalysisResults(this, data)
    end
    
end

