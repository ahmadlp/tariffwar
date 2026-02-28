function epsilon_S = get(source_name, dataset_name, S)
%TARIFFWAR.ELASTICITY.GET  Get trade elasticities for a (source, dataset) pair.
%
%   epsilon_S = tariffwar.elasticity.get(source_name, dataset_name, S)
%
%   Returns an S x 1 vector of trade elasticities (epsilon, NOT sigma)
%   mapped to the target dataset's sector classification.
%
%   For uniform sources, returns the same value for all S sectors.
%   For sources with native sector classification matching the dataset,
%   returns directly. For mismatched classifications, applies concordance.
%
%   Inputs:
%     source_name  - string, e.g. 'lashkaripour_2021'
%     dataset_name - string, e.g. 'wiod', 'icio', 'itpd'
%     S            - number of sectors in the target dataset
%
%   See also: tariffwar.elasticity.get_sigma_cube, tariffwar.elasticity.registry

    reg = tariffwar.elasticity.registry();
    idx = find(strcmp({reg.name}, source_name), 1);
    if isempty(idx)
        error('tariffwar:elasticity:unknownSource', ...
            'Unknown elasticity source: ''%s''. Use tariffwar.elasticity.list_sources().', ...
            source_name);
    end

    entry = reg(idx);
    if ~entry.implemented
        error('tariffwar:elasticity:notImplemented', ...
            'Elasticity source ''%s'' is not yet implemented.\nPaper: %s', ...
            source_name, entry.paper);
    end

    % Get raw values at source's native classification
    raw = entry.getter();

    % Handle uniform case
    if strcmp(entry.classification, 'uniform')
        epsilon_S = raw.value * ones(S, 1);
        return;
    end

    % For sources at wiod_16 classification targeting wiod dataset: direct
    if strcmp(entry.classification, 'wiod_16') && strcmp(dataset_name, 'wiod')
        epsilon_S = raw.epsilon;
        return;
    end

    % For other (source, dataset) pairs: apply concordance
    % The concordance maps from source's sectors to dataset's sectors
    C = tariffwar.concordance.get_sector_map(source_name, dataset_name, S);
    epsilon_S = C * raw.epsilon;

    % Fill uncovered sectors (zero rows in concordance) with fallback
    zero_mask = (epsilon_S == 0);
    if any(zero_mask)
        fallback_val = 4;  % Simonovska-Waugh uniform
        epsilon_S(zero_mask) = fallback_val;
    end
end
