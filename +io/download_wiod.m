function download_wiod(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_WIOD  Download WIOD 2016 Release data.
%
%   tariffwar.io.download_wiod()
%   tariffwar.io.download_wiod(data_root)
%   tariffwar.io.download_wiod(data_root, verbose)
%
%   Downloads World Input-Output Tables (WIOTs) from the WIOD 2016 Release,
%   then converts each XLSB file to a pure numeric CSV (data starts at E7).
%   Source: University of Groningen, hosted on DataverseNL.
%
%   Conversion uses Python with pandas + pyxlsb, which works on all
%   platforms (macOS, Linux, Windows). MATLAB's readmatrix for XLSB
%   requires Excel for Windows and is not portable.
%
%   Prerequisites: Python 3 with pandas and pyxlsb packages.
%     pip install pandas pyxlsb
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end

    out_dir = fullfile(data_root, 'wiod');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % Check which year files are missing (WIOD covers 2000-2014)
    wiod_years = 2000:2014;
    missing_years = [];
    for y = wiod_years
        if ~isfile(fullfile(out_dir, sprintf('WIOT%d.csv', y)))
            missing_years(end+1) = y; %#ok<AGROW>
        end
    end
    if isempty(missing_years)
        if verbose
            fprintf('[tariffwar.io] All %d WIOD CSV files present. Skipping.\n', numel(wiod_years));
        end
        return;
    end
    if verbose
        fprintf('[tariffwar.io] Missing WIOD years: %s\n', mat2str(missing_years));
    end

    % DataverseNL direct download URLs (DOI: 10.34894/PJ2M1C)
    url = 'https://dataverse.nl/api/access/datafile/199104';
    zip_path = fullfile(out_dir, 'WIOD2016_XLSB.zip');

    % Download ZIP if needed
    if ~isfile(zip_path)
        if verbose
            fprintf('[tariffwar.io] Downloading WIOD 2016 Release (Excel format)...\n');
            fprintf('[tariffwar.io] URL: %s\n', url);
            fprintf('[tariffwar.io] Destination: %s\n', zip_path);
            fprintf('[tariffwar.io] This may take several minutes (~877 MB)...\n');
        end

        try
            tariffwar.io.robust_download(url, zip_path, verbose);
        catch ME
            error('tariffwar:io:downloadFailed', ...
                'Failed to download WIOD data: %s\nURL: %s\nManual download: https://www.rug.nl/ggdc/valuechain/wiod/wiod-2016-release', ...
                ME.message, url);
        end
    else
        if verbose
            fprintf('[tariffwar.io] ZIP already present: %s\n', zip_path);
        end
    end

    % Extract ZIP (only extract xlsb files not already present)
    xlsb_files = dir(fullfile(out_dir, 'WIOT*.xlsb'));
    if numel(xlsb_files) < 15
        if verbose
            fprintf('[tariffwar.io] Extracting ZIP...\n');
        end
        unzip(zip_path, out_dir);
    end

    % Convert each XLSB to pure numeric CSV via Python
    xlsb_files = dir(fullfile(out_dir, 'WIOT*.xlsb'));
    if verbose
        fprintf('[tariffwar.io] Converting %d XLSB files to CSV via Python...\n', numel(xlsb_files));
    end

    for i = 1:numel(xlsb_files)
        xlsb_path = fullfile(out_dir, xlsb_files(i).name);

        % Extract year from filename (e.g. WIOT2000_Nov16_ROW.xlsb -> 2000)
        tokens = regexp(xlsb_files(i).name, 'WIOT(\d{4})', 'tokens');
        if isempty(tokens)
            if verbose
                fprintf('[tariffwar.io]   Skipping unrecognized file: %s\n', xlsb_files(i).name);
            end
            continue;
        end
        yr = tokens{1}{1};
        csv_name = sprintf('WIOT%s.csv', yr);
        csv_path = fullfile(out_dir, csv_name);

        % Skip if CSV already exists
        if isfile(csv_path)
            if verbose
                fprintf('[tariffwar.io]   %s already exists, skipping.\n', csv_name);
            end
            delete(xlsb_path);
            continue;
        end

        if verbose
            fprintf('[tariffwar.io]   %s -> %s\n', xlsb_files(i).name, csv_name);
        end

        % Use Python with pandas + pyxlsb for portable xlsb reading
        % Data starts at row 7 (skip 6 header rows), column E (drop first 4 columns)
        py = find_python();
        py_cmd = sprintf([ ...
            '%s -c "' ...
            'import pandas as pd; ' ...
            'df = pd.read_excel(''%s'', engine=''pyxlsb'', header=None, skiprows=6); ' ...
            'df.iloc[:, 4:].to_csv(''%s'', index=False, header=False)' ...
            '"'], py, strrep(xlsb_path, '''', '\'''), strrep(csv_path, '''', '\'''));

        [status, result] = system(py_cmd);
        if status ~= 0
            error('tariffwar:io:xlsbConversionFailed', ...
                ['Failed to convert %s to CSV.\n' ...
                 'Python output: %s\n' ...
                 'Ensure Python 3 with pandas and pyxlsb is installed:\n' ...
                 '  pip install pandas pyxlsb'], ...
                xlsb_files(i).name, result);
        end

        delete(xlsb_path);
    end

    % Clean up ZIP
    if isfile(zip_path)
        delete(zip_path);
    end

    if verbose
        fprintf('[tariffwar.io] WIOD data downloaded and converted to CSV: %s\n', out_dir);
    end
end


function py = find_python()
    [s, ~] = system('python3 --version');
    if s == 0, py = 'python3'; return; end
    [s, ~] = system('python --version');
    if s == 0, py = 'python'; return; end
    error('tariffwar:io:noPython', 'Python 3 not found. Install from python.org');
end
