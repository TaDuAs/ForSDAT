classdef Randomizer
    methods (Static)
        function x = uniform(size, a, mixedNegPos)
        % uniform(size)
        %   Generates a vector of uniformly distributed random values.
        %       size: 
        %           specifies the dimention sizes of the randomized vector
        %           [dim1, dim2, ...]. If size = [n], returns vector of
        %           size [1, n].
        % uniform(__, amplitude)
        %   Generates a vector of uniformly distributed random values with
        %   a maximum value specified by amplitude.
        %       amplitude:
        %           a scalar value specifying the maximal value in the
        %           output vector
        % uniform(__, range)
        %   Generates a vector of uniformly distributed random values with
        %   in the specified range.
        %       range:
        %           a 2 part vector [min max] specifying the range in
        %           between the randm values should occur
        
        % [mixedNegPos]
            if length(size) == 1
                size = [1, size];
            end
            
            x = rand(size);

            if nargin >= 3 && mixedNegPos
                if isempty(a)
                    a = 1;
                elseif length(a) > 1
                    error('Range and mixed negative-positive values are not supported together');
                end
                x = x * a * 2 - a;
            elseif nargin >= 2
                if length(a) == 1
                    x = x * a;
                elseif length(a) == 2
                    amin = min(a);
                    amax = max(a);
                    x = amin + x*(amax-amin);
                elseif length(a) > 2
                    error('Range must be between two values');
                end
            end
        end
        
        function x = uniformInt(size, amplitude, mixedNegPos)
            if nargin < 3
                mixedNegPos = false;
            end
            
            x = round(Randomizer.uniform(size, amplitude, mixedNegPos));
        end
        
        function x = normal(size, mu, sigma)
            x = normrnd(mu, sigma, size);%randn
        end
        
        function x = gamma(size, a, b)
        % Randomizes gamma values according to gamma parameters a & b
        % Output vector dimentions specified in size
            x = gamrnd(a, b, size);
        end
        
        function x = gammaMpvS(size, mpv, sigma)
        % Randomizes gamma values according to most prevalent value (mpv)
        % and standard deviation (sigma)
        % Output vector dimentions specified in size
            var = sigma.^2;
            a = (mpv.^2)./var + 1;
            b = var./mpv;
            
            x = Randomizer.gamma(size, a, b);
        end
        
        function val = lr(size, k, rv)
        % Generates a random loading rate between 1000 and the applied
        % loading rate (k*rv) in multiplies of 500 pN/sec
        % 
        % focus on lower loading rates
        
            % Use up to 85% of applied loading rate
            maxval = 0.85*k*rv;
        
            val = Randomizer.uniformInt(size, [2, round(maxval/500)])*500 ...
                    - Randomizer.uniformInt(size, [0, round(0.1*maxval/500)])*500;
                
            % Don't allow lr bellow 1000
            belowmin = find(val < 1000);
            val(belowmin) = 1000 + abs(val(belowmin));
        end
    end
    
end

