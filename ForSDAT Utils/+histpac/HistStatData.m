classdef HistStatData
    properties
        % Histogram
        NBins;
        BinEdges;
        Frequencies;
        
        % Distribution
        HasDistribution = false;
        IsNormalized = false;
        MPV;
        StandardDeviation;
        PDF;
        GoodnessOfFit;
    end
end

