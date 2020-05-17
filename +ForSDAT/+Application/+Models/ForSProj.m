classdef ForSProj < handle
    properties (Access=protected)
        Context gen.Cache;
    end
    
    properties (SetObservable)
        CurrentEditedTask ForSDAT.Core.Tasks.PipelineDATask;
        CurrentViewedTask ForSDAT.Core.Tasks.PipelineDATask;
        DataAccessor Simple.DataAccess.DataAccessor = ForSDAT.Application.IO.JpkFDCDataAccessor.empty();
    end
    
    methods 
        function this = ForSProj(context)
            this.Context = context;
        end
    end
end

