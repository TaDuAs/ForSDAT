function data = buildRuptureOutputStructure(data, channel, distance, events, ruptForce, originalEventIndex, df)
    ruptures = [];
    ruptures.i = events(1:3, :);
    ruptures.force = ruptForce;
    ruptures.distance = distance(events(2, :));
    ruptures.derivative = df;
    ruptures.originalRuptureIndex = originalEventIndex;

    data.(channel) = ruptures;
end

