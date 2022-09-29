classdef AnalysisViewFactory < ForSDAT.Application.Client.AnalysisViewFacade.IAnalysisViewFactory
    
    methods
        function obj = AnalysisViewFactory(inputArg1,inputArg2)
            %ANALYSISVIEWFACTORY Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
    end
end

