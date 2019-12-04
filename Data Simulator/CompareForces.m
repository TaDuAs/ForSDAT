import Simple.*;
import Simple.UI.*;
import Simple.Math.*;

if ~exist('lastFolderPath', 'var') || isempty(lastFolderPath)
    lastFolderPath = [pwd '\..\SimulationResults\'];
end

% Choose batch folder
folderPath = uigetdir(lastFolderPath, 'Open Simulation Analysis Report');

if isempty(folderPath) || (length(folderPath) == 1 && folderPath == 0)
    disp('You really should choose a folder...');
    return;
end

files = dir([folderPath '\true_positive\*.xml']);
files = [files; dir([folderPath '\weird\*.xml'])];
n = length(files);

measuredForce = Simple.List(n);
modeledForce = Simple.List(n);
simulatedForce = Simple.List(n);
calculatedLR = Simple.List(n);
noiseAmpCalculated = Simple.List(n);
noiseAmpSimulated = Simple.List(n);
proggressBar = ConsoleProggressBar('Loading simulation results...', n, 10, true);

for i = 1:n
    currFile = files(i);
    results = Simple.IO.MXML.load([currFile.folder '\' currFile.name]);
    
    if results.simulation.didSimulateSpecificInteraction
        measuredForce.add(results.analysis.SingleInteraction.measuredForce);
        modeledForce.add(results.analysis.SingleInteraction.modeledForce);
        simulatedForce.add(results.simulation.specificInteraction.f);
        noiseAmpCalculated.add(results.analysis.NoiseAmplitude);
        noiseAmpSimulated.add(results.simulation.info.data.noiseAmp);
        calculatedLR.add(results.analysis.SingleInteraction.apparentLoadingRate);
    end
    
    proggressBar.reportProggress(1);
end

cprintf('_Comments', 'All Done!\n');


forces = [];
forces.modeled = modeledForce.vector;
forces.measured = measuredForce.vector;
forces.simulated = simulatedForce.vector;
forces.simulatedNoiseAmp = noiseAmpSimulated.vector;
forces.lr = calculatedLR.vector;


%%
measuredForceDelta = measuredForce.vector - simulatedForce.vector;
measuredForceDeltaNormalized = measuredForceDelta ./ simulatedForce.vector * 100;
measuredForceDeltaNormalNoise = measuredForceDelta ./ noiseAmpSimulated.vector;

modeledForceDelta = modeledForce.vector - simulatedForce.vector;
modeledForceDeltaNormalized = modeledForceDelta ./ simulatedForce.vector * 100;
modeledForceDeltaNormalNoise = modeledForceDelta ./ noiseAmpSimulated.vector;

figure();
subplot(211);
hold on;
Histool.plot(measuredForceDelta, 'fd', 25);
Histool.plot(modeledForceDelta, 'fd', 25);
% title('Delta Calculated Force (F_C_a_l_c_u_l_a_t_e_d - F_S_i_m_u_l_a_t_e_d)');
legend('Measured Rupture Force (F_s_t_a_r_t - F_e_n_d)', 'WLC Rupture Force');
xlabel('\DeltaF (F_C_a_l_c_u_l_a_t_e_d - F_S_i_m_u_l_a_t_e_d) (pN)');
ylabel('Frequency');
title('Calculated Rupture Force Distribution Arround The Simulated Force');
axis([-50 150 0 75]);

subplot(212);
hold on;
Histool.plot(measuredForceDeltaNormalNoise, 0.2);
Histool.plot(modeledForceDeltaNormalNoise, 0.2);
legend('Measured Rupture Force (F_s_t_a_r_t - F_e_n_d)', 'WLC Rupture Force');
xlabel('\DeltaF/N');
ylabel('Frequency');
axis([-1.4 4 0 75]);