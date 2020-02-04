function disableWarnings(lastWarnFlag)
    if nargin < 1 || ~islogical(lastWarnFlag) || numel(lastWarnFlag) ~= 1; lastWarnFlag = false; end
    
    if lastWarnFlag
        [msgstr, MSGID] = lastwarn();
        warning('off', MSGID);
    else
        MSGID_findpeaks_largeMinPeakHeight = 'signal:findpeaks:largeMinPeakHeight';
        warning('off', MSGID_findpeaks_largeMinPeakHeight);
        disp('turned off signal:findpeaks:largeMinPeakHeight warnings');

        MSGID_ContainersMap_NoKeyToRemove = 'MATLAB:Containers:Map:NoKeyToRemove';
        warning('off', MSGID_ContainersMap_NoKeyToRemove);
        disp('turned off MATLAB:Containers:Map:NoKeyToRemove warnings');
    end
end