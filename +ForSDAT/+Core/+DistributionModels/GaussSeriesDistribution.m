classdef GaussSeriesDistribution < handle
    %GAUSSSERIESDISTMODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(GetAccess='public',SetAccess='protected')
%Order - The order of the gaussian series
%   Order is a 
        Order (1,1) int {isPositiveIntegerValuedNumeric} = 1;
        
%ParameterValues Parameter values.
%    ParameterVales is a vector containing the values of the parameters of
%    the probability distribution.
        ParameterValues;
    end
    
    properties (GetAccess=public, Dependent)
%NumParameter Number of parameters.
%    NumParameters is the number of parameters in the distribution.
%
%    See also ParameterValues.
        NumParameters;
                
%ParameterNames Parameter names.
%    ParameterNames is a cell array of strings containing the names of the
%    parameters of the probability distribution.
%
%    See also ParameterValues, ParameterDescription.
        ParameterNames;
    end
    methods
        function n = get.NumParameters(this)
            n = this.Order * this.NumParamsPerSeriesElement;
        end
        
        function names = get.ParameterNames(this)
            params = repmat(this.ParamNamesPerSeriesElement, 1, this.Order);
            elements = arrayfun(@num2str, repelem(1:this.Order, 1, this.NumParamsPerSeriesElement), 'UniformOutput', false);
            names = strcat(params, elements);
        end
    end
    
    properties(GetAccess='public',Constant=true)
        NumParamsPerSeriesElement = prob.NormalDistribution.NumParameters;
        ParamNamesPerSeriesElement = prob.NormalDistribution.ParameterNames;
        
%DistributionName Distribution name.
%    The DistributionName property indicates the name of the probability
%    distribution.
%
%    See also ParameterNames, ParameterValues.
        DistributionName = 'GaussSeries';
        
%ParameterDescription Parameter description.
%    ParameterNames is a cell array of strings containing short
%    descriptions of the parameters of the probability distribution.
%
%    See also ParameterNames, ParameterValues.
        ParameterDescription = prob.NormalDistribution.ParameterDescription;
        end
    
    methods
        function this = GaussSeriesDistribution(order, paramValues)
            this.Order = order;
            
            n = numel(paramValues);
            if order * this.NumParamsPerSeriesElement ~= n
                throw(MException('GaussSeriesDistribution:ParametersNumberInvalid', 'Number of distribution parameters must be %dxorder of gauss series, but was %d', this.NumParamsPerSeriesElement, n));
            end
        end
        
        function m = mean(this)
            m = this.ParameterValues(1:2:end);
        end

        function v = var(this)
            v = this.ParameterValues(2:2:end);
        end
    end
end

