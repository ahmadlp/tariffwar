function cube = build_cubes_wiod(cfg, year)
%TARIFFWAR.DATA.BUILD_CUBES_WIOD  Build unbalanced data cube from raw WIOD CSV.
%
%   cube = tariffwar.data.build_cubes_wiod(cfg, year)
%
%   Reads raw WIOD CSV, applies inventory correction, aggregates sectors
%   (56 → 16), and computes trade cubes.
%   Does NOT load tariffs or balance trade.
%
%   Returns struct with: N, S, Xjik_3D, services_sector,
%   countries, sectors, dataset, year
%
%   See also: tariffwar.data.build_cubes

    N_raw = 44;
    S_raw = 56;

    if cfg.verbose
        fprintf('[build_cubes_wiod] Preparing WIOD %d from raw CSV...\n', year);
    end

    % --- Step 1: Read raw WIOD CSV ---
    csv_path = fullfile(cfg.data_root, 'Data_Preparation_Files', 'WIOD_Data', ...
        sprintf('WIOT%d.csv', year));
    if ~isfile(csv_path)
        error('tariffwar:data:csvNotFound', 'WIOD CSV not found: %s', csv_path);
    end
    DATA = readmatrix(csv_path);

    % --- Step 2: Inventory correction (INV=0) ---
    [Z, F, ~] = tariffwar.data.inventory_correct(DATA, N_raw, S_raw);

    % --- Step 3: Sector aggregation (56 → 16) ---
    agg_path = fullfile(cfg.data_root, 'Data_Preparation_Files', 'Baseline_Model', ...
        'AGG_S_16.csv');
    [Z, F, R, N, S] = tariffwar.data.aggregate_sectors(Z, F, N_raw, S_raw, agg_path);

    % --- Step 4: Compute cubes ---
    cubes = tariffwar.data.compute_cubes(Z, F, R, N, S);

    % --- Step 5: Get sector labels ---
    [~, sector_labels] = tariffwar.concordance.wiod16_to_isic4();

    % --- Step 6: Get country list ---
    countries = {};
    cpath = fullfile(cfg.data_root, 'Country_List.xlsx');
    if isfile(cpath)
        countries = readcell(cpath);
        if size(countries, 2) > 1, countries = countries(:, 1); end
    end

    % --- Assemble output ---
    cube.Xjik_3D         = cubes.Xijs3D;
    cube.N                = N;
    cube.S                = S;
    cube.services_sector  = S;  % last sector = services
    cube.countries        = countries;
    cube.sectors          = sector_labels;
    cube.dataset          = 'wiod';
    cube.year             = year;

    if cfg.verbose
        fprintf('[build_cubes_wiod] WIOD %d: N=%d, S=%d\n', year, N, S);
    end
end
