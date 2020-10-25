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
            if nargin < 1; arr = []; end
            if nargin < 2 || isempty(a); a = 0.05; end
            
            this = this.setData(arr, a);
        end
        
        function this = setData(this, arr, a)
            if nargin < 1; arr = []; end
            if nargin < 2 || isempty(a); a = 0.05; end
            
            this.Value = mean(arr(:));
            this.Std = std(arr(:));
            this.N = this.calcN(arr);
            this.SEM = this.Std/sqrt(this.N);
            [this.CiError, this.ConfidenceIntervals] = util.econfi(this.Value, a, this.Std, this.N);
            this.Alpha = a;
        end
    end
    
    % combining groups
    methods 
        function n = calcN(A, arr)
            if nargin < 2
                n = sum(arrayfun(@(mv) mv.N, A));
            elseif isnumeric(arr)
                n = numel(arr);
            elseif isa(arr, 'ForSDAT.Application.Models.MeanValue')
                n = sum(arrayfun(@(mv) mv.N, arr));
            else
                throw(MException('ForSDAT:Application:Models:MeanValue:InvalidValueType', 'ForSDAT.Application.Models.MeanValue can only perform calculations on numeric values and ForSDAT.Application.Models.MeanValue'));
            end
        end
        
        function combinedMean = mean(A)
            % calculateas the combined groups mean value
            n = zeros(size(A));
            u = zeros(size(A));
            for i = 1:numel(A)
                mv = A(i);
                n(i) = mv.N;
                u(i) = mv.Value;
            end
            
            combinedMean = sum(u.*n)/sum(n);
        end
        
        function combinedSD = std(A)
            % calculates the combined groups standard deviation
            
            if numel(A) == 0
                combinedSD = [];
                return;
            end
            
            cn = A(1).N;
            cu = A(1).Value;
            cv = A(1).Std^2;
            
            for i = 2:numel(A)
                n2 = A(i).N;
                u2 = A(i).Value;
                v2 = A(i).Std^2;
                
                % see Cochrane handbook Version 6.1, 2020, table 6.5.a
                cv = ((cn-1)*cv + (n2-1)*v2 + cn*n2/(cn+n2)*(cu^2 + u2^2 -2*cu*u2))/(cn + n2 - 1);
                cu = (cu*cn + u2*n2)/(cn+n2);
                cn = sum(cn, n2);
            end
            
            % take the square root of the combined groups' variance
            combinedSD = sqrt(cv);
        end
    end
end

