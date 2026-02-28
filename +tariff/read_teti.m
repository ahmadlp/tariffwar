function T = read_teti(year, varargin)
%TARIFFWAR.TARIFF.READ_TETI  Read Teti GTD tariff data for a single year.
%
%   T = tariffwar.tariff.read_teti(2014)
%   T = tariffwar.tariff.read_teti(2014, 'data_root', './data')
%
%   Pre-filters the 2.7 GB CSV with awk (year column = 3), then reads
%   the filtered result into MATLAB. Returns a table with columns:
%     iso1, iso2, sector, tariff
%
%   Inputs:
%     year      - scalar year (1988–2021)
%     data_root - (optional) path to data/ directory
%
%   See also: tariffwar.tariff.build_tariffs

    p = inputParser;
    addRequired(p, 'year', @isnumeric);
    addParameter(p, 'data_root', '', @ischar);
    addParameter(p, 'verbose', true, @islogical);
    parse(p, year, varargin{:});

    % --- Find the raw CSV ---
    pkg_root = fileparts(fileparts(mfilename('fullpath')));  % +tariffwar/
    if isempty(p.Results.data_root)
        search_dirs = {fullfile(pkg_root, 'raw_data', 'Data_Preparation_Files', 'Teti_GTD'), ...
                       fullfile(pkg_root, 'raw_data')};
    else
        search_dirs = {fullfile(p.Results.data_root, 'tariff data'), ...
                       p.Results.data_root};
    end

    csv_path = '';
    for d = 1:numel(search_dirs)
        candidates = dir(fullfile(search_dirs{d}, 'tariff_isic33*.csv'));
        if ~isempty(candidates)
            csv_path = fullfile(search_dirs{d}, candidates(1).name);
            break;
        end
    end
    if isempty(csv_path)
        error('tariffwar:tariff:csvNotFound', ...
            'Teti GTD CSV not found.\nSearched: %s', strjoin(search_dirs, '\n  '));
    end

    % --- Pre-filter with awk (year is column 3) ---
    tmp_file = fullfile(tempdir, sprintf('teti_%d.csv', year));

    if p.Results.verbose
        fprintf('[read_teti] Source: %s\n', csv_path);
        fprintf('[read_teti] Pre-filtering year %d with awk...\n', year);
    end

    awk_cmd = sprintf('awk -F'','' ''NR==1 || $3==%d'' "%s" > "%s"', ...
        year, csv_path, tmp_file);
    [status, cmdout] = system(awk_cmd);
    if status ~= 0
        error('tariffwar:tariff:awkFailed', 'awk pre-filter failed: %s', cmdout);
    end

    % --- Read filtered CSV ---
    if p.Results.verbose
        f_info = dir(tmp_file);
        fprintf('[read_teti] Filtered file: %.1f MB, reading...\n', f_info.bytes / 1e6);
    end

    opts = delimitedTextImportOptions('NumVariables', 12);
    opts.VariableNames = {'iso1', 'iso2', 'year', 'sector', ...
        'tariff', 'mfn', 'tariff_w', 'mfn_w', ...
        'tariff95', 'mfn95', 'tariff95_w', 'mfn95_w'};
    opts.VariableTypes = {'char', 'char', 'double', 'double', ...
        'double', 'double', 'double', 'double', ...
        'double', 'double', 'double', 'double'};
    opts.DataLines = [2, Inf];
    opts.Delimiter = ',';

    T_raw = readtable(tmp_file, opts);

    % Keep only the columns we need
    T = T_raw(:, {'iso1', 'iso2', 'sector', 'tariff'});

    % Drop rows with missing tariff
    valid = ~isnan(T.tariff);
    T = T(valid, :);

    if p.Results.verbose
        fprintf('[read_teti] Year %d: %d rows with valid tariffs\n', year, height(T));
    end

    % Clean up temp file
    delete(tmp_file);
end
