function [ param] = prepOptionalParams( value, order, sendIfEmpty )
    param = struct('value', value, 'order', order, 'sendIfEmpty', sendIfEmpty);
end

