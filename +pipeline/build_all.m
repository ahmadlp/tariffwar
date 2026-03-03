function build_all(varargin)
%TARIFFWAR.PIPELINE.BUILD_ALL  Build all data files for the tariff war analysis.
%
%   tariffwar.pipeline.build_all()
%   tariffwar.pipeline.build_all('dataset', 'wiod')
%   tariffwar.pipeline.build_all('dataset', 'icio', 'years', 2016:2021)
%
%   Produces one .mat file per (dataset, year) containing:
%     - Unbalanced trade cube (Xjik_3D)
%     - Teti GTD tariffs (tjik_3D)
%     - All elasticity sources (sigma struct with one field per source)
%
%   Output: +tariffwar/mat/WIOD2014.mat, ICIO2020.mat, ITPD2005.mat, etc.
%
%   No intermediate files are produced.
%
%   See also: tariffwar.io.load_data, tariffwar.pipeline.run

    p = inputParser;
    addParameter(p, 'dataset', 'all', @ischar);
    addParameter(p, 'years', [], @isnumeric);
    addParameter(p, 'verbose', true, @islogical);
    parse(p, varargin{:});

    verbose = p.Results.verbose;

    % Output directory
    pkg_root = fileparts(fileparts(mfilename('fullpath')));
    outdir   = fullfile(pkg_root, 'mat');
    if ~isfolder(outdir), mkdir(outdir); end

    % Config for data loading
    cfg = tariffwar.defaults();
    cfg.verbose = verbose;

    % Dataset configs — default year ranges
    default_years = struct( ...
        'wiod', 2000:2014, ...
        'icio', 2011:2022, ...
        'itpd', 2000:2019);

    max_teti_year = 2021;

    if strcmp(p.Results.dataset, 'all')
        ds_names = {'wiod', 'icio', 'itpd'};
    else
        ds_names = {p.Results.dataset};
    end

    % Get all implemented elasticity sources
    reg = tariffwar.elasticity.registry();
    reg = reg([reg.implemented]);

    % Teti concordance (shared across all datasets/years)
    [C_teti_wiod, teti_codes] = tariffwar.concordance.teti35_to_wiod();

    t_start = tic;
    n_files = 0;

    for d = 1:numel(ds_names)
        ds = ds_names{d};
        cfg.dataset = ds;

        % Determine years
        if isempty(p.Results.years)
            years = default_years.(ds);
        else
            years = p.Results.years;
        end

        if verbose
            fprintf('\n============  %s (%d years)  ============\n', upper(ds), numel(years));
        end

        % Sigma is computed lazily — recomputed when S changes
        last_S = -1;
        sigma  = struct();

        for t = 1:numel(years)
            yr = years(t);

            if verbose
                fprintf('\n[%s %d] (%d/%d)\n', upper(ds), yr, t, numel(years));
            end

            % --- Trade cube ---
            if verbose, fprintf('  Trade cube...'); end
            switch ds
                case 'wiod'
                    cube = tariffwar.data.build_cubes_wiod(cfg, yr);
                case 'icio'
                    cube = tariffwar.data.build_cubes_icio(cfg, yr);
                case 'itpd'
                    cube = tariffwar.data.build_cubes_itpd(cfg, yr);
            end
            if verbose, fprintf(' N=%d, S=%d\n', cube.N, cube.S); end

            % --- Recompute sigma if sector count changed ---
            if cube.S ~= last_S
                sigma = compute_all_sigmas(reg, ds, cube.S, verbose);
                last_S = cube.S;
            end

            % --- Tariff cube ---
            teti_yr = min(yr, max_teti_year);
            if verbose
                fprintf('  Tariffs (Teti %d)...', teti_yr);
            end
            T_teti = tariffwar.tariff.read_teti(teti_yr, 'verbose', false);
            tjik_raw = build_raw_tariff(T_teti, cube.countries, teti_codes, cube.N);
            tjik_3D  = apply_tariff_concordance(tjik_raw, C_teti_wiod, ds, cube.S, cube.N);
            % Zero diagonal
            for k = 1:cube.S
                tjik_3D(:,:,k) = tjik_3D(:,:,k) .* (1 - eye(cube.N));
            end
            if verbose
                nz = nnz(tjik_3D);
                fprintf(' %d non-zero, mean=%.2f%%\n', nz, 100*mean(tjik_3D(tjik_3D>0)));
            end

            % --- Assemble single struct ---
            data.Xjik_3D        = cube.Xjik_3D;
            data.tjik_3D        = tjik_3D;
            data.sigma          = sigma;
            data.N              = cube.N;
            data.S              = cube.S;
            data.services_sector = cube.services_sector;
            data.countries      = cube.countries;
            data.sectors        = cube.sectors;
            data.dataset        = ds;
            data.year           = yr;

            % --- Save ---
            fname = fullfile(outdir, sprintf('%s%d.mat', upper(ds), yr));
            save(fname, 'data', '-v7.3');
            n_files = n_files + 1;

            if verbose
                f_info = dir(fname);
                fprintf('  Saved %s (%.0f KB)\n', fname, f_info.bytes/1024);
            end
        end
    end

    elapsed = toc(t_start);
    if verbose
        fprintf('\n============  DONE: %d files in %.1f sec  ============\n', n_files, elapsed);
        fprintf('Output: %s\n', outdir);
    end
end


