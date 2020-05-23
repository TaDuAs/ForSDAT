function nbins = calcNBins(data, method, minimalBins)
% histool.calcNBins calculates the required number of histogram bins for
% the set of data according to the specified binning method.
%
% nbins = histool.calcNBins(data, method)
%   calculates the number of bins for specified data set accorind to the
%   binning method.
% Input:
%   data -      data set
%   method -    binning method (case insensitive, default='freedman–diaconis'):
%               'sturges' - Struges binning rule
%               'fd', 'freedman–diaconis', 'freedman diaconis' - freedman–diaconis binning rule
%               'sqrt', 'square root', 'square-root' - n = sqrt(N)
% Output:
%   nbins -     the number of bins in the histogram
%
% nbins = histool.calcNBins(data, binWidth)
%   calculates the number of bins for specified data set using specified
%   bin width.
% Input:
%   data -      data set
%   binWidth -  a numeric scalar representing the width of the bins in the
%               histogram
% Output:
%   nbins -     the number of bins in the histogram
% 
% nbins = histool.calcNBins(___, minimalBins)
%   Also takes in the minimal number of bins to plot
% Input:
%   minimalBins - the minimal number of bins to use when plotting the
%                 histogram
% 
% Author - Tada, 2020
% 
% See also:
% histool.stats
% histool.histdist
% histool.mode
% histool.supportedBinningMethods
% 
    if nargin < 2 || isempty(method); method = 'fd'; end
    if nargin < 3 || isempty(minimalBins); minimalBins = 0; end
    
    [~, supportedMethods] = histool.supportedBinningMethods();

    if isnumeric(method)
        binterval = method;
        nbins = ceil(range(data)/binterval);
    elseif ischar(method) || isStringScalar(method)
        n = numel(data);

        % Calculate number of bins using the wanted method
        switch lower(char(method))
            case supportedMethods.Sturges
                nbins = round(log(n) + 1);
            case supportedMethods.FD
                nbins = round(2 * iqr(data) / (n^(1/3)));
            case supportedMethods.Sqrt
                nbins = round(sqrt(n));
            otherwise
                error(['Binning method ''' method ''' not supported']);
        end
    else
        supportedMethodsList = histool.supportedBinningMethods();
        throw(MException('histool:InvalidBinningMethod', ...
            'Binning method should be either a numeric scalar specifying the bin size or one of ["%s"]', strjoin(supportedMethodsList, '"')));
    end

    % ensure at least minimal bins are set
    if nbins < minimalBins
        nbins = minimalBins;
    end
end