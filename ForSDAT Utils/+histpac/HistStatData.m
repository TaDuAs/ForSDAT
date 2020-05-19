classdef HistStatData
    properties
        % Histogram
        NBins;
        BinEdges;
        Frequencies;
        
        % Distribution
        HasDistribution = false;
        MPV;
        StandardDeviation;
        PDF;
        GoodnessOfFit;
    end
end

