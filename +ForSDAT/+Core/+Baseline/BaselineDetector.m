classdef BaselineDetector < handle
    %BASELINEDETECTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        
        function this = BaselineDetector()
        end
        
        function b = isBaselineTilted(this)
            b = false;
        end
        
        function [baseline, y, noiseAmp, coefficients, s, mu] = detect(this, x, y)
            error('not implemented');
        end
        
        function init(~, varargin)
            % noop
        end
    end
    
end

