function [list, keyValueStruct] = supportedBinningMethods()
    persistent valueList;
    persistent valueStruct;
    
    if isempty(valueList)
        [valueList, valueStruct] = gen.listOfValidTextValues(...
            'Sturges', 'sturges',...
            'FD', {'fd', 'freedman–diaconis', 'freedman diaconis'}, ...
            'Sqrt', {'sqrt', 'square root', 'square-root'});
    end
    
    list = valueList;
    keyValueStruct = valueStruct;
end