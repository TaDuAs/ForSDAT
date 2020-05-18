function rearranged = rearangeArray(A, mode)
% rearranges a row vector or the columns of a 2d matrix
% arr - the array to rearrange
% mode - 'conv' = converging: from the edges to the center:
%               [1 2 3 4 5 6 7 8 9 10]
%               = [1 10 2 9 3 8 4 7 5 6]
%      - 'alt' = alternating: from left to right once from the left then
%      form the middle (left mid left+1 mid+1...)
%               [1 2 3 4 5 6 7 8 9 10]
%               = [1 6 2 7 3 8 4 9 5 10]
%      - 'rand' = random order
    if nargin < 2
        mode = 'alt';
    end
    n = size(A, 2);
    
    % handle even and odd n differently
    if mod(n, 2) == 0
        delta = 0;
    else
        delta = 1;
    end
    
    switch mode
        case 'alt'
            idx = [1:ceil(n/2); ceil(n/2)+1:n+delta];
            idx = idx(1:numel(idx)-delta);
        case 'conv'
            idx = [1:ceil(n/2); (n+delta:-1:ceil(n/2)+1)-delta];
            idx = idx(1:numel(idx)-delta);
        case 'rand'
            idx = randperm(n);
        otherwise
            error('Invalid order mode');
    end
    
    rearranged = A(:, idx);
end

