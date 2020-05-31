classdef SuccessRateValidator < ForSDAT.Application.Workflows.CRV.ICookedResultValidator
    properties
        AcceptedPercentage = 1;
    end
    
    methods
        function [isvalid, msg] = validate(this, dataList, results)
            msg = '';
            successRate = numel(dataList) / results.BatchInfo.N * 100;
            isvalid = successRate >= this.AcceptedPercentage;
            
            if ~isvalid
                msg = sprintf('Experiment results were rejected due to low success rate %g%%', round(successRate, 2));
            end
        end
    end
end

