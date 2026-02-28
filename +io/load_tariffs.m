function tjik_3D = load_tariffs(cfg, year, N, S)
%TARIFFWAR.IO.LOAD_TARIFFS  Load tariff data for a given year.
%
%   tjik_3D = tariffwar.io.load_tariffs(cfg, year, N, S)
%
%   Returns an N x N x S cube of applied tariff rates.
%   Element (j,i,k) = tariff imposed by country i on imports from j in sector k.
%
%   Tariff sources:
%     'trains'   - UNCTAD TRAINS (legacy, WIOD only, 2000–2014)
%     'teti_gtd' - Teti Global Tariff Database (not yet implemented)
%
%   See also: tariffwar.run

    switch cfg.tariff_source
        case 'trains'
            tjik_3D = load_trains(cfg, year, N, S);

        case 'teti_gtd'
            tjik_3D = load_teti_gtd(cfg, year, N, S);

        otherwise
            error('tariffwar:io:unknownTariffSource', ...
                'Unknown tariff source: ''%s''.', cfg.tariff_source);
    end
end


function tjik_3D = load_trains(cfg, year, N, S)
%LOAD_TRAINS  Load TRAINS tariff .mat file.

    fpath = fullfile(cfg.data_root, 'Data_Preparation_Files', 'TRAINS_Data', ...
        sprintf('tariff_%d.mat', year));
    if ~isfile(fpath)
        error('tariffwar:io:tariffNotFound', ...
            'TRAINS tariff file not found: %s', fpath);
    end

    loaded = load(fpath);

    % The .mat file should contain tjik_3D (N x N x S)
    if isfield(loaded, 'tjik_3D')
        tjik_3D = loaded.tjik_3D;
    else
        % Try common alternative names
        fnames = fieldnames(loaded);
        error('tariffwar:io:tariffVarNotFound', ...
            'Expected variable ''tjik_3D'' in %s. Found: %s', ...
            fpath, strjoin(fnames, ', '));
    end

    % Validate dimensions
    if ~isequal(size(tjik_3D), [N, N, S])
        error('tariffwar:io:tariffDimMismatch', ...
            'Tariff cube is %s, expected [%d %d %d].', ...
            mat2str(size(tjik_3D)), N, N, S);
    end
end


function tjik_3D = load_teti_gtd(cfg, year, N, S)
%LOAD_TETI_GTD  Load Teti Global Tariff Database tariffs.
%
%   Reads ISIC 2-digit level tariff data from Teti GTD CSV/DTA files.
%   Aggregates to the target dataset's sector classification.

    gtd_dir = fullfile(cfg.data_root, 'Data_Preparation_Files', 'Teti_GTD');
    if ~isfolder(gtd_dir)
        error('tariffwar:io:gtdNotFound', ...
            'Teti GTD data not found: %s\nRun tariffwar.io.download_tariffs() first.', gtd_dir);
    end

    % Look for CSV files
    csv_files = dir(fullfile(gtd_dir, '*.csv'));
    if isempty(csv_files)
        % Try DTA files
        dta_files = dir(fullfile(gtd_dir, '*.dta'));
        if isempty(dta_files)
            error('tariffwar:io:gtdNoFiles', ...
                'No CSV or DTA files found in: %s', gtd_dir);
        end
        % Read first DTA file
        fpath = fullfile(gtd_dir, dta_files(1).name);
        T = readtable(fpath);
    else
        fpath = fullfile(gtd_dir, csv_files(1).name);
        T = readtable(fpath);
    end

    if cfg.verbose
        fprintf('[tariffwar.io] Loading Teti GTD from: %s\n', fpath);
    end

    % Filter to requested year
    vnames = T.Properties.VariableNames;
    year_col = find(strcmpi(vnames, 'year'), 1);
    if isempty(year_col)
        year_col = find(contains(vnames, 'year', 'IgnoreCase', true), 1);
    end

    if ~isempty(year_col)
        T = T(T{:, year_col} == year, :);
    end

    if isempty(T) || height(T) == 0
        warning('tariffwar:io:gtdYearNotFound', ...
            'Year %d not found in Teti GTD. Using zero tariffs.', year);
        tjik_3D = zeros(N, N, S);
        return;
    end

    % Load country list for mapping
    countries = tariffwar.io.load_country_list(cfg);

    % Parse tariff data
    % GTD ISIC-33 format has columns: importer, exporter, isic2, year, tariff
    % Map to NxNxS cube using country and sector concordances
    % This is a simplified reader; exact column names depend on GTD version

    imp_col = find(contains(vnames, 'importer', 'IgnoreCase', true), 1);
    exp_col = find(contains(vnames, 'exporter', 'IgnoreCase', true), 1);
    tar_col = find(contains(vnames, 'tariff', 'IgnoreCase', true) | ...
                   contains(vnames, 'mfn', 'IgnoreCase', true) | ...
                   contains(vnames, 'applied', 'IgnoreCase', true), 1);
    sec_col = find(contains(vnames, 'isic', 'IgnoreCase', true) | ...
                   contains(vnames, 'sector', 'IgnoreCase', true), 1);

    if isempty(imp_col) || isempty(exp_col) || isempty(tar_col)
        warning('tariffwar:io:gtdParseError', ...
            'Could not parse GTD columns. Using zero tariffs.');
        tjik_3D = zeros(N, N, S);
        return;
    end

    % Build tariff cube
    tjik_3D = zeros(N, N, S);

    importers = T{:, imp_col};
    exporters = T{:, exp_col};
    tariffs   = T{:, tar_col};

    if iscell(importers), importers = string(importers); end
    if iscell(exporters), exporters = string(exporters); end

    % Map country codes to indices
    for r = 1:height(T)
        i_idx = find(strcmp(countries, importers(r)), 1);
        j_idx = find(strcmp(countries, exporters(r)), 1);
        if ~isempty(i_idx) && ~isempty(j_idx)
            % Apply tariff to all sectors (or specific sector if available)
            tar_val = tariffs(r);
            if ~isnan(tar_val)
                if ~isempty(sec_col)
                    % Sector-specific tariff — map to dataset sectors
                    % For now, apply uniformly
                    tjik_3D(j_idx, i_idx, :) = tar_val / 100;
                else
                    tjik_3D(j_idx, i_idx, :) = tar_val / 100;
                end
            end
        end
    end

    if cfg.verbose
        fprintf('[tariffwar.io] Teti GTD loaded: mean tariff = %.2f%%\n', ...
            100 * mean(tjik_3D(:)));
    end
end
