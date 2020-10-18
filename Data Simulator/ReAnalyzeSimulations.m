import Simple.*;
import Simple.App.*;
import Simple.Math.*;
import Simple.Scientific.*;
import Simple.UI.*;

% ForSDATApp.ensureAppLoaded();
% logFile = '';
% if ~exist('restoreSimulation_pathName', 'var') || isempty(restoreSimulation_pathName) || ~ischar(restoreSimulation_pathName)
%     restoreSimulation_pathName = [pwd '\..\SimulationResults\'];
% end
% restoreSimulation_pathName = uigetdir(restoreSimulation_pathName, 'Open JPK F-D Curve Batch');

mgr = Simple.IO.MXML.load([pwd '\Data Simulator\analysisManager.xml']);
foldersToAnalyze = {...
    'C:\Users\taldu\Google Drive\SimulationResults\2018-05-27 take2',...
    };

for folderIndex = 1:length(foldersToAnalyze)
restoreSimulation_pathName = foldersToAnalyze{folderIndex};
    
restoration_files = dir([restoreSimulation_pathName '\*.xml']);
restoration_files = {restoration_files.name};
proggressBar = ConsoleProggressBar('FDC Simulation&Analysis & Analysis-Analysis & Analysis-Analysis-Monitoring...', length(restoration_files), 10, true, '*');

for fileIndex = 1:length(restoration_files)
    %----------------------------------------------------------------------
    % Load simulation results from file
    fileName = restoration_files{fileIndex};
    results = Simple.IO.MXML.load([restoreSimulation_pathName '\' fileName]);

    %----------------------------------------------------------------------
    % Reanalyze the whole thing
    results.analysis = mgr.analyze(fdc, 'retract');

    %----------------------------------------------------------------------
    % Do all sorts of preparations on the simulation results
    smfsFilterTask = mgr.getTask('SMIFilterTask');
    simInfo = results.simulation.info;
    fdc = results.fdc;
    fdc.segments(1).distance = simInfo.data.d * 10^-9;
    fdc.segments(1).force = simInfo.data.f * 10^-12;
    dist = simInfo.data.d - simInfo.data.contact;
    frc = simInfo.data.f - simInfo.data.baseline.shift;
    yNoNoise = frc - simInfo.data.segments.ynoise;
    specific = results.simulation.info.specificInteraction;
    nonSpecific = results.simulation.info.nonSpecificInteractions;
    data = results.analysis;
    noiseAmplitude = simInfo.data.noiseAmp;
    errorFlag = false;
    keepSimInfoFlag = true;
    err = [];
    curvesNum = 1000;
    startRun = now;
    stopSimulationFlag = false;
    deltaMeasuredForce = Simple.List(curvesNum);
    deltaMeasuredForceInNoiseAmp = Simple.List(curvesNum);
    deltaModeledForce = Simple.List(curvesNum);
    deltaModeledForceInNoiseAmp = Simple.List(curvesNum);
    
    %----------------------------------------------------------------------
    % interaction matrix:
    % [ 
    %   interaction struct vector index;
    %   start loading index;
    %   rupture index;
    %   start loading distance;
    %   rupture distance;
    %   rupture force;
    %   wlc persistence length;
    %   wlc contour length;
    % ]
    if isempty(results.simulation.interactions)
        interactionMatrix = zeros(8, 0);
    else
        lsrsIndices = [results.simulation.interactions.i];
        lsrsDistances = dist(lsrsIndices);
        if sum(size(lsrsDistances) == size(lsrsIndices)) < 2
            lsrsDistances = lsrsDistances';
        end
        interactionMatrix = [
            1:length(results.simulation.interactions);
            lsrsIndices;
            lsrsDistances;
            results.simulation.interactions.f;
            double([results.simulation.interactions.p]);
            double([results.simulation.interactions.l]);
            ones(1,length(results.simulation.interactions));
            ];
    end

    % sort by rupture distance and filter out irelevant ruptures
    interactionMatrix = sortrows(interactionMatrix', [-3, -2])';
    interactionMatrix(9, interactionMatrix(6, :) < 2*simInfo.data.noiseAmp &...
        abs(frc(interactionMatrix(3, :))-frc(interactionMatrix(3, :)+1)) < 2*simInfo.data.noiseAmp) = 0;
    interactionMatrix(9, interactionMatrix(9, :) == 1 & ...
                         (interactionMatrix(5, :) < results.interactionWindow(1) |...
                          interactionMatrix(5, :) > results.interactionWindow(2))) = -1;
    specificInteraction = [];
    didSimulateSpecificInteraction = false;

    % Find best candidate for specific interaction, use data without noise
    breakLoopFlag = false;
    for i = 1:size(interactionMatrix, 2)
        if interactionMatrix(9, i) ~= 1
            continue;
        end

        currInteraction = results.simulation.interactions(interactionMatrix(1, i));
        previousRuptureIndex = simInfo.data.contactIndex;
        firstInteractionFlag = true;
        for prevInteractionIndex = i+1:size(interactionMatrix, 2)
            if interactionMatrix(9, prevInteractionIndex) ~= 0
                previousRuptureIndex = interactionMatrix(3, prevInteractionIndex);
                firstInteractionFlag = false;
                break;
            end
        end
        apparentLoadingStartIndex = previousRuptureIndex;%max(currInteraction.i(1), previousRuptureIndex);

        % Get rid of noise anomallies
        if (currInteraction.i(2) - apparentLoadingStartIndex) <= results.noiseAnomaly.DataPoints
            continue;
        end

        breakLoopFlag = true;
        for j = apparentLoadingStartIndex:currInteraction.i(2)
            % determine if rupture event starts loading below baseline offset factor
            if (yNoNoise(j) > -data.BaselineOffsetFactor && yNoNoise(j) < 0) ||...
               (frc(j) > -data.BaselineOffsetFactor && frc(j) < 0)
                k = currInteraction.i(2);
                n = length(yNoNoise);
                % Determine if rupture event ends below baseline offset factor
                while k < n && yNoNoise(k) < yNoNoise(k+1)
                    k = k+1;
                end
                if yNoNoise(k) > -data.BaselineOffsetFactor || frc(k) > -data.BaselineOffsetFactor
                    isThisTheSpecificInteraction = true;
                    if firstInteractionFlag
                        currInteractionContactSlope = real(wlc.S(0, currInteraction.p, currInteraction.l));
                        if abs(slope2angle(-simInfo.k) - slope2angle(currInteractionContactSlope)) < deg2rad(35)
                            isThisTheSpecificInteraction = false;
                        end
                    end

                    if isThisTheSpecificInteraction
                        specificInteraction = currInteraction;
                        didSimulateSpecificInteraction = true;
                    end
                end
                break;
            end

    %                     % Don't iterate through all the indexes if data shows decreasing trend
    %                     if j > 1 && yNoNoise(j) < yNoNoise(j-1)
    %                         breakLoopFlag = true;
    %                         break;
    %                     end
        end

        if breakLoopFlag
            break;
        end
    end
    didDetectSpecificInteraction = ~isempty(getobj(data, 'SingleInteraction.i'));
    if didSimulateSpecificInteraction
        if didDetectSpecificInteraction
            results.status2 = 'true_positive';

            deltaMeasuredForce.add(specificInteraction.f - data.SingleInteraction.measuredForce);
            deltaMeasuredForceInNoiseAmp.add((specificInteraction.f - data.SingleInteraction.measuredForce)/results.simulation.info.data.noiseAmp);
            deltaModeledForce.add(specificInteraction.f - data.SingleInteraction.measuredForce);
            deltaModeledForceInNoiseAmp.add((specificInteraction.f - data.SingleInteraction.modeledForce)/results.simulation.info.data.noiseAmp);

            if data.SingleInteraction.i(2) <= specificInteraction.i(2) - 3 ||...
               data.SingleInteraction.i(2) >= specificInteraction.i(2) + 3
                results.status2 = 'weird';
                results.statusReason{length(results.statusReason) + 1} = 'rupture distance';
                results.statusData{length(results.statusData) + 1} = ...
                    struct('detectedRuptureIndex', data.SingleInteraction.i(2),...
                           'simulatedRuptureIndex', specificInteraction.i(2));
                xxx = smfsFilterTask.getChannelData(data, 'x');
                results.statusData{length(results.statusData) + 1} = ...
                    struct('detectedRuptureDistance', xxx(data.SingleInteraction.i(2)),...
                           'simulatedRuptureDistance', dist(specificInteraction.i(2)));
            end
            relevantSpecificForceRange = [specificInteraction.f - 2*noiseAmplitude, specificInteraction.f + 2*noiseAmplitude];
            if data.SingleInteraction.measuredForce < relevantSpecificForceRange(1) ||...
               data.SingleInteraction.measuredForce > relevantSpecificForceRange(2)
               results.status2 = 'weird';
               results.statusReason{length(results.statusReason) + 1} = 'measured rupture force';
               results.statusData{length(results.statusData) + 1} = ...
                    struct('detectedMeasuredRuptureForce', data.SingleInteraction.measuredForce,...
                           'simulatedRuptureForce', specificInteraction.f);
            end
            if data.SingleInteraction.modeledForce < relevantSpecificForceRange(1) ||...
               data.SingleInteraction.modeledForce > relevantSpecificForceRange(2)
               results.status2 = 'weird';
               results.statusReason{length(results.statusReason) + 1} = 'modeled rupture force';
               results.statusData{length(results.statusData) + 1} = ...
                    struct('detectedModeledRuptureForce', data.SingleInteraction.modeledForce,...
                           'simulatedRuptureForce', specificInteraction.f);
            end

            % Calculate the stiefness from WLC model, assume that the error of
            % the derivative is similar to that of the force, as the error of
            % x is verry small in comparrison to the noise
            specificInteractionWlcFunc = wlc.createExpretion(PhysicalConstants.kB * PhysicalConstants.RT,...
                specificInteraction.p, specificInteraction.l);
            specificInteractionWlcDer = specificInteractionWlcFunc.derive();
            stiffness = specificInteractionWlcDer.invoke(dist(specificInteraction.i(2)));
            if data.SingleInteraction.slope < stiffness - 2*noiseAmplitude ||...
               data.SingleInteraction.slope > stiffness + 2*noiseAmplitude
               results.status2 = 'weird';
               results.statusReason{length(results.statusReason) + 1} = 'stiffness';
            end
        else
            results.status2 = 'false_negative';
        end
    else
        if ~didDetectSpecificInteraction
            results.status2 = 'true_negative';
        else
            results.status2 = 'false_positive';
        end
    end
    
    newStatusFolder = [restoreSimulation_pathName '\' results.status2 '\'];
    if ~exist(newStatusFolder, 'dir')
        mkdir(newStatusFolder);
    end
    movefile([restoreSimulation_pathName '\' fileName], [newStatusFolder fileName]);
    
    proggressBar.reportProggress(1);
end
end