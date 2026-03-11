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
%   Years without a .mat file are skipped and recorded in results.skipped_data.
%
%   Name-value options:
%     'Algorithm'          - fsolve algorithm (default: 'levenberg-marquardt')
%     'MaxIter'            - max iterations per attempt (default: 50)
%     'MaxFunEvals'        - max function evaluations (default: Inf)
%     'TolFun'             - function tolerance (default: 1e-6)
%     'TolX'               - step tolerance (default: 1e-8)
%     'Display'            - solver display (default: 'iter')
%     'T0_scale'           - [wi, Yi, tjik] initial guess (default: [0.9, 1.1, 1.25])
%     'output_file'        - CSV path (default: results/results.csv)
%     'save_map'           - save a static welfare map per run (default: false)
%     'map_output_dir'     - map output directory (default: results/maps)
%     'max_retries'        - restart attempts with random T0 (default: 3)
%     'stall_window'       - iterations before stall check (default: 3)
%     'min_progress'       - min relative ||F|| decrease (default: 0.10)
%
%   Returns a struct with CSV and map paths plus per-run summary statistics.

    datasets = normalize_text_list(datasets);
    elasticities = normalize_text_list(elasticities);
    years = years(:).';

    cfg = tariffwar.defaults();
    output_file = fullfile(cfg.results_dir, 'results.csv');
    save_map = false;
    map_output_dir = fullfile(cfg.results_dir, 'maps');
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
            case 'save_map',           save_map = varargin{i+1};
            case 'map_output_dir',     map_output_dir = varargin{i+1};
            case 'max_retries',        cfg.solver.max_retries = varargin{i+1};
            case 'stall_window',       cfg.solver.stall_window = varargin{i+1};
            case 'min_progress',       cfg.solver.min_progress = varargin{i+1};
        end
    end

    cfg.verbose = ~strcmpi(cfg.solver.Display, 'off');
    cfg.balance_trade.Display = cfg.solver.Display;

    reg = tariffwar.elasticity.registry();
    elas = resolve_elasticities(elasticities, reg);
    requested_runs = numel(datasets) * numel(years) * numel(elas);
    detailed_reporting = requested_runs <= 6;

    try
        gdp_map = tariffwar.io.load_gdp();
    catch err
        fprintf('Warning: GDP data unavailable (%s). Dollar values will be NaN.\n', err.message);
        gdp_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end

    out_dir = fileparts(output_file);
    if ~isempty(out_dir) && ~isfolder(out_dir)
        mkdir(out_dir);
    end
    if save_map && ~isfolder(map_output_dir)
        mkdir(map_output_dir);
    end

    fid = fopen(output_file, 'w');
    if fid < 0
        error('tariffwar:pipeline:outputOpenFailed', ...
            'Could not open output file: %s', output_file);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, 'Country,Year,Dataset,Elasticity,Percent_Change,Dollar_Change,Real_GDP,Exitflag\n');

    all_results = {};
    map_files = {};
    skipped_data = struct('dataset', {}, 'year', {}, 'reason', {});

    for di = 1:numel(datasets)
        ds = datasets{di};
        for yi = 1:numel(years)
            yr = years(yi);
            mat_file = fullfile(cfg.mat_dir, sprintf('%s%d.mat', upper(ds), yr));
            if ~isfile(mat_file)
                reason = sprintf('Missing bundled file %s', sprintf('%s%d.mat', upper(ds), yr));
                skipped_data(end + 1) = struct('dataset', ds, 'year', yr, 'reason', reason); %#ok<AGROW>
                fprintf('Skipping %s %d: %s\n', upper(ds), yr, reason);
                continue;
            end

            if cfg.verbose
                fprintf('\n=== Loading %s %d ===\n', upper(ds), yr);
            end
            d = tariffwar.io.load_data(ds, yr, 'mat_dir', cfg.mat_dir);
            N = d.N;
            S = d.S;

            for ei = 1:numel(elas)
                if cfg.verbose
                    fprintf('\n--- Elasticity: %s ---\n', elas(ei).abbrev);
                end

                sigma_S = d.sigma.(elas(ei).abbrev).sigma_S;
                sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);

                Xjik_raw = d.Xjik_3D;
                if strcmp(ds, 'icio')
                    Xjik_raw = Xjik_raw + repmat(eye(N), [1, 1, S]);
                end

                Xjik_3D = tariffwar.data.balance_trade(Xjik_raw, sigma_k3D, d.tjik_3D, N, S, cfg);
                [lam, Yi3D, Ri3D, e_ik3D] = tariffwar.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);
                [X_sol, ef, out] = tariffwar.solver.nash_equilibrium( ...
                    N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, cfg);
                pct = tariffwar.welfare.welfare_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, d.tjik_3D);

                [dollar_change, country_gdp] = compute_dollar_values(pct, d.countries, yr, N, gdp_map);
                total_cost = compute_total_cost(dollar_change);
                tariff_stats = extract_tariff_stats(X_sol, N, d.countries);
                us_idx = find_country_index(d.countries, 'USA');
                us_welfare = NaN;
                if ~isempty(us_idx)
                    us_welfare = pct(us_idx);
                end
                worst_outcome = find_extreme_country(d.countries, pct, 'min');
                best_outcome = find_extreme_country(d.countries, pct, 'max');

                map_file = '';
                if save_map
                    map_file = fullfile(map_output_dir, sprintf( ...
                        'welfare_map_%s_%d_%s.png', lower(ds), yr, elas(ei).abbrev));
                    tariffwar.viz.export_welfare_map(d.countries, pct, ...
                        'output_file', map_file, ...
                        'dataset', ds, ...
                        'year', yr, ...
                        'elasticity', elas(ei).abbrev);
                    map_files{end + 1} = map_file; %#ok<AGROW>
                end

                iterations = NaN;
                if isfield(out, 'iterations')
                    iterations = out.iterations;
                end
                max_residual = NaN;
                if isfield(out, 'max_residual')
                    max_residual = out.max_residual;
                end

                print_run_report(ds, yr, elas(ei).abbrev, N, S, tariff_stats, ...
                    us_welfare, mean(pct), median(pct), total_cost, worst_outcome, ...
                    best_outcome, ef, iterations, max_residual, map_file, detailed_reporting);

                write_rows(fid, d.countries, yr, ds, elas(ei).name, pct, dollar_change, country_gdp, ef);

                all_results{end + 1} = struct( ... %#ok<AGROW>
                    'dataset', ds, ...
                    'year', yr, ...
                    'elasticity', elas(ei).name, ...
                    'elasticity_abbrev', elas(ei).abbrev, ...
                    'pct_change', pct, ...
                    'dollar_change', dollar_change, ...
                    'country_gdp', country_gdp, ...
                    'exitflag', ef, ...
                    'iterations', iterations, ...
                    'max_residual', max_residual, ...
                    'countries', {d.countries}, ...
                    'avg_tariff', tariff_stats.avg, ...
                    'median_tariff', tariff_stats.median, ...
                    'min_tariff', tariff_stats.min, ...
                    'max_tariff', tariff_stats.max, ...
                    'us_welfare', us_welfare, ...
                    'world_mean', mean(pct), ...
                    'world_median', median(pct), ...
                    'matched_gdp_cost', total_cost, ...
                    'map_file', map_file);
            end
        end
    end

    clear cleaner
    print_pipeline_footer(output_file, numel(all_results), numel(map_files), skipped_data);

    results.csv_file = output_file;
    results.map_files = map_files;
    results.runs = all_results;
    results.skipped_data = skipped_data;
    if numel(all_results) == 1
        results.pct_change = all_results{1}.pct_change;
        results.dollar_change = all_results{1}.dollar_change;
        results.exitflag = all_results{1}.exitflag;
        results.countries = all_results{1}.countries;
        results.map_file = all_results{1}.map_file;
    end
