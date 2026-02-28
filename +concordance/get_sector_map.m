function C = get_sector_map(source_name, dataset_name, S)
%TARIFFWAR.CONCORDANCE.GET_SECTOR_MAP  Get concordance matrix for (source, dataset) pair.
%
%   C = tariffwar.concordance.get_sector_map(source_name, dataset_name, S)
%
%   Returns an S_dataset x S_source concordance matrix C such that:
%     epsilon_dataset = C * epsilon_source
%
%   For coarse-to-fine mappings (dataset has finer granularity than source),
%   sub-sectors inherit the parent's elasticity value (flat assignment).
%   For fine-to-coarse mappings, a simple average is used.
%
%   All non-WIOD classifications first map to WIOD-16, then chain to the
%   target dataset via wiod16_to_icio or wiod16_to_itpd.
%
%   Inputs:
%     source_name  - elasticity source identifier (e.g. 'lashkaripour_2021')
%     dataset_name - target dataset (e.g. 'wiod', 'icio', 'itpd')
%     S            - number of sectors in the target dataset
%
%   See also: tariffwar.elasticity.get

    % Get source metadata from registry
    reg = tariffwar.elasticity.registry();
    idx = find(strcmp({reg.name}, source_name), 1);
    if isempty(idx)
        error('tariffwar:concordance:unknownSource', ...
            'Unknown elasticity source: ''%s''.', source_name);
    end
    source_class = reg(idx).classification;
    S_source = reg(idx).native_sectors;

    % Dispatch based on source classification
    switch source_class

        case 'wiod_16'
            C_to_wiod = eye(16);

        case 'isic_rev3'
            C_to_wiod = tariffwar.concordance.isic3_to_wiod(S_source, 16);

        case 'shapiro_13'
            C_to_wiod = tariffwar.concordance.shapiro13_to_wiod(S_source, 16);

        case 'isic_rev2'
            C_to_wiod = tariffwar.concordance.gyy19_to_wiod(S_source, 16);

        case 'sitc_rev2'
            C_to_wiod = tariffwar.concordance.bsy49_to_wiod(S_source, 16);

        case 'tiva_19'
            C_to_wiod = tariffwar.concordance.fontagne19_to_wiod(S_source, 16);

        case 'isic4_14'
            C_to_wiod = tariffwar.concordance.ll14_to_wiod(S_source, 16);

        case 'uniform'
            % Should not reach here — uniform is handled in elasticity.get
            C = eye(S);
            return;

        otherwise
            error('tariffwar:concordance:unknownClassification', ...
                'No concordance available for classification ''%s''.', source_class);
    end

    % Chain to target dataset
    switch dataset_name
        case 'wiod'
            C = C_to_wiod;
        case 'icio'
            C = tariffwar.concordance.wiod16_to_icio(S) * C_to_wiod;
        case 'itpd'
            C = tariffwar.concordance.wiod16_to_itpd(S) * C_to_wiod;
        otherwise
            error('tariffwar:concordance:unknownDataset', ...
                'Unknown dataset: ''%s''.', dataset_name);
    end

    % Validate dimensions
    if size(C, 1) ~= S
        error('tariffwar:concordance:dimensionMismatch', ...
            'Concordance matrix has %d rows, expected %d (S_dataset).', size(C, 1), S);
    end
end
