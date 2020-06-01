classdef ManualSimpleWave < spec.models.Model
    % ManualSimpleWave accepts boundaries from a curve and determines which
    % simple periodic function best fits the data within these boundaries
    
    properties (GetAccess=public, SetAccess=private)
        Func function_handle;
    end
    
    properties (Access=private)
        tBounds;
        yBounds;
    end
    
    methods
        function this = ManualSimpleWave(tb, yb)
            [this.tBounds, tbi] = sort(tb);
            this.yBounds = yb(tbi);
        end
        
        function this = optimize(this, x, y)
            tb = this.tBounds;
            yb = this.yBounds;
            
            % calculate deltas and guess frequency and phase
            dt = range(tb);
            
            % prep guess function array
            guessFunctions = {@sin, @(x) -sin(x), @cos, @(x) -cos(x)};
            nWaveTypes = numel(guessFunctions);
            
            %
            % prep guess parameter sets
            %
            
            % frequency
            guessFreq = [2*pi, pi, 0.5*pi] / dt;
            nGuesses = numel(guessFreq);
            
            % amplitude
            guessAmpSin = [0.5, 1, 1] * range(yb);
            guessAmpCos = [0.5, 0.5, 1] * range(yb);
            
            % phase shift
            guessPhase = guessFreq*tb(1);
            
            % baseline shift 
            shift = yb(1) + [zeros(1, nGuesses*2), -1*guessAmpCos, guessAmpCos]; % this is already 1x12 vector - ready for final calculation

            % prep final function/parameter-set arrays
            guessAmp = [repmat(guessAmpSin, 1, 2), repmat(guessAmpCos, 1, 2)];
            guessFreq = repmat(guessFreq, 1, nWaveTypes);
            guessPhase = repmat(guessPhase, 1, nWaveTypes);
            foo = repelem(guessFunctions, 1, nGuesses);
            
            % calculate the inner wave variable
            guessX = x(:)*guessFreq - guessPhase;

            % calculate estimations using all functions
            guessY = zeros(size(guessX));
            for i = 1:numel(foo)
                estimFunc = foo{i};

                guessY(:,i) = guessAmp(i) .* estimFunc(guessX(:, i)) + shift(i);
            end
            
            % calculate cost function
            yc = y(:);
            cost = zeros(1, size(guessY, 2));
            for j = 1:size(guessY, 2)
                cost(j) = this.doCalculateRCF(yc, guessY(:, j));
            end
            
            % find best estimate
            [~, bestJ] = min(cost);
            
            % save optimiazation results
            this.Func = foo{bestJ};
            this.Parameters = [guessAmp(bestJ); guessFreq(bestJ); guessPhase(bestJ); shift(bestJ)];
        end
        
        % Execute the model calculation
        function y = doCalc(this, x, b)
            y = b(1) * this.Func(b(2) * x - b(3)) + b(4);
        end
    end
    
    methods (Access=protected) 
        % Validate model parameter set
        function validateParameterSet(this, paramSet)
            assert(iscolumn(paramSet) && numel(paramSet) == 4,...
                'ManualWave is a simple Sine/Cosine wave function. Parameter set should include [amplitude; frequency; phase; shift]');
        end
    end
end

