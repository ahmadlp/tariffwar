function download_tariffs(data_root, verbose, source)
%TARIFFWAR.IO.DOWNLOAD_TARIFFS  Download tariff data.
%
%   tariffwar.io.download_tariffs()
%   tariffwar.io.download_tariffs(data_root, verbose, source)
%
%   Sources:
%     'teti_gtd' - Teti Global Tariff Database (default)
%
%   Teti GTD data is hosted on Dropbox in .7z format. Dropbox blocks all
%   programmatic downloads, so the function opens your browser, waits for
%   you to click "Download", and then auto-extracts the archive.
%
%   Prerequisites: Python 3 with py7zr (pip install py7zr)
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

    out_dir = fullfile(data_root, 'tariffs');
    if ~isfolder(out_dir), mkdir(out_dir); end

    archive_name = 'isic33_vbeta1-2024-12.7z';
    file_path    = fullfile(out_dir, archive_name);
    if ispc
        downloads_dir = fullfile(getenv('USERPROFILE'), 'Downloads');
    else
        downloads_dir = fullfile(getenv('HOME'), 'Downloads');
    end
    downloads_path = fullfile(downloads_dir, archive_name);

    % --- Already done? ---
    if ~isempty(dir(fullfile(out_dir, 'tariff_isic33*.csv')))
        if verbose
            fprintf('[tariffwar.io] Teti GTD CSV already present. Skipping.\n');
        end
        return;
    end

    % --- Archive already in target dir or ~/Downloads? ---
    if ~is_7z(file_path) && is_7z(downloads_path)
        if verbose
            fprintf('[tariffwar.io] Found %s in ~/Downloads, moving...\n', archive_name);
        end
        movefile(downloads_path, file_path);
    end

    if is_7z(file_path)
        extract_and_cleanup(file_path, out_dir, verbose);
        return;
    end

    % --- Clean up any stale HTML files ---
    if isfile(file_path), delete(file_path); end

    % --- Pre-flight: py7zr ---
    py = find_python();
    [status, ~] = system(sprintf('%s -c "import py7zr"', py));
    if status ~= 0
        error('tariffwar:io:missingPy7zr', ...
            'py7zr required: pip install py7zr');
    end

    % --- Open browser for manual download ---
    browse_url = ['https://www.dropbox.com/scl/fi/jjknrptwj814vf3d3lqw6/' ...
                  'isic33_vbeta1-2024-12.7z' ...
                  '?rlkey=4dvoeic1w6f7dg2y9y4cpjlnt0k1rxky&dl=0'];

    fprintf('[tariffwar.io] Opening Dropbox page — click "Download" in your browser.\n');
    web(browse_url, '-browser');

    % --- Poll for the .7z to appear ---
    max_wait = 300;          % 5 minutes
    poll_sec = 2;
    waited   = 0;

    while waited < max_wait
        if is_7z(file_path), break; end
        if is_7z(downloads_path)
            movefile(downloads_path, file_path);
            break;
        end
        pause(poll_sec);
        waited = waited + poll_sec;
        if verbose && mod(waited, 30) == 0
            fprintf('[tariffwar.io] Waiting for download... (%d/%d sec)\n', waited, max_wait);
        end
    end

    if ~is_7z(file_path)
        if isfile(file_path), delete(file_path); end
        error('tariffwar:io:downloadTimeout', ...
            ['Timed out after %d s. If still downloading, move the .7z to:\n' ...
             '  %s\nThen re-run.'], max_wait, out_dir);
    end

    extract_and_cleanup(file_path, out_dir, verbose);
end


function tf = is_7z(p)
    tf = false;
    if ~isfile(p), return; end
    fid = fopen(p, 'r');
    if fid == -1, return; end
    m = fread(fid, 2, 'uint8')';
    fclose(fid);
    tf = numel(m) == 2 && m(1) == 55 && m(2) == 122;   % 0x37 0x7A
end


function py = find_python()
    [s, ~] = system('python3 --version');
    if s == 0, py = 'python3'; return; end
    [s, ~] = system('python --version');
    if s == 0, py = 'python'; return; end
    error('tariffwar:io:noPython', 'Python 3 not found. Install from python.org');
end


function extract_and_cleanup(file_path, out_dir, verbose)
    if verbose
        fprintf('[tariffwar.io] Extracting .7z via py7zr...\n');
    end
    py = find_python();
    cmd = sprintf( ...
        '%s -c "import py7zr; py7zr.SevenZipFile(''%s'',''r'').extractall(''%s'')"', ...
        py, strrep(file_path, '''', '\'''''), strrep(out_dir, '''', '\'''''));
    [status, result] = system(cmd);
    if status ~= 0
        error('tariffwar:io:extractFailed', ...
            'Extraction failed: %s\nInstall: pip install py7zr', result);
    end
    delete(file_path);
    if verbose
        fprintf('[tariffwar.io] Teti GTD extracted to: %s\n', out_dir);
    end
end
