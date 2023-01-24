function clusters = statGroupClusters(pht, means, varargin)
% util.statGroupClusters generates clusters of groups according to 
% similarity determined by a post-hoc test. The cluster names can be 
% annotated on top of a plot.
%
%--------------------------------------------------------------------------
% Input:
%   pht:
%       Post-hoc table. Determines statistically significant differences
%       between different groups of data retrieved from multcompare.
%
%   means:
%       The group means matrix retrieved from multcompare.
%
% Opntional Name-Value Pairs Input:
%   Alpha:
%       Numeric scalar value between zero and one determining the alpha
%       value.
%       The default value is 0.05.
%
%   FirstClusterCharacter:
%       The character to use as first letter to denote the different
%       groups. Generally this is used to determine if you want it as
%       upper/lower case letters or to use some non-latin alphabet.
%       The default is value 'A'.
%
%--------------------------------------------------------------------------
% Output:
%   clusters:
%       A character cell array containing the alphabetical cluster 
%       designation for each group. The clusters are sorted according to 
%       the enumeration in the supplied post-hoc table.
%
%--------------------------------------------------------------------------
% Example:
%
%   load hogg;
%   alpha = 0.05;
%   [p, ~, stat] = anova1(hogg, [], 'off');
%   [pht, means, ~, groupNames] = multcompare(stat, 'Alpha', alpha, 'Display', 'off');
%   clusters = util.statGroupClusters(pht, means, 'Alpha', alpha);
%   
%     pht(:, [1,2,6]) = 
%           1.0000    2.0000    0.0059
%           1.0000    3.0000    0.0013
%           1.0000    4.0000    0.0001
%           1.0000    5.0000    0.2119
%           2.0000    3.0000    0.9719
%           2.0000    4.0000    0.5544
%           2.0000    5.0000    0.4806
%           3.0000    4.0000    0.8876
%           3.0000    5.0000    0.1905
%           4.0000    5.0000    0.0292
%           
%     clusters =
%       1×5 cell array
%           {'A'}    {'BC'}    {'BC'}    {'B'}    {'AC'}
%     groupNames(:)' = 
%           1        2         3         4        5
%
%--------------------------------------------------------------------------
% Example 1 Output explanation:
%
% The tuckey test results indicate that group 1 is significantly different 
% from groups 2, 3 and 4, but not 5.
% Groups 2 and 3 is significantly different from group 1 but not from all 
% the other groups.
% Group 4 is significantly different from groups 1 and 5 but similar to 2 
% and 3
% Group 5 is significantly different from group 4, but similar to the rest.
% Therefore, the clusters are arranged as follows:
%   'A' - groups 1 and 5
%   'C' - Groups 2, 3 and 5
%   'B' - Groups 2, 3 and 4
%
%--------------------------------------------------------------------------
% Example 2: lower case clusters (or numeric values) - this can also be
%            used to generate clusters of non-latin alphabets, in case this
%            is necessary.
%
%   load hogg;
%   alpha = 0.05;
%   [p, ~, stat] = anova1(hogg, [], 'off');
%   [pht, means, ~, groupNames] = multcompare(stat, 'Alpha', alpha, 'Display', 'off');
%   lowerCaseClusters = util.statGroupClusters(pht, means, 'Alpha', alpha, 'FirstClusterCharacter', 'a');
%   greekAlphabetClusters = util.statGroupClusters(pht, means, 'Alpha', alpha, 'FirstClusterCharacter', char(945));
%   numericClusters = util.statGroupClusters(pht, means, 'Alpha', alpha, 'FirstClusterCharacter', '1');
%   
%     lowerCaseClusters =
%       1×5 cell array
%           {'a'}    {'bc'}    {'bc'}    {'b'}    {'ac'}
%
%     greekAlphabetClusters =
%       1×5 cell array
%           {'α'}    {'βγ'}    {'βγ'}    {'β'}    {'αγ'}
%
%     numericClusters =
%       1×5 cell array
%           {'1'}    {'23'}    {'23'}    {'2'}    {'13'}
%       
%--------------------------------------------------------------------------
% Written by TADA Apr 2022
% Comments:
% I tested the runtime duration within a for loop of 1000 repeats, with the 
% hogg dataset. It took roughly 0.6 ms per iteration. This is probably not
% the most efficient method. However, it is not likely to perform statistical 
% analysis of this sort over that many more groups. This means that the
% runtime of this method should not be too long even for extreme cases.
% 

    config = parseInputVars(varargin{:});
    ng = numel(unique(pht(:, 1))) + 1;
    groupClustersSorted = repmat({''}, 1, ng);
    nextClusterChar = config.FirstClusterCharacter;
    bins = false(ng, ng);
    
    [~, sortMeansIdx] = sort(means(:, 1));
    unsortMeansIdx(sortMeansIdx) = 1:ng;
    
    % find all statistically similar group pairs
    pairSubs = pht(pht(:, 6) >= config.Alpha, [1, 2]);
    
    % mark all mutually similar groups in the bins matrix prepare the bins 
    % matrix sorted by group means
    for i = 1:size(pairSubs, 1)
        bins(unsortMeansIdx(pairSubs(i, 1)), unsortMeansIdx(pairSubs(i, 2))) = true;
        bins(unsortMeansIdx(pairSubs(i, 2)), unsortMeansIdx(pairSubs(i, 1))) = true;
    end
    
    for i = 1:ng
        % determine if the current group is already in a cluster
        if isempty(groupClustersSorted{i})
            % if the current group is not clustered yet, set its cluster 
            % name to the next letter of the alphabet
            groupClustersSorted{i} = nextClusterChar;
            nextClusterChar = char(nextClusterChar + 1);
        else
            % if the current group is already clustered, go to the next one
            continue;
        end

        % find all groups that are not significantly different from the 
        % current group
        insignificantGroups = find(bins(i, :));

        % if no other groups are similar to this group, go on to the one
        if isempty(insignificantGroups)
            continue;
        end

        % iterate through all groups that are similar to the current one 
        % and add them to the same cluster as the current group.
        for j = insignificantGroups
            % if the current similar group does not already belong to the 
            % same cluster as the current group, add the cluster name to 
            % that groups cluster array
            if ~any(arrayfun(@(c) ismember(c, groupClustersSorted{i}), groupClustersSorted{j}))
                
                % if the group from this iteration is significantly
                % different from previous iterations that were similar to
                % the current group, make a new cluster, and mark both it
                % and the current group in that cluster
                if j > i && j > insignificantGroups(1) && ~any(bins(j, insignificantGroups(insignificantGroups < j)))
                    groupClustersSorted{i} = [groupClustersSorted{i}, nextClusterChar];
                    groupClustersSorted{j} = [groupClustersSorted{j}, nextClusterChar];
                    nextClusterChar = char(nextClusterChar + 1);
                else
                    groupClustersSorted{j} = [groupClustersSorted{j}, groupClustersSorted{i}];
                end
            end
        end
    end
    
    % unsort group means
    groupClustersUnsorted = groupClustersSorted(unsortMeansIdx);
    
    % remap the clusters so that they appear according to group appearance
    % and not according to the sorted groups.
    unsortClusterRemap = remapClusterNames(config, groupClustersUnsorted, ng);
    
    % reassign the cluster names according to the order of their appearance
    clusters = reassignClusterNames(groupClustersUnsorted, unsortClusterRemap, ng);
