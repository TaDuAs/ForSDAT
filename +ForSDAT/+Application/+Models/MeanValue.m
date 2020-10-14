classdef MeanValue
    properties
        % Mean value
        Value;  
        
        % Standard deviation
        Std;
        
        % Standard error
        SEM;
        
        % Error calculated using T-Score
        CiError;
        
        % Confidence intervals around the mean value
        ConfidenceIntervals;
        
        % Number of samples
        N;
        
        % Level of significance
        Alpha;  
    end
    
    methods
        function this = MeanValue(arr, a)
            if nargin < 2 || isempty(a); a = 0.05; end
            
            this.Value = mean(arr(:));
            this.Std = std(arr(:));
            this.N = numel(arr);
            this.SEM = this.Std/sqrt(this.N);
            [this.CiError, this.ConfidenceIntervals] = util.econfi(this.Value, a, this.Std, this.N);
            this.Alpha = a;
        end
    end
end

