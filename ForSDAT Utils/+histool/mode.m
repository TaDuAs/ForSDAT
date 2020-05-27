function value = mode(pd, bins)
% Calculates the mode of a distribution object. The mode is calculated
% analytically some of the distributions, or determined numerically when
% the analytical solution cannot be determined or is not yet supported.
%
% Distributions supported for analytical solution:
%   Normal
%   Gamma
%   Weibull
%   Inverse-Gaussian
%   Log-Normal
%   Rayleigh
% 
% modeValue = histool.mode(pd)
%   calculates the analytical mode when possible. If not possible, returns
%   the absolute maximum within 5 standard deviations from the mean value
% 
% modeValue = histool.mode(pd, bins)
%   calculates the analytical mode when possible. If not possible, returns
%   the absolute maximum within the specified bins range
%
% Author - TADA, 2020
% 
% See also
% histool.histdist
% histool.stats
% histool.calcNBins
% histool.supportedBinningMethods
%

    value = [];
    switch lower(char(pd.DistributionName))
        case {'normal', 'gauss'}
            value = mean(pd);
        case 'gamma'
            if pd.a >= 1
                value = (pd.a - 1)*pd.b;
            end
        case 'weibull'
            if pd.B > 1
                value = pd.A*(((pd.B-1)/pd.B)^(1/pd.B));
            else
                value = 0;
            end
        case {'inversegaussian', 'inverse gaussian', 'inverse-gaussian'}
            mu = pd.mu;
            lambda = pd.lambda;
            value = mu * (((1 + ((3*mu)/(2*lambda))^2)^0.5) - (3*mu)/(2*lambda));
        case {'lognormal', 'log-normal', 'log normal'}
            value = exp(pd.mu - pd.sigma^2);
        case 'rayleigh'
            value = pd.B;
        % TODO: add support for more distributions
    end

    % if the mode cannot be calculated directly, find maximal value within 
    % the inspected range
    if isempty(value)
        if nargin < 2 || isempty(bins)
            % Calculates a vector of small intervals between mu - 5sigma and mu + 5sig
            mu = mean(pd);
            sig = std(pd);
            x = linspace(mu - 5*sig, mu + 5*sig, 2000);
        else
            % generate a vector in the bins range
            x = bins2x(bins);
        end
        
        % calculate the small interval pdf values
        pdfValues = pdf(pd, x);
        
        % calculate the maximal value of the distribution in the specifeid
        % range
        [~, modeIdx] = max(pdfValues(:));
        value = x(modeIdx);
    end
end

