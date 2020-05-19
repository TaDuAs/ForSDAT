function model = buildModel(options)
    modelName = lower(char(options.Model));
    if startsWith(modelName, 'gauss')
        model = histpac.fit.MultiModalGaussFitter();
        model.Order = getModelOrder(modelName);
    elseif ~isempty(modelName)
        model = histpac.fit.BuiltinDistributionFitter();
        model.DistributionName = options.Model;
        if ~isempty(options.ModelFittingMode)
            model.FittingMode = options.ModelFittingMode;
        end
    end
end

function order = getModelOrder(model)
    sorder = regexp(model, '\d*$', 'match');
    if isempty(sorder)
        order = 1;
    else
        order = str2double(sorder);
        if numel(order) ~= 1 || ~isPositiveIntegerValuedNumeric(order)
            throw(MException('util:hist:InvalidModelOrder', ...
                'Model fitting order must be a positive integer'));
        end
    end
end