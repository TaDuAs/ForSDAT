function [outSegments, headers] = readJPK(file, wantedSegments)
% original code taken from Fodis version 1.3
% https://github.com/galvanetto/Fodis
% N. Galvanetto, et al. Fodis: Software for Protein Unfolding Analysis, Biophysical Journal. 114 (2018) 1264�1266. doi:10.1016/j.bpj.2018.02.004.
% 
% modifications by TADA, 2020:
% * Reading all segments by default and not only retract segment
% * Added ability to read only wanted segments using input, segments are
%   chosen either by name or by index 1..N
% * Curve data is returned as cell array of segments/channel data as 
%   follows:
%   {nExtractedSegments, nExtractedChannels = 3}
% * Extracted channels include vertical-deflection, tip-sample-separation
%   and segment-time which is evaluated from segment duration and 
%   sampling-rate. All segments extracted are hard-coded into the function
%   and cannot be configured from outside
% * Output includes segment meta-data in the form of a struct array in the 
%   varriable headers, whose indices correspond to the indices of the first
%   dimention of outSegments. The struct has the following fields:
%       {
%            index;             % double, segment index, i.e. 1..N
%            name;              % char, segment name, i.e. extend/retract/delay
%            springConstant;    % double, cantilever spring constant
%            sensitivity;       % double, cantilever sensitivity;
%            xPosition;         % double, x-position of the scanner, for force maps
%            yPosition;         % double, y-position of the scanner, for force maps
%            curveIndex;        % double, the index of the curve in the batch, for force maps
%       }

    if nargin < 2 || isempty(wantedSegments)
        wantedSegments = 'all';
    elseif ischar(wantedSegments) || iscellstr(wantedSegments) || isstring(wantedSegments)
        wantedSegments = lower(string(wantedSegments));
    end
    
    %Preallocate cell for put the traces
    sharedHeaderPresence = 0;
    outSegments = cell(0, 3);
    headers = generateHeadersStruct(0);

    f = filesep;                              %Filseparatore (differ from system)
    tmpName = tempname;                     %Assign a temporary name to the extracted folder.
    [~, fileNoPath] = fileparts(file);

    %Unzip jpk-force
    filenames = unzip(file, fullfile(tmpName, fileNoPath));

    % disp(['File Written to' tmpName])

    %Remove part of path not necessary 'path-until the filename'
    filenamesCutted = filenames;
    for i = 1:length(filenames)

        stringActualFilename = filenamesCutted{i};
        lengthFolderTemp = length(tmpName);

        indexStartNameFile = strfind(stringActualFilename, tmpName);

        if ~isempty(indexStartNameFile)
            stringActualFilenameCutted = stringActualFilename(indexStartNameFile+lengthFolderTemp:end);
            filenamesCutted{i} = stringActualFilenameCutted;
        end
    end

    %% Extract general headerInformation
    generalHeaderLocation = ~cellfun('isempty', strfind(filenamesCutted, fullfile(fileNoPath, 'header.properties')));
    [extendLength, retractLength, extendPauseLength, retractPauseLength] = Fodis.IO.extractGeneralHeaderInformation(filenames(generalHeaderLocation));

    %% Extract sharedData headerInformation
    sharedHeaderLocation = ~cellfun('isempty', strfind(filenamesCutted, fullfile('shared-data', 'header.properties')));

    if ~isempty(find(sharedHeaderLocation, 1))
        structChannel = Fodis.IO.extractSharedHeaderInformation(filenames(sharedHeaderLocation));
        sharedHeaderPresence = 1;
    end

    %% Extract number of segment
    segmentFilenameLocation = find(~cellfun('isempty', strfind(filenamesCutted, 'segments')));

    %Exclude all Directory (not file).
    validSegmentLocationIndex = ones(1, length(segmentFilenameLocation)); %Vector of valid file. 1 valid, 0 not valid
    segmentNumber = zeros(1, length(segmentFilenameLocation));

    for jj = 1:length(segmentFilenameLocation)

        if isdir(filenames{segmentFilenameLocation(jj)})                       %Directory ->nothing to search
            validSegmentLocationIndex(jj) = 0;
            segmentNumber(jj) = -1;        
        else
            % Extract number of segments
            actualFilename = filenamesCutted{segmentFilenameLocation(jj)};

            separatorInSegmentFilename = strfind(actualFilename, f);
            segmentInSegmentFilename = strfind(actualFilename, 'segment');

            separatorPreSegmentNumberIndex = find(separatorInSegmentFilename>segmentInSegmentFilename(1));     %Separator before of the number of the segment
            separatorPreSegmentNumber = separatorInSegmentFilename(separatorPreSegmentNumberIndex(1));

            separatorPostSegmentNumberIndex = find(separatorInSegmentFilename>separatorPreSegmentNumber);      %Separator after of the number of the segment
            separatorPostSegmentNumber = separatorInSegmentFilename(separatorPostSegmentNumberIndex(1));

            segmentNumber(jj) = str2double(actualFilename(separatorPreSegmentNumber+1:separatorPostSegmentNumber-1)); %All number of segment present in file

        end
    end

    numSegments = max(segmentNumber) + 1;
    outSegments = cell(numSegments, 3);
    headers = generateHeadersStruct(numSegments);
    
    parsedSegments = false(1, numSegments);
    
    for j = 1:numSegments
        kk = j - 1;
        
        % only keep wanted segments - in case segment index was specified
        if isnumeric(wantedSegments) && ~ismember(kk, wantedSegments-1)
            continue;
        end
        allFilenameInActualSegment = filenames(segmentFilenameLocation(segmentNumber == kk));

        segmentHeader = contains(allFilenameInActualSegment, 'header');

        % read the headers from file
        openSegmentHeaderFile = fopen(char(allFilenameInActualSegment(segmentHeader)), 'r');
        dataSegmentHeader = textscan(openSegmentHeaderFile, '%s', 'delimiter', '\n');
        dataSegmentHeader = dataSegmentHeader{1};
        fclose(openSegmentHeaderFile);

        segmentType = Fodis.IO.extractParameterValue(dataSegmentHeader, 'force-segment-header.settings.style');

        % only keep wanted segments - in case segment type was specified
        if isstring(wantedSegments) && ~ismember(lower(segmentType), wantedSegments)
            continue;
        end

        % search for available Channel            
        columnsPossibleName = {'vDeflection', 'tipSampleSeparation', 'verticalTipPosition', 'smoothedCapacitiveSensorHeight', ...
            'capacitiveSensorHeight', 'measuredHeight', 'height'};

        segmentColumns = Fodis.IO.extractParameterValue(dataSegmentHeader, 'channels.list');
        columnsName = strsplit(segmentColumns, ' ');

        %Extract information on recorded channel
        IndexColumnAvailable = zeros(3, length(columnsPossibleName));

        for jj = 1:length(columnsName)

            valueInList = find(cellfun('isempty', strfind(columnsPossibleName, columnsName{jj})) == 0);         %Search which column are present
            indexInFilename = find(cellfun('isempty', strfind(allFilenameInActualSegment, [f columnsName{jj}])) == 0);%And where is the filename with that info

            if (find(valueInList, 1))
                IndexColumnAvailable(1, valueInList) = 1;                   % 1 if the possible name is present is equal to 1, 0 otherwise
                IndexColumnAvailable(2, valueInList) = jj;                  % if there is put a position on the second value
                IndexColumnAvailable(3, valueInList) = indexInFilename;     % Put the filename position of the value
            end
        end
        
        %% search for time axis
        

        %% Search for yaxis (VDeflection)
        indexYValue = 0;
        indexYValueFormat = 0;

        if (IndexColumnAvailable(1, 1) == 0)
            disp(['Cannot Find VDeflection in File: ' file]);
            return;
        else
            indexYValue = IndexColumnAvailable(3, 1);
            indexYValueFormat = IndexColumnAvailable(2, 1);
        end
        
        %% Search for good xaxis (tip-sample separation)
        indexXValue = 0;
        indexXValueFormat = 0;

        validIndex = find(IndexColumnAvailable(1, 2:end));

        if isempty(validIndex)
            disp(['Not Found Any valid format in File: ' file]);
            return;
        else
            indexXValue = IndexColumnAvailable(3, 1+validIndex(1));
            indexXValueFormat = IndexColumnAvailable(2, 1+validIndex(1));
