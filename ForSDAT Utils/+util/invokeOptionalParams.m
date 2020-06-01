function varargout = invokeOptionalParams(fh, params)
    input = cell(1, 0);
    
    if nargin >= 2
        [~, sortedIndices] = sort([params.order]);
        params = params(sortedIndices);
        for i = 1:length(params)
            currParam = params(i);
            if ~isempty(currParam.value) || currParam.sendIfEmpty
                input{length(input) + 1} = currParam.value;
            end
        end
    end
    
    if nargout > 0
        varargout = cell(1, nargout);
    elseif nargout(fh) > 0
        varargout = cell(1, 1);
    else
        varargout = {};
    end
    [varargout{:}] = fh(input{:});
end

