function rerun_failed(varargin)
%TARIFFWAR.RERUN_FAILED  Re-solve only the failed cases from results.csv.
%
%   tariffwar.rerun_failed()
%   tariffwar.rerun_failed('MaxIter', 200)
%   tariffwar.rerun_failed('datasets', {'wiod'})
%
%   Reads results/results.csv, identifies rows with Exitflag <= 0,
%   re-runs those (dataset, year, elasticity) triples with the new
%   convergence logic, and writes results to a temp CSV.
%
%   If re-run improves convergence, merges improved rows into the main
%   results.csv. Always cleans up temp files.
%
%   Name-value options (all run.m options plus):
%     'datasets' - restrict re-run to specific datasets (cell of strings)

    pkg_root = fileparts(mfilename('fullpath'));
    main_csv = fullfile(pkg_root, 'results', 'results.csv');
    temp_csv = fullfile(pkg_root, 'results', 'results_rerun_tmp.csv');

    % Parse optional dataset filter
    ds_filter = {};
    extra_args = {};
    i = 1;
    while i <= numel(varargin)
        if strcmp(varargin{i}, 'datasets')
            ds_filter = varargin{i+1};
            if ischar(ds_filter), ds_filter = {ds_filter}; end
            i = i + 2;
        else
            extra_args{end+1} = varargin{i}; %#ok<AGROW>
            extra_args{end+1} = varargin{i+1}; %#ok<AGROW>
            i = i + 2;
        end
    end

    % Cleanup guard: always delete temp CSV
    cleanup = onCleanup(@() delete_if_exists(temp_csv));

    % --- Read main CSV and identify failures ---
    if ~isfile(main_csv)
        error('No results file found: %s', main_csv);
    end
    T = readtable(main_csv, 'TextType', 'string');
    failed = T(T.Exitflag <= 0, :);

    if isempty(failed)
        fprintf('No failed cases found. All exitflags > 0.\n');
        return;
    end

    % Get unique (Dataset, Year, Elasticity) triples
    triples = unique(failed(:, {'Dataset', 'Year', 'Elasticity'}), 'rows');
    fprintf('Found %d failed triples (%d rows).\n', height(triples), height(failed));

    % Apply dataset filter
    if ~isempty(ds_filter)
        mask = ismember(triples.Dataset, ds_filter);
        triples = triples(mask, :);
        fprintf('Filtered to %d triples for datasets: %s\n', ...
            height(triples), strjoin(ds_filter, ', '));
    end

    if isempty(triples)
        fprintf('No triples to re-run after filtering.\n');
        return;
    end

    % --- Build reverse map: full elasticity name -> abbreviation ---
    reg = tariffwar.elasticity.registry();
    name_to_abbrev = containers.Map('KeyType', 'char', 'ValueType', 'char');
    for k = 1:numel(reg)
        name_to_abbrev(reg(k).name) = reg(k).abbrev;
    end

    % --- Group by dataset and collect years/elasticities ---
    ds_list = unique(triples.Dataset);
    for di = 1:numel(ds_list)
        ds = ds_list(di);
        ds_triples = triples(triples.Dataset == ds, :);

        ds_years = unique(ds_triples.Year)';
        ds_elas_names = unique(ds_triples.Elasticity);

        % Convert full names to abbreviations
        ds_abbrevs = cell(size(ds_elas_names));
        for k = 1:numel(ds_elas_names)
            nm = char(ds_elas_names(k));
            if name_to_abbrev.isKey(nm)
                ds_abbrevs{k} = name_to_abbrev(nm);
            else
                ds_abbrevs{k} = nm;
            end
        end

        fprintf('\n=== Re-running %s: %d years x %d elasticities ===\n', ...
            char(ds), numel(ds_years), numel(ds_abbrevs));
        fprintf('  Years: %s\n', num2str(ds_years));
        fprintf('  Elasticities: %s\n', strjoin(ds_abbrevs, ', '));

        % Run with temp output
        tariffwar.run(char(ds), ds_years, ds_abbrevs, ...
            'output_file', temp_csv, extra_args{:});

        % --- Compare and report ---
        if isfile(temp_csv)
            T_new = readtable(temp_csv, 'TextType', 'string');
            new_triples = unique(T_new(:, {'Dataset', 'Year', 'Elasticity', 'Exitflag'}), 'rows');

            n_improved = sum(new_triples.Exitflag > 0);
            n_still_failed = sum(new_triples.Exitflag <= 0);
            fprintf('\n--- Results for %s ---\n', char(ds));
            fprintf('  Improved (ef > 0): %d / %d triples\n', n_improved, height(new_triples));
            fprintf('  Still failed:      %d / %d triples\n', n_still_failed, height(new_triples));

            if n_still_failed > 0
                still_bad = new_triples(new_triples.Exitflag <= 0, :);
                for r = 1:height(still_bad)
                    fprintf('    FAILED: %s %d %s (ef=%d)\n', ...
                        still_bad.Dataset(r), still_bad.Year(r), ...
                        still_bad.Elasticity(r), still_bad.Exitflag(r));
                end
            end

            % Merge improved rows into main CSV
            if n_improved > 0
                merge_results(main_csv, T_new, T);
                fprintf('  Merged %d improved rows into %s\n', ...
                    sum(T_new.Exitflag > 0), main_csv);
            end
        end
    end

    fprintf('\nRerun complete.\n');
end


function merge_results(main_csv, T_new, T_old)
%MERGE_RESULTS  Replace failed rows in main CSV with improved re-run rows.

    % Only merge rows that actually improved
    improved_rows = T_new(T_new.Exitflag > 0, :);
    if isempty(improved_rows), return; end

    % Build composite key for matching
    old_keys = strcat(T_old.Country, '_', string(T_old.Year), '_', ...
        T_old.Dataset, '_', T_old.Elasticity);
    new_keys = strcat(improved_rows.Country, '_', string(improved_rows.Year), '_', ...
        improved_rows.Dataset, '_', improved_rows.Elasticity);

    % Replace matched rows
    [~, old_idx, new_idx] = intersect(old_keys, new_keys, 'stable');
    T_old.Percent_Change(old_idx) = improved_rows.Percent_Change(new_idx);
    T_old.Exitflag(old_idx) = improved_rows.Exitflag(new_idx);

    % Write back
    writetable(T_old, main_csv);
end


function delete_if_exists(f)
    if isfile(f)
        delete(f);
        fprintf('[cleanup] Deleted temp file: %s\n', f);
    end
end
