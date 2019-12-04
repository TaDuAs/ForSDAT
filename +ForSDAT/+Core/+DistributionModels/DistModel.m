classdef DistModel < handle & mfc.IDescriptor
    %DISTMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name (1,:) char = 'Normal';
    end
    
    methods (Hidden)
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'Name'};
            defaultValues = {'Normal'};
        end
    end
    
    methods
        function this = DistModel(name)
            this.Name = name;
        end
        
        function pd = fit(this, x)
            pd = {};
        end
    end
end

