classdef ExperimentRepository < lists.IDictionary & lists.IObservable & mfc.IDescriptor & mxml.IMXmlIgnoreFields
    %EXPERIMENTREPOSITORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name;
    end
    
    properties (Access=private)
        Repository_ lists.Dictionary;
        
        % non serializable field
        BatchResults ForSDAT.Application.Models.ExperimentRepositoryResultsArchive;
    end
    
    methods (Access={?ForSDAT.Application.IO.ExperimentRepositoryDAO})
        function setResultsArchive(this, archive)
            arguments
                this ForSDAT.Application.Models.ExperimentRepository {gen.valid.mustBeValidScalar(this)}
                archive ForSDAT.Application.Models.ExperimentRepositoryResultsArchive {gen.valid.mustBeValidScalar(archive)}
            end
            
            this.BatchResults = archive;
        end
    end
    
    methods (Access=private)
        function raiseCollectionChangedEvent(this, action, key)
            if ischar(key)
                idx = {key};
            else
                idx = key;
            end
            args = lists.CollectionChangedEventData(action, idx);

            % raise event
            notify(this, 'collectionChanged', args);
        end
    end
    
    methods (Hidden)
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
            ctorParams = {'Name'};
            defaultValues = {'Name', ''};
        end
        
        % mxml.IMXmlIgnoreFields interface
        function ignoreList = getMXmlIgnoreFieldsList(this)
            ignoreList = {'BatchResults'};
        end
    end
    
    methods
        function this = ExperimentRepository(name)
            this.Name = name;
            this.Repository_ = lists.Dictionary();
        end
        
        function n = length(this)
            n = this.Repository_.length();
        end
        function tf = isempty(this)
            tf = this.isemptyHandle() || this.Repository_.isempty();
        end
        function s = size(this, dim)
            if nargin < 2
                s = size(this.Repository_);
            else
                s = size(this.Repository_, dim);
            end
        end
        
        function value = getv(this, key)
            value = this.Repository_.getv(key);
        end
        
        function setExperimentResults(this, key, results, dataList)
            this.setv(key, results);
            this.BatchResults.setv(key, dataList);
        end
        
        function setv(this, key, value)
            if this.isKey(key)
                action = 'change';
            else
                action = 'add';
            end
            this.Repository_.setv(key, value);
            this.raiseCollectionChangedEvent(action, key);
        end
        
        function add(this, key, value)
            if this.isKey(key)
                action = 'change';
            else
                action = 'add';
            end
            this.Repository_.add(key, value);
            this.raiseCollectionChangedEvent(action, key);
        end
        
        function removeAt(this, key)
            if this.isKey(key)
                didRemove = true;
            else
                didRemove = false;
            end
            
            this.Repository_.removeAt(key);
            
            if didRemove
                this.raiseCollectionChangedEvent('remove', key);
            end
        end
        
        % replaces all items in the dictionary with a new key-value set
        function setVector(this, keys, values)
            prevKeys = this.keys();
            
            this.Repository_.setVector(keys, values);
            
            if ~isempty(prevKeys)
                this.raiseCollectionChangedEvent('remove', prevKeys);
            end
            if ~isempty(keys)
                this.raiseCollectionChangedEvent('add', keys);
            end
        end
        
        % clears the dictionary
        function clear(this)
            prevKeys = this.keys();
            
            this.Repository_.clear();
            
            if ~isempty(prevKeys)
                this.raiseCollectionChangedEvent('remove', prevKeys);
            end
        end
        
        % Gets all stored keys
        function keys = keys(this)
            keys = this.Repository_.keys();
        end
        
        % Gets all stored values
        function items = values(this)
            items = this.Repository_.values();
        end
        
        % Determines whether the cache stores a value with the specified
        % key
        function containsKey = isKey(this, key)
            containsKey = this.Repository_.isKey(key);
        end
        function tf = containsIndex(this, key)
            tf = this.isKey(key);
        end
    end
end

