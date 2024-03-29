classdef (Abstract) CookedDataAnalyzer < handle & mxml.IMXmlIgnoreFields
    % CookedDataAnalyzer is a base class for cooked data analyzers.
    % Cooked data analyzers saves and analyzes the processed raw data and
    % manage experminet repository for post-processing the results of 
    % multiple experiments, such as Bell-Evans plot etc.
    % 
    % * Cooked data as opposed to raw data
    
    properties (Hidden)
        ArrheniusPrefactor = 10^6; % [Hz]
                                   % Li et al. Langmuir 2014, https://doi.org/10.1021/la501189n
        BellEvansAlpha = 0.95;
    end
    
    methods (Hidden)
        function ignoreList = getMXmlIgnoreFieldsList(~)
            ignoreList = {'ExperimentRepository', 'RepositoryContext', 'ExperimentRepositoryListener'};
        end
    end
    
    % 
    % Current running analysis properties
    %
    properties (GetAccess=public, SetAccess=private)
        % The context for saving persistence of current running analysis
        AnalysisContext mvvm.AppContext;
        
        % The data access object for managing of current running analysis
        DataAccessor dao.DataAccessor = dao.MXmlDataAccessor.empty();
        
        % The setup settings of the current running analysis
        Settings ForSDAT.Core.Setup.AnalysisSettings;
        
        % The Id of the currently analyzed experiment/force-curve-batch
        RunningExperimentId;
        
        % The batch info of current analyzed experiment
        CurrentBatchInfo ForSDAT.Application.Models.BatchInfo;
        
        % The method used to evaluate outliers
        OutlierEvalMethod char {mustBeMember(OutlierEvalMethod, {'movmedian', 'movmean'})} = 'movmedian';
        
        % The logarithmic (natural logarithm) window for outlier evaluation
        OutlierEvalLogarithmicWindow double = 1.5;
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
        ExperimentRepository ForSDAT.Application.Models.ExperimentRepository;
    end
        
    % 
    % Post Analysis proeprties
    %
    properties (GetAccess=public, SetAccess=public)
        % List of post processing validators
        % A processed batch is validated using these validators before
        % being added to the experiments repository
        ResultsValidators ForSDAT.Application.Workflows.CRV.ICookedResultValidator ...
            = ForSDAT.Application.Workflows.CRV.SuccessRateValidator.empty();
    end
    
    methods % property accessors
        function repo = get.ExperimentRepository(this)
            key = 'CookedData_ExperimentResultsRepository';
            if this.RepositoryContext.isKey(key)
                repo = this.RepositoryContext.get(key);
                if ~isa(repo, 'ForSDAT.Application.Models.ExperimentRepository')
                    throw(MException('ForSDAT:ExperimentRepository:Context:InvalidType', 'Expected ExperimentRepository but context contains %s', class(repo)));
                end
            else
                repo = ForSDAT.Application.Models.ExperimentRepository.empty();
            end
        end
        
        function set.ExperimentRepository(this, repo)
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
                    (isempty(this.ExperimentRepository) || ~strcmp(experimentRepoName, this.ExperimentRepository.Name))
                
                % load experiment repository from file or create a new
                % experiment repository if none exist with the given name
                repo = this.ExperimentRepositoryDAO.loadOrCreate(experimentRepoName);
                
                this.ExperimentRepository = repo;
            end
        end
        
        function loadExperimentRepository(this, name)
            % backup current experiments repository
            if ~isempty(this.ExperimentRepository)
                this.ExperimentRepositoryDAO.save(this.ExperimentRepository);
            end
            
            % load wanted repository from file
            this.ExperimentRepository = this.ExperimentRepositoryDAO.load(name);
        end
        
        function importExperimentsRepository(this, path)
            % backup current experiments repository
            if ~isempty(this.ExperimentRepository)
                this.ExperimentRepositoryDAO.save(this.ExperimentRepository);
            end
            
            % import wanted repository
            this.ExperimentRepository = this.ExperimentRepositoryDAO.import(path);
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
        
        function restorePoint = createRestorePoint(this, data, results)
        % Creates a process-in-progress restoration point struct
        
            restorePoint = struct();
            
            % prep accepted curve data object list
            if nargin < 2 || isempty(data)
                valuesCellArray = this.getDataList().values;
                restorePoint.data = [valuesCellArray{:}];
            else
                restorePoint.data = data;
            end
            
            % set meta data restoration info
            if nargin < 3 || isempty(results)
                restorePoint.results = struct();
                restorePoint.results.BatchInfo = this.CurrentBatchInfo;
                restorePoint.results.Id = this.RunningExperimentId;
            else
                restorePoint.results = results;
            end
        end
        
        function experimentId = restoreProcess(this, restorePoint)
        % Restores a process-in-progress from a previous restoration point
        % or exported analyzed data
            
            this.clearDataList();
            
            if ~isfield(restorePoint, 'data')
                data = [];
            else
                data = restorePoint.data;
            end
            results = restorePoint.results;
            
            % restore batch info and experiment id
            this.CurrentBatchInfo = results.BatchInfo;
            this.RunningExperimentId = results.Id;
            
            % return experiment id
            experimentId = results.Id;
            
            % the field of each data item used as unique id
            keyField = this.getDataItemKeyField();
            
            % add all restored data items to the accepted data list
            for i = 1:length(data)
                currItem = data(i);
                this.addToDataList(currItem, currItem.(keyField));
            end
        end
        
        function experimentId = loadPreviouslyProcessedDataOutput(this, path)
        % Loads previously processed data
            importDetails = this.getImportDetails(path);
            [data, results] = this.DataAccessor.importResults(importDetails);
            experimentId = this.restoreProcess(this.createRestorePoint(data, results));
        end
        
        function startFresh(this, batchInfo)
            this.CurrentBatchInfo = batchInfo;
            this.clearDataList();
        end
        
        function results = wrapUpAndAnalyze(this)
            valuesCellArray = this.getDataList().values;
            
            % prep accepted curve data object list
            dataList = [valuesCellArray{:}];
            
            if isempty(dataList)
                results = ForSDAT.Application.Models.ForsSpecExperimentResults.empty();
                return;
            end
            
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
                [isvalid, rejectionMsg] = validator.validate(dataList, results);
                if ~isvalid
                    break;
                end
            end
            
            % if the results are valid add them to the experiments
            % repository
            if isvalid
                this.addExperimentToRepository(results, dataList);
            else
                % otherwise, remove experiment from repository 
                this.removeExperimentFromRepository(results);
                
                % raise a warning with the rejection message
                warningMessage = ['Experiment (', results.Id, ') results rejected due to: ', strrep(rejectionMsg, '%', '%%')];
                warning('ForSDAT:CookedDataAnalyzer:ResultsRejected', warningMessage);
            end
        end
    end
    
    methods % Generate Report Data from Experiment Repository Archives
        function data = getRepositoryData(this, repo)
        % Loads an experiment repository and gets the summary results of 
        % that repository.
        % 
        % Input:
        %   repo - The name of desired experiments repository.
        %
            
            if nargin >= 2 && ~isempty(repo) && gen.isSingleString(repo)
                this.loadExperimentRepository(repo);
            end
            data = [this.ExperimentRepository.values{:}];
        end
        
        function [summary, ds] = getRepositoryFullDataSet(this, repo)
        % Loads an experiment repository and gets the results of that 
        % repository. Returns summary data and full data list from archive.
        % If no archive exists, an error may be thrown.
        %
        % Input:
        %   repo    - The name of desired experiments repository.
        % Output:
        %   summary - A struct array of summary data for each experiment in
        %             the repository
        %   ds      - A table containing the full data list of all 
        %             experiments in the repository. Each record in the
        %             table is uniquely identified by a combination of 3 
        %             variables: "Repository", "ExperimentId", "CurveId"
        %             The other variables in the table are generated by 
        %             deriving classes.
        %
            if nargin < 2; repo = []; end
            
            % load repository
            summary = this.getRepositoryData(repo);
            
            % if full dataset was already generated from archive, load that
            % file for beter performance
            if this.ExperimentRepositoryDAO.doesFullRepositoryDataSetExist(repo)
                ds = this.ExperimentRepositoryDAO.loadFullRepositoryDataSet(repo);
                this.validateResultsTable(ds);
            else
                % generate full data set of the repository from archive
                ds = this.generateFullRepositoryDataSet(summary);
                this.validateResultsTable(ds);
                this.ExperimentRepositoryDAO.saveFullRepositoryDataSet(repo, ds);
            end
        end
        
        function ds = getCombinedRepositoriesFullDataSet(this, repos, recordsPerRepository)
        % Gets the archived results of a list of experiment repositories. 
        % 
        % ds = analyzer.getCombinedRepositoriesFullDataSet(repos, [recordsPerRepository])
        % 
        % Input:
        %   repos                - A list of repository names
        %   recordsPerRepository - Optional. An expected number of curves
        %                          per repository. Used for table
        %                          preallocation. Default value is 1000.
        % Output:
        %   ds - A table containing the full data list of all experiments 
        %        in the repository. Each record in the table is uniquely 
        %        identified by a combination of 3 variables: 
        %        "Repository", "ExperimentId", "CurveId"
        %        The other variables in the table are generated by deriving
        %        classes.
        %
            if nargin < 3 || ~isempty(recordsPerRepository); recordsPerRepository = 1000; end
            
            % preallocate according to expected number of records per repository
            cookedData = analyzer.allocateResultsTable(recordsPerRepository * repoNum);
            this.validateResultsTable(cookedData);
        
            % Load results for each repository and compile all into single
            % table. each row is uniquely identified by three columns:
            %   Repository   - The name of the repository to which the record belongs to
            %   ExperimentId - The id of the experiment in the repository during which the record was acquired
            %   CurveId      - The id of the record/curve
            % Allthough in practice, the CurveId is likely unique.
            totalRows = 0;
            for i = 1:repoNum
                % load repository data
                [~, repoDS] = analyzer.getRepositoryFullDataSet(repos{i});

                % append repository dataset to the combined dataset
                rowsInCurrDS = size(repoDS, 1);
                cookedData(totalRows + 1:totalRows + rowsInCurrDS, :) = repoDS;
                totalRows = totalRows + rowsInCurrDS;
            end

            % return the data table
            if totalRows < size(cookedData, 1)
                cookedData = cookedData(1:totalRows, :);
            end
            
            ds = cookedData;
            
            %TODO: Add caching ability.
        end
        
    end
    
    methods % Bell-Evans Post-Analysis
        function [params, p, R2] = bellEvansPlot(this, fig, showParams, varargin)
            % Plots the Bell-Evans curve for a set of MPFs and LRs
            % Returns:
            %   params - Bell-Evans parameters object (ForSDAT.Application.Models.BellEvansParams)
            %   p - Bell-Evans regression curve coefficients
            %   R2 - coefficient of determination - R squared
            %
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
            
            if nargin < 3 || isempty(showParams); showParams = true; end
            
            if isempty(this.ExperimentRepository)
                params = ForSDAT.Application.Models.BellEvansParams();
                return;
            end
            
            [params, p, R2] = this.bellEvansFit();
            [mpf, mpfErr, x, xErr] = this.prepareBellEvansData();
            
            if nargin < 4
                varargin = {'Marker', 'o',...
                    'MarkerFaceColor', 'b',...
                    'MarkerEdgeColor', 'b',...
                    'LineStyle', 'none'};
                regPlotParams = {};
            else
                regParamsMask = cellfun(@(p) isequal(p, 'RegressionPlotParams'), varargin);
                if ~any(regParamsMask)
                    regPlotParams = {};
                else
                    regParamsIdx = find(regParamsMask, 1, 'first');
                    regPlotParams = varargin{regParamsIdx + 1};
                    varargin(regParamsIdx:regParamsIdx+1) = [];
                end
            end
            
            if nargin < 2 || isempty(fig)
                fig = gcf();
            elseif isa(fig, 'matlab.graphics.axis.Axes') || isa(fig, 'matlab.ui.control.UIAxes')
                subplot(fig); % focus axes
                fig = ancestor(fig, 'figure');
            else
                fig = figure(fig);
            end
            errorbar(x, mpf, mpfErr, mpfErr, xErr, xErr, varargin{:});
            
            hold on;
            regY = polyval(p, x);
            plot(x, regY, regPlotParams{:});
            
            % Create xlabel
            xlabel({'ln(r)'}, 'FontSize', 24);

            % Create ylabel
            ylabel({'MPF (pN)'}, 'FontSize', 24);

            % Create textbox
            if showParams
                textbox = annotation(fig,'textbox',...
                    [0.15 0.72 0.20 0.19],...
                    'String',{['R^2 = ', num2str(round(R2, 4))],...
                              [sprintf('\\chi_\\beta = %g�%g ', params.Chi, params.ChiErr), char(197)],...
                              sprintf('k_o_f_f = %g�%g �10^-^3Hz', params.Koff*1000, params.KoffErr*1000),...
                              sprintf('\\DeltaG = %g�%g kJ�mol^-^1', params.DeltaG/1000, params.DeltaGErr/1000)},...
                    'FitBoxToText','on',...
                    'FontSize', 18);
            end
        end
        
        function [params, p, R2] = bellEvansFit(this)
        % Fits the Bell-Evans trendline to a set of MPFs and LRs
        % Returns:
        %   params - Bell-Evans parameters object (ForSDAT.Application.Models.BellEvansParams)
        %   p - Bell-Evans regression curve coefficients
        %   R2 - coefficient of determination - R squared
        %
        % Bell-Evans model:
        %   F = (kB*T/X)*ln(Xr/kB*T*koff)
        %   where F is the MPF
        %         kB is boltzmans constant
        %         T is the temperature
        %         X is the distance of the energy barrier needed to be
        %                  overcome for unbinding to occur allong the
        %                  direction of applied force
        %         r is the apparent loading rate
        %         koff is the rate of dissociation at equilibrium
        % 
        % Energy barrier extraction:
        %   G = R*T*ln(koff/A)
        %   where A is the Arrhenius prefactor
        %         R is the gas constant
        %         T is the temperature
        %         koff is the dissociation rate
        %
        
            params = ForSDAT.Application.Models.BellEvansParams();
            if isempty(this.ExperimentRepository)
                return;
            end
            
            [mpf, mpfErr, x, xErr] = this.prepareBellEvansData();
            
