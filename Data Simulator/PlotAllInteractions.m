figure(3);
plot(dist, yNoNoise, 'k');
hold on;
plot(dist, dist*0-simInfo.data.noiseAmp, 'r');
plot(dist, dist*0-data.BaselineOffsetFactor, 'm');
plot(dist, dist*0-2*simInfo.data.noiseAmp, 'r');
for i = 1:length(results.simulation.interactions)
    plot(dist, results.simulation.interactions(i).y);
end
hold off;
deltaY = range(yNoNoise)*0.03;
rangeY = [min(yNoNoise)-deltaY, max(yNoNoise)+deltaY];
deltaX = range(dist)*0.03;
rangeX = [min(dist)-deltaX, max(dist)+deltaX];
axis([rangeX rangeY]);
clear deltaY;
clear rangeY;
clear deltaX;
clear rangeX;