classdef ForsSpecExperimentResults 
    properties
        % Experiment information
        Id;
        Speed;
        BatchInfo = ForSDAT.Application.Models.BatchInfo();
        
        % Histogram information
        BinningMethod;
        MinimalBins;
        FittingModel;
        FitR2Threshold;
        
        % Results
        MostProbableForce;
        ForceStd;
        ForceErr;
        LoadingRate;
        LoadingRateErr;
    end
end

