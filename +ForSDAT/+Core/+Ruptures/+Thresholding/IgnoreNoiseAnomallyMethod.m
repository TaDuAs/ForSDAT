classdef IgnoreNoiseAnomallyMethod < ForSDAT.Core.Ruptures.Thresholding.IThresholdMethod & mfc.IDescriptorStruct
    %SIZEVSNOISEMETHOD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        noiseAnomallyFetcher IoC.IDependencyFetcher = IoC.DependencyFetcher.empty();
    end
    
    methods (Hidden) % meta data
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            % The pairs of optional parameters will be translated by the factory to key-value parameters.
            % for instance {'@child1', 'child1'} will be translated to {'child1', [the value extracted from the child1 field in the extractor object]}
            ctorParams = {'%NoiseAnomallyFetcher'};

            % The default values of mandatory parameters are denoted as key-value pairs where the name of the dependency is followed by the default value
            % when the ctor will be invoked, id value will be extracted from the extractors 'id' field if it exists, if it doesn't, the default value (here '')
            % will be sent instead.
            defaultValues = {};
        end
    end
    
    methods
        function this = IgnoreNoiseAnomallyMethod(noiseAnomallyFetcher)
            this.noiseAnomallyFetcher = noiseAnomallyFetcher;
        end

        function mask = apply(this, rsReRf, frc, dist, noiseAmp)
            n = size(rsReRf, 2);
            mask = true(1, n);
            prevRs = 1;
            noiseAnomally = this.noiseAnomallyFetcher.fetch();
            for i = 1:n
                currRs = rsReRf(1, i);
                prevPointAtNoiseDomain = prevRs + find(frc(prevRs:currRs) >= -noiseAmp, 1, 'last') - 1;
                mask(i) = isempty(prevPointAtNoiseDomain) || ...
                          ((currRs - prevPointAtNoiseDomain) > noiseAnomally.dataPoints);
                prevRs = currRs;
            end
        end
    end
end

