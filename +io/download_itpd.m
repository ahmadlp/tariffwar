function download_itpd(data_root, verbose, variant)
%TARIFFWAR.IO.DOWNLOAD_ITPD  Download USITC ITPD-S database.
%
%   tariffwar.io.download_itpd()
%   tariffwar.io.download_itpd(data_root, verbose, variant)
%
%   Downloads the International Trade and Production Database for Estimation
%   (Structural) from USITC. This is ITPD-S (not ITPD-E) which includes
%   domestic trade flows needed for trade share computation.
%
%   Variants:
%     'full'     - Full dataset (1.4 GB compressed, 29.3 GB uncompressed)
%     'no_names' - Codes only, no country/sector names (1.0 GB compressed)
%     '2017_19'  - Years 2017-2019 only (182 MB compressed)
%     '2019'     - Year 2019 only (84 MB compressed) [DEFAULT]
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end
    if nargin < 3, variant = '2019'; end

    out_dir = fullfile(data_root, 'Data_Preparation_Files', 'ITPD_Data');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % Skip if ITPD CSV already exists
    existing = dir(fullfile(out_dir, 'ITPD*.csv'));
    if ~isempty(existing)
        if verbose
            fprintf('[tariffwar.io] ITPD-S CSV already present. Skipping.\n');
        end
        return;
    end

    % USITC download URLs for ITPD-S Release 1.1
    switch variant
        case 'full'
            url = 'https://www.usitc.gov/data/gravity/itpd_s/itpd_s_r1.1.zip';
            desc = 'full dataset (WARNING: 29.3 GB uncompressed)';
        case 'no_names'
            url = 'https://www.usitc.gov/data/gravity/itpd_s/itpd_s_r1.1_no_names.zip';
            desc = 'codes only (14 GB uncompressed)';
        case '2017_19'
            url = 'https://www.usitc.gov/data/gravity/itpd_s/itpd_s_r1.1_2017_19.zip';
            desc = 'years 2017-2019 (3 GB uncompressed)';
        case '2019'
            url = 'https://www.usitc.gov/data/gravity/itpd_s/itpd_s_r1.1_2019.zip';
            desc = 'year 2019 only (989 MB uncompressed)';
        otherwise
            error('tariffwar:io:unknownVariant', ...
                'Unknown ITPD-S variant: ''%s''. Use ''full'', ''no_names'', ''2017_19'', or ''2019''.', variant);
    end

    zip_path = fullfile(out_dir, sprintf('itpd_s_r1.1_%s.zip', variant));

    if verbose
        fprintf('[tariffwar.io] Downloading ITPD-S R1.1 (%s)...\n', desc);
        fprintf('[tariffwar.io] URL: %s\n', url);
    end

    try
        websave(zip_path, url);
    catch ME
        error('tariffwar:io:downloadFailed', ...
            'Failed to download ITPD-S: %s\nURL: %s\nManual download: https://www.usitc.gov/data/gravity/itpds', ...
            ME.message, url);
    end

    if verbose
        fprintf('[tariffwar.io] Extracting...\n');
    end
    unzip(zip_path, out_dir);

    if verbose
        fprintf('[tariffwar.io] ITPD-S data downloaded to: %s\n', out_dir);
    end
end
