function robust_download(url, file_path, verbose)
%TARIFFWAR.IO.ROBUST_DOWNLOAD  Download a file with CDN anti-bot handling.
%
%   tariffwar.io.robust_download(url, file_path)
%   tariffwar.io.robust_download(url, file_path, verbose)
%
%   Tries multiple download strategies in order:
%     1. MATLAB websave (simplest, works for most servers)
%     2. curl with cookie handshake (handles Akamai/CDN anti-bot)
%
%   The cookie handshake visits the parent directory first to obtain a
%   session cookie, then uses that cookie for the actual download. This
%   bypasses CDN bot-detection that blocks direct programmatic access.
%
%   See also: tariffwar.io.download_all

    if nargin < 3, verbose = true; end

    % --- Strategy 1: MATLAB websave ---
    try
        websave(file_path, url);
        if isfile(file_path) && ~is_html(file_path)
            return;
        end
        % Got HTML instead of real file — delete and try next strategy
        if isfile(file_path), delete(file_path); end
    catch
        % websave failed (403, timeout, etc.) — try next strategy
        if isfile(file_path), delete(file_path); end
    end

    % --- Strategy 2: curl with cookie handshake ---
    if verbose
        fprintf('[tariffwar.io] websave blocked, trying curl with cookie handshake...\n');
    end

    % Derive parent URL for cookie acquisition
    parts = split(url, '/');
    parent_url = strjoin(parts(1:end-1), '/');

    cookie_jar = [tempname, '.txt'];
    cleanup = onCleanup(@() delete_if_exists(cookie_jar));

    % Visit parent page to get session cookie
    [~, ~] = system(sprintf('curl -s -c "%s" -o /dev/null --max-time 15 "%s"', ...
        cookie_jar, parent_url));

    % Download with cookie
    [status, ~] = system(sprintf( ...
        'curl -s -L -b "%s" -o "%s" --max-time 600 "%s"', ...
        cookie_jar, file_path, url));

    if status == 0 && isfile(file_path) && ~is_html(file_path)
        return;
    end

    % Clean up failed download
    if isfile(file_path), delete(file_path); end

    error('tariffwar:io:downloadFailed', ...
        'All download strategies failed for:\n  %s\nPlease download manually and place at:\n  %s', ...
        url, file_path);
end


function tf = is_html(file_path)
%IS_HTML  Check if a file starts with HTML markup.
    fid = fopen(file_path, 'r');
    if fid == -1
        tf = false;
        return;
    end
    header = fread(fid, 20, '*char')';
    fclose(fid);
    tf = contains(header, '<!DOCTYPE', 'IgnoreCase', true) || ...
         contains(header, '<html', 'IgnoreCase', true);
end


function delete_if_exists(f)
    if isfile(f), delete(f); end
end
