classdef SingleMoleculeInteraction
    
    
    properties
        X;
        Koff;
    end
    
    methods
        function this = SingleMoleculeInteraction(x, k)
            % x in A, k in Hz
            this.X = x;
            this.Koff = k;
        end
        
        function f = calcForce(this, r, T)
        % calculates the adhesion rupture force required for this system
        % according to the Bell-Evans-Ritchie model at a specified loading
        % rate.
        % this.calcBERRuptureForce(r, [T]):
        %   r: a vector of apparent loading rates in pN/sec
        %   T (optional): the temperature (in K) if not specified, uses RT
        
            % if T is not specified, use room temp (RT)
            if nargin < 3
                T = Simple.Scientific.PhysicalConstants.RT;
            end
            
            % calculate thermal energy
            kBT = physconst('Boltzmann')*T*10^22; % J = N*m = 10^10A*10^9pN = 10^19A*nN
            
            % calculate bell evans estimation
            f = (kBT/this.X)*log(this.X*r/(kBT*this.Koff));
            %f = bellevans(r, this.X, this.Koff, T);
        end
    end
    
    methods (Static)
        function p = BiotinAvidin()
            % De Paris, R., et al., 2000, Single Molecules, pp. 285-290,
            % Force spectroscopy and dynamics of the biotin-avidin bond studied by scanning force microscopy. 
            p = SingleMoleculeInteraction(20, 10^-3);
        end
        
        function p = DopaTiO2()
            % Das, P. & Reches, M., 2016, Nanoscale, 8(33), 15309-15316
            % Revealing the role of catechol moieties in the interactions between peptides and inorganic surfaces
            p = SingleMoleculeInteraction(1.15, 2*10^-3);
        end
    end
    
end

