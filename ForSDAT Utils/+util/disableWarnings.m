function disableWarnings(id)
    if nargin < 1; end
    
    if isempty(id)
        MSGID_findpeaks_largeMinPeakHeight = 'signal:findpeaks:largeMinPeakHeight';
        warning('off', MSGID_findpeaks_largeMinPeakHeight);
        disp('turned off signal:findpeaks:largeMinPeakHeight warnings');

        MSGID_ContainersMap_NoKeyToRemove = 'MATLAB:Containers:Map:NoKeyToRemove';
        warning('off', MSGID_ContainersMap_NoKeyToRemove);
        disp('turned off MATLAB:Containers:Map:NoKeyToRemove warnings');
    elseif strcmpi(id, 'last')
        [~, warningId] = lastwarn();
        warning('off', warningId);
        disp(['turned off ' warningId ' warnings']);
    else
        warning('off', id);
        disp(['turned off ' id ' warnings']);
    end
end