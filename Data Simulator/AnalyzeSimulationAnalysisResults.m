import Simple.*;
import Simple.App.*;
import Simple.Math.*;
import Simple.Scientific.*;

smfsFilterTask = mgr.getTask('SMIFilterTask');
windowTask = mgr.getTask('ForSDAT.Core.Tasks.InteractionWindowTask');

dist = simInfo.data.d - simInfo.data.contact;
frc = simInfo.data.f - simInfo.data.baseline.shift;
yNoNoise = frc - simInfo.data.segments.ynoise;

results = [];
results.status = '';
results.statusReason = {};
results.statusData = {};
results.exception = '';
results.interactionWindow = [windowTask.filter.startAt windowTask.filter.endAt];
results.noiseAnomaly = windowTask.filter.noiseAnomally;
results.simulation.info = simInfo;
results.fdc = fdc;
results.analysis = data;
interaction = [];
results.simulation.interactions = struct('i', {}, 'f', {}, 'y', {}, 'p', {}, 'l', {});

for i = 1:length(nonSpecific)
    currNonSpec = nonSpecific(i);
    if ~isempty(currNonSpec.persistenceLength)
        if isnan(currNonSpec.i)
            abcdefg = [];
        end
        interaction.i = currNonSpec.i;
        interaction.f = currNonSpec.RuptureForce;
        interaction.y = currNonSpec.wlcY;
        interaction.p = currNonSpec.persistenceLength;
        interaction.l = currNonSpec.contourLength;
        results.simulation.interactions(length(results.simulation.interactions) + 1) = interaction;
    end
end
if ~isempty(specific.persistenceLength) && ~isnan(specific.persistenceLength)
    interaction.i = [specific.startLoadingAtIdx; length(specific.loadingDomainX) + specific.startLoadingAtIdx];
    interaction.f = specific.ruptureForce;
    interaction.y = specific.wlcY;
    interaction.p = specific.persistenceLength;
    interaction.l = specific.contourLength;
    results.simulation.interactions(length(results.simulation.interactions) + 1) = interaction;
end

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
lsrsIndices = [results.simulation.interactions.i];
lsrsDistances = dist(lsrsIndices);
if isempty(results.simulation.interactions)
    interactionMatrix = zeros(8, 0);
else
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
results.simulation.specificInteraction = [];
results.simulation.didSimulateSpecificInteraction = false;
results.simulation.didSimulateSpecificInteraction = simInfo.specificInteraction.didSpecificallyInteract;
if results.simulation.didSimulateSpecificInteraction
    interaction = [];
    interaction.i = [specific.startLoadingAtIdx; length(specific.loadingDomainX) + specific.startLoadingAtIdx];
    interaction.f = specific.ruptureForce;
    interaction.y = specific.wlcY;
    interaction.p = specific.persistenceLength;
    interaction.l = specific.contourLength;
    results.simulation.specificInteraction = interaction;
end

