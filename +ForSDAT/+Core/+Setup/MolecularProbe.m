classdef MolecularProbe < ForSDAT.Core.Setup.ForSProbe
    %MOLECULARPROBE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Linker chemo.Polymer = chemo.PEG(0);
        Molecule chemo.Mol = chemo.PEG(0);
    end
    
    methods
        function x = maxLength(this)
            x = this.Linker.getSize() + this.Molecule.getSize();
        end
        
        function x = minLength(this)
            x = this.Linker.getSize();
        end
    end
end

