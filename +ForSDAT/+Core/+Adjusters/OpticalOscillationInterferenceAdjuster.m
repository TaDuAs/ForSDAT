classdef OpticalOscillationInterferenceAdjuster < ForSDAT.Core.Adjusters.LongWaveDisturbanceAdjusterBeta
    % Detects a non-linear long wavelength disturbance to the baseline 
    % according to:
    %   Yu, H., Siewny, M.G., Edwards, D.T., Sanders, A.W. and Perkins, T.T., 
    %   2017.
    %   Hidden dynamics in the unfolding of individual bacteriorhodopsin proteins.
    %   Science, 355(6328), pp.945-950.
    % Supplementary equation S1
    %
    % Yu et al. formula:
    %   dZ_interference = w1 + w2*x + (w3 + w4*x)*sin((w5 + w6*x)*x + w7)
    %   x = Z_zpt - dZ_cantilever
    %   dZ_cantilever = dZ_measured - dZ_interference
    % where
    % dZ_measured is the measured deflection of the cantilever,
    % dZ_interference is the contribution of the optical-interference
    %   artifact on dZ_measured,
    % dZ_cantilever is the actual deflection of the cantilever that gives
    %   rise to the applied force (F_corrected = k*dZ_cantilever)
    % Z_zpt is the distance the cantilever has been retracted
    % x is the extension (i.e., tip-sample separation)
    % w1–w7 are fitting parameters
    
    
    properties
        iterations (1,1) double {mustBeInteger, mustBeFinite, mustBePositive} = 5;
    end
    
    methods
        function this = OpticalOscillationInterferenceAdjuster(...
                fittingRangeParams,...
                fitToSegmentId,...
                fixSegmentId,...
                iterations)
            warning('Don''t use this method, it''s not ready for production...');
            if nargin < 1; fittingRangeParams = []; end
            if nargin < 2; fitToSegmentId = []; end
            if nargin < 3; fixSegmentId = []; end
            
            % call base ctor
            this@ForSDAT.Core.Adjusters.LongWaveDisturbanceAdjusterBeta(fittingRangeParams, [], fitToSegmentId, fixSegmentId);
            
            if nargin >= 4 && ~isempty(iterations)
                this.iterations = iterations;
            end
        end
        
        function [fFixed, fitArgs, waveFVector, shift] = adjust(this, fToFix, zToFix, fFit, zFit, k)
        % Adjusts long-wavelength disturbances to the baseline
            import Simple.croparr;
        
            % Fit wave function
            fFitSegment = croparr(fFit, this.fittingRangeParams.a, this.fittingRangeParams.b);
            zFitSegment = croparr(zFit, this.fittingRangeParams.a, this.fittingRangeParams.b);
            dZ_measured = fFitSegment/k;
            dZ_measured_full = fFit/k;
            
            % prepare fitting function
            [yuEtAlFormula, yuEtAlCoeff] = this.yuEtAlFunction();
            yuEtAlFitType = fittype(yuEtAlFormula, 'independent', 'x', 'coeff', yuEtAlCoeff);
            fitOpt = fitoptions(yuEtAlFitType);
            
            fRange = range(fFit);
            zRange = range(zFit);
            fitOpt.Lower = [min(fFit)-fRange, -fRange/zRange, -fRange, -0.5*fRange, -Inf, -Inf, -Inf];
            fitOpt.Upper = [max(fFit)+fRange, fRange/zRange, fRange, 0.5*fRange, Inf, Inf, Inf];
            fitOpt.MaxFunEvals = 150;
            fitOpt.MaxIter = 100;
            
            % initial assessment of the extension is the measured piezo
            % distance
            % perform the fitting on the fit section, but calculate till
            % convergence with the full vector
            x = zFitSegment; 
            x_full = fFit;
            
            % fit iteratively till convergence
            for i = 1:this.iterations
                fitArgs = fit(x(:), dZ_measured(:), yuEtAlFitType, fitOpt);
                
                % Generate wave vector for the analyzed segment
                dZ_interference = this.calcWaveVector(x, fitArgs);
                dZ_interference_full = this.calcWaveVector(x_full, fitArgs);
                
                % calculate the new cantilever deflection by subtracting
                % the new value of the optical interference
                dZ_cantilever = sort(dZ_measured - dZ_interference);
                dZ_cantilever_full = sort(dZ_measured_full - dZ_interference_full);
                
                % estimate the new extension value
                x = zFitSegment - dZ_cantilever;
                x_full = zFit - dZ_cantilever_full;
            end
            
            waveFVector = this.calcWaveVector(x_full, fitArgs);
            fFixed = fToFix - waveFVector;
            shift = 0;
            
            % debug plot
            if false && Simple.isdebug()
                figure();
                plot(zFitSegment,fFitSegment,zToFix,fToFix,zToFix,waveFVector,zToFix,fToFix-waveFVector);
                legend('Fit To...', 'Retract', 'Fit Wave', 'Retract Signal');
                title('Fourier Fit Baseline');
            end
        end
        
        function waveFVector = calcWaveVector(this, z, fitArgs)
            [foo, coeff] = this.yuEtAlFunction();
            val = {};
            for i = 1:numel(coeff)
                val{i} = fitArgs.(coeff{i});
            end
            
            waveFVector = foo(val{:}, z);
        end
        
        function [foo, coeff] = yuEtAlFunction(this)
            % generates an anonymous function representation of Yu et al.
            % formula
            foo = @(w1, w2, w3, w4, w5, w6, w7, x) w1 + w2*x + (w3 + w4*x).*sin((w5 + w6*x).*x + w7);
%             foo = @(w1, w2, w3, w4, w5, w6, w7, x) w1 + w2*x + (w3 + w4*x).*sin((w5 + w6*x) + w7);
            
            if nargout > 1
                coeff = {'w1', 'w2', 'w3', 'w4', 'w5', 'w6', 'w7'};
%                 coeff = {'w1', 'w2', 'w3', 'w4', 'w5', 'w6', 'w7'};
            end
        end
    end
end