classdef CurveSimulatorDA < Simple.DataAccess.FileSystemDataAccessor
    %CURVESIMULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Simulator ForSDAT.Sim.CurveSimulator;
    end
    
    methods 
        function this = CurveSimulatorDA(simulator, app, exporter, batchPath, processedResultsPath, errorLogPath)
            if (nargin < 5); processedResultsPath = []; end
            if (nargin < 6); errorLogPath = []; end
            
            this@Simple.DataAccess.FileSystemDataAccessor(app, exporter, batchPath, processedResultsPath, errorLogPath);
            
            if nargin >= 1
                this.Simulator = simulator;
            end
        end
    end
    methods
        % Loads a single data item.
        % Implement in derived class to get the data item from whichever
        % source is used (file system, web service, database, whatever
        % floats your boat....)
        % key represents a unique identifier of the required data item in
        % the PersistenceContainer it is held in.
        function item = load(this, key)
            item = [];
        end
        
        % Loads a batch of data items in the form of a Simple.DataAccess.DataQueue
        queue = loadQueue(this)
        
        % Accept data item - it passed processing
        acceptData(this, key)
        
        % Reject data item - it doesn't pass processing
        rejectData(this, key)

        % Reverts any previously made decisions regarding a data item
        revertDecision(this, key)

        % Logs an error in the processing of a data item
        logError(this, key, err)

        % Saves the processed data results of a data analysis process
        saveResults(this, data, output)
        
        % Import previously processed data results
        data = importResults(this, importDetails)
    end
end

