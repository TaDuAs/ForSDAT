classdef SCFSExperimentResults 
    properties
        % Experiment information
        Id;
        Speed;
        BatchInfo = ForSDAT.Application.Models.BatchInfo();
        
        % Results
        MaxAdhesionForce ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        MaxAdhesionDistance ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        DetachmentWork ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        NRuptures ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        RuptureForce ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        InterRuptureDistance ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        MaxRuptureDistance ForSDAT.Application.Models.MeanValue = ForSDAT.Application.Models.MeanValue();
        
        % Results Lists
        RuptureForceList;
        RuptureDistanceList;
    end
end

