function nbins = calcNBins(data, method, minimalBins)
    if nargin < 4 || isempty(minimalBins); minimalBins = 0; end
    
    [~, supportedMethods] = histpac.supportedBinningMethods();

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
        supportedMethodsList = histpac.supportedBinningMethods();
        throw(MException('histpac:InvalidBinningMethod', ...
            'Binning method should be either a numeric scalar specifying the bin size or one of ["%s"]', strjoin(supportedMethodsList, '"')));
    end

    % ensure at least minimal bins are set
    if nbins < minimalBins
        nbins = minimalBins;
    end
end