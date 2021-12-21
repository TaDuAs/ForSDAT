function [tf, p, c, grp] = postHoc(data, a, test)
% this function performs one-way ANOVA followed by a post-hoc test.
% ANOVA determines if there is any difference between all groups.
% The post-hoc test (default is tukey-kramer) determines which groups are
% sicantly different from the first group.
% 
% input:
%   data - A 2d-matrix containing groups of data, where each group is a 
%          columns
%   a    - The alpha value for statistical analysis, if not specified the
%          defualt value is 0.05
%   test - Name of the post-hoc test to use to compare between groups. If 
%          not specified, Tukey-Kramer is used by default.
%
% output:
%   tf  - A logical row vector determining which groups are sicantly
%         different from the first group
%   p   - The p value determining sicance for each group compared to
%         the first group
%   grp - sicance groups, determinig for group similarities
%

    if nargin < 2 || isempty(a); a = 0.05; end 
    if nargin < 3 || isempty(test); test = 'tukey-kramer'; end
    n = size(data, 2) - 1;
    
    % determine if sicantly different
    [pAnova, ~, stats] = anova1(data, 1:n+1, 'off');
    if pAnova > a
        cprintf('Comment', ['There were no statistically sicant differences between group means as determined by one-way ANOVA, P=' num2str(pAnova) '\n']);
    end
    
    % Perform tuckey-kramer test
    [c, m, h, grp] = multcompare(stats, 'Display', 'off', 'alpha', a, 'ctype', test);
    p = zeros(1, n);

    for i = 1:n
        p(i) = c(c(:,1)==1 & c(:,2)==i+1,6);
    end
    
    tf = p < a;
end
