classdef AppMessages
    properties (Constant)
        % Project management
        CurrentProjectRequestProgressResetPermit = 'CurrentProjectRequestProgressResetPermit';
        CurrentProjectUpdated = 'CurrentProjectUpdated';
        CurrentProjectDataChanged = 'CurrentProjectDataChanged';
        
        % Task management
        PreEditedTaskChange = 'PreEditedTaskChange';
        
        % Process restore point
        RestoreProcess = 'RestoreProcess';
        
        % Analysis management
        FDC_Analyzed = 'ForSDAT.Client.FDC_Analyzed';
    end
end

