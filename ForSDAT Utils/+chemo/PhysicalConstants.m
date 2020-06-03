classdef PhysicalConstants
    properties (Constant)
        kB = physconst('Boltzmann')*10^21 % Boltzmann constant [pN*nm/K], N*m/K=10^12pN*10^9nm/K = 10^21pN*nm/K
        RT = 298; % Room Temprature [K]
        NAvogadro = 6.02e23; % Avogadros constant
        R = physconst('Boltzmann') * chemo.PhysicalConstants.NAvogadro; % Gas constant [J/(mol*K)]
    end
end

