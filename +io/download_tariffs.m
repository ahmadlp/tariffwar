function download_tariffs(data_root, verbose, source)
%TARIFFWAR.IO.DOWNLOAD_TARIFFS  Download tariff data.
%
%   tariffwar.io.download_tariffs()
%   tariffwar.io.download_tariffs(data_root, verbose, source)
%
%   Downloads tariff data from the specified source.
%
%   Sources:
%     'teti_gtd' - Teti Global Tariff Database (default)
%                  Available at ISIC 2-digit, HS sections, Ag/Non-Ag levels.
%     'trains'   - UNCTAD TRAINS (legacy, already in replication files)
%
%   Teti GTD data is hosted on Dropbox in .7z format.
%   Requires 7z command-line tool for extraction.
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end
    if nargin < 3, source = 'teti_gtd'; end

    switch source
        case 'trains'
            if verbose
                fprintf('[tariffwar.io] TRAINS tariffs are already in replication files.\n');
                fprintf('[tariffwar.io] Location: %s\n', ...
                    fullfile(data_root, 'Data_Preparation_Files', 'TRAINS_Data'));
            end
            return;

        case 'teti_gtd'
            download_teti_gtd(data_root, verbose);

        otherwise
            error('tariffwar:io:unknownTariffSource', ...
                'Unknown tariff source: ''%s''.', source);
    end
end


function download_teti_gtd(data_root, verbose)
%DOWNLOAD_TETI_GTD  Download Teti Global Tariff Database.

    out_dir = fullfile(data_root, 'Data_Preparation_Files', 'Teti_GTD');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % Teti GTD Dropbox URLs (beta v1, December 2024)
    % ISIC 2-digit level is most useful for sector-level analysis
    urls = struct( ...
        'name', {'isic33', 'hs_sections', 'pairs'}, ...
        'desc', {'ISIC 2-digit tariffs', 'HS section tariffs', 'Bilateral pair tariffs'}, ...
        'url',  {'https://www.dropbox.com/scl/fi/jjknrptwj814vf3d3lqw6/isic33_vbeta1-2024-12.7z?dl=1', ...
                 'https://www.dropbox.com/scl/fi/7dg2y9y4cpjlnt0n1rxky/section_88_21_vbeta1-2024-12.7z?dl=1', ...
                 'https://www.dropbox.com/scl/fi/wnsgnkkqz2ifb2vqiuyce/Pairs_vbeta1-2024-12.7z?dl=1'});

    % Download ISIC 2-digit by default (most useful)
    url_info = urls(1);  % isic33

    file_path = fullfile(out_dir, 'isic33_vbeta1-2024-12.7z');

    if verbose
        fprintf('[tariffwar.io] Downloading Teti GTD (%s)...\n', url_info.desc);
        fprintf('[tariffwar.io] Source: feodorateti.github.io\n');
    end

    try
        websave(file_path, url_info.url);
    catch ME
        error('tariffwar:io:downloadFailed', ...
            'Failed to download Teti GTD: %s\nManual download: https://feodorateti.github.io/data.html', ...
            ME.message);
    end

    % Extract .7z (requires 7z command-line tool)
    if verbose
        fprintf('[tariffwar.io] Extracting .7z archive...\n');
    end

    [status, ~] = system(sprintf('7z x "%s" -o"%s" -y', file_path, out_dir));
    if status ~= 0
        warning('tariffwar:io:extractionFailed', ...
            'Could not extract .7z file. Please install 7-Zip and run:\n  7z x "%s" -o"%s"', ...
            file_path, out_dir);
    end

    if verbose
        fprintf('[tariffwar.io] Teti GTD data downloaded to: %s\n', out_dir);
    end
end
