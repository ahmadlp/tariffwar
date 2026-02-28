function data = prepare_wiod(cfg, year)
%TARIFFWAR.DATA.PREPARE_WIOD  Full WIOD data preparation pipeline.
%
%   data = tariffwar.data.prepare_wiod(cfg, year)
%
%   Reads raw WIOD CSV, applies inventory correction, aggregates sectors
%   (56 → 16), computes cubes, loads tariffs, and solves for balanced trade.
%
%   This is a clean reproduction of Step_01_Baseline.m + Step_02_Baseline.m.
%
%   Returns a struct with:
%     .N, .S, .Xjik_3D, .tjik_3D, .services_sector
%
%   See also: tariffwar.io.load_dataset

    N_raw = 44;
    S_raw = 56;

    if cfg.verbose
        fprintf('[tariffwar.data] Preparing WIOD %d from raw CSV...\n', year);
    end

    % --- Step 1: Read raw WIOD CSV ---
    csv_path = fullfile(cfg.data_root, 'Data_Preparation_Files', 'WIOD_Data', ...
        sprintf('WIOT%d.csv', year));
    if ~isfile(csv_path)
        error('tariffwar:data:csvNotFound', ...
            'WIOD CSV not found: %s', csv_path);
    end
    DATA = dlmread(csv_path, ',');

    % --- Step 2: Inventory correction (INV=0) ---
    [Z, F, ~] = tariffwar.data.inventory_correct(DATA, N_raw, S_raw);

    % --- Step 3: Sector aggregation (56 → 16) ---
    agg_path = fullfile(cfg.data_root, 'Data_Preparation_Files', 'Baseline_Model', ...
        'AGG_S_16.csv');
    [Z, F, R, N, S] = tariffwar.data.aggregate_sectors(Z, F, N_raw, S_raw, agg_path);

    % --- Step 4: Compute cubes ---
    cubes = tariffwar.data.compute_cubes(Z, F, R, N, S);

    % --- Step 5: Build sigma cube for balanced trade step ---
    % Use the config's elasticity source for sigma
    services_sector = S;  % last sector = services
    sigma_k3D = tariffwar.elasticity.get_sigma_cube(...
        cfg.elasticity, cfg.dataset, N, S, services_sector, cfg.services_sigma);

    % --- Step 6: Load tariffs ---
    tjik_3D = tariffwar.io.load_tariffs(cfg, year, N, S);

    % --- Step 7: Balance trade (D=0) ---
    Xijs_new3D = tariffwar.data.balance_trade(...
        cubes.Xijs3D, sigma_k3D, tjik_3D, N, S, cfg);

    % --- Assemble output ---
    data.N = N;
    data.S = S;
    data.Xjik_3D = Xijs_new3D;
    data.tjik_3D = tjik_3D;
    data.services_sector = services_sector;

    if cfg.verbose
        fprintf('[tariffwar.data] WIOD %d prepared: N=%d, S=%d\n', year, N, S);
    end
end