end

function unsortClusterRemap = remapClusterNames(config, groupClustersUnsorted, nGroups)
    
    lastRemappedClusterChar = char(config.FirstClusterCharacter - 1);
    
    % generate a map with keys being the old cluster values and the values
    % being the new values.
    unsortClusterRemap = containers.Map();
    
    % iterate through all clusters of all groups to remap the cluster names
    for i = 1:nGroups
        groupClusters = groupClustersUnsorted{i};
        for currCluster = groupClusters    
            % if old cluster value already is remapped, continue
            if unsortClusterRemap.isKey(currCluster)
                continue;
            end
            
            % remap current cluster old value to the new value
            lastRemappedClusterChar = char(lastRemappedClusterChar + 1);
            unsortClusterRemap(currCluster) = lastRemappedClusterChar;
        end
    end
end

function clusters = reassignClusterNames(groupClustersUnsorted, unsortClusterRemap, nGroups)
    clusters = cell(1, nGroups);
    
    for grpIdx = 1:nGroups
        currGroupClusters = groupClustersUnsorted{grpIdx};
        
        % replace each cluster old value with the remapped value
        for currClusterIdx = 1:numel(currGroupClusters)
            currCluster = currGroupClusters(currClusterIdx);
            
            % get the remapped cluster value
            clusterNewValue = unsortClusterRemap(currCluster);
            
            % replace the old values of current cluster with their remapped values
            currGroupClusters(currClusterIdx) = clusterNewValue;
        end
        
        % assign remapped group clusters to the output
        clusters{grpIdx} = sort(currGroupClusters);
    end
end

function s = parseInputVars(varargin)
    p = inputParser();
    p.addParameter('Alpha', 0.05, @validateAlpha);
    p.addParameter('FirstClusterCharacter', 'A', @(c) assert(~isempty(c) && ischar(c) && isscalar(c)));
    p.parse(varargin{:});
    
    s = p.Results;
end

function validateAlpha(a)
    mustBeScalarOrEmpty(a);
    mustBeNumeric(a);
    mustBePositive(a);
    mustBeLessThan(a, 1);
end