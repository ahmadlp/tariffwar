function download_icio(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_ICIO  Download OECD ICIO Extended tables (2011-2022).
%
%   tariffwar.io.download_icio()
%   tariffwar.io.download_icio(data_root)
%   tariffwar.io.download_icio(data_root, verbose)
%
%   Downloads OECD Inter-Country Input-Output Extended tables (2023 edition).
%   Two ZIP bundles cover all needed years:
%     2011-2015 bundle: 5 CSVs in Extended format (S=28)
%     2016-2022 bundle: 7 CSVs in Extended format (S=28)
%
%   Only downloads bundles containing missing year files; skips bundles
%   whose years are already on disk. ZIPs are cleaned up after extraction.
%
%   Expected files: {year}.csv for years 2011-2022 (Extended format, S=28)
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end

    out_dir = fullfile(data_root, 'Data_Preparation_Files', 'ICIO_Data');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % OECD ICIO 2023 Extended edition download URLs
    % Source: https://www.oecd.org/en/data/datasets/inter-country-input-output-tables.html
    base_url = 'https://stats.oecd.org/wbos/fileview2.aspx?IDFile=';
    bundles = struct( ...
        'name',   {'2011-2015', '2016-2022'}, ...
        'uuid',   {'1a841dd1-a38e-4faa-9a86-95b41b0aac30', ...
                   'c95e1402-462c-4fc7-951f-a2df3fb1d8f3'}, ...
        'years',  {{2011:2015}, {2016:2022}});

    % Check which bundles have missing years
    bundles_needed = false(1, numel(bundles));
    for i = 1:numel(bundles)
        yrs = bundles(i).years{1};
        for y = yrs
            if ~isfile(fullfile(out_dir, sprintf('%d.csv', y)))
                bundles_needed(i) = true;
                if verbose
                    fprintf('[tariffwar.io] ICIO %d: CSV not found.\n', y);
                end
                break;
            end
        end
    end

    if ~any(bundles_needed)
        if verbose
            fprintf('[tariffwar.io] All ICIO Extended CSV files present (2011-2022). Skipping.\n');
        end
        return;
    end

    % Download bundles that contain missing years
    for i = 1:numel(bundles)
        if ~bundles_needed(i)
            continue;
        end

        url = [base_url, bundles(i).uuid];
        zip_name = sprintf('ICIO_Extended_%s.zip', bundles(i).name);
        zip_path = fullfile(out_dir, zip_name);

        if verbose
            fprintf('[tariffwar.io] Downloading ICIO Extended %s...\n', bundles(i).name);
        end

        try
            tariffwar.io.robust_download(url, zip_path, verbose);
            unzip(zip_path, out_dir);
            delete(zip_path);
        catch ME
            warning('tariffwar:io:downloadFailed', ...
                'Failed to download ICIO Extended %s: %s', bundles(i).name, ME.message);
        end
    end

    % Remove any leftover SML files where Extended now exists
    sml_files = dir(fullfile(out_dir, '*_SML.csv'));
    for i = 1:numel(sml_files)
        tokens = regexp(sml_files(i).name, '^(\d{4})_SML\.csv$', 'tokens');
        if ~isempty(tokens)
            ext_path = fullfile(out_dir, sprintf('%s.csv', tokens{1}{1}));
            if isfile(ext_path)
                delete(fullfile(out_dir, sml_files(i).name));
                if verbose
                    fprintf('[tariffwar.io] Removed %s (Extended %s.csv exists).\n', ...
                        sml_files(i).name, tokens{1}{1});
                end
            end
        end
    end

    if verbose
        fprintf('[tariffwar.io] ICIO Extended download complete: %s\n', out_dir);
    end
end
