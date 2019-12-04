function f = bellevans(r, chi, koff, T)
    import Simple.Scientific.PhysicalConstants;
    if nargin < 4
        T = PhysicalConstants.RT;
    end
    kbt = PhysicalConstants.kB * T;
    f = kbt/chi*log(chi*r/(kbt*koff));
end

