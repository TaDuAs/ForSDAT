import Simple.*;
import Simple.Math.*;
import ForSDAT.*;
import ForSDAT.Application.*;
import ForSDAT.Core.*;

ForSDATApp.ensureAppLoaded();

simInfo = [];
simInfo.foom = Simple.Math.OOM.Pico;
simInfo.doom = Simple.Math.OOM.Nano;
koomFactor = 10^(-(simInfo.foom-simInfo.doom));
simInfo.k = 0.03*koomFactor; % cantilever spring constant, N/m -> pN/nm
simInfo.sr = 1024; % sampling rate, Hz
simInfo.zLength = 500; % nm
simInfo.rv = 0.4 * 10^3; % retract velocity, um/sec -> nm/sec
tmax = simInfo.zLength / simInfo.rv;
t1 = linspace(0, tmax, tmax*simInfo.sr); % time vector, sec
simInfo.relativeSetpoint = 500; % F=200pN

contactDomainLength = simInfo.relativeSetpoint / simInfo.k; % X = F/k, nm
contactDomainTiming = contactDomainLength / simInfo.rv; % sec
contactPointIndex = find(t1 > contactDomainTiming, 1, 'first'); % sec

x1 = t1*simInfo.rv - contactDomainLength; % distance vector, nm

% Contact Domain: exponentially decaying hookean interaction
contactDomainDecayFactor = -5*simInfo.k/koomFactor;
yContact = -[x1(1:contactPointIndex) zeros(1, length(x1)-contactPointIndex)]*simInfo.k;% .* exp(contactDomainDecayFactor*(x1+contactDomainLength));

% non specific interaction
% nonSpecific.contourLength = 60; % nm
% nonSpecific.persistenceLength = 0.01; % nm
n_nonSpecificInteractions = Randomizer.uniformInt(1, 10);
nonSpecific = struct(...
    'loadingDistance', {},...
    'RuptureForce', {},...
    'ruptureDistance', {},...
    'loadingDomainX', {},...
    'persistenceLength', {},...
    'contourLength', {},...
    'wlcY', {},...
    'i', {});
nonSpecific_Y = zeros(1, length(x1));
nonSpecific_lastRuptureDistance = x1(contactPointIndex);
for i = 1:n_nonSpecificInteractions
    curr = [];
    
    % Loading distance of non-specific interactions distributes normally
    % arround 20nm with a normal distribution of 10nm
    curr.loadingDistance = Randomizer.normal(1, 20, 10); % 20 +/- 10 nm
    if curr.loadingDistance < 0
        continue;
    end
    
    % Non-specific rupture force uniformly distributed between 50 & 250 nN
    curr.RuptureForce = Randomizer.uniform(1, [50 250]); % 50:250 pN
    
    curr.ruptureDistance = curr.loadingDistance + x1(contactPointIndex); % nm
    curr.loadingDomainX = x1(x1 <= curr.ruptureDistance & x1 >= x1(contactPointIndex));
    curr.loadingDomainX = [curr.loadingDomainX - (curr.ruptureDistance-curr.loadingDistance) curr.ruptureDistance];
    
    % Calculate WLC parameters & force profile
    [curr.persistenceLength, curr.contourLength] = wlc.PL(...
        curr.ruptureDistance,...
        curr.RuptureForce,...
        Randomizer.lr(1, simInfo.k, simInfo.rv)/simInfo.rv);
    [curr.wlcY, curr.persistenceLength, curr.contourLength] = wlc.correctSolution(...
        curr.loadingDomainX, curr.persistenceLength, curr.contourLength);
    curr.wlcY = -[zeros(1, contactPointIndex), curr.wlcY, zeros(1, length(x1) - length(curr.loadingDomainX) - contactPointIndex)];
%     curr.wlcY = -[zeros(1, contactPointIndex), curr.loadingDomainX*simInfo.k, zeros(1, length(x1) - length(curr.loadingDomainX) - contactPointIndex)];

    % calculate interaction start-end indices
    curr.i = [contactPointIndex; length(curr.loadingDomainX) + contactPointIndex];
    
    % Add interaction to the list and to the non-specific interactions vector
    nonSpecific(length(nonSpecific) + 1) = curr;
    nonSpecific_Y = nonSpecific_Y + curr.wlcY;
    nonSpecific_lastRuptureDistance = max([nonSpecific_lastRuptureDistance, curr.ruptureDistance]);
end

% specific interaction
specificInteractionSpecs = SingleMoleculeInteraction.DopaTiO2;

% generate uniformly distributed random values between 1000 and the applied
% loading rate (rv*k). use multipliers of 500 pN/sec
specific.loadingRate = Randomizer.lr(1, simInfo.k, simInfo.rv);% Randomizer.uniformInt(1, [2, simInfo.k*simInfo.rv*2/1000])*500;

% Calculate most probable rupture force according to the generated loading rate
specific.MPF = specificInteractionSpecs.calcForce(specific.loadingRate);

% Generate gamma distributed random force arround the calculated MPF with a
% standard deviation of 10%
specific.ruptureForce = Randomizer.gammaMpvS(1, specific.MPF, specific.MPF*0.1);

specific.absoluteRuptureDistance = Randomizer.normal(1, 60, 10); % 45 nm approximately corresponds to fully stretched 5kD PEG
                                                                 % 60 nm ~ 7.5kD PEG

