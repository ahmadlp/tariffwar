function download_wiod(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_WIOD  Download WIOD 2016 Release data.
%
%   tariffwar.io.download_wiod()
%   tariffwar.io.download_wiod(data_root)
%   tariffwar.io.download_wiod(data_root, verbose)
%
%   Downloads World Input-Output Tables (WIOTs) from the WIOD 2016 Release.
%   Source: University of Groningen, hosted on DataverseNL.
%
%   The Excel ZIP contains individual year files (2000–2014) in XLSB format.
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

    % DataverseNL direct download URLs (DOI: 10.34894/PJ2M1C)
    % Excel format (XLSB) — most accessible for Matlab
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

    % Convert XLSB to CSV if needed
    if verbose
        fprintf('[tariffwar.io] WIOD data downloaded to: %s\n', out_dir);
        fprintf('[tariffwar.io] Note: Files are in XLSB format. Use readtable() to read.\n');
        fprintf('[tariffwar.io] If CSV files already exist in WIOD_Data/, they take precedence.\n');
    end
end
