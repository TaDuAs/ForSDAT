function groupClusters = statGroupClusters(pht, varargin)
% util.statGroupClusters generates clusters of groups according to
% population similarity determined by a post-hoc test.
% 

    config = parseInputVars(varargin{:});
    ng = numel(unique(pht(:, 1))) + 1;
    groupClusters = repmat({''}, 1, ng);
    lastSignificantGroup = 'A';

    for i = 1:ng

        % determine if the current item already is grouped
        if isempty(groupClusters{i})
            % if the current item is not grouped yet, set its group to the next
            % letter of the alphabet
            groupClusters{i} = lastSignificantGroup;
            lastSignificantGroup = char(lastSignificantGroup + 1);
        else
            % if the current item is already grouped, go to the next one
            continue;
        end

        % find all groups that are not significantly different from the current
        % group
        insignificantGroups = vertcat(...
            pht(pht(:, 1) == i & pht(:, 6) > config.Alpha, 2),...
            pht(pht(:, 2) == i & pht(:, 6) > config.Alpha, 1));

        % if no other items are similar to this item, go on to the one
        if isempty(insignificantGroups)
            continue;
        end

        % iterate through all similar items and add them to the same group as
        % this item.
        for j = insignificantGroups
            % if the current similar item does not already belong to the same 
            % group as the current item, add the group to that items grouping
            if ~any(arrayfun(@(pht) ismember(pht, groupClusters{i}), groupClusters{j}))
                groupClusters{j} = [groupClusters{j}, groupClusters{i}];
            end
        end
    end
end

function s = parseInputVars(varargin)
    p = inputParser();
    p.addParameter('Alpha', 0.05, @validateAlpha);
    p.parse(varargin{:});
    
    s = p.Results;
end

function validateAlpha(a)
    mustBeScalarOrEmpty(a);
    mustBeNumeric(a);
    mustBePositive(a);
    mustBeLessThan(a, 1);
end