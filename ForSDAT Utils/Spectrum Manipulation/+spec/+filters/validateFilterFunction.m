function validateFilterFunction(filter, n, customMsg)
    if nargin < 2 || isempty(n); n = 2; end
    if nargin < 3
        customMsg = 'filter functions must follow the signature: ';
        if n == 2
            customMsg = [customMsg, 'function filteredSignal = filter(x, y)'];
        elseif n == 3
            customMsg = [customMsg, 'function filteredSignal = filter(x, y, [model/filter])'];
        else
            customMsg = ['filter functions must accept ', num2str(n), ' input variables and return one output variable'];
        end
    end
    assert(isa(filter, 'function_handle') && nargin(filter) >= n, customMsg);
end