%             [p, S] = polyfit(x, mpf, 1);
%             R2 = util.getFitR2(mpf, S);
            
            % use curve fitting toolbox linear fit in order to obtain
            % coefficients confidence intervals, then backward calculate
            % the standard error of each coefficient and extract the
            % standard errors of the kinetic parameters
            fitTypeObj = fittype('poly1');
            [fitObj, gof] = fit(x(:), mpf(:), fitTypeObj);
            R2 = gof.adjrsquare;
            p = [fitObj.p1, fitObj.p2];
            
            % calculate standard errors of coefficients
            alpha = this.BellEvansAlpha;
            confi = confint(fitObj, alpha); % confidence intervals
            t = tinv((1+alpha)/2, gof.dfe); % student distribution
            polyErr = (confi(2,:)-confi(1,:)) ./ (2*t); % standard errors
            relPolyErr = polyErr ./ p;
            
            % extract kinetic values from the fit
            a = p(1); % KBT/chi
            b = p(2); % a*ln(chi/KBT*Koff)
            
            % ln(chi/KBT*Koff)
            bDiva = b/a; 
            bDivaErr = sqrt(sum(relPolyErr.^2)) * bDiva;
            
            % chi/KBT*Koff
            B = exp(bDiva);
            BErr = bDivaErr/bDiva * B;
            
            T = chemo.PhysicalConstants.RT; % RT in K
            heatEnergy = chemo.PhysicalConstants.kB*T;% KBT in J
            
            % Extract transition state distance/rupture distance 
            chi = heatEnergy/a; % in Angstoms
            chiErr = relPolyErr(1)*chi;
            
            % extract dissociation rate
            koff = 1/(B*a);
            koffErr = sqrt(sum([BErr/B, relPolyErr(1)].^2)) * koff;
            
            % calculate the energy barrier
            Af = this.ArrheniusPrefactor;
            R = chemo.PhysicalConstants.R;
            G = -R * T * log(koff/Af) / 1000; % kJ/mol
            GErr = koffErr/koff;
            
            % return parameters and standard errors
            [params.Chi, params.ChiErr] = util.roundError(chi, chiErr);
            [params.Koff, params.KoffErr] = util.roundError(koff, koffErr);
            [params.DeltaG, params.DeltaGErr] = util.roundError(G, GErr);
        end
        
        function [chi, koff, refForce, deltaG] = reverseBellEvansPlot(this, repositoryNames, refLR)
        % Calculates the Bell-Evans parametes for a list of experiment
        % repositories.
        % 
        % [chi, koff, refForce, deltaG] = reverseBellEvansPlot(analyzer, repositoryNames)
        % Calculates the Bell-Evans parameters to a list of experiment
        % repositories (separately for each item on the list)
        % Input:
        %   repositoryNames - a cell array of character vectors containing 
        %                     the list of experiment repositories
        % Output:
        %   chi      - A nx2 matrix containing the value of chi in the 
        %              first column and the standard error in the second.
        %              Chi is the distance between the bound state and
        %              transision state.
        %   koff     - A nx2 matrix containing the value of koff in the 
        %              first column and the standard error in the second.
        %              Koff is the dissociation rate.
        %   refForce - A nx2 matrix containing the value of refForce in the 
        %              first column and the standard error in the second. 
        %              refForce is the rupture force of each system all
        %              calculated for the same loading rate for reference.
        %   deltaG   - A nx2 matrix containing the value of deltaG in the 
        %              first column and the standard error in the second. 
        %              DeltaG is the energy barrier between the bound state
        %              and the transition state
        % [___] = reverseBellEvansPlot(___, refLR)
        % Also takes in a reference loading rate for force calculations
        % Input:
        %   refLR - A positive finite numeric scalar
        %
            
            % validate input
            if nargin < 3 || isempty(refLR); refLR = 5; end
            mustBeNumeric(refLR);
            mustBeFinite(refLR);
            mustBePositive(refLR);
            assert(isscalar(refLR), 'refLR must be a numeric scalar');
            assert(iscellstr(repositoryNames) || isstring(repositoryNames), 'repositoryNames must be a cell array of character vectors or a string array');
            
            repositoryNames = cellstr(repositoryNames);
            chi = zeros(numel(repositoryNames), 2);
            koff = zeros(numel(repositoryNames), 2);
            deltaG = zeros(numel(repositoryNames), 2);
            refForce = zeros(numel(repositoryNames), 2);
            kBT = chemo.PhysicalConstants.kB * chemo.PhysicalConstants.RT;
            
            for i = 1:numel(repositoryNames)
                this.loadExperimentRepository(repositoryNames{i});
                
                params = this.bellEvansFit();
                chi(i, :) = [params.Chi, params.ChiErr];
                koff(i, :) = [params.Koff, params.KoffErr];
                deltaG(i, :) = [params.DeltaG, params.DeltaGErr];
                
                % kbt/chi
                af = kBT/params.Chi;
                aerr = params.ChiErr/params.Chi;
                
                % ln(chi*r/kbt*koff)
                bf = log(params.Chi*refLR/(kBT*params.Koff));
                berr = sqrt(sum([params.ChiErr/params.Chi, params.KoffErr/params.Koff].^2));
                
                % calculate the force and its standard error
                frc = af*bf;
                frcErr = sqrt(sum([aerr/af, berr/bf].^2))*frc;
                refForce(i, :) = [frc, frcErr];
            end
        end
        
        function [mpf, mpfErr, x, xErr] = prepareBellEvansData(this)
        % Gets the full list of MPF vs. ln(r) values from the current
        % experiment repository.
        % Where MPF is the most probable force and r is the loading rate of
        % of a given experiment 
        % 
        % prepareBellEvansData(analyzer)
        % Output:
        %   mpf -    row vector of the MPFs of all experiments in the 
        %            current experiments repository
        %   mpfErr - row vector of the MPF errors of all experiments in the 
        %            current experiments repository
        %   x -      row vector of the ln(r) of all experiments in the 
        %            current experiments repository
        %   xErr -   row vector of the ln(r) errors of all experiments in 
        %            the current experiments repository
        %
        
            data = [this.ExperimentRepository.values{:}];
            
            validValues = data(~[data.IsOutlier]);
            
            lr = vertcat(validValues.LoadingRate);
            lrErr = vertcat(validValues.LoadingRateErr);
            mpf = vertcat(validValues.MostProbableForce);
            mpfErr = vertcat(validValues.ForceErr);
            
            % Calculate reggression
            x = log(lr);
            xErr = lrErr./lr;
        end
    end
    
    methods (Access=protected)
        
        function addExperimentToRepository(this, experiment, dataList)
            repo = this.ExperimentRepository;
            
            % save cooked data and summary results in the experiment 
            % repository
            repo.setExperimentResults(experiment.Id, experiment, dataList);
        end
        
        function removeExperimentFromRepository(this, experiment)
            repo = this.ExperimentRepository;
            
            if repo.isKey(experiment.Id)
                repo.removeAt(experiment.Id);
            end
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
        
