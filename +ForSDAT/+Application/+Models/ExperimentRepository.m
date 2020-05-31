classdef ExperimentRepository < lists.IDictionary & lists.IObservable
    %EXPERIMENTREPOSITORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name;
    end
    
    properties (Access=private)
        Repository_ lists.Map;
    end
    
    methods (Access=private)
        function onCollectionChanged(this, ~, args)
            this.notify('collectionChanged', args);
        end
    end
    
    methods
        function this = ExperimentRepository(name, varargin)
            this.Name = name;
            this.Repository_ = lists.Map(varargin{:});
            this.Repository_.addlistener('collectionChanged', @this.onCollectionChanged);
        end
        
        function n = length(this)
            n = this.Repository_.length();
        end
        function tf = isempty(this)
            tf = this.Repository_.isempty();
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
        
        function setv(this, key, value)
            this.Repository_.setv(key, value);
        end
        
        function add(this, key, value)
            this.Repository_.add(key, value);
        end
        
        function removeAt(this, key)
            this.Repository_.removeAt(key);
        end
        
        % replaces all items in the dictionary with a new key-value set
        function setVector(this, keys, values)
            this.Repository_.setVector(keys, values);
        end
        
        % clears the dictionary
        function clear(this)
            this.Repository_.clear();
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

