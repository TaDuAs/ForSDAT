function R2 = getFitR2(x, S)
    R2 = 1 - (S.normr/norm(x - mean(x)))^2;
end

