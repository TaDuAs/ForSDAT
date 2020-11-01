classdef ForcePlateauBaselineDetector < ForSDAT.Core.Baseline.SimpleBaselineDetector & mfc.IDescriptor
    properties (SetObservable)
        binningMethod = 'sqrt';
        minimalBins = 15;
    end
    
    methods (Hidden)
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        % 
        % ctor dependency rules:
        %   Extract from fields:
        %       Parameter name is the name of the property, with or without
        %       '&' prefix
        %   Hardcoded string: 
        %       Parameter starts with a '$' sign. For instance, parameter
        %       value '$Pikachu' is translated into a parameter value of
        %       'Pikachu', wheras parameter value '$$Pikachu' will be
        %       translated into '$Pikachu' when it is sent to the ctor
        %   Optional ctor parameter (key-value pairs):
        %       Parameter name starts with '@'
        %   Get parameter value from dependency injection:
        %       Parameter name starts with '%'
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'stdScore'};
            defaultValues = {'stdScore', []};
        end
    end
    
    methods
        % ctor
        function this = ForcePlateauBaselineDetector(stdScore)
            if nargin < 1 
                stdScore = [];
            end
            
            this@ForSDAT.Core.Baseline.SimpleBaselineDetector(1, stdScore, true);
        end
        
        function [baseline, y, noiseAmp, coefficients, s, msd] = detect(this, x, y)
        % Finds the baseline of the curve
        % Returns:
        %   baseline - the numeric value of the baseline
        %   y - the force vector, unchanged by this method
        %   noiseAmp - the evaluated amplitude of noise oscilations
        %   coefficients - the coefficients of the baseline polynomial fit
        %   s - standard error values
        %   msd - {mean, std}
        
            % get data segments which correspond to the force plateau/peaks
            % assume this is the baseline's controbution
            [xp, yp] = this.getForcePlateauSubset(x, y);
            
            % perform simple baseline detection on the plateau segments
            [baseline, ~, noiseAmp, coefficients, s, msd] = detect@ForSDAT.Core.Baseline.SimpleBaselineDetector(this, xp, yp);
            
            % subtract baseline
            y = y - polyval(coefficients, x, s);
        end
        
        function [xp, yp, mask] = getForcePlateauSubset(this, x, y)
            % prepare histogram data
            statData = histool.stats(y, 'BinningMethod', this.binningMethod, 'MinimalBins', this.minimalBins);

            % find plateau
            avgFreq = mean(statData.Frequencies);
            stdFreq = std(statData.Frequencies);
            plateauThreshold = avgFreq + 1*stdFreq;
            
            % find the frequencies and force values in the plateau
            forcePlateau = statData.BinEdges(statData.Frequencies > plateauThreshold);
            
            % prepare mask of the data that corresponds to the plateau
            mask = y >= min(forcePlateau) & y <= max(forcePlateau);
            xp = x(mask);
            yp = y(mask);
        end
        
        function b = isBaselineTilted(this)
            b = true;
        end
    end
end