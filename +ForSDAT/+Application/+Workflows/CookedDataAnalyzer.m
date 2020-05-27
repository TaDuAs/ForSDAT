classdef (Abstract) CookedDataAnalyzer < handle
    % CookedDataAnalyzer saves and analyzes the processed raw data.
    % Cooked as opposed to raw data
    
    properties (GetAccess=public, SetAccess=private)
        Context;
        DataAccessor;
        Settings;
    end
    
    properties (Dependent, GetAccess=public, SetAccess=private)
        ExpetimentResultsRepository;
    end
    
    methods % property accessors
        function repo = get.ExpetimentResultsRepository(this)
            repo = this.Context.get('CookedData_ExperimentResultsRepository');
        end
    end
    
    methods
        function this = CookedDataAnalyzer(context)
            this.Context = context;
        end
        
        function this = init(this, dataAccessor, settings)
            this.DataAccessor = dataAccessor;
            this.Settings = settings;
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
        
        function loadPreviouslyProcessedDataOutput(this, importDetails)
        % Loads previously processed data
            this.clearDataList();
            data = this.DataAccessor.importResults(importDetails);
            for i = 1:length(data)
                this.addToDataList(data(i), data(i).(importDetails.keyField));
            end
        end
        
        function startFresh(this)
            this.clearDataList();
        end
        
        function [chi, koff, p, R2] = bellEvansPlot(this, data, fig, plotOpt)
            % Plots the Bell-Evans curve for a set of MPFs and LRs
            % Returns:
            %   chi - energy barrier distance [?]
            %   koff - Dissosiation rate [Hz]
            %   p - Bell-Evans regression curve coefficients
            %   R2 - R^2
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
            
            lr = vertcat(data.lr);
            lrErr = vertcat(data.lrErr);
            mpf = vertcat(data.mpf);
            mpfErr = vertcat(data.mpfErr);
            
            if ~exist('plotOpt', 'var')
                plotOpt = struct(...
                    'Marker', 'o',...
                    'MarkerFaceColor', 'b',...
                    'MarkerEdgeColor', 'b',...
                    'LineStyle', 'none');
            end
            
            % Calculate reggression
            x = log(lr);
            xErr = lrErr./lr;
            
            [p, S] = polyfit(x, mpf, 1);
            R2 = 1 - (S.normr/norm(mpf - mean(mpf)))^2;
            
            fig = mvvm.getobj(plotOpt, 'Fig');
            if isempty(fig)
                fig = gcf();
            else
                fig = figure(fig);
            end
            xyerrorbar(x, mpf, xErr, mpfErr, plotOpt);
            
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
                          ['k_o_f_f=' num2str(round(koff*1000, 2)) 'ª10^-^3Hz']},...
                'FitBoxToText','on',...
                'FontSize', 18);
        end
    end
    
    methods (Access=protected)
        
        function list = getDataList(this)
            % Gets the data list from the context
            % If it is not initialized yet, create a new one
            listRepKey = [class(this) '_DataList'];
            if ~this.Context.hasEntry(listRepKey)
                list = this.createDataListInstance();
                this.Context.set(listRepKey, list);
            else
                list = this.Context.get(listRepKey);
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
        output = wrapUpAndAnalyze(this)
        
        % Examine the analysis results of a single curve and determine
        % whether should accept or reject it.
        bool = examineCurveAnalysisResults(this, data)
    end
    
end