% Start loading at the last non-specific rupture + normally distributing
% random value of 5 +/- 5nm
specific.startLoadingAt = 0;%nonSpecific_lastRuptureDistance + Randomizer.normal(1, 0, 10); 
if specific.startLoadingAt < 0
    specific.startLoadingAt = 0;
end

if specific.startLoadingAt < specific.absoluteRuptureDistance
    specific.loadingDomainX = x1(x1 > specific.startLoadingAt & x1 <= specific.absoluteRuptureDistance) - specific.startLoadingAt;
end

specific.didSpecificallyInteract = Randomizer.uniformInt(1, 10, false) >= 6;

if specific.didSpecificallyInteract && (isfield(specific, 'loadingDomainX') && ~isempty(specific.loadingDomainX))
    specific.relativeRuptureDistance = specific.loadingDomainX(end);
    [specific.persistenceLength, specific.contourLength] =...
        wlc.PL(specific.relativeRuptureDistance, specific.ruptureForce, specific.loadingRate/simInfo.rv);

    % Calculate all solutions of the wlc
    [specific.wlcY_solution, specific.persistenceLength, specific.contourLength] =...
        wlc.correctSolution(specific.loadingDomainX, specific.persistenceLength, specific.contourLength);

    specific.startLoadingAtIdx = find(x1 < specific.startLoadingAt, 1, 'last');
    specific.wlcY = -[...
        zeros(1, specific.startLoadingAtIdx)...
        specific.wlcY_solution,...specific.wlcY_solutions(specific.mostProbableSolutionIndex, :),...
        zeros(1, length(x1) - length(specific.loadingDomainX) - specific.startLoadingAtIdx)];
else
    specific.startLoadingAt = [];
    specific.absoluteRuptureDistance = [];
    specific.loadingDomainX = [];
    specific.startLoadingAtIdx = [];
    specific.wlcY = zeros(1, length(x1));
    specific.wlcY_solution = [];
    specific.persistenceLength = [];
    specific.contourLength = [];
    specific.ruptureForce = 0;
    specific.didSpecificallyInteract = false;
end

% noise: uniformly distributed around 0 with a maximum value which is
% normally distributed around 7.5% of the relative setpoint value
noiseAmpMu = 0.075 * simInfo.relativeSetpoint;
noiseAmpSig = 0.025 * simInfo.relativeSetpoint;
noiseAmplitude = Randomizer.normal(1, noiseAmpMu, noiseAmpSig);
ynoise = Randomizer.uniform(length(x1), noiseAmplitude, true);

% final signal
driftSlope = 0;
baselineShift = Randomizer.uniform(1, 10000, true);
y1 = driftSlope*x1 + yContact + ynoise + nonSpecific_Y + specific.wlcY + baselineShift;
x1 = x1 + Randomizer.uniform(1, 10000, true);

simInfo.specificInteraction = specific;
simInfo.nonSpecificInteractions = nonSpecific;
simInfo.data.t = t1;
simInfo.data.d = x1;
simInfo.data.f = y1;
simInfo.data.baseline.shift = baselineShift;
simInfo.data.baseline.slope = driftSlope;
simInfo.data.noiseAmp = noiseAmplitude;
simInfo.data.contact = x1(contactPointIndex);
simInfo.data.contactIndex = contactPointIndex;
simInfo.data.segments.baselineDrift = driftSlope*x1;
simInfo.data.segments.contact = yContact;
simInfo.data.segments.ynoise = ynoise;
simInfo.data.segments.nonSpecific_Y = nonSpecific_Y;
simInfo.data.segments.specific_wlcY = specific.wlcY;

%         % plot
%         figure(2);
%         % hold on;
%         plot(x1, y1);
%         hold on;
%         specificRuptureIndex = length(specific.loadingDomainX) + specific.startLoadingAtIdx;
% 
%         % generated specific interaction
%         plot(x1(specificRuptureIndex), y1(specificRuptureIndex), 'go');
%         plot(x1, specific.wlcY + baselineShift, 'g');
% 
%         % suspect specific interaction
%         suspectSpecificInteractionIndex = find([nonSpecific.ruptureDistance] == max([nonSpecific.ruptureDistance]));
%         suspectSpecificInteraction = nonSpecific(suspectSpecificInteractionIndex);
%         if isempty(suspectSpecificInteractionIndex)
%             suspectSpecificRuptureIndex = [];
%         else
%             suspectSpecificRuptureIndex = length(suspectSpecificInteraction.loadingDomainX) + contactPointIndex;
%             plot(x1(suspectSpecificRuptureIndex), y1(suspectSpecificRuptureIndex), 'ro');
%             plot(x1, suspectSpecificInteraction.wlcY + baselineShift, 'r');
%         end
%         hold off;


% Generate force distance curve
fdc = ForceDistanceCurve();
fdcSeg = ForceDistanceSegment();
fdcSeg.name = 'retract';
fdcSeg.index = 2;
fdcSeg.springConstant = simInfo.k;
fdcSeg.sensitivity = 50;
fdcSeg.time = t1;

% use double precision for this one
defaultDigits = digits(64);
fdcSeg.force = y1 * 10^-12;
fdcSeg.distance = x1 * 10^-9;
digits(defaultDigits);
fdc.segments(1) = fdcSeg;

%%
if exist('showSimulateSingleCurveResults', 'var') && showSimulateSingleCurveResults && (~exist('suppressPlotting','var') || ~suppressPlotting)
    figure(5);
    plot(x1, y1);
end