%             disp(['Loaded Channel: ' columnsPossibleName{1+validIndex(1)}]);

%                 if validIndex(1)~= 2; disp(['Tip Sample Separation not found in File: ' file]);end
        end

        %Extract Format
        yChannelName = columnsName{indexYValueFormat};
        xChannelName = columnsName{indexXValueFormat};

        if (sharedHeaderPresence)

            yChannel = Fodis.IO.extractParameterValue(dataSegmentHeader, ['channel.' yChannelName '.lcd-info']);
            yFormat = structChannel.(['Channel' yChannel]).format;
            yMultiplier = structChannel.(['Channel' yChannel]).multiplier.Total;

            xChannel = Fodis.IO.extractParameterValue(dataSegmentHeader, ['channel.' xChannelName '.lcd-info']);
            xFormat = structChannel.(['Channel' xChannel]).format;
            xMultiplier = structChannel.(['Channel' xChannel]).multiplier.Total;
            
            % extract cantilever spring constant
            springConstantRaw = structChannel.(['Channel' yChannel]).multiplier.force;
            if isnumeric(springConstantRaw)
                springConstant = springConstantRaw;
            else
                springConstant = str2double(springConstantRaw);
            end
            
            % extract cantilever sensitivity
            sensitivityRaw = structChannel.(['Channel' yChannel]).multiplier.distance;
            if isnumeric(sensitivityRaw)
                sensitivity = sensitivityRaw;
            else
                sensitivity = str2double(sensitivityRaw);
            end

        else  %%Versione old pre 2011

            yStructChannel = Fodis.IO.extractSegmentHeaderInformation(allFilenameInActualSegment(segmentHeader), yChannelName);
            yFormat = yStructChannel.(yChannelName).format;
            yMultiplier = yStructChannel.(yChannelName).multiplier.Total;

            xStructChannel = Fodis.IO.extractSegmentHeaderInformation(allFilenameInActualSegment(segmentHeader), xChannelName);
            xFormat = xStructChannel.(xChannelName).format;
            xMultiplier = xStructChannel.(xChannelName).multiplier.Total;
            
            % I don't have reference for testing, lets assume it is the same
            springConstantRaw = structChannel.(['Channel' yChannel]).multiplier.force;
            if isnumeric(springConstantRaw)
                springConstant = springConstantRaw;
            else
                springConstant = str2double(springConstantRaw);
            end
            
            sensitivityRaw = structChannel.(['Channel' yChannel]).multiplier.distance;
            if isnumeric(sensitivityRaw)
                sensitivity = sensitivityRaw;
            else
                sensitivity = str2double(sensitivityRaw);
            end
        end

        % Read the good x channel from file
        xChannelFileName = char(allFilenameInActualSegment{indexXValue});
        fidtss = fopen(xChannelFileName, 'r', 'b', 'UTF-8');
        xAxisValue = fread(fidtss, xFormat);
        fclose(fidtss);

        % adjust tip sample separation value
        tipSampleSeparation = xMultiplier*xAxisValue-min(xMultiplier*xAxisValue);

        % read vertical deflection data from file
        fidF = fopen(char(allFilenameInActualSegment(indexYValue)), 'r', 'b', 'UTF-8');
        Fdata = fread(fidF, yFormat);
        fclose(fidF);

        % adjust vertical deflection value
        vDeflaction = yMultiplier*Fdata;

        segDuration = str2double(Fodis.IO.extractParameterValue(dataSegmentHeader, 'force-segment-header.settings.segment-settings.duration'));
        outSegments{j, 1} = linspace(0, segDuration, numel(tipSampleSeparation));
        outSegments{j, 2} = tipSampleSeparation';
        outSegments{j, 3} = vDeflaction';
        
        % send headers as output
        headers(j).index = kk + 1;
        headers(j).name = segmentType;
        headers(j).springConstant = springConstant;
        headers(j).sensitivity = sensitivity;
        headers(j).xPosition = str2double(Fodis.IO.extractParameterValue(dataSegmentHeader, 'force-segment-header.environment.xy-scanner-position-map.xy-scanner.tip-scanner.start-position.x'));
        headers(j).yPosition = str2double(Fodis.IO.extractParameterValue(dataSegmentHeader, 'force-segment-header.environment.xy-scanner-position-map.xy-scanner.tip-scanner.start-position.y'));
        headers(j).curveIndex = str2double(Fodis.IO.extractParameterValue(dataSegmentHeader, 'force-segment-header.environment.xy-scanner-position-map.xy-scanners.position-index'));
        
        parsedSegments(j) = true;
    end
    
    outSegments = outSegments(parsedSegments, :);
    headers = headers(parsedSegments);
    
    
    try
        rmdir(tmpName, 's');
    catch ex
        warning(ex.identifier, ex.message);
        % can't delete temp curve for some reason
    end
end

function headers = generateHeadersStruct(n)

    headersPreallocation = cell(n);
    headers = struct('index', headersPreallocation, 'name', headersPreallocation,...
        'springConstant', headersPreallocation, 'sensitivity', headersPreallocation,...
        'xPosition', headersPreallocation, 'yPosition', headersPreallocation, 'curveIndex', headersPreallocation);
end