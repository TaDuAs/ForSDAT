classdef NoiseAnomally < handle & mfc.IDescriptor
    %NOISEANOMALLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataPoints;
        length;
        speed;
        samplingRate;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'length', 'speed', 'samplingRate'};
            defaultValues = {'length', [], 'speed', [], 'samplingRate', []};
        end
    end
    
    methods
        function this = NoiseAnomally(length, speed, samplingRate)
            this.length = length;
            this.speed = speed;
            this.samplingRate = samplingRate;
            this.dataPoints = ForSDAT.Core.lvsr2nDataPoints(length, speed, samplingRate);
        end
    end
    
end

