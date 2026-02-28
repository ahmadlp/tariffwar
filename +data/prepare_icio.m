function data = prepare_icio(cfg, year)
%TARIFFWAR.DATA.PREPARE_ICIO  Prepare OECD ICIO data for a single year.
%
%   data = tariffwar.data.prepare_icio(cfg, year)
%
%   Reads OECD ICIO Extended (2016-2022) CSV. Sector codes use ISIC Rev 4
%   letter-number format (A01, C10T12, D, etc.). 85 economies, 49 sectors.
%   Services (ISIC D onwards) collapsed to 1 aggregate.
%
%   Returns struct with: .N, .S, .Xjik_3D, .tjik_3D, .services_sector

    % --- Find the CSV ---
    % Try multiple possible locations and naming conventions
    search_paths = { ...
        fullfile(cfg.data_root, 'Data_Preparation_Files', 'ICIO_Data', sprintf('%d.csv', year)); ...
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
        fprintf('[tariffwar.data] Reading ICIO %d from: %s\n', year, csv_path);
    end

    raw = readtable(csv_path, 'ReadVariableNames', true, 'ReadRowNames', true);
    data_matrix = table2array(raw);

    % --- Parse row/column structure ---
    row_names = raw.Properties.RowNames;
    col_names = raw.Properties.VariableNames;

    % Row names: "AGO_A01", "AGO_A02", ... ; also "VA", "OUT", "TLS" at bottom
    % Split into (country, sector) pairs
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
        fprintf('[tariffwar.data] ICIO raw: N=%d countries, S=%d sectors\n', N_raw, S_raw);
    end

    % --- Identify intermediate demand columns (country_sector format) ---
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
    % ICIO has IO rows first (NS rows), then VA/OUT aggregate rows.
    % Columns: first NS = intermediate demand, then FD, then possibly OUT.
    % Use the first NS rows and columns directly (they correspond to the IO table).

    if cfg.verbose
        fprintf('[tariffwar.data] IO block: %d rows x first %d cols\n', NS, NS);
    end

    % Intermediate: first NS rows x first NS columns of data matrix
    Z = data_matrix(io_rows(1:NS), 1:NS);

    % Reshape Z: (S_raw, N_raw, S_raw, N_raw) = (s_src, i_src, s_dst, j_dst)
    Z_4d = reshape(Z, [S_raw, N_raw, S_raw, N_raw]);
    X_int = squeeze(sum(Z_4d, 3));   % (S_raw, N_raw, N_raw) sum over dest sectors

    % Final demand: columns after NS, grouped by country (6 FD categories each)
    % The last column may be OUT (total output) — exclude it from FD sum.
    % Not all countries may have FD columns (ICIO Extended: ~81 of 85 have FD).
    fd_cats = {'HFCE', 'NPISH', 'GGFC', 'GFCF', 'INVNT', 'DPABR'};
    n_fd_cats = numel(fd_cats);

    % Identify FD columns by checking for FD category suffixes
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

    if cfg.verbose
        fprintf('[tariffwar.data] FD columns identified: %d\n', n_fd_cols);
    end

    if n_fd_cols > 0 && mod(n_fd_cols, n_fd_cats) == 0
        % FD columns are evenly divisible by 6 categories
        n_fd_countries = n_fd_cols / n_fd_cats;
        F_raw = data_matrix(io_rows(1:NS), fd_cols);

        % Parse FD country codes to map to our country ordering
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

        % Map FD countries to our unique_countries ordering
        [~, fd_to_ctry] = ismember(fd_country_codes, unique_countries);

        % Build FD cube: sum over FD categories for each (source, dest) pair
        X_fd = zeros(S_raw, N_raw, N_raw);
        for fc = 1:n_fd_countries
            if fd_to_ctry(fc) > 0
                dest_idx = fd_to_ctry(fc);
                fd_block = F_raw(:, (fc-1)*n_fd_cats+1 : fc*n_fd_cats);
                fd_total = sum(fd_block, 2);  % sum across 6 categories
                X_fd(:, :, dest_idx) = X_fd(:, :, dest_idx) + ...
                    reshape(fd_total, [S_raw, N_raw]);
            end
        end
    else
        % Fallback: sum all non-IO, non-OUT columns, distribute by dest
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
    Xijs3D_raw = permute(X_total, [2, 3, 1]);  % (N_raw, N_raw, S_raw) = (i, j, s)

    % --- Classify goods vs services ---
    % Goods: ISIC sections A, B, C (agriculture, mining, manufacturing)
    % Services: ISIC sections D onwards (utilities, construction, trade, transport, etc.)
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
        fprintf('[tariffwar.data] Goods sectors: %d | Service sectors: %d -> 1\n', n_goods, numel(svc_idx));
        fprintf('[tariffwar.data] Final: N=%d, S=%d (%d goods + 1 services)\n', N, S, n_goods);
    end

    % Collapse services (vectorized)
    Xijs3D = zeros(N, N, S);
    Xijs3D(:, :, 1:n_goods) = Xijs3D_raw(:, :, goods_idx);
    Xijs3D(:, :, S) = sum(Xijs3D_raw(:, :, svc_idx), 3);
    Xijs3D = max(Xijs3D, 0);

    % --- Tariffs (zero if not available) ---
    try
        tjik_3D = tariffwar.io.load_tariffs(cfg, year, N, S);
    catch
        if cfg.verbose
            fprintf('[tariffwar.data] No tariff data for ICIO %d. Using zero tariffs.\n', year);
        end
        tjik_3D = zeros(N, N, S);
    end

    % --- Balance trade ---
    sigma_k3D = tariffwar.elasticity.get_sigma_cube(...
        cfg.elasticity, cfg.dataset, N, S, S, cfg.services_sigma);
    Xijs_new3D = tariffwar.data.balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg);

    % --- Assemble output ---
    data.N = N;
    data.S = S;
    data.Xjik_3D = Xijs_new3D;
    data.tjik_3D = tjik_3D;
    data.services_sector = S;
    data.countries = unique_countries;
    data.sectors = [unique_sectors(goods_idx); {'Services (aggregate)'}];

    if cfg.verbose
        fprintf('[tariffwar.data] ICIO %d prepared: N=%d, S=%d\n', year, N, S);
    end
end
