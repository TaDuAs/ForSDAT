classdef GenericMolecule < chemo.Mol
    properties
        Size = 0;
    end
    
    methods
        function this = GenericMolecule(molSize)
            if nargin >= 1 && ~isempty(molSize)
                this.Size = molSize;
            end
        end
        
        function x = getSize(this)
            x = this.Size;
        end
    end
end

