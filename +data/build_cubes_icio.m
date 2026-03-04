function cube = build_cubes_icio(cfg, year)
%TARIFFWAR.DATA.BUILD_CUBES_ICIO  Build unbalanced data cube from OECD ICIO CSV.
%
%   cube = tariffwar.data.build_cubes_icio(cfg, year)
%
%   Reads OECD ICIO Extended CSV, parses country-sector structure,
%   builds intermediate + final demand cubes, collapses services.
%   Does NOT load tariffs or balance trade.
%
%   Returns struct with: N, S, Xjik_3D, services_sector,
%   countries, sectors, dataset, year
%
%   See also: tariffwar.data.build_cubes

    % --- Find the CSV ---
    search_paths = { ...
        fullfile(cfg.data_root, 'Data_Preparation_Files', 'ICIO_Data', sprintf('%d.csv', year)); ...
        fullfile(cfg.data_root, 'Data_Preparation_Files', 'ICIO_Data', sprintf('%d_SML.csv', year)); ...
        fullfile(cfg.data_root, 'Data_Preparation_Files', 'ICIO_Data', sprintf('ICIO2023_%d.csv', year))};

    csv_path = '';
    for p = 1:numel(search_paths)
        if isfile(search_paths{p})
            csv_path = search_paths{p};
            break;
        end
    end
    if isempty(csv_path)
        error('tariffwar:data:icioNotFound', ...
            'ICIO CSV not found for year %d.\nSearched: %s', year, strjoin(search_paths, '\n  '));
    end

    if cfg.verbose
        fprintf('[build_cubes_icio] Reading ICIO %d from: %s\n', year, csv_path);
    end

    raw = readtable(csv_path, 'ReadVariableNames', true, 'ReadRowNames', true);
    data_matrix = table2array(raw);

    % --- Parse row/column structure ---
    row_names = raw.Properties.RowNames;
    col_names = raw.Properties.VariableNames;

    has_underscore = contains(row_names, '_');
    io_rows = find(has_underscore);
    row_parts = cellfun(@(x) regexp(x, '^([A-Z0-9]+)_(.+)$', 'tokens'), ...
        row_names(io_rows), 'UniformOutput', false);
    valid_rows = ~cellfun(@isempty, row_parts);
    io_rows = io_rows(valid_rows);
    row_parts = row_parts(valid_rows);
    row_countries = cellfun(@(x) x{1}{1}, row_parts, 'UniformOutput', false);
    row_sectors   = cellfun(@(x) x{1}{2}, row_parts, 'UniformOutput', false);

    unique_countries = unique(row_countries, 'stable');
    unique_sectors   = unique(row_sectors, 'stable');
    N_raw = numel(unique_countries);
    S_raw = numel(unique_sectors);
    NS = N_raw * S_raw;

    if cfg.verbose
        fprintf('[build_cubes_icio] ICIO raw: N=%d countries, S=%d sectors\n', N_raw, S_raw);
    end

    % --- Identify intermediate demand columns ---
    col_parts = cellfun(@(x) regexp(x, '^([A-Z0-9]+)_(.+)$', 'tokens'), ...
        col_names, 'UniformOutput', false);
    valid_cols = ~cellfun(@isempty, col_parts);
    col_countries = cell(numel(col_names), 1);
    col_sectors   = cell(numel(col_names), 1);
    for c = 1:numel(col_names)
        if valid_cols(c)
            col_countries{c} = col_parts{c}{1}{1};
            col_sectors{c}   = col_parts{c}{1}{2};
        else
            col_countries{c} = '';
            col_sectors{c}   = col_names{c};
        end
    end

    % --- Build bilateral trade flow cube ---
    Z = data_matrix(io_rows(1:NS), 1:NS);
    Z_4d = reshape(Z, [S_raw, N_raw, S_raw, N_raw]);
    X_int = squeeze(sum(Z_4d, 3));

    % --- Final demand ---
    fd_cats = {'HFCE', 'NPISH', 'GGFC', 'GFCF', 'INVNT', 'DPABR'};
    n_fd_cats = numel(fd_cats);

    fd_col_mask = false(1, numel(col_names));
    for c = NS+1:numel(col_names)
        for fc = 1:n_fd_cats
            if endsWith(col_names{c}, ['_' fd_cats{fc}])
                fd_col_mask(c) = true;
                break;
            end
        end
    end
    fd_cols = find(fd_col_mask);
    n_fd_cols = numel(fd_cols);

    if n_fd_cols > 0 && mod(n_fd_cols, n_fd_cats) == 0
        n_fd_countries = n_fd_cols / n_fd_cats;
        F_raw = data_matrix(io_rows(1:NS), fd_cols);

        fd_country_codes = cell(n_fd_countries, 1);
        for fc = 1:n_fd_countries
            col_idx = fd_cols((fc-1)*n_fd_cats + 1);
            parts = regexp(col_names{col_idx}, '^([A-Z0-9]+)_', 'tokens');
            if ~isempty(parts)
                fd_country_codes{fc} = parts{1}{1};
            else
                fd_country_codes{fc} = '';
            end
        end

        [~, fd_to_ctry] = ismember(fd_country_codes, unique_countries);

        X_fd = zeros(S_raw, N_raw, N_raw);
        for fc = 1:n_fd_countries
            if fd_to_ctry(fc) > 0
                dest_idx = fd_to_ctry(fc);
                fd_block = F_raw(:, (fc-1)*n_fd_cats+1 : fc*n_fd_cats);
                fd_total = sum(fd_block, 2);
                X_fd(:, :, dest_idx) = X_fd(:, :, dest_idx) + ...
                    reshape(fd_total, [S_raw, N_raw]);
            end
        end
    else
        out_col = find(strcmpi(col_names, 'OUT'));
        fd_end = numel(col_names);
        if ~isempty(out_col)
            fd_end = out_col(1) - 1;
        end
        F_sum = sum(data_matrix(io_rows(1:NS), NS+1:fd_end), 2);
        X_fd_2d = reshape(F_sum, [S_raw, N_raw]) / N_raw;
        X_fd = repmat(X_fd_2d, [1, 1, N_raw]);
    end

    X_total = X_int + X_fd;

    % --- Aggregate split-country entities ---
    % OECD ICIO Extended splits China/Mexico into sub-entities for processing
    % trade analysis. CN1 (domestic) + CN2 (processing) hold all IO data;
    % CHN holds only final demand. Same for MX1+MX2 -> MEX.
    agg_groups = {{'CHN', 'CN1', 'CN2'}; {'MEX', 'MX1', 'MX2'}};
    children_to_remove = [];

    for g = 1:numel(agg_groups)
        parent_code = agg_groups{g}{1};
        child_codes = agg_groups{g}(2:end);
        parent_idx = find(strcmp(unique_countries, parent_code));
        if isempty(parent_idx), continue; end

        child_idx = zeros(1, numel(child_codes));
        skip = false;
        for c = 1:numel(child_codes)
            idx = find(strcmp(unique_countries, child_codes{c}));
            if isempty(idx), skip = true; break; end
            child_idx(c) = idx;
        end
        if skip, continue; end

        for c = 1:numel(child_idx)
            X_total(:, parent_idx, :) = X_total(:, parent_idx, :) + X_total(:, child_idx(c), :);
        end
        for c = 1:numel(child_idx)
            X_total(:, :, parent_idx) = X_total(:, :, parent_idx) + X_total(:, :, child_idx(c));
        end
        children_to_remove = [children_to_remove, child_idx]; %#ok<AGROW>

        if cfg.verbose
            fprintf('[build_cubes_icio] Aggregated %s into %s\n', ...
                strjoin(child_codes, '+'), parent_code);
        end
    end

    if ~isempty(children_to_remove)
        keep_idx = setdiff(1:N_raw, children_to_remove);
        X_total = X_total(:, keep_idx, :);
        X_total = X_total(:, :, keep_idx);
        unique_countries = unique_countries(keep_idx);
        N_raw = numel(unique_countries);
        if cfg.verbose
            fprintf('[build_cubes_icio] Post-aggregation: N=%d countries\n', N_raw);
        end
    end

    Xijs3D_raw = permute(X_total, [2, 3, 1]);

    % --- Classify goods vs services ---
    svc_mask = false(S_raw, 1);
    for s = 1:S_raw
        first_char = unique_sectors{s}(1);
        if first_char >= 'D' && first_char <= 'Z'
            svc_mask(s) = true;
        end
    end

    goods_idx = find(~svc_mask);
    svc_idx   = find(svc_mask);
    n_goods   = numel(goods_idx);
    S = n_goods + 1;
    N = N_raw;

    if cfg.verbose
        fprintf('[build_cubes_icio] Goods: %d | Services: %d -> 1 | Final: N=%d, S=%d\n', ...
            n_goods, numel(svc_idx), N, S);
    end

    % Collapse services
    Xijs3D = zeros(N, N, S);
    Xijs3D(:, :, 1:n_goods) = Xijs3D_raw(:, :, goods_idx);
    Xijs3D(:, :, S) = sum(Xijs3D_raw(:, :, svc_idx), 3);
    Xijs3D = max(Xijs3D, 0);

    % --- Sector labels ---
    sector_labels = [unique_sectors(goods_idx); {'Services (aggregate)'}];

    % --- Assemble output ---
    cube.Xjik_3D         = Xijs3D;
    cube.N                = N;
    cube.S                = S;
    cube.services_sector  = S;
    cube.countries        = unique_countries;
    cube.sectors          = sector_labels;
    cube.dataset          = 'icio';
    cube.year             = year;

    if cfg.verbose
        fprintf('[build_cubes_icio] ICIO %d: N=%d, S=%d\n', year, N, S);
    end
end