end


function values = normalize_text_list(values)
    if ischar(values) || (isstring(values) && isscalar(values))
        values = {char(string(values))};
        return;
    end
    values = cellstr(string(values(:)));
end


function write_rows(fid, countries, year, dataset, elasticity, pct, dollar_change, country_gdp, exitflag)
    for ci = 1:numel(countries)
        c = normalize_country(countries{ci});
        if isnan(country_gdp(ci))
            fprintf(fid, '%s,%d,%s,%s,%.6f,,,%d\n', c, year, dataset, elasticity, pct(ci), exitflag);
        else
            fprintf(fid, '%s,%d,%s,%s,%.6f,%.2f,%.2f,%d\n', ...
                c, year, dataset, elasticity, pct(ci), dollar_change(ci), country_gdp(ci), exitflag);
        end
    end
end


function [dollar_change, country_gdp] = compute_dollar_values(pct, countries, yr, N, gdp_map)
    dollar_change = NaN(N, 1);
    country_gdp = NaN(N, 1);
    matched_gdp_sum = 0;
    row_idx = 0;
    for ci = 1:N
        c = normalize_country(countries{ci});
        if strcmp(c, 'ROW')
            row_idx = ci;
            continue;
        end
        key = sprintf('%s_%d', c, yr);
        if gdp_map.isKey(key)
            country_gdp(ci) = gdp_map(key);
            dollar_change(ci) = 0.01 * pct(ci) * country_gdp(ci);
            matched_gdp_sum = matched_gdp_sum + country_gdp(ci);
        end
    end

    if row_idx > 0
        wld_key = sprintf('WLD_%d', yr);
        if gdp_map.isKey(wld_key)
            country_gdp(row_idx) = gdp_map(wld_key) - matched_gdp_sum;
            dollar_change(row_idx) = 0.01 * pct(row_idx) * country_gdp(row_idx);
        end
    end
