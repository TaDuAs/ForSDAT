classdef ForSpecProj < ForSDAT.Application.Models.ForSProj & mfc.IDescriptor
    properties (Access=private)
        onChangeListeners_;
    end
    
    properties (SetObservable)
        Settings ForSDAT.Core.Setup.AnalysisSettings;
        RawAnalyzer ForSDAT.Core.RawDataAnalyzer;
        CookedAnalyzer ForSDAT.Application.Workflows.CookedDataAnalyzer = ForSDAT.Application.Workflows.SMICookedDataAnalyzer.empty();
        
        % The name of current experiment collection
        % I.E certain molecule/treatment/parameters etc.
        % All speeds/cantilevers/loading rates of a given
        % molecule/treatment/parameters will be part of the same experiment
        % collection to be analyzed together in the end
        % Used to identify an experiments repository and to save/load it
        ExperimentCollectionName;
        
        % The identifier of the current experiment, i.e:
        % retract speed = 0.2
        % spring constant = 0.5
        % and so on...
        % used to identify the results of a specific measurement in the
        % experiments repository
        RunningExperimentId;
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
            ctorParams = {'%AnalysisContext'};
            defaultValues = {};
        end
    end
    
    methods % Ctor
        function this = ForSpecProj(context)
            this@ForSDAT.Application.Models.ForSProj(context);
            
            this.onChangeListeners_ = addlistener(this, 'DataAccessor', 'PostSet', @this.notifyCookedAnalyzer);
            this.onChangeListeners_(2) = addlistener(this, 'CookedAnalyzer', 'PostSet', @this.notifyCookedAnalyzer);
            this.onChangeListeners_(3) = addlistener(this, 'RawAnalyzer', 'PostSet', @this.notifyRawAnalyzer);
            this.onChangeListeners_(4) = addlistener(this, 'Settings', 'PostSet', @this.notifyAllAnalzers);
            this.onChangeListeners_(5) = addlistener(this, 'ExperimentCollectionName', 'PostSet', @this.notifyCookedAnalyzer);
            this.onChangeListeners_(6) = addlistener(this, 'RunningExperimentId', 'PostSet', @this.notifyCookedAnalyzer);
        end
    end
    
    methods (Access=private)
        function notifyAllAnalzers(this, src, e)
            this.notifyCookedAnalyzer(src, e);
            this.notifyRawAnalyzer(src, e);
        end
        
        function notifyCookedAnalyzer(this, src, e)
            obj = this.CookedAnalyzer;
            if ~isempty(obj)
            	obj.init(this.DataAccessor, this.Settings, this.RunningExperimentId, this.ExperimentCollectionName);
            end
        end
        
        function notifyRawAnalyzer(this, src, e)
            obj = this.RawAnalyzer;
            if ~isempty(obj) && ~isempty(this.Settings)
            	obj.init(this.Settings);
            end
        end
        
    end
end

