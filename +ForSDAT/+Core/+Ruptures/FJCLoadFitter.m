classdef FJCLoadFitter < ForSDAT.Core.Ruptures.ChainFit & mfc.IDescriptor
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
        T = chemo.PhysicalConstants.RT;
        estimatedContourLength = 1;
        estimatedKuhnLength = 1;
        constraintsFunc = [];
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'T', 'estimatedContourLength', 'estimatedKuhnLength', 'constraintsFunction'};
            defaultValues = {...
                'T', [], ...
                'estimatedContourLength', [], ...
                'estimatedKuhnLength', [],...
                'constraintsFunction', function_handle.empty()};
        end
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
            this.initFromLinker(mvvm.getobj(settings, 'Measurement.Probe.Linker', chemo.PEG(0)));
        end
        
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            kBT = chemo.PhysicalConstants.kB * this.T;
            [lk, L, s, mu] = util.fjc.fit(x, -y, this.estimatedKuhnLength, this.estimatedContourLength, this.T);
            
            func = fjc.createExpretion(kBT, lk, L);
                        
            isGoodFit = L >= x(end) && lk > 0;
            if isGoodFit && ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, fjcFit, s, mu);
            end
        end
        
        function [funcs, isGoodFit, s, mu] = fitAll(this, x, y, ruptureIdx)
            kBT = chemo.PhysicalConstants.kB * this.T;
            ruptureDist = x(ruptureIdx(:));
            LcRange = [ruptureDist(:)*0.95, ruptureDist(:)*1.1];
            klRange = repmat([0, 0.35], numel(ruptureIdx), 1);
            [p, l, s, mu] = util.fjc.fitAll(x, y, LcRange, klRange, this.T);
            
            n = numel(ruptureIdx);
            for i = n:-1:1
                funcs(i) = util.fjc.createExpretion(kBT, p(i), l(i));
            end
            
            isGoodFit = all(l(:) >= reshape(x(ruptureIdx), [], 1) & p(:) > 0);
            if isGoodFit && ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, wlcFit, s, mu);
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