classdef CompositeBaselineDetector < ForSDAT.Core.Baseline.BaselineDetector & mfc.IDescriptor
    %COMPOSITEBASELINEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        primary ForSDAT.Core.Baseline.BaselineDetector;
        secondary ForSDAT.Core.Baseline.BaselineDetector;
        stdThreshold = 0.1;
    end
    
    methods % meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'primaryBaselineDetector', 'secondaryBaselineDetector', 'stdThreshold'};
            defaultValues = {...
                'primaryBaselineDetector', ForSDAT.Core.Baseline.BaselineDetector.empty(),...
                'secondaryBaselineDetector', ForSDAT.Core.Baseline.BaselineDetector.empty()};
        end
    end
    
    methods
        function this = CompositeBaselineDetector(primaryBaselineDetector, secondaryBaselineDetector, stdThreshold)
            this.primary = primaryBaselineDetector;
            this.secondary = secondaryBaselineDetector;
            
            if nargin >= 3 && ~isempty(stdThreshold)
                this.stdThreshold = stdThreshold;
            end
        end
        
        function init(this, varargin)
            this.primary.init(varargin{:});
            this.secondary.init(varargin{:});
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu] = detect(this, x, y)
            
            % Activate primary baseline detection algorithm
            [baseline, y, noiseAmp, coefficients, s, mu] = this.primary.detect(x, y);
            
            % If the standard deviation is larger than the threshold value
            % fraction of the signal range
            if mu{2} > this.stdThreshold * range(y)
                % Activate secondary baseline detection algorithm
                [baseline1, y1, noiseAmp1, coefficients1, s1, mu1] = this.secondary.detect(x, y);
                
                % Keep the better baseline fit
                if mu1{2} < mu{2}
                    baseline = baseline1;
                    y = y1;
                    coefficients = coefficients1;
                    s = s1;
                    mu = mu1;
                    noiseAmp = noiseAmp1;
                end
            end
        end
        
        function b = isBaselineTilted(this)
            b = this.primary.isBaselineTilted();
        end
    end
    
end

