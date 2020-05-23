function x = bins2x(bins)
% Calculates a vector of small intervals from histogram bins for displaying 
% probability distribution functions on a histogram
    interval = bins(2) - bins(1);
    x = linspace(min(bins), max(bins)+interval, 1000)';
end

