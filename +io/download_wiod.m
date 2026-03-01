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
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end

    out_dir = fullfile(data_root, 'Data_Preparation_Files', 'WIOD_Data');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % Skip if CSV files already exist
    existing_csv = dir(fullfile(out_dir, 'WIOT*.csv'));
    if numel(existing_csv) >= 15
        if verbose
            fprintf('[tariffwar.io] WIOD CSV files already present (%d files). Skipping.\n', ...
                numel(existing_csv));
        end
        return;
    end

    % DataverseNL direct download URLs (DOI: 10.34894/PJ2M1C)
    url = 'https://dataverse.nl/api/access/datafile/199104';
    zip_path = fullfile(out_dir, 'WIOD2016_XLSB.zip');

    if verbose
        fprintf('[tariffwar.io] Downloading WIOD 2016 Release (Excel format)...\n');
        fprintf('[tariffwar.io] URL: %s\n', url);
        fprintf('[tariffwar.io] Destination: %s\n', zip_path);
        fprintf('[tariffwar.io] This may take several minutes (~877 MB)...\n');
    end

    try
        websave(zip_path, url);
    catch ME
        error('tariffwar:io:downloadFailed', ...
            'Failed to download WIOD data: %s\nURL: %s\nManual download: https://www.rug.nl/ggdc/valuechain/wiod/wiod-2016-release', ...
            ME.message, url);
    end

    % Extract ZIP
    if verbose
        fprintf('[tariffwar.io] Extracting ZIP...\n');
    end
    unzip(zip_path, out_dir);

    % Convert each XLSB to pure numeric CSV
    xlsb_files = dir(fullfile(out_dir, 'WIOT*.xlsb'));
    if verbose
        fprintf('[tariffwar.io] Converting %d XLSB files to CSV...\n', numel(xlsb_files));
    end

    for i = 1:numel(xlsb_files)
        xlsb_path = fullfile(out_dir, xlsb_files(i).name);
        [~, name, ~] = fileparts(xlsb_files(i).name);
        csv_path = fullfile(out_dir, [name '.csv']);

        if verbose
            fprintf('[tariffwar.io]   %s -> %s\n', xlsb_files(i).name, [name '.csv']);
        end

        data = readmatrix(xlsb_path, 'Range', 'E7');
        writematrix(data, csv_path);
        delete(xlsb_path);
    end

    % Clean up ZIP
    delete(zip_path);

    if verbose
        fprintf('[tariffwar.io] WIOD data downloaded and converted to CSV: %s\n', out_dir);
    end
end
