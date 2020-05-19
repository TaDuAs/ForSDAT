function value = mode(pd, bins)
    value = [];
    switch lower(pd.DistributionName)
        case {'normal', 'gauss'}
            value = mean(pd);
        case 'gamma'
            if pd.a >= 1
                value = (pd.a - 1)/pd.b;
            end
        case 'weibull'
            if pd.B > 1
                value = pd.A*(((pd.B-1)/pd.B)^(1/pd.B));
            else
                value = 0;
            end
        % TODO: add support for more distributions
    end

    % if the mode cannot be calculated directly, find maximal value within 
    % the inspected range
    if isempty(value)
        x = bins2x(bins);
        value = max(pdf(pd, x), 'all');
    end
end

