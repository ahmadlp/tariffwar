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
%
%   Teti GTD data is hosted on Dropbox in .7z format.
%   Requires 7z command-line tool for extraction (brew install p7zip).
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end
    if nargin < 3, source = 'teti_gtd'; end

    switch source
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

    % Skip if CSV already exists
    existing = dir(fullfile(out_dir, 'tariff_isic33*.csv'));
    if ~isempty(existing)
        if verbose
            fprintf('[tariffwar.io] Teti GTD CSV already present. Skipping.\n');
        end
        return;
    end

    % Pre-flight check for 7z
    [status, ~] = system('7z --help');
    if status ~= 0
        error('tariffwar:io:missing7z', ...
            ['7-Zip is required to extract Teti GTD archives.\n' ...
             'Install with: brew install p7zip']);
    end

    % Teti GTD Dropbox URLs (beta v1, December 2024)
    url = 'https://www.dropbox.com/scl/fi/jjknrptwj814vf3d3lqw6/isic33_vbeta1-2024-12.7z?dl=1';

    file_path = fullfile(out_dir, 'isic33_vbeta1-2024-12.7z');

    if verbose
        fprintf('[tariffwar.io] Downloading Teti GTD (ISIC 2-digit tariffs)...\n');
        fprintf('[tariffwar.io] Source: feodorateti.github.io\n');
    end

    try
        websave(file_path, url);
    catch ME
        error('tariffwar:io:downloadFailed', ...
            'Failed to download Teti GTD: %s\nManual download: https://feodorateti.github.io/data.html', ...
            ME.message);
    end

    % Extract .7z
    if verbose
        fprintf('[tariffwar.io] Extracting .7z archive...\n');
    end

    [status, ~] = system(sprintf('7z x "%s" -o"%s" -y', file_path, out_dir));
    if status ~= 0
        error('tariffwar:io:extractionFailed', ...
            'Could not extract .7z file. Ensure 7-Zip is installed:\n  brew install p7zip');
    end

    % Clean up archive
    delete(file_path);

    if verbose
        fprintf('[tariffwar.io] Teti GTD data downloaded to: %s\n', out_dir);
    end
end
