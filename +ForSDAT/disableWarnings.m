%%
MSGID_findpeaks_largeMinPeakHeight = 'signal:findpeaks:largeMinPeakHeight';
warning('off', MSGID_findpeaks_largeMinPeakHeight);
disp('turned off signal:findpeaks:largeMinPeakHeight warnings');

MSGID_ContainersMap_NoKeyToRemove = 'MATLAB:Containers:Map:NoKeyToRemove';
warning('off', MSGID_findpeaks_largeMinPeakHeight);
disp('turned off MATLAB:Containers:Map:NoKeyToRemove warnings');

%%
[msgstr, MSGID] = lastwarn();
warning('off', MSGID);