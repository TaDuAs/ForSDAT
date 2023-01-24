sinfo = ForSDAT.Sim.SimInfo();
sim = ForSDAT.Sim.CurveSimulator(sinfo, ...
        [ForSDAT.Sim.DistanceSimulator(sinfo), ...
         ForSDAT.Sim.ContactDomainSimulator(sinfo), ...
         ForSDAT.Sim.BaselineSimulator(sinfo), ...
         ForSDAT.Sim.NoiseSimulator(sinfo),...
         ForSDAT.Sim.NonSpecificInteractionSimulator(sinfo, 'LoadingLengthMu', 60, 'LoadingLengthSig', 45)]);
n = 1;

fig  = figure(119);

for i = n:-1:1
    fdc(i) = sim.simulate(1,1,i);
    
    clf(fig);
    fdc.plotCurve(fig);
    legend('off');
    print -dmeta -noui;
end

% save('simulatedCurves.mat', 'fdc');