% =========================================================================
function sigma = compute_all_sigmas(reg, ds, S, verbose)
%COMPUTE_ALL_SIGMAS  Compute epsilon/sigma for all sources mapped to one dataset.
%   Returns struct with one field per source (keyed by abbreviation).

    sigma = struct();

    for i = 1:numel(reg)
        entry = reg(i);

        if strcmp(entry.classification, 'uniform')
            raw = entry.getter();
            epsilon_S = raw.value * ones(S, 1);
        elseif strcmp(entry.classification, 'insample')
            raw = entry.getter();
            switch ds
                case 'wiod', epsilon_wiod = raw.epsilon_wiod;
                case 'icio', epsilon_wiod = raw.epsilon_icio;
                case 'itpd', epsilon_wiod = raw.epsilon_itpd;
            end
            epsilon_S = chain_to_dataset(epsilon_wiod, ds, S);
        else
            raw = entry.getter();
            % Source -> WIOD-16
            C_to_wiod = concordance_to_wiod(entry);
            epsilon_wiod = C_to_wiod * raw.epsilon;
            % WIOD-16 -> target dataset
            epsilon_S = chain_to_dataset(epsilon_wiod, ds, S);
        end

        % Fallback for uncovered sectors
        zero_mask = (epsilon_S == 0);
        if any(zero_mask)
            epsilon_S(zero_mask) = 4;  % Simonovska-Waugh
            if verbose
                fprintf('  [sigma %s] %d uncovered sectors -> fallback eps=4\n', ...
                    entry.abbrev, sum(zero_mask));
            end
        end

        s.epsilon_S = epsilon_S;
        s.sigma_S   = epsilon_S + 1;
        s.source    = entry.name;
        sigma.(entry.abbrev) = s;
    end

    if verbose
        fprintf('  Sigma: %d sources mapped to %s (S=%d)\n', numel(reg), upper(ds), S);
    end
end


function C_to_wiod = concordance_to_wiod(entry)
    switch entry.classification
        case 'wiod_16',  C_to_wiod = eye(16);
        case 'isic_rev3', C_to_wiod = tariffwar.concordance.isic3_to_wiod(entry.native_sectors, 16);
        case 'shapiro_13', C_to_wiod = tariffwar.concordance.shapiro13_to_wiod(entry.native_sectors, 16);
        case 'isic_rev2', C_to_wiod = tariffwar.concordance.gyy19_to_wiod(entry.native_sectors, 16);
        case 'sitc_rev2', C_to_wiod = tariffwar.concordance.bsy49_to_wiod(entry.native_sectors, 16);
        case 'tiva_19',  C_to_wiod = tariffwar.concordance.fontagne19_to_wiod(entry.native_sectors, 16);
        case 'isic4_14', C_to_wiod = tariffwar.concordance.ll14_to_wiod(entry.native_sectors, 16);
        otherwise
            error('tariffwar:buildAll:noConc', ...
                'No concordance for classification: ''%s''.', entry.classification);
    end
end


function epsilon_S = chain_to_dataset(epsilon_wiod, ds, S)
    switch ds
        case 'wiod', epsilon_S = epsilon_wiod;
        case 'icio', epsilon_S = tariffwar.concordance.wiod16_to_icio(S) * epsilon_wiod;
        case 'itpd', epsilon_S = tariffwar.concordance.wiod16_to_itpd(S) * epsilon_wiod;
        otherwise, error('tariffwar:buildAll:unknownDS', 'Unknown dataset: %s', ds);
    end
end


% =========================================================================
function tjik_raw = build_raw_tariff(T, countries, teti_codes, N)
%BUILD_RAW_TARIFF  Map Teti table to N x N x 35 cube.

    n_sectors = numel(teti_codes);
    tjik_raw = zeros(N, N, n_sectors);

    code_to_col = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for s = 1:n_sectors
        code_to_col(teti_codes(s)) = s;
    end

    iso_to_idx = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for i = 1:N
        c = countries{i};
        if iscell(c), c = c{1}; end
        iso_to_idx(c) = i;
    end

    importers = T.iso1;
    exporters = T.iso2;
    sectors   = T.sector;
    tariffs   = T.tariff;
    if iscell(importers), importers = string(importers); end
    if iscell(exporters), exporters = string(exporters); end

    for r = 1:height(T)
        imp = char(importers(r));
        exp = char(exporters(r));
        sec = sectors(r);
        tar = tariffs(r);
        if isnan(tar) || tar < 0, continue; end
        if ~iso_to_idx.isKey(imp) || ~iso_to_idx.isKey(exp), continue; end
        if ~code_to_col.isKey(sec), continue; end
        tjik_raw(iso_to_idx(exp), iso_to_idx(imp), code_to_col(sec)) = tar / 100;
    end
end


function tjik_3D = apply_tariff_concordance(tjik_raw, C_teti_wiod, ds, S, N)
    switch ds
        case 'wiod', C = C_teti_wiod;
        case 'icio', C = tariffwar.concordance.wiod16_to_icio(S) * C_teti_wiod;
        case 'itpd', C = tariffwar.concordance.wiod16_to_itpd(S) * C_teti_wiod;
        otherwise, error('tariffwar:buildAll:unknownDS', 'Unknown dataset: %s', ds);
    end
    t_2d = reshape(tjik_raw, N*N, 35);
    t_target_2d = t_2d * C';
    tjik_3D = reshape(t_target_2d, N, N, S);
end