% Find best candidate for specific interaction, use data without noise
breakLoopFlag = false;
% for i = 1:size(interactionMatrix, 2)
%     if interactionMatrix(9, i) ~= 1
%         continue;
%     end
% 
%     currInteraction = results.simulation.interactions(interactionMatrix(1, i));
%     previousRuptureIndex = simInfo.data.contactIndex;
%     firstInteractionFlag = true;
%     for prevInteractionIndex = i+1:size(interactionMatrix, 2)
%         if interactionMatrix(9, prevInteractionIndex) ~= 0
%             previousRuptureIndex = interactionMatrix(3, prevInteractionIndex);
%             firstInteractionFlag = false;
%             break;
%         end
%     end
%     apparentLoadingStartIndex = previousRuptureIndex;%max(currInteraction.i(1), previousRuptureIndex);
% 
%     % Get rid of noise anomallies
%     if (currInteraction.i(2) - apparentLoadingStartIndex) <= results.noiseAnomaly.DataPoints
%         continue;
%     end
% 
%     breakLoopFlag = true;
%     for j = apparentLoadingStartIndex:currInteraction.i(2)
%         % determine if rupture event starts loading below baseline offset factor
%         if (yNoNoise(j) > -data.BaselineOffsetFactor && yNoNoise(j) < 0) ||...
%            (frc(j) > -data.BaselineOffsetFactor && frc(j) < 0)
%             k = currInteraction.i(2);
%             n = length(yNoNoise);
%             % Determine if rupture event ends below baseline offset factor
%             while k < n && yNoNoise(k) < yNoNoise(k+1)
%                 k = k+1;
%             end
%             if yNoNoise(k) > -data.BaselineOffsetFactor || frc(k) > -data.BaselineOffsetFactor
%                 isThisTheSpecificInteraction = true;
%                 if firstInteractionFlag
%                     currInteractionContactSlope = real(wlc.S(0, currInteraction.p, currInteraction.l));
%                     if abs(slope2angle(-simInfo.k) - slope2angle(currInteractionContactSlope)) < deg2rad(35)
%                         isThisTheSpecificInteraction = false;
%                     end
%                 end
% 
%                 if isThisTheSpecificInteraction
%                     results.simulation.specificInteraction = currInteraction;
%                     results.simulation.didSimulateSpecificInteraction = true;
%                 end
%             end
%             break;
%         end
% 
% %                     % Don't iterate through all the indexes if data shows decreasing trend
% %                     if j > 1 && yNoNoise(j) < yNoNoise(j-1)
% %                         breakLoopFlag = true;
% %                         break;
% %                     end
%     end
% 
%     if breakLoopFlag
%         break;
%     end
% end
didDetectSpecificInteraction = ~isempty(getobj(data, 'SingleInteraction.i'));
if results.simulation.didSimulateSpecificInteraction
    if didDetectSpecificInteraction
        results.status = 'true_positive';

        deltaMeasuredForce.add(results.simulation.specificInteraction.f - data.SingleInteraction.measuredForce);
        deltaMeasuredForceInNoiseAmp.add((results.simulation.specificInteraction.f - data.SingleInteraction.measuredForce)/results.simulation.info.data.noiseAmp);
        deltaModeledForce.add(results.simulation.specificInteraction.f - data.SingleInteraction.measuredForce);
        deltaModeledForceInNoiseAmp.add((results.simulation.specificInteraction.f - data.SingleInteraction.modeledForce)/results.simulation.info.data.noiseAmp);

        if data.SingleInteraction.i(2) <= results.simulation.specificInteraction.i(2) - 3 ||...
           data.SingleInteraction.i(2) >= results.simulation.specificInteraction.i(2) + 3
            results.status = 'weird';
            results.statusReason{length(results.statusReason) + 1} = 'rupture distance';
            results.statusData{length(results.statusData) + 1} = ...
                struct('detectedRuptureIndex', data.SingleInteraction.i(2),...
                       'simulatedRuptureIndex', results.simulation.specificInteraction.i(2));
            xxx = smfsFilterTask.getChannelData(data, 'x');
            results.statusData{length(results.statusData) + 1} = ...
                struct('detectedRuptureDistance', xxx(data.SingleInteraction.i(2)),...
                       'simulatedRuptureDistance', dist(results.simulation.specificInteraction.i(2)));
        end
        relevantSpecificForceRange = [results.simulation.specificInteraction.f - 2*noiseAmplitude, results.simulation.specificInteraction.f + 2*noiseAmplitude];
        if data.SingleInteraction.measuredForce < relevantSpecificForceRange(1) ||...
           data.SingleInteraction.measuredForce > relevantSpecificForceRange(2)
           results.status = 'weird';
           results.statusReason{length(results.statusReason) + 1} = 'measured rupture force';
           results.statusData{length(results.statusData) + 1} = ...
                struct('detectedMeasuredRuptureForce', data.SingleInteraction.measuredForce,...
                       'simulatedRuptureForce', results.simulation.specificInteraction.f);
        end
        if data.SingleInteraction.modeledForce < relevantSpecificForceRange(1) ||...
           data.SingleInteraction.modeledForce > relevantSpecificForceRange(2)
           results.status = 'weird';
           results.statusReason{length(results.statusReason) + 1} = 'modeled rupture force';
           results.statusData{length(results.statusData) + 1} = ...
                struct('detectedModeledRuptureForce', data.SingleInteraction.modeledForce,...
                       'simulatedRuptureForce', results.simulation.specificInteraction.f);
        end

        % Calculate the stiefness from WLC model, assume that the error of
        % the derivative is similar to that of the force, as the error of
        % x is verry small in comparrison to the noise
        specificInteractionWlcFunc = wlc.createExpretion(PhysicalConstants.kB * PhysicalConstants.RT,...
            results.simulation.specificInteraction.p, results.simulation.specificInteraction.l);
        specificInteractionWlcDer = specificInteractionWlcFunc.derive();
        stiffness = specificInteractionWlcDer.invoke(dist(results.simulation.specificInteraction.i(2)));
        if data.SingleInteraction.slope < stiffness - 2*noiseAmplitude ||...
           data.SingleInteraction.slope > stiffness + 2*noiseAmplitude
           results.status = 'weird';
           results.statusReason{length(results.statusReason) + 1} = 'stiffness';
        end
    else
        results.status = 'false_negative';
    end
else
    if ~didDetectSpecificInteraction
        results.status = 'true_negative';
    else
        results.status = 'false_positive';
    end
end

if ~exist('suppressPlotting','var') || ~suppressPlotting
    figure(2);
    hold off;
    plot(dist, frc);
    hold on;
    minForce = min([frc, -data.SingleInteraction.measuredForce, -data.SingleInteraction.modeledForce]);
    rangeForce = range([frc, -data.SingleInteraction.measuredForce, -data.SingleInteraction.modeledForce]);
    rangeDist = range(dist);
    fbounds = [minForce-0.03*rangeForce max(frc)+0.03*rangeForce];
    dbounds = [dist(1)-0.03*rangeDist dist(end)+0.03*rangeDist];
    plot([results.interactionWindow(1) results.interactionWindow(1)], fbounds, 'r');
    plot([results.interactionWindow(2) results.interactionWindow(2)], fbounds, 'r');
    plot(dbounds, [-data.BaselineOffsetFactor -data.BaselineOffsetFactor], 'r');
    if ~isempty(results.simulation.specificInteraction)
        plot(dist, results.simulation.specificInteraction.y, 'g');
    end
    if data.SingleInteraction.didDetect
        plot(dist(data.SingleInteraction.i(2)), -data.SingleInteraction.measuredForce, 'bo');
        plot(dist(data.SingleInteraction.i(2)), -data.SingleInteraction.modeledForce, 'go');
    end
    hold off;
    axis([dbounds fbounds]);
end