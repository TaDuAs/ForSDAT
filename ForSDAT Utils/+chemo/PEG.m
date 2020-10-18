classdef PEG < chemo.Polymer
    % PEG: H-(O-CH2-CH2)-OH 
    
    properties (Constant)
        repeatingUnitMw = 12 * 2 + 1 * 4 + 16; % 4H+2C+O
        repeatingUnitStretchedLength = chemo.sp3ChainLength(...
            [chemo.Chemistry.BondLengths.CC_sp3 2*chemo.Chemistry.BondLengths.CO_sp3]); % nm %%% could be 0.28 nm per monomer unit?
        experimentalPersistenceLength = 0.38; % nm, reported in literature
    end
    
    properties
        Mw;
    end
    
    methods
        function this = PEG(mw)
            if nargin >= 1
                if numel(mw) > 1
                    this = arrayfun(@chemo.PEG, mw);
                else
                    this.Mw = mw;
                end
            end
        end
        
        function x = getSize(this)
            x = this.backboneLength(this);
        end
        
        function l = backboneLength(this)
            l = backboneLength@chemo.Polymer(this, [this.Mw]);
        end
        
        function pl = persistenceLength(this)
            pl = [this.experimentalPersistenceLength];
        end
        
        function mw = getRepeatingUnitMw(this)
            mw = [this.repeatingUnitMw];
        end
    end
    
    methods (Hidden)
        function l = getRepeatingUnitStretchedBackboneLength(this)
            l = [this.repeatingUnitStretchedLength];
        end
    end
end