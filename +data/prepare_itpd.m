function data = prepare_itpd(cfg, year)
%TARIFFWAR.DATA.PREPARE_ITPD  Prepare USITC ITPD-S data for a single year.
%
%   data = tariffwar.data.prepare_itpd(cfg, year)
%
%   Reads USITC ITPD-S CSV. For the full file (305M+ rows), uses system
%   awk to pre-filter to the requested year before loading into Matlab.
%   Services (industry_id >= 154) collapsed to 1 aggregate sector.
%
%   Returns struct with: .N, .S, .Xjik_3D, .tjik_3D, .services_sector

    % --- Find the CSV ---
    search_dirs = { ...
        fullfile(cfg.data_root, 'Data_Preparation_Files', 'ITPD_Data')};

    csv_path = '';
    for d = 1:numel(search_dirs)
        candidates = dir(fullfile(search_dirs{d}, 'ITPD*.csv'));
        if ~isempty(candidates)
            csv_path = fullfile(search_dirs{d}, candidates(1).name);
            break;
        end
        candidates = dir(fullfile(search_dirs{d}, 'itpd*.csv'));
        if ~isempty(candidates)
            csv_path = fullfile(search_dirs{d}, candidates(1).name);
            break;
        end
    end
    if isempty(csv_path)
        error('tariffwar:data:itpdNotFound', ...
            'No ITPD-S CSV found.\nSearched: %s', strjoin(search_dirs, '\n  '));
    end

    if cfg.verbose
        fprintf('[tariffwar.data] ITPD-S source: %s\n', csv_path);
        fprintf('[tariffwar.data] Pre-filtering to year %d with awk (this is fast)...\n', year);
    end

    % --- Pre-filter with awk for speed (305M rows -> ~9M for one year) ---
    % CSV columns: exporter_dynamic_code,importer_dynamic_code,year,industry_id,
    %              trade,flag_mirror,flag_zero,flag_itpds,exporter_iso3,importer_iso3,broad_sector
    % year is column 3, keep header + rows where $3 == year
    tmp_file = fullfile(tempdir, sprintf('itpd_s_%d.csv', year));
    awk_cmd = sprintf('awk -F, ''NR==1 || $3==%d'' "%s" > "%s"', year, csv_path, tmp_file);
    [status, cmdout] = system(awk_cmd);
    if status ~= 0
        error('tariffwar:data:awkFailed', 'awk pre-filter failed: %s', cmdout);
    end

    % Check filtered file size
    f_info = dir(tmp_file);
    if cfg.verbose
        fprintf('[tariffwar.data] Filtered file: %.1f MB\n', f_info.bytes / 1e6);
    end

    % --- Read the filtered CSV ---
    if cfg.verbose
        fprintf('[tariffwar.data] Reading filtered ITPD-S into Matlab...\n');
    end
    opts = detectImportOptions(tmp_file);
    T_year = readtable(tmp_file, opts);

    if height(T_year) == 0
        error('tariffwar:data:yearNotFound', 'Year %d not found in ITPD-S.', year);
    end

    if cfg.verbose
        fprintf('[tariffwar.data] Loaded %d rows for year %d\n', height(T_year), year);
    end

    % --- Parse columns ---
    vnames = T_year.Properties.VariableNames;
    exp_col = find_col(vnames, {'exporter_iso3', 'exporter_dynamic_code'});
    imp_col = find_col(vnames, {'importer_iso3', 'importer_dynamic_code'});
    ind_col = find_col(vnames, {'industry_id'});
    val_col = find_col(vnames, {'trade', 'trade_value'});

    exporters  = T_year{:, exp_col};
    importers  = T_year{:, imp_col};
    industries = T_year{:, ind_col};
    values     = T_year{:, val_col};

    % Convert to string if cell
    if iscell(exporters), exporters = string(exporters); end
    if iscell(importers), importers = string(importers); end

    % Remove rows with missing trade values or empty country codes
    valid = ~isnan(values) & strlength(exporters) > 0 & strlength(importers) > 0;
    exporters  = exporters(valid);
    importers  = importers(valid);
    industries = industries(valid);
    values     = values(valid);

    unique_countries  = unique([exporters; importers], 'stable');
    unique_industries = sort(unique(industries));
    N_raw = numel(unique_countries);
    S_raw = numel(unique_industries);

    if cfg.verbose
        fprintf('[tariffwar.data] Raw: N=%d countries, S=%d industries\n', N_raw, S_raw);
    end

    % --- Build raw cube with accumarray (vectorized) ---
    [~, exp_idx] = ismember(exporters, unique_countries);
    [~, imp_idx] = ismember(importers, unique_countries);
    [~, ind_idx] = ismember(industries, unique_industries);

    good = exp_idx > 0 & imp_idx > 0 & ind_idx > 0;
    lin_idx = sub2ind([N_raw, N_raw, S_raw], ...
        exp_idx(good), imp_idx(good), ind_idx(good));
    Xijs3D_raw = accumarray(lin_idx, values(good), [N_raw * N_raw * S_raw, 1]);
    Xijs3D_raw = reshape(Xijs3D_raw, [N_raw, N_raw, S_raw]);

    % --- Filter to countries with meaningful trade ---
    % Drop countries whose total trade (exports + imports) is below threshold
    % to ensure numerical stability in the solver. Default: keep countries
    % with at least 0.01% of world total trade.
    total_exports = squeeze(sum(sum(Xijs3D_raw, 2), 3));  % (N_raw, 1)
    total_imports = squeeze(sum(sum(Xijs3D_raw, 1), 3));   % (1, N_raw) -> (N_raw, 1)
    total_trade = total_exports + total_imports(:);
    world_trade = sum(total_trade);

    min_share = 1e-4;  % 0.01% of world trade
    if isfield(cfg, 'itpd_min_trade_share')
        min_share = cfg.itpd_min_trade_share;
    end
    keep_mask = total_trade >= min_share * world_trade;

    % If max_countries is set, keep only the top-N by total trade
    if isfield(cfg, 'itpd_max_countries')
        [~, rank_order] = sort(total_trade, 'descend');
        top_N = min(cfg.itpd_max_countries, N_raw);
        top_mask = false(N_raw, 1);
        top_mask(rank_order(1:top_N)) = true;
        keep_mask = keep_mask & top_mask;
    end

    keep_idx = find(keep_mask);
    N_keep = numel(keep_idx);

    if cfg.verbose
        fprintf('[tariffwar.data] Country filter: keeping %d / %d countries (%.2f%% trade threshold)\n', ...
            N_keep, N_raw, 100 * min_share);
    end

    Xijs3D_raw = Xijs3D_raw(keep_idx, keep_idx, :);
    unique_countries = unique_countries(keep_idx);

    % --- Collapse services (industry_id >= 154) ---
    svc_mask = unique_industries >= 154;
    goods_idx = find(~svc_mask);
    svc_idx   = find(svc_mask);
    n_goods   = numel(goods_idx);
    S = n_goods + 1;
    N = N_keep;

    if cfg.verbose
        fprintf('[tariffwar.data] Collapsing %d service industries -> 1 aggregate\n', numel(svc_idx));
        fprintf('[tariffwar.data] Final: N=%d, S=%d (%d goods + 1 services)\n', N, S, n_goods);
    end

    Xijs3D = zeros(N, N, S);
    Xijs3D(:, :, 1:n_goods) = Xijs3D_raw(:, :, goods_idx);
    Xijs3D(:, :, S) = sum(Xijs3D_raw(:, :, svc_idx), 3);
    Xijs3D = max(Xijs3D, 0);

    % --- Optional: collapse to broader sector classification ---
    % When using elasticities with fewer native sectors (e.g. wiod_16 = 16),
    % aggregate ITPD-S sectors to that classification for a compact, well-
    % conditioned problem. Without this, 154 sectors share only 16 distinct
    % elasticity values, creating redundancy that slows the solver.
    if isfield(cfg, 'itpd_sector_collapse') && ~isempty(cfg.itpd_sector_collapse)
        C = tariffwar.concordance.wiod16_to_itpd(S);  % S_target x 16
        % C is 154 x 16. Transpose gives 16 x 154. But C has 0/1 entries
        % so C'*X aggregates sectors. Need to apply to 3rd dim of Xijs3D.
        S_new = size(C, 2);  % 16
        Xijs3D_collapsed = zeros(N, N, S_new);
        for w = 1:S_new
            sector_mask = C(:, w) > 0;  % which of 154 sectors map to WIOD sector w
            Xijs3D_collapsed(:, :, w) = sum(Xijs3D(:, :, sector_mask), 3);
        end
        if cfg.verbose
            fprintf('[tariffwar.data] Collapsed %d sectors -> %d (%s)\n', ...
                S, S_new, cfg.itpd_sector_collapse);
        end
        Xijs3D = Xijs3D_collapsed;
        S = S_new;
    end

    % Add tiny positive floor to prevent exact zeros causing NaN
    % Use a small fraction of the mean positive trade flow
    pos_vals = Xijs3D(Xijs3D > 0);
    if ~isempty(pos_vals)
        trade_floor = mean(pos_vals) * 1e-12;
        Xijs3D = max(Xijs3D, trade_floor);
    end

    % --- Tariffs ---
    try
        tjik_3D = tariffwar.io.load_tariffs(cfg, year, N, S);
    catch
        if cfg.verbose
            fprintf('[tariffwar.data] No tariff data for ITPD-S %d. Using zero tariffs.\n', year);
        end
        tjik_3D = zeros(N, N, S);
    end

    % --- Balance trade ---
    % When sectors are collapsed, dataset is now 'itpd' but S matches wiod_16.
    % Tell get_sigma_cube the effective dataset for elasticity lookup.
    effective_dataset = cfg.dataset;
    if isfield(cfg, 'itpd_sector_collapse') && ~isempty(cfg.itpd_sector_collapse)
        effective_dataset = 'wiod';  % S=16 matches wiod_16 classification
    end
    sigma_k3D = tariffwar.elasticity.get_sigma_cube(...
        cfg.elasticity, effective_dataset, N, S, S, cfg.services_sigma);
    Xijs_new3D = tariffwar.data.balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg);

    % --- Assemble output ---
    data.N = N;
    data.S = S;
    data.Xjik_3D = Xijs_new3D;
    data.tjik_3D = tjik_3D;
    data.services_sector = S;
    data.countries = cellstr(unique_countries);
    data.effective_dataset = effective_dataset;  % 'wiod' if sectors collapsed

    if cfg.verbose
        fprintf('[tariffwar.data] ITPD-S %d prepared: N=%d, S=%d\n', year, N, S);
    end

    % Clean up temp file
    delete(tmp_file);
end


function col = find_col(vnames, candidates)
    for i = 1:numel(candidates)
        idx = find(strcmpi(vnames, candidates{i}), 1);
        if ~isempty(idx)
            col = idx;
            return;
        end
    end
    error('tariffwar:data:columnNotFound', ...
        'Could not find column matching: %s', strjoin(candidates, ', '));
end
