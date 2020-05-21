function validateBinningMethod(method)
    try
        if isnumeric(method)
            gen.valid.mustBeFinitePositiveRealScalar(method);
        elseif gen.isSingleString(method)
            supportedMethods = histpac.supportedBinningMethods();
            mustBeMember(lower(char(method)), supportedMethods);
        else
            error('Invalid error type');
        end
    catch ex
        supportedMethods = histpac.supportedBinningMethods();
        err = MException('util:hist:InvalidBinningMethod', ...
                sprintf('Histogram binning method must be either numeric bin width or one of ["%s"]', strjoin(supportedMethods, '"')));
        err.addCause(ex);
        err.throw();
    end
end