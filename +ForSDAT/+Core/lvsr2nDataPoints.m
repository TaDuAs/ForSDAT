function n = lvsr2nDataPoints(l, v, sr)
% Calculates the number of data points according to specified length,
% velocity and sampling-rate
    n = floor(sr*l/v);
end

