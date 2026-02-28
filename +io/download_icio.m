function download_icio(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_ICIO  Download OECD ICIO 2023 tables.
%
%   tariffwar.io.download_icio()
%   tariffwar.io.download_icio(data_root)
%   tariffwar.io.download_icio(data_root, verbose)
%
%   Downloads OECD Inter-Country Input-Output tables (2023 edition).
%   Each ZIP contains CSV files for a 5-year period.
%
%   Coverage: 76 economies + ROW, 45 ISIC Rev 4 sectors, 1995–2020.
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

    % OECD ICIO 2023 edition download URLs (CSV ZIPs, grouped by 5-year periods)
    % Source: stats.oecd.org, extracted from pymrio library
    bundles = struct( ...
        'name',  {'1995-2000', '2001-2005', '2006-2010', '2011-2015', '2016-2020'}, ...
        'uuid',  {'d26ad811-5b58-4f0c-a4e3-06a1469e475c', ...
                  '7cb93dae-e491-4cfd-ac67-889eb7016a4a', ...
                  'ea165bfb-3a85-4e0a-afee-6ba8e6c16052', ...
                  '1f791bc6-befb-45c5-8b34-668d08a1702a', ...
                  'd1ab2315-298c-4e93-9a81-c6f2273139fe'});

    base_url = 'https://stats.oecd.org/wbos/fileview2.aspx?IDFile=';

    for i = 1:numel(bundles)
        url = [base_url, bundles(i).uuid];
        zip_name = sprintf('ICIO2023_%s.zip', bundles(i).name);
        zip_path = fullfile(out_dir, zip_name);

        if verbose
            fprintf('[tariffwar.io] Downloading ICIO %s...\n', bundles(i).name);
        end

        try
            websave(zip_path, url);
            unzip(zip_path, out_dir);
        catch ME
            warning('tariffwar:io:downloadFailed', ...
                'Failed to download ICIO %s: %s', bundles(i).name, ME.message);
        end
    end

    if verbose
        fprintf('[tariffwar.io] ICIO data downloaded to: %s\n', out_dir);
    end
end
