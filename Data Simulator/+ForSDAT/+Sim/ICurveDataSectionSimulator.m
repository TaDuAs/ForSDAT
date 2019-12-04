classdef (Abstract) ICurveDataSectionSimulator < handle & matlab.mixin.Heterogeneous
    methods (Abstract)
        [x, y, t] = simulateData(this, t, x, curve);
    end
end

