classdef (Abstract) CookedDataAnalyzer < handle
    % CookedDataAnalyzer is a base class for cooked data analyzers.
    % Cooked data analyzers saves and analyzes the processed raw data and
    % manage experminet repository for post-processing the results of 
    % multiple experiments, such as Bell-Evans plot etc.
    % 
    % * Cooked data as opposed to raw data
    
    properties (Hidden)
        ArrheniusPrefactor = 10^-6; % [Hz]
                                    % Li et al. Langmuir 2014, https://doi.org/10.1021/la501189n
                                    % in this article they report using
                                    % A=10^6, but that is a misprint, its in fact 10^-6Hz 
        BellEvansAlpha = 0.95;
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
                try
                    repo = this.ExperimentRepositoryDAO.load(experimentRepoName);
                catch ex
                    disp(getReport(ex));
                    repo = ForSDAT.Application.Models.ExperimentRepository.empty();
                end
                
                % if the file is missing or is empty or is corrupted
                if repo.isemptyHandle() || ~isa(repo, 'ForSDAT.Application.Models.ExperimentRepository')
                    repo = ForSDAT.Application.Models.ExperimentRepository(experimentRepoName);
                    this.ExperimentRepositoryDAO.save(repo);
                end
                
                this.ExperimentRepository = repo;
            end
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
                [isvalid, rejectionMsg] = validator.validate(dataList, results);
                if ~isvalid
                    break;
                end
            end
            
            % if the results are valid add them to the experiments
            % repository
            if isvalid
                this.addExperimentToRepository(results);
            else
                % otherwise, remove experiment from repository 
                this.removeExperimentFromRepository(results);
                
                % raise a warning with the rejection message
                warningMessage = ['Experiment (', results.Id, ') results rejected due to: ', strrep(rejectionMsg, '%', '%%')];
                warning('ForSDAT:CookedDataAnalyzer:ResultsRejected', warningMessage);
            end
        end
        
        function [params, p, R2] = bellEvansPlot(this, fig, varargin)
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
            
            if isempty(this.ExperimentRepository)
                params = ForSDAT.Application.Models.BellEvansParams();
                return;
            end
            
            [params, p, R2] = this.bellEvansFit();
            [mpf, mpfErr, x, xErr] = this.prepareBellEvansData();
            
            if nargin < 3
                varagin = {'Marker', 'o',...
                    'MarkerFaceColor', 'b',...
                    'MarkerEdgeColor', 'b',...
                    'LineStyle', 'none'};
            end
            
            if nargin < 2 || isempty(fig)
                fig = gcf();
            else
                fig = figure(fig);
            end
            errorbar(x, mpf, mpfErr, mpfErr, xErr, xErr, varagin{:});
            
            hold on;
            regY = polyval(p, x);
            plot(x, regY);
            
            % Create xlabel
            xlabel({'ln(r)'}, 'FontSize', 24);

            % Create ylabel
            ylabel({'MPF (pN)'}, 'FontSize', 24);

            % Create textbox
%             textbox = annotation(fig,'textbox',...
%                 [0.15 0.72 0.20 0.19],...
%                 'String',{['R^2 = ', num2str(round(R2, 4))],...
%                           [sprintf('\\chi_\\beta = %g ', params.Chi), char(197)],...
%                           sprintf('k_o_f_f = %g ª10^-^3Hz', params.Koff*1000),...
%                           sprintf('\\DeltaG = %g kJªmol^-^1', params.DeltaG/1000)},...
%                 'FitBoxToText','on',...
%                 'FontSize', 18);
            textbox = annotation(fig,'textbox',...
                [0.15 0.72 0.20 0.19],...
                'String',{['R^2 = ', num2str(round(R2, 4))],...
                          [sprintf('\\chi_\\beta = %g±%g ', params.Chi, params.ChiErr), char(197)],...
                          sprintf('k_o_f_f = %g±%g ª10^-^3Hz', params.Koff*1000, params.KoffErr*1000),...
                          sprintf('\\DeltaG = %g±%g kJªmol^-^1', params.DeltaG/1000, params.DeltaGErr/1000)},...
                'FitBoxToText','on',...
                'FontSize', 18);
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
            
            [mpf, mpfErr, x, xErr] = prepareBellEvansData(this);
            
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
            G = R * T * log(koff/Af) / 1000; % kJ/mol
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
                this.importExperimentsRepository(repositoryNames{i});
                
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
    end
    
    methods (Access=protected)
        
        function addExperimentToRepository(this, experiment)
            repo = this.ExperimentRepository;
            
            repo.setv(experiment.Id, experiment);
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
    
    methods (Access=private)
        function onRepositoryUpdated(this, repo, ~)
            this.ExperimentRepositoryDAO.save(repo);
        end
        
        function [mpf, mpfErr, x, xErr] = prepareBellEvansData(this)
            
            data = [this.ExperimentRepository.values{:}];
            
            lr = vertcat(data.LoadingRate);
            lrErr = vertcat(data.LoadingRateErr);
            mpf = vertcat(data.MostProbableForce);
            mpfErr = vertcat(data.ForceErr);
            
            % Calculate reggression
            x = log(lr);
            xErr = lrErr./lr;
        end
    end
end

