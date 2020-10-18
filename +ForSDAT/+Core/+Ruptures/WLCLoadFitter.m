classdef WLCLoadFitter < ForSDAT.Core.Ruptures.ChainFit & mfc.IDescriptor
    % Bustamante formula:
    % F = KbT/P*[0.25*(1-x/L)^-2 - 0.25 + x/L]
    %
    % Where
    % F is the exerted force
    % x is the extenssion of the molecule in the direction of the applied force
    % Kb is the Boltzmann constant
    % T is the absolute temperature
    % P is the persistence length
    % L is the contour length
    
    properties
        T = chemo.PhysicalConstants.RT;
        estimatedContourLength = 50;
        estimatedPersistenceLength = 0.1;
        constraintsFunc = [];
        model = 'Bustamante';
    end
    
    methods (Hidden) % factory meta data
        % provides initialization description for mfc.MFactory
        % ctorParams is a cell array which contains the parameters passed to
        % the ctor and which properties are to be set during construction
        function [ctorParams, defaultValues] = getMfcInitializationDescription(~)
            ctorParams = {'T', 'estimatedContourLength', 'estimatedPersistenceLength', 'constraintsFunc'};
            defaultValues = {...
                'T', [], ...
                'estimatedContourLength', [], ...
                'estimatedPersistenceLength', [],...
                'constraintsFunc', function_handle.empty()};
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
            fitter = WLCLoadFitter(T, [], [], constraintFunction);
            filter.initFromLinker(linker);
        end
    end
    
    methods
        function this = WLCLoadFitter(T, estimatedContourLength, estimatedPersistenceLength, constraintsFunction)
            this@ForSDAT.Core.Ruptures.ChainFit(false);
            
            if exist('T', 'var') && ~isempty(T)
                this.T = T;
            end
            if exist('estimatedContourLength', 'var') && ~isempty(estimatedContourLength)
                this.estimatedContourLength = estimatedContourLength;
            end
            if exist('estimatedPersistenceLength', 'var') && ~isempty(estimatedPersistenceLength)
                this.estimatedPersistenceLength = estimatedPersistenceLength;
            end
            
            if exist('constraintsFunction', 'var')
                this.constraintsFunc = constraintsFunction;
            end
        end
        
        function init(this, settings)
            this.initFromLinker(mvvm.getobj(settings, 'Measurement.Probe.Linker', chemo.PEG(0)));
        end
        
        function [funcs, isGoodFit, s, mu] = fitAll(this, x, y, ruptureIdx)
            kBT = chemo.PhysicalConstants.kB * this.T;
            ruptureDist = x(ruptureIdx(:));
            LcRange = [ruptureDist(:), inf];
            LpRange = repmat([0, inf], numel(ruptureIdx), 1);
            [p, l, s, mu] = util.wlc.fitAll(x, y, LcRange, LpRange, this.T);

            n = numel(ruptureIdx);
            for i = n:-1:1
                funcs(i) = util.wlc.createExpretion(kBT, p(i), l(i));
            end

            isGoodFit = all(l(:) >= reshape(x(ruptureIdx), [], 1) & p(:) > 0);
            if isGoodFit && ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, wlcFit, s, mu);
            end
        end
        
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            kBT = chemo.PhysicalConstants.kB * this.T;
            [p, l, s, mu] = util.wlc.fit(x, -y, this.estimatedPersistenceLength, this.estimatedContourLength, this.T, this.model);
            
            func = util.wlc.createExpretion(kBT, p, l);
                        
            isGoodFit = l >= x(end) && p > 0;
            if isGoodFit && ~isempty(this.constraintsFunc)
                isGoodFit = this.constraintsFunc(func, wlcFit, s, mu);
            end
        end
    end
    
    methods (Access=private)
        function initFromLinker(this, linker)
            this.estimatedContourLength = linker.backboneLength;
            this.estimatedPersistenceLength = linker.experimentalPersistenceLength;
        end
    end
end