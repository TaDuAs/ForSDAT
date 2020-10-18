classdef NoiseAnomally < handle & mfc.IDescriptor
    %NOISEANOMALLY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DataPoints;
        Length;
        Speed;
        SamplingRate;
    end
    
    methods % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'Length', 'Speed', 'SamplingRate'};
            defaultValues = {'Length', [], 'Speed', [], 'SamplingRate', []};
        end
    end
    
    methods
        function this = NoiseAnomally(length, speed, samplingRate)
            this.Length = length;
            this.Speed = speed;
            this.SamplingRate = samplingRate;
            this.DataPoints = ForSDAT.Core.lvsr2nDataPoints(length, speed, samplingRate);
        end
    end
    
end

