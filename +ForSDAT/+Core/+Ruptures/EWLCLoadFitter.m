classdef EWLCLoadFitter < ChainFit
    % Marko-Siggia WLC formula:
    % Kpeg = dF/dx = KbT/P*L * (0.5(1-x/L0)^-3 + 1)
    % Therefore, F = KbT/P*L * (0.25(1-x/L)^-3 + 1)
    %
    % Where
    % F is the exerted force
    % x is the extenssion of the molecule in the direction of the applied force
    % Kpeg is the spring constant of the PEG molecule
    % Kb is the Boltzmann constant
    % T is the absolute temperature
    % P is the persistence length 
    % L is the contour length
    
    properties
        T = 298;
        L = 1;
        P = 1;
    end
    
    methods
        function [func, isGoodFit, s, mu] = dofit(this, x, y)
            import Simple.Scientific.PhysicalConstants;
            import Simple.Math.Ex.*;
            wlcFunction = [num2str(PhysicalConstants.kB * this.T) '/(P*L)*(0.25*((1-(x/L))^(-3))+1)'];
            [wlcFit, s, mu] = fit(x(:), y(:), wlcFunction);%, 'Start', [this.P, this.L]);
            
            func =...
                Multiply(...
                    Divide(...
                        Scalar(PhysicalConstants.kB * this.T),...
                        Multiply(Scalar(wlcFit.P), Scalar(wlcFit.L))),...
                    Add(...
                        One(),...
                        Multiply(...
                            Scalar(0.25),...
                            Power(...
                                Subtract(One, Divide(X, Scalar(wlcFit.L))),...
                                Scalar(-3)))));
            
            isGoodFit = wlcFit.L > 0 && wlcFit.P > 0;
        end
    end
    
end