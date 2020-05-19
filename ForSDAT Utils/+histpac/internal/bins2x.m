function x = bins2x(bins)
    interval = bins(2) - bins(1);
    x = linspace(min(bins), max(bins)+interval, 1000)';
end