end


function total_cost = compute_total_cost(dollar_change)
    matched = dollar_change(~isnan(dollar_change));
    if isempty(matched)
        total_cost = NaN;
    else
        total_cost = sum(matched);
    end
end


function stats = extract_tariff_stats(X_sol, N, countries)
    levels = 100 * abs(X_sol(2 * N + 1:end));
    [max_value, max_idx] = max(levels);
    [min_value, min_idx] = min(levels);
    stats.avg = mean(levels);
    stats.median = median(levels);
    stats.min = min_value;
    stats.max = max_value;
    stats.min_country = normalize_country(countries{min_idx});
    stats.max_country = normalize_country(countries{max_idx});
end


function idx = find_country_index(countries, code)
    idx = [];
    for i = 1:numel(countries)
        if strcmp(normalize_country(countries{i}), code)
            idx = i;
            return;
        end
    end
end


function info = find_extreme_country(countries, values, mode)
    valid = find(~isnan(values));
    if isempty(valid)
        info.country = '';
        info.value = NaN;
        return;
    end

    switch lower(mode)
        case 'min'
            [value, local_idx] = min(values(valid));
        case 'max'
            [value, local_idx] = max(values(valid));
        otherwise
            error('tariffwar:pipeline:unknownExtremeMode', 'Unknown mode: %s', mode);
    end

    idx = valid(local_idx);
    info.country = normalize_country(countries{idx});
    info.value = value;
end


