function cube = build_cubes_itpd(cfg, year)
%TARIFFWAR.DATA.BUILD_CUBES_ITPD  Build unbalanced data cube from USITC ITPD-S CSV.
%
%   cube = tariffwar.data.build_cubes_itpd(cfg, year)
%
%   Reads USITC ITPD-S CSV (uses awk pre-filter for speed), builds
%   sparse cube, filters countries, collapses services to 1 aggregate.
%   Saves at native 154-sector resolution. Does NOT load tariffs or balance trade.
%
%   Returns struct with: N, S, Xjik_3D, services_sector,
%   countries, sectors, dataset, year
%
%   See also: tariffwar.data.build_cubes

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
        fprintf('[build_cubes_itpd] ITPD-S source: %s\n', csv_path);
        fprintf('[build_cubes_itpd] Pre-filtering to year %d with awk...\n', year);
    end

    % --- Pre-filter with awk ---
    tmp_file = fullfile(tempdir, sprintf('itpd_s_%d.csv', year));
    awk_cmd = sprintf('awk -F, ''NR==1 || $3==%d'' "%s" > "%s"', year, csv_path, tmp_file);
    [status, cmdout] = system(awk_cmd);
    if status ~= 0
        error('tariffwar:data:awkFailed', 'awk pre-filter failed: %s', cmdout);
    end

    % --- Read filtered CSV ---
    if cfg.verbose
        f_info = dir(tmp_file);
        fprintf('[build_cubes_itpd] Filtered file: %.1f MB\n', f_info.bytes / 1e6);
    end
    opts = detectImportOptions(tmp_file);
    T_year = readtable(tmp_file, opts);

    if height(T_year) == 0
        error('tariffwar:data:yearNotFound', 'Year %d not found in ITPD-S.', year);
    end

    if cfg.verbose
        fprintf('[build_cubes_itpd] Loaded %d rows for year %d\n', height(T_year), year);
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

    if iscell(exporters), exporters = string(exporters); end
    if iscell(importers), importers = string(importers); end

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
        fprintf('[build_cubes_itpd] Raw: N=%d countries, S=%d industries\n', N_raw, S_raw);
    end

    % --- Build raw cube ---
    [~, exp_idx] = ismember(exporters, unique_countries);
    [~, imp_idx] = ismember(importers, unique_countries);
    [~, ind_idx] = ismember(industries, unique_industries);

    good = exp_idx > 0 & imp_idx > 0 & ind_idx > 0;
    lin_idx = sub2ind([N_raw, N_raw, S_raw], ...
        exp_idx(good), imp_idx(good), ind_idx(good));
    Xijs3D_raw = accumarray(lin_idx, values(good), [N_raw * N_raw * S_raw, 1]);
    Xijs3D_raw = reshape(Xijs3D_raw, [N_raw, N_raw, S_raw]);

    % --- Filter countries ---
    total_exports = squeeze(sum(sum(Xijs3D_raw, 2), 3));
    total_imports = squeeze(sum(sum(Xijs3D_raw, 1), 3));
    total_trade = total_exports + total_imports(:);
    world_trade = sum(total_trade);

    min_share = 1e-4;
    if isfield(cfg, 'itpd_min_trade_share')
        min_share = cfg.itpd_min_trade_share;
    end
    keep_mask = total_trade >= min_share * world_trade;

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
        fprintf('[build_cubes_itpd] Country filter: keeping %d / %d countries\n', N_keep, N_raw);
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
        fprintf('[build_cubes_itpd] Collapsing %d service industries -> 1 aggregate\n', numel(svc_idx));
        fprintf('[build_cubes_itpd] Final: N=%d, S=%d (%d goods + 1 services)\n', N, S, n_goods);
    end

    Xijs3D = zeros(N, N, S);
    Xijs3D(:, :, 1:n_goods) = Xijs3D_raw(:, :, goods_idx);
    Xijs3D(:, :, S) = sum(Xijs3D_raw(:, :, svc_idx), 3);
    Xijs3D = max(Xijs3D, 0);

    % --- Add trade floor ---
    pos_vals = Xijs3D(Xijs3D > 0);
    if ~isempty(pos_vals)
        trade_floor = mean(pos_vals) * 1e-12;
        Xijs3D = max(Xijs3D, trade_floor);
    end

    % --- Sector labels ---
    sector_labels = cell(S, 1);
    for s = 1:n_goods
        sector_labels{s} = sprintf('ITPD industry %d', unique_industries(goods_idx(s)));
    end
    sector_labels{S} = 'Services (aggregate)';

    % --- Assemble output ---
    cube.Xjik_3D         = Xijs3D;
    cube.N                = N;
    cube.S                = S;
    cube.services_sector  = S;
    cube.countries        = cellstr(unique_countries);
    cube.sectors          = sector_labels;
    cube.dataset          = 'itpd';
    cube.year             = year;

    if cfg.verbose
        fprintf('[build_cubes_itpd] ITPD-S %d: N=%d, S=%d\n', year, N, S);
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
