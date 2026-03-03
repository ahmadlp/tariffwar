function results = estimate_cp2014(mat_dir, dataset, years, varargin)
%TARIFFWAR.ELASTICITY.ESTIMATE_CP2014  Estimate trade elasticities via CP2014 trilateral gravity.
%
%   results = tariffwar.elasticity.estimate_cp2014(mat_dir, 'icio', 2016:2022)
%   results = tariffwar.elasticity.estimate_cp2014(mat_dir, 'itpd', 2000:2019)
%
%   Pools data across the given years for one dataset, aggregates native
%   sectors into the 16 broad WIOD sectors, and produces per-sector OLS
%   estimates using the Caliendo & Parro (2014) trilateral ratio
%   identification strategy.
%
%   Output is a 16x1 epsilon vector (15 estimated goods + 1 services
%   assigned fallback). Services sector (16) always gets the fallback
%   value since tariffs on services are typically zero.
%
%   Methodology (replicates ../trade_elasticity/ reference scripts):
%     1. Aggregate native sectors to 16 WIOD groups (sum trade, avg tariffs)
%     2. Form all ordered country trilaterals (i < j < n)
%     3. Dependent variable:  Y = log(Xij*Xjn*Xni / Xji*Xnj*Xin)
%     4. Independent variable: X = log(tij*tjn*tni / tji*tnj*tin)
%     5. Country fixed effects: D(e,i)=D(e,j)=D(e,n)=1
%     6. OLS, no constant, HC1 robust standard errors
%
%   Returns struct with:
%     .epsilon_fe    - 16x1 trade elasticities (FE specification, primary)
%     .epsilon_nofe  - 16x1 trade elasticities (no FE specification)
%     .se_fe         - 16x1 robust standard errors (FE)
%     .se_nofe       - 16x1 robust standard errors (no FE)
%     .N_obs         - 16x1 observation counts per sector
%     .beta_fe       - 16x1 raw OLS coefficients (FE)
%     .beta_nofe     - 16x1 raw OLS coefficients (no FE)
%     .S             - 16 (always WIOD-16 output)
%     .N_countries   - number of countries in pooled sample
%     .dataset       - string
%     .years         - vector of years used
%     .sectors       - 16x1 cell of WIOD sector labels
%     .fallback_mask - 16x1 logical (true = used fallback)
%
%   See also: tariffwar.elasticity.registry, tariffwar.build_all

    p = inputParser;
    addParameter(p, 'import_pctile_cutoff', 2.5, @isnumeric);
    addParameter(p, 'trim_pctile', [1 99], @isnumeric);
    addParameter(p, 'min_obs', 30, @isnumeric);
    addParameter(p, 'fallback_epsilon', 4.0, @isnumeric);
    addParameter(p, 'sector_groups', {}, @iscell);
    addParameter(p, 'verbose', true, @islogical);
    parse(p, varargin{:});
    opts = p.Results;

    S_out = 16;  % Always produce WIOD-16 output

    wiod_labels = { ...
        'Agriculture, forestry, fishing'; ...
        'Mining and quarrying'; ...
        'Food products, beverages, tobacco'; ...
        'Textiles, wearing apparel, leather'; ...
        'Wood, paper, printing'; ...
        'Coke and refined petroleum'; ...
        'Chemicals and pharmaceuticals'; ...
        'Rubber, plastics, non-metallic minerals'; ...
        'Basic metals'; ...
        'Fabricated metals'; ...
        'Computer, electronic, optical'; ...
        'Electrical equipment'; ...
        'Machinery and equipment n.e.c.'; ...
        'Transport equipment'; ...
        'Other manufacturing; repair'; ...
        'Services (aggregate)'};

    % =====================================================================
    % Step 1: Load all years and find common structure
    % =====================================================================
    if opts.verbose
        fprintf('\n========== CP2014 In-Sample Estimation: %s ==========\n', upper(dataset));
        fprintf('Years: %d-%d (%d years)\n', years(1), years(end), numel(years));
        fprintf('Aggregating native sectors to WIOD-16 before estimation\n');
    end

    all_data = cell(numel(years), 1);
    all_countries = cell(numel(years), 1);
    S_native = zeros(numel(years), 1);

    for t = 1:numel(years)
        yr = years(t);
        fname = fullfile(mat_dir, sprintf('%s%d.mat', upper(dataset), yr));
        if ~isfile(fname)
            error('estimate_cp2014:fileNotFound', 'File not found: %s', fname);
        end
        loaded = load(fname, 'data');
        all_data{t} = loaded.data;
        all_countries{t} = loaded.data.countries;
        S_native(t) = loaded.data.S;
    end

    % Find common countries across all years
    common_countries = all_countries{1};
    for t = 2:numel(years)
        common_countries = intersect(common_countries, all_countries{t}, 'stable');
    end
    N_common = numel(common_countries);

    if opts.verbose
        fprintf('Common countries: %d | Native S range: %d-%d\n', ...
            N_common, min(S_native), max(S_native));
    end

    % Sector grouping: map each WIOD sector to its "leader" sector
    group_leader = (1:S_out)';
    for g = 1:numel(opts.sector_groups)
        grp = opts.sector_groups{g};
        for k = 2:numel(grp)
            group_leader(grp(k)) = grp(1);
        end
    end

    % =====================================================================
    % Step 2: Per-sector estimation on aggregated WIOD-16 sectors
    % =====================================================================
    epsilon_fe    = zeros(S_out, 1);
    epsilon_nofe  = zeros(S_out, 1);
    se_fe_vec     = zeros(S_out, 1);
    se_nofe_vec   = zeros(S_out, 1);
    beta_fe_vec   = zeros(S_out, 1);
    beta_nofe_vec = zeros(S_out, 1);
    N_obs         = zeros(S_out, 1);
    fallback_mask = false(S_out, 1);

    for s = 1:S_out
        if opts.verbose
            fprintf('\n--- WIOD Sector %d/%d: %s ---\n', s, S_out, wiod_labels{s});
        end

        % If this sector is pooled with a group leader, copy results
        if group_leader(s) ~= s
            leader = group_leader(s);
            epsilon_fe(s) = epsilon_fe(leader);
            epsilon_nofe(s) = epsilon_nofe(leader);
            se_fe_vec(s) = se_fe_vec(leader);
            se_nofe_vec(s) = se_nofe_vec(leader);
            beta_fe_vec(s) = beta_fe_vec(leader);
            beta_nofe_vec(s) = beta_nofe_vec(leader);
            N_obs(s) = N_obs(leader);
            fallback_mask(s) = fallback_mask(leader);
            if opts.verbose
                fprintf('  -> Pooled with sector %d (%s)\n', leader, wiod_labels{leader});
            end
            continue;
        end

        % Find all WIOD sectors in this group (leader + followers)
        group_members = find(group_leader == s);

        % Services sector: assign fallback directly
        if s == S_out
            if opts.verbose
                fprintf('  Services sector -> fallback eps=%.1f\n', opts.fallback_epsilon);
            end
            epsilon_fe(s) = opts.fallback_epsilon;
            epsilon_nofe(s) = opts.fallback_epsilon;
            fallback_mask(s) = true;
            continue;
        end

        % Pool trilateral observations across years
        Y_pool = [];
        X_pool = [];
        D_rows = [];
        D_cols = [];
        obs_offset = 0;

        for t = 1:numel(years)
            d = all_data{t};
            S_nat = d.S;

            % Map to common country indices
            [~, idx_in_year] = ismember(common_countries, d.countries);
            if any(idx_in_year == 0)
                error('estimate_cp2014:countryMapping', ...
                    'Common country not found in year %d', years(t));
            end

            % Get WIOD-16 mapping for this year's native sectors
            wiod_map = get_wiod16_mapping(dataset, S_nat);
            native_in_group = find(ismember(wiod_map, group_members));

            if isempty(native_in_group)
                if opts.verbose && t == 1
                    fprintf('  Year %d: no native sectors map to WIOD %d, skipping\n', years(t), s);
                end
                continue;
            end

            % Aggregate trade flows: sum across sub-sectors
            Xs_raw = d.Xjik_3D(idx_in_year, idx_in_year, native_in_group);
            Xs = sum(Xs_raw, 3);

            % Aggregate tariffs: simple average (reference code lines 27-28)
            tau_raw = d.tjik_3D(idx_in_year, idx_in_year, native_in_group);
            tau_avg = mean(tau_raw, 3);
            tau_s = 1 + tau_avg;  % Convert to (1 + rate)

            % Set zero trade flows to NaN (reference code line 64)
            Xs(Xs == 0) = NaN;

            % Import-based country trimming (reference code lines 78-86)
            total_imports = nansum(Xs, 1)';
            p_low = prctile(total_imports, opts.import_pctile_cutoff);
            active = total_imports >= p_low & ~isnan(total_imports);
            active_idx = find(active);
            N_active = numel(active_idx);

            if N_active < 3
                if opts.verbose
                    fprintf('  Year %d: only %d active countries, skipping\n', years(t), N_active);
                end
                continue;
            end

            % Extract submatrices for active countries
            X_act = Xs(active_idx, active_idx);
            tau_act = tau_s(active_idx, active_idx);

            % Construct all ordered trilaterals (i < j < n)
            triplets = nchoosek(1:N_active, 3);
            E = size(triplets, 1);
            ii = triplets(:,1);
            jj = triplets(:,2);
            nn = triplets(:,3);

            % Vectorized trilateral ratios
            Xij = X_act(sub2ind([N_active, N_active], ii, jj));
            Xjn = X_act(sub2ind([N_active, N_active], jj, nn));
            Xni = X_act(sub2ind([N_active, N_active], nn, ii));
            Xji = X_act(sub2ind([N_active, N_active], jj, ii));
            Xnj = X_act(sub2ind([N_active, N_active], nn, jj));
            Xin = X_act(sub2ind([N_active, N_active], ii, nn));

            Y_obs = log( (Xij .* Xjn .* Xni) ./ (Xji .* Xnj .* Xin) );

            tij = tau_act(sub2ind([N_active, N_active], ii, jj));
            tjn = tau_act(sub2ind([N_active, N_active], jj, nn));
            tni = tau_act(sub2ind([N_active, N_active], nn, ii));
            tji = tau_act(sub2ind([N_active, N_active], jj, ii));
            tnj = tau_act(sub2ind([N_active, N_active], nn, jj));
            tin = tau_act(sub2ind([N_active, N_active], ii, nn));

            X_obs = log( (tij .* tjn .* tni) ./ (tji .* tnj .* tin) );

            % Build FE dummy indices
            global_idx = active_idx;
            row_base = obs_offset + (1:E)';
            D_rows = [D_rows; row_base; row_base; row_base]; %#ok<AGROW>
            D_cols = [D_cols; global_idx(ii); global_idx(jj); global_idx(nn)]; %#ok<AGROW>

            Y_pool = [Y_pool; Y_obs]; %#ok<AGROW>
            X_pool = [X_pool; X_obs]; %#ok<AGROW>
            obs_offset = obs_offset + E;

            if opts.verbose
                fprintf('  Year %d: N_active=%d, trilaterals=%d, native_secs=%d\n', ...
                    years(t), N_active, E, numel(native_in_group));
            end
        end

        % Drop NaN and Inf observations
        valid = isfinite(Y_pool) & isfinite(X_pool);
        Y_pool = Y_pool(valid);
        X_pool = X_pool(valid);

        % Remap FE indices for valid observations
        valid_full = find(valid);
        [~, D_keep] = ismember(D_rows, valid_full);
        keep_mask = D_keep > 0;
        D_rows_clean = D_keep(keep_mask);
        D_cols_clean = D_cols(keep_mask);

        n_obs_raw = numel(Y_pool);

        if n_obs_raw < opts.min_obs
            if opts.verbose
                fprintf('  Insufficient observations (%d < %d), using fallback eps=%.1f\n', ...
                    n_obs_raw, opts.min_obs, opts.fallback_epsilon);
            end
            epsilon_fe(s) = opts.fallback_epsilon;
            epsilon_nofe(s) = opts.fallback_epsilon;
            fallback_mask(s) = true;
            continue;
        end

        % Check if tariff variation exists
        if all(X_pool == 0) || std(X_pool) < 1e-12
            if opts.verbose
                fprintf('  No tariff variation, using fallback eps=%.1f\n', opts.fallback_epsilon);
            end
            epsilon_fe(s) = opts.fallback_epsilon;
            epsilon_nofe(s) = opts.fallback_epsilon;
            fallback_mask(s) = true;
            continue;
        end

        % Outlier trimming: drop Y outside [1st, 99th] percentile
        y_lo = prctile(Y_pool, opts.trim_pctile(1));
        y_hi = prctile(Y_pool, opts.trim_pctile(2));
        trim_keep = Y_pool >= y_lo & Y_pool <= y_hi;
        Y_trim = Y_pool(trim_keep);
        X_trim = X_pool(trim_keep);

        % Remap FE indices for trimmed observations
        trim_full = find(trim_keep);
        [~, D_trim_map] = ismember(D_rows_clean, trim_full);
        trim_fe_keep = D_trim_map > 0;
        D_rows_trim = D_trim_map(trim_fe_keep);
        D_cols_trim = D_cols_clean(trim_fe_keep);

        n_trim = numel(Y_trim);
        N_obs(s) = n_trim;

        if n_trim < opts.min_obs
            if opts.verbose
                fprintf('  After trimming: %d obs (< %d), using fallback\n', n_trim, opts.min_obs);
            end
            epsilon_fe(s) = opts.fallback_epsilon;
            epsilon_nofe(s) = opts.fallback_epsilon;
            fallback_mask(s) = true;
            continue;
        end

        % =================================================================
        % No-FE OLS: Y = beta * X, no constant, robust SE
        % =================================================================
        beta_nf = (X_trim' * X_trim) \ (X_trim' * Y_trim);
        e_nf = Y_trim - X_trim * beta_nf;
        k_nf = 1;
        meat_nf = X_trim' * (e_nf.^2 .* X_trim);
        bread_nf = 1 / (X_trim' * X_trim);
        V_nf = (n_trim / (n_trim - k_nf)) * bread_nf * meat_nf * bread_nf;
        se_nf = sqrt(V_nf);

        beta_nofe_vec(s) = beta_nf;
        se_nofe_vec(s) = se_nf;
        epsilon_nofe(s) = max(-beta_nf, 0);

        if opts.verbose
            fprintf('  No-FE: beta=%.4f, se=%.4f, eps=%.4f (n=%d)\n', ...
                beta_nf, se_nf, epsilon_nofe(s), n_trim);
        end

        % =================================================================
        % FE OLS: Y = beta * X + gamma * D, no constant, robust SE
        % Uses FWL (Frisch-Waugh-Lovell) for efficient computation
        % =================================================================
        D_sparse = sparse(D_rows_trim, D_cols_trim, 1, n_trim, N_common);
        active_fe = find(full(sum(D_sparse, 1)) > 0);
        D_sparse = D_sparse(:, active_fe);

        k_fe = 1 + size(D_sparse, 2);

        % FWL partialling out
        DtD = D_sparse' * D_sparse;
        X_tilde = X_trim - D_sparse * (DtD \ (D_sparse' * X_trim));
        Y_tilde = Y_trim - D_sparse * (DtD \ (D_sparse' * Y_trim));

        beta_f = (X_tilde' * X_tilde) \ (X_tilde' * Y_tilde);

        % Residuals from full model
        XD = [X_trim, D_sparse];
        beta_all = (XD' * XD) \ (XD' * Y_trim);
        e_fe = Y_trim - XD * beta_all;

        % HC1 robust SE on the partialled-out coefficient
        meat_fe = X_tilde' * (e_fe.^2 .* X_tilde);
        bread_fe = 1 / (X_tilde' * X_tilde);
        V_fe = (n_trim / (n_trim - k_fe)) * bread_fe * meat_fe * bread_fe;
        se_f = sqrt(V_fe);

        beta_fe_vec(s) = beta_f;
        se_fe_vec(s) = se_f;
        epsilon_fe(s) = max(-beta_f, 0);

        if opts.verbose
            fprintf('  FE:    beta=%.4f, se=%.4f, eps=%.4f (n=%d, k=%d)\n', ...
                beta_f, se_f, epsilon_fe(s), n_trim, k_fe);
        end

        % =================================================================
        % Apply fallback if coefficient is not negative
        % =================================================================
        if beta_f >= 0
            if opts.verbose
                fprintf('  WARNING: FE beta >= 0. ');
            end
            if beta_nf < 0
                epsilon_fe(s) = epsilon_nofe(s);
                if opts.verbose
                    fprintf('Using no-FE estimate (eps=%.4f)\n', epsilon_fe(s));
                end
            else
                epsilon_fe(s) = opts.fallback_epsilon;
                epsilon_nofe(s) = opts.fallback_epsilon;
                fallback_mask(s) = true;
                if opts.verbose
                    fprintf('Both specs non-negative. Fallback eps=%.1f\n', opts.fallback_epsilon);
                end
            end
        end
    end

    % =====================================================================
    % Step 3: Assemble results
    % =====================================================================
    results.epsilon_fe    = epsilon_fe;
    results.epsilon_nofe  = epsilon_nofe;
    results.se_fe         = se_fe_vec;
    results.se_nofe       = se_nofe_vec;
    results.beta_fe       = beta_fe_vec;
    results.beta_nofe     = beta_nofe_vec;
    results.N_obs         = N_obs;
    results.S             = S_out;
    results.N_countries   = N_common;
    results.dataset       = dataset;
    results.years         = years;
    results.sectors       = wiod_labels;
    results.fallback_mask = fallback_mask;

    % Print summary table
    if opts.verbose
        fprintf('\n\n========== ESTIMATION RESULTS: %s -> WIOD-16 ==========\n', upper(dataset));
        fprintf('%-4s %-40s %10s %10s %10s %10s %8s %s\n', ...
            'Sec', 'Label', 'eps_FE', 'se_FE', 'eps_noFE', 'se_noFE', 'N_obs', 'Fallback');
        fprintf('%s\n', repmat('-', 1, 100));
        for s = 1:S_out
            lbl = wiod_labels{s};
            if length(lbl) > 40, lbl = [lbl(1:37) '...']; end
            fb = '';
            if fallback_mask(s), fb = ' *FALLBACK*'; end
            fprintf('%-4d %-40s %10.4f %10.4f %10.4f %10.4f %8d%s\n', ...
                s, lbl, epsilon_fe(s), se_fe_vec(s), ...
                epsilon_nofe(s), se_nofe_vec(s), N_obs(s), fb);
        end
        fprintf('\nFallback sectors: %d / %d\n', sum(fallback_mask), S_out);
        fprintf('=========================================================\n');
    end
end


% =========================================================================
function wiod_map = get_wiod16_mapping(dataset, S)
%GET_WIOD16_MAPPING  Map native sector indices to WIOD-16 sector numbers.
%   Consistent with concordance files in +tariffwar/+concordance/.

    switch dataset
        case 'icio'
            switch S
                case 28  % Extended format (2016-2022)
                    wiod_map = [ ...
                        1; 1; 1;           ... % A01, A02, A03
                        2; 2; 2; 2; 2;     ... % B05-B09
                        3;                 ... % C10T12
                        4;                 ... % C13T15
                        5; 5;              ... % C16, C17_18
                        6;                 ... % C19
                        7; 7;              ... % C20, C21
                        8; 8;              ... % C22, C23
                        9; 9;              ... % C24A, C24B
                        10;                ... % C25
                        11;                ... % C26
                        12;                ... % C27
                        13;                ... % C28
                        14; 14; 14;        ... % C29, C301, C302T309
                        15;                ... % C31T33
                        16];                   % Services
                case 23  % SML format (2011-2015)
                    wiod_map = [ ...
                        1; 1;              ... % A01_02, A03
                        2; 2; 2;           ... % B05_06, B07_08, B09
                        3;                 ... % C10T12
                        4;                 ... % C13T15
                        5; 5;              ... % C16, C17_18
                        6;                 ... % C19
                        7; 7;              ... % C20, C21
                        8; 8;              ... % C22, C23
                        9;                 ... % C24
                        10;                ... % C25
                        11;                ... % C26
                        12;                ... % C27
                        13;                ... % C28
                        14; 14;            ... % C29, C30
                        15;                ... % C31T33
                        16];                   % Services
                case 22  % Standard ICIO
                    wiod_map = [ ...
                        1;                 ... % 01T03
                        2; 2; 2;           ... % 05T06, 07T08, 09
                        3;                 ... % 10T12
                        4;                 ... % 13T15
                        5; 5;              ... % 16, 17T18
                        6;                 ... % 19
                        7;                 ... % 20T21
                        8; 8;              ... % 22, 23
                        9;                 ... % 24
                        10;                ... % 25
                        11;                ... % 26
                        12;                ... % 27
                        13;                ... % 28
                        14; 14;            ... % 29, 30
                        15;                ... % 31T33
                        16];                   % Services
                otherwise
                    error('estimate_cp2014:badS', ...
                        'Unknown ICIO sector count S=%d', S);
            end

        case 'itpd'
            wiod_map = zeros(S, 1);
            % Agriculture: ITPD 1-26 -> WIOD 1
            wiod_map(1:min(26,S)) = 1;
            % Mining: ITPD 27-33 -> WIOD 2
            wiod_map(max(27,1):min(33,S)) = 2;
            % Manufacturing: ITPD 34-153 -> WIOD 3-15
            mfg_ranges = {34:56, 57:68, 69:77, 78:79, 80:95, 96:103, ...
                          104:108, 109:114, 115:122, 123:127, 128:135, ...
                          136:142, 143:153};
            for w = 1:13
                wiod_sec = w + 2;
                for idx = mfg_ranges{w}
                    if idx <= S
                        wiod_map(idx) = wiod_sec;
                    end
                end
            end
            % Services: last sector -> WIOD 16
            if S >= 154
                wiod_map(154:S) = 16;
            end

        case 'wiod'
            wiod_map = (1:S)';

        otherwise
            error('estimate_cp2014:badDataset', 'Unknown dataset: %s', dataset);
    end
end
