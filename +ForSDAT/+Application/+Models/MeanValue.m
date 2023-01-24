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
        function this = MeanValue(arr, a, flag)
            if nargin < 1; arr = []; end
            if nargin < 2 || isempty(a); a = 0.05; end
            if nargin < 3 || isempty(flag); flag = 'omitnan'; end
            
            this = this.setData(arr, a, flag);
        end
        
        function this = setData(this, arr, a, flag)
            if nargin < 1; arr = []; end
            if nargin < 2 || isempty(a); a = 0.05; end
            if nargin < 3 || isempty(flag); flag = 'omitnan'; end
            
            if strcmp(flag, 'zeronan') && isnumeric(arr)
                arr(isnan(arr)) = 0;
                flag = 'omitnan';
            end
            
            this.Value = mean(arr(:), flag);
            this.Std = std(arr(:), flag);
            this.N = this.calcN(arr, flag);
            this.SEM = this.Std/sqrt(this.N);
            [this.CiError, this.ConfidenceIntervals] = util.econfi(this.Value, a, this.Std, this.N);
            this.Alpha = a;
        end
    end
    
    % combining groups
    methods 
        function n = calcN(A, arr, flag)
            if nargin < 3 || isempty(flag) || strcmp(flag, 'zeronan'); flag = 'omitnan'; end
            if nargin < 2
                n = sum(arrayfun(@(mv) mv.N, A), flag);
            elseif isnumeric(arr)
                if strcmp(flag, 'omitnan')
                    n = sum(~isnan(arr));
                else
                    n = numel(arr);
                end
            elseif isa(arr, 'ForSDAT.Application.Models.MeanValue')
                n = sum(arrayfun(@(mv) mv.N, arr), flag);
            else
                throw(MException('ForSDAT:Application:Models:MeanValue:InvalidValueType', 'ForSDAT.Application.Models.MeanValue can only perform calculations on numeric values and ForSDAT.Application.Models.MeanValue'));
            end
        end
        
        function combinedMean = mean(A, flag)
            if nargin < 2 || isempty(flag); flag = 'omitnan'; end
            
            % calculateas the combined groups mean value
            n = zeros(size(A));
            u = zeros(size(A));
            for i = 1:numel(A)
                mv = A(i);
                n(i) = mv.N;
                
                if isnan(mv.Value) && strcmp(flag, 'zeronan')
                    u(i) = 0;
                    n(i) = 0;
                else
                    u(i) = mv.Value;
                end
            end
            
            if strcmp(flag, 'zeronan')
                flag = 'omitnan';
            end
            combinedMean = sum(u.*n, flag)/sum(n, flag);
        end
        
        function combinedSD = std(A, flag)
            if nargin < 2 || isempty(flag); flag = 'omitnan'; end
            % calculates the combined groups standard deviation
            
            if numel(A) == 0
                combinedSD = [];
                return;
            end
            
            cn = A(1).N;
            cu = A(1).Value;
            cv = A(1).Std^2;
            
            if isnan(cu)
                cu = 0;
                cv = 0;
                cn = 0;
            end
            
            for i = 2:numel(A)
                n2 = A(i).N;
                u2 = A(i).Value;
                v2 = A(i).Std^2;
                
                if isnan(u2) && strcmp(flag, 'omitnan')
                    continue;
                elseif isnan(u2) && strcmp(flag, 'zeronan')
                    u2 = 0;
                    v2 = 0;
                end
                
                % see Cochrane handbook Version 6.1, 2020, table 6.5.a
                cv = ((cn-1)*cv + (n2-1)*v2 + cn*n2/(cn+n2)*(cu^2 + u2^2 -2*cu*u2))/(cn + n2 - 1);
                cu = (cu*cn + u2*n2)/(cn+n2);
                cn = cn + n2;
            end
            
            % take the square root of the combined groups' variance
            combinedSD = sqrt(cv);
        end
    end
end

