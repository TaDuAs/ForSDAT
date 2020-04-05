classdef ForSpecProj < ForSDAT.Application.Models.ForSProj & mfc.IDescriptor
    properties (Access=private)
        onChangeListeners_;
    end
    
    properties (SetObservable)
        Settings;
        RawAnalyzer ForSDAT.Core.RawDataAnalyzer;
        CookedAnalyzer ForSDAT.Application.Workflows.CookedDataAnalyzer = ForSDAT.Application.Workflows.SMICookedDataAnalyzer.empty();
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
        end
    end
    
    methods (Access=private)
        function notifyAllAnalzers(this, ~, ~)
            this.notifyCookedAnalyzer();
            this.notifyRawAnalyzer();
        end
        
        function notifyCookedAnalyzer(this, ~, ~)
            obj = this.CookedAnalyzer;
            if ~isempty(obj)
            	obj.init(this.Context, this.dataAccessor, this.settings);
            end
        end
        
        function notifyRawAnalyzer(this, ~, ~)
            obj = this.RawAnalyzer;
            if ~isempty(obj) && ~isempty(this.Settings)
            	obj.init(this.Settings);
            end
        end
        
    end
end