%         function markOutlierExperiments(this, window)
%             if nargin < 2 || isempty(window)
%                 window = this.OutlierEvalLogarithmicWindow;
%             end
%             
%             [mpf, ~, lnr] = this.prepareBellEvansData();
%             
%             [x, i] = sort(lnr);
%             dx = [1, diff(x)];
%             incrementMask = dx == 0;
%             x(incrementMask) = x(incrementMask) + abs(0.0001*dx(find(incrementMask) - 1));
%             y = mpf(i);
%             
%             % determine which experiments are outliers
%             % the outlier mask should match the order of the original data
%             otlierMask(i) = isoutlier(y, this.OutlierEvalMethod, window, 'SamplePoints', x);
%             
%             for i = find(otlierMask)
%                 experiment = this.ExperimentRepository.getv(i);
%             end
%         end


        function ds = generateFullRepositoryDataSet(this, summary)
            % generate a full dataset from the archive of the current 
            % experiment repository 
            
            % allocate the combined repository data table
            batchInfo = [summary.BatchInfo];
%             combinedResults = this.
            (sum([batchInfo.N]));
            totalRows = 0;
            
            % load the complete archive instead of loading a single entry
            % each iteration
            this.ExperimentRepository.BatchResults.loadArchive();
            
            % build data table from all experiments in repository
            repoKeys = this.ExperimentRepository.keys();
            for i = 1:numel(repoKeys)
                expId = repoKeys{i};
                
                % fetch experiment from archive
                results = this.ExperimentRepository.BatchResults.getv(expId);
                
                % append experiment results to the repository data table
                rowsInCurrDS = numel(results);
                combinedResults((totalRows + 1):(totalRows + rowsInCurrDS), :) = this.extractDataOfInterest(results);
                
                % burn the experiment ID to the data
                combinedResults{(totalRows + 1):(totalRows + rowsInCurrDS), 'ExperimentId'} = string(expId);
                totalRows = totalRows + rowsInCurrDS;
            end
            
            % burn repository id to the dataset
            combinedResults{:, 'Repository'} = string(this.ExperimentRepository.Name);
            
            % return the data table
            if totalRows < size(combinedResults, 1)
                ds = combinedResults(1:totalRows, :);
            else
                ds = combinedResults;
            end
        end
        
        function validateResultsTable(this, cookedData)
            if ~all(ismember({'Repository', 'ExperimentId', 'CurveId'}, cookedData.Properties.VariableNames))
                throw(MException('ForSDAT:Application:Workflow:CookedDataAnalyzer:MissingKeyVarriable', 'Results table generated by deriving cooked analyzer doesn''t have all Key varriables "Repository", "ExperimentId" and "CurveId"'));
            end
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
        
        % Generates a results-table with n empty records for preallocation
        % purposes
        % The table should include three variables used to uniquely
        % identify the records in the table: 
        % "Repository", "ExperimentId", "CurveId"
        % The other variables in the table are generated by deriving 
        % classes according to the relevant data structures analyzed.
        t = allocateResultsTable(this, n)
    end
    
    methods (Abstract, Access=protected)
        % Generates a results-table from cooked-data list
        t = extractDataOfInterest(this, dataList)
    end
    
    methods (Access=protected)
        function importDetails = getImportDetails(this, path)
            importDetails.path = path;
            importDetails.keyField = this.getDataItemKeyField();
        end
        
        function keyField = getDataItemKeyField(this)
            keyField = 'file';
        end
    end
    
    methods (Access=private)
        function onRepositoryUpdated(this, repo, ~)
            this.ExperimentRepositoryDAO.save(repo);
            this.ExperimentRepositoryDAO.deleteFullRepositoryDataSet(repo);
        end
    end
end

