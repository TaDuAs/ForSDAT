classdef FJCLoadFitter < ForSDAT.Core.Ruptures.ChainFit
    % Uses taylor approximation of the inverse langevine function:
    % F = KbT/lk*(3*x/L + (9/5)*(x/L).^3 + (297/175)*(x/L).^5 + (1539/875)*(x/L).^7);
    %
    % Where
    % F is the exerted force
    % x is the extenssion of the molecule in the direction of the applied force
    % Kb is the Boltzmann constant
    % T is the absolute temperature
    % lk is the Kuhn length
    % L is the contour length
    
    properties
        T = Simple.Scientific.PhysicalConstants.RT;
        estimatedContourLength = 1;
        estimatedKuhnLength = 1;
        constraintsFunc = [];
    end
    
    methods (Static)
        function fitter = fromLinker(linker, T, constraintFunction)
            if nargin < 3
                constraintFunction = [];
            end
            if nargin < 2
                T = [];
            end
            fitter = FJCLoadFitter(T, [], [], constraintFunction);
            filter.initFromLinker(linker);
        end
    end
    
    methods
        function this = FJCLoadFitter(T, estimatedContourLength, estimatedKuhnLength, constraintsFunction)
            this@ForSDAT.Core.Ruptures.ChainFit(false);
            
            if exist('T', 'var') && ~isempty(T)
                this.T = T;
            end
            if exist('estimatedContourLength', 'var') && ~isempty(estimatedContourLength)
                this.estimatedContourLength = estimatedContourLength;
            end
            if exist('estimatedKuhnLength', 'var') && ~isempty(estimatedKuhnLength)
                this.estimatedKuhnLength = estimatedKuhnLength;
            end
            
            if exist('constraintsFunction', 'var')
                this.constraintsFunc = constraintsFunction;
            end
        end
        
        function init(this, settings)
            this.initFromLinker(settings.measurement.linker);
        end
        
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            import Simple.Math.*;
            kBT = Simple.Scientific.PhysicalConstants.kB * this.T;
            [lk, L, s, mu] = fjc.fit(x, -y, this.estimatedKuhnLength, this.estimatedContourLength, this.T);
            
            func = fjc.createExpretion(kBT, lk, L);
                        
            isGoodFit = L >= x(end) && lk > 0;
            if isGoodFit && ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, fjcFit, s, mu);
            end
        end
    end
    
    methods (Access=private)
        function initFromLinker(this, linker)
            this.estimatedContourLength = linker.backboneLength;
            this.estimatedKuhnLength = linker.experimentalPersistenceLength * 2;
        end
    end
end