function [singleResult, originalIndex] = filterFlagsMatrix(mat, flagsRow, orderBy)
    [~, i] = sortrows(mat', [-flagsRow, orderBy]);
    if isempty(i) || (mat(flagsRow, i(1)) == 0)
        originalIndex = zeros(1,0);
        singleResult = zeros(3,0);
    else
        originalIndex = i(1);
        singleResult = mat(:, i(1));
        singleResult(flagsRow) = [];
    end
end

