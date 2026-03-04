function results = run(datasets, years, elasticities, varargin)
%TARIFFWAR.PIPELINE.RUN  Run tariff war analysis.
%
%   tariffwar.pipeline.run('wiod', 2014, 'IS')
%   tariffwar.pipeline.run('wiod', 2014, 'IS', 'Algorithm', 'levenberg-marquardt')
%   tariffwar.pipeline.run('wiod', 2014, 'IS', 'T0_scale', [0.8, 1.2, 1.5])
%   tariffwar.pipeline.run({'wiod','icio'}, 2000:2014, {'IS','U4'})
%
%   Positional args:
%     datasets     - string or cell ('wiod', 'icio', 'itpd')
%     years        - numeric vector (e.g. 2014 or 2000:2014)
%     elasticities - abbreviation or cell. Available sources:
%
%       Abbrev  Full name                        Paper
%       ------  ---------                        -----
%       IS      in_sample                        In-sample (dataset-specific)
%       U4      uniform_4                        Simonovska & Waugh (2014, JIE)
%       CP      caliendo_parro_2015              Caliendo & Parro (2015, ReStud)
%       BSY     bagwell_staiger_yurukoglu_2021   BSY (2021, Econometrica)
%       GYY     giri_yi_yilmazkuday_2021         GYY (2021, JIE)
%       Shap    shapiro_2016                     Shapiro (2016, AEJ)
%       FGO     fontagne_2022                    Fontagne et al. (2022, JIE)
%       LL      lashkaripour_lugovskyy_2023      LL (2023, AER)
%
%   Year coverage (from prebuilt .mat files):
%     WIOD:  2000-2014  (44 countries, 16 sectors)
%     ICIO:  2011-2022  (81 countries, 28 sectors)
%     ITPD:  2000-2019  (135 countries, 154 sectors)
%   Years without a .mat file are silently skipped.
%
%   Name-value options:
%     'Algorithm'          - fsolve algorithm (default: 'levenberg-marquardt')
%     'MaxIter'            - max iterations per attempt (default: 50)
%     'MaxFunEvals'        - max function evaluations (default: Inf)
%     'TolFun'             - function tolerance (default: 1e-6)
%     'TolX'               - step tolerance (default: 1e-8)
%     'Display'            - solver display (default: 'iter')
%     'T0_scale'           - [wi, Yi, tjik] initial guess (default: [0.9, 1.1, 1.25])
%     'output_file'        - CSV path (default: +tariffwar/results/results.csv)
%     'max_retries'        - restart attempts with random T0 (default: 3)
%     'stall_window'       - iterations before stall check (default: 3)
%     'min_progress'       - min relative ||F|| decrease (default: 0.10)

    % Normalize inputs
    if ischar(datasets), datasets = {datasets}; end
    if ischar(elasticities), elasticities = {elasticities}; end

    % Load defaults, override from varargin
    cfg = tariffwar.defaults();
    pkg_root = fileparts(fileparts(mfilename('fullpath')));
    output_file = fullfile(pkg_root, 'results', 'results.csv');
    for i = 1:2:numel(varargin)
        switch varargin{i}
            case 'Algorithm',          cfg.solver.algorithm = varargin{i+1};
            case 'MaxIter',            cfg.solver.MaxIter = varargin{i+1};
            case 'MaxFunEvals',        cfg.solver.MaxFunEvals = varargin{i+1};
            case 'TolFun',             cfg.solver.TolFun = varargin{i+1};
            case 'TolX',               cfg.solver.TolX = varargin{i+1};
            case 'Display',            cfg.solver.Display = varargin{i+1};
            case 'T0_scale'
                v = varargin{i+1};
                cfg.solver.T0_scale.wi = v(1);
                cfg.solver.T0_scale.Yi = v(2);
                cfg.solver.T0_scale.tjik = v(3);
            case 'output_file',        output_file = varargin{i+1};
            case 'max_retries',        cfg.solver.max_retries = varargin{i+1};
            case 'stall_window',       cfg.solver.stall_window = varargin{i+1};
            case 'min_progress',       cfg.solver.min_progress = varargin{i+1};
            % 'algorithm_fallback' removed — Nash uses single algorithm
        end
    end


    % Resolve elasticity abbreviations
    reg = tariffwar.elasticity.registry();
    elas = resolve_elasticities(elasticities, reg);

    % Open CSV
    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && ~isfolder(out_dir), mkdir(out_dir); end
    fid = fopen(output_file, 'w');
    fprintf(fid, 'Country,Year,Dataset,Elasticity,Percent_Change,Exitflag\n');

    % === Main loop ===
    all_results = {};
    for di = 1:numel(datasets)
      ds = datasets{di};
      for yi = 1:numel(years)
        yr = years(yi);
        % Skip years without a .mat file
        mat_file = fullfile(cfg.mat_dir, sprintf('%s%d.mat', upper(ds), yr));
        if ~isfile(mat_file)
            fprintf('Skipping %s %d (no data file)\n', upper(ds), yr);
            continue;
        end

        fprintf('Loading %s %d...\n', upper(ds), yr);
        d = tariffwar.io.load_data(ds, yr, 'mat_dir', cfg.mat_dir);
        N = d.N;  S = d.S;

        for ei = 1:numel(elas)
            fprintf('  %s... ', elas(ei).abbrev);

            % Sigma cube from prebuilt data
            sigma_S   = d.sigma.(elas(ei).abbrev).sigma_S;
            sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);

            % Diagonal scaling for sparse datasets (ICIO has ~6% zero diagonals)
            Xjik_raw = d.Xjik_3D;
            if strcmp(ds, 'icio'), Xjik_raw = Xjik_raw + repmat(eye(N), [1, 1, S]); end

            % Step 1: Balance trade -- remove trade deficits (zero-deficit counterfactual)
            Xjik_3D = tariffwar.data.balance_trade(Xjik_raw, sigma_k3D, d.tjik_3D, N, S, cfg);
            % Step 2: Compute derived cubes -- trade shares, income, revenue, expenditure shares
            [lam, Yi3D, Ri3D, e_ik3D] = tariffwar.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);
            % Step 3: Solve Nash equilibrium -- find optimal tariffs via fsolve
            [X_sol, ef, out] = tariffwar.solver.nash_equilibrium(N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, cfg);
            % Step 4: Compute welfare -- percent change in real income per country
            pct = tariffwar.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, d.tjik_3D);

            fprintf('ef=%d iter=%d mean=%.3f%%\n', ef, out.iterations, mean(pct));

            % Write CSV rows
            for ci = 1:N
                c = d.countries{ci};
                if iscell(c), c = c{1}; end
                fprintf(fid, '%s,%d,%s,%s,%.6f,%d\n', c, yr, ds, elas(ei).name, pct(ci), ef);
            end

            all_results{end+1} = struct('dataset', ds, 'year', yr, ...
                'elasticity', elas(ei).name, 'pct_change', pct, ...
                'exitflag', ef, 'countries', {d.countries}); %#ok<AGROW>
        end
      end
    end

    fclose(fid);
    fprintf('Done. Output: %s\n', output_file);

    % Return
    results.csv_file = output_file;
    results.runs     = all_results;
    if numel(all_results) == 1
        results.pct_change = all_results{1}.pct_change;
        results.exitflag   = all_results{1}.exitflag;
        results.countries  = all_results{1}.countries;
    end
end


function entries = resolve_elasticities(names, reg)
    entries = struct([]);
    for i = 1:numel(names)
        idx = find(strcmp({reg.abbrev}, names{i}), 1);
        if isempty(idx), idx = find(strcmp({reg.name}, names{i}), 1); end
        if isempty(idx), error('Unknown elasticity: %s', names{i}); end
        if isempty(entries), entries = reg(idx);
        else, entries(end+1) = reg(idx); end %#ok<AGROW>
    end
end
