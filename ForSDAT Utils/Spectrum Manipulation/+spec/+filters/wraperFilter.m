function filter = wraperFilter(wraper, inner)
    spec.filters.validateFilterFunction(wraper, 3);

    function fixedSignal = wraperFilterFunction(x, y, ~)
        fixedSignal = wraper(x, y, inner);
    end
    
    filter = @wraperFilterFunction;
end

