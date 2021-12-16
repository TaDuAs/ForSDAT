function e = sem(x)
    e = std(x, 'omitnan')/sqrt(numel(x));
end