function e = sem(x, d)
    if nargin < 2 || isempty(d); d = 1; end
    
    % compute along the specified dimension
    s = std(x, [], d, 'omitnan');
    n = sum(~isnan(x), d);
    e = s./sqrt(n);
end