function print_run_report(dataset, year, elasticity, country_count, sector_count, tariff_stats, ...
    us_welfare, world_mean, world_median, total_cost, worst_outcome, best_outcome, ...
    exitflag, iterations, max_residual, map_file, detailed_reporting)

    cost_label = format_total_cost(total_cost);

    if detailed_reporting
        print_rule('=');
        fprintf('Run Complete\n\n');

        fprintf('Scenario\n');
        fprintf('  Nash tariff war equilibrium\n\n');

        fprintf('Context\n');
        fprintf('  Dataset: %s %d\n', upper(dataset), year);
        fprintf('  Elasticity: %s\n', elasticity);
        fprintf('  Countries: %d\n', country_count);
        fprintf('  Sectors: %d\n\n', sector_count);

        fprintf('Policy\n');
        fprintf('  Tariff regime: importer-specific uniform Nash tariffs\n');
        fprintf('  Average importer tariff: %.2f%%\n', tariff_stats.avg);
        fprintf('  Median importer tariff: %.2f%%\n', tariff_stats.median);
        fprintf('  Range across importers: %.2f%% to %.2f%%\n', tariff_stats.min, tariff_stats.max);
        fprintf('  Highest importer tariff: %s (%.2f%%)\n', tariff_stats.max_country, tariff_stats.max);
        fprintf('  Lowest importer tariff: %s (%.2f%%)\n\n', tariff_stats.min_country, tariff_stats.min);

        fprintf('Outcomes\n');
        if isnan(us_welfare)
            fprintf('  U.S. welfare change: not available\n');
        else
            fprintf('  U.S. welfare change: %.3f%%\n', us_welfare);
        end
        fprintf('  World average welfare change: %.3f%%\n', world_mean);
        fprintf('  Median country welfare change: %.3f%%\n', world_median);
        fprintf('  Worst country welfare outcome: %s (%.3f%%)\n', worst_outcome.country, worst_outcome.value);
        fprintf('  Best country welfare outcome: %s (%.3f%%)\n', best_outcome.country, best_outcome.value);
        fprintf('  Matched-GDP welfare change: %s\n\n', cost_label);

        fprintf('Solver\n');
        fprintf('  Exitflag: %d\n', exitflag);
        fprintf('  Iterations: %s\n', format_integer(iterations));
        if ~isnan(max_residual)
            fprintf('  Max residual: %.2e\n', max_residual);
        end
        if ~isempty(map_file)
            fprintf('\nFiles\n');
            fprintf('  Map: %s\n', map_file);
        end
        print_rule('=');
        return;
    end

    line = sprintf(['Completed Nash tariff war | %s %d | %s | avg tariff %.2f%% | ' ...
        'U.S. welfare %s | world avg %.3f%%'], ...
        upper(dataset), year, elasticity, tariff_stats.avg, ...
        format_percent(us_welfare), world_mean);
    if ~isnan(total_cost)
        line = sprintf('%s | matched GDP %s', line, cost_label);
    end
    if ~isempty(map_file)
        line = sprintf('%s | map saved', line);
    end
    fprintf('%s\n', line);
end


function print_pipeline_footer(output_file, run_count, map_count, skipped_data)
    print_rule('-');
    fprintf('Pipeline Complete\n\n');

    fprintf('Output\n');
    fprintf('  CSV: %s\n', output_file);
    fprintf('  Runs completed: %d\n', run_count);
    if map_count > 0
        fprintf('  Maps saved: %d\n', map_count);
    end
    if ~isempty(skipped_data)
        fprintf('  Skipped dataset-years: %d\n', numel(skipped_data));
    end

    print_rule('-');
end


function print_rule(ch)
    fprintf('\n%s\n', repmat(ch, 1, 72));
end


function label = format_total_cost(total_cost)
    if isnan(total_cost)
        label = 'not available';
        return;
    end

    abs_cost = abs(total_cost);
    if abs_cost >= 1e12
        label = sprintf('$%.2fT', total_cost / 1e12);
    else
        label = sprintf('$%.1fB', total_cost / 1e9);
    end
end


function label = format_percent(value)
    if isnan(value)
        label = 'n/a';
    else
        label = sprintf('%.3f%%', value);
    end
end


function label = format_integer(value)
    if isnan(value)
        label = 'n/a';
    else
        label = sprintf('%d', value);
    end
end


function country = normalize_country(value)
    country = value;
    if iscell(country)
        country = country{1};
    end
    country = char(string(country));
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
