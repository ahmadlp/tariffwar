function download_all(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_ALL  Download all datasets.
%
%   tariffwar.io.download_all()
%   tariffwar.io.download_all(data_root)
%   tariffwar.io.download_all(data_root, verbose)
%
%   Downloads all trade data, tariff data, and GDP data needed for
%   the tariff war simulation package.
%
%   Datasets downloaded:
%     1. WIOD 2016 Release (Excel format, ~877 MB)
%     2. OECD ICIO 2023 (CSV ZIPs, ~5 downloads)
%     3. USITC ITPD-S R1.1 (year 2019 subset by default, ~84 MB)
%     4. Teti GTD (ISIC 2-digit tariffs)
%     5. World Bank WDI GDP (via API)
%
%   See also: tariffwar.io.download_wiod, tariffwar.io.download_icio,
%             tariffwar.io.download_itpd, tariffwar.io.download_tariffs,
%             tariffwar.io.download_gdp

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(tariffwar.repo_root(), 'raw_data');
    end
    if nargin < 2, verbose = true; end

    if verbose
        fprintf('\n========================================\n');
        fprintf(' tariffwar.io.download_all\n');
        fprintf('========================================\n');
        fprintf(' Data root: %s\n', data_root);
        fprintf('========================================\n\n');
    end

    steps = {'WIOD', 'ICIO', 'ITPD-S', 'Tariffs (Teti GTD)', 'GDP (WDI)'};

    % 1. WIOD
    if verbose, fprintf('[1/5] %s\n', steps{1}); end
    try
        tariffwar.io.download_wiod(data_root, verbose);
    catch ME
        warning('tariffwar:io:downloadFailed', 'WIOD download failed: %s', ME.message);
    end

    % 2. OECD ICIO
    if verbose, fprintf('\n[2/5] %s\n', steps{2}); end
    try
        tariffwar.io.download_icio(data_root, verbose);
    catch ME
        warning('tariffwar:io:downloadFailed', 'ICIO download failed: %s', ME.message);
    end

    % 3. USITC ITPD-S
    if verbose, fprintf('\n[3/5] %s\n', steps{3}); end
    try
        tariffwar.io.download_itpd(data_root, verbose, 'no_names');
    catch ME
        warning('tariffwar:io:downloadFailed', 'ITPD-S download failed: %s', ME.message);
    end

    % 4. Tariffs
    if verbose, fprintf('\n[4/5] %s\n', steps{4}); end
    try
        tariffwar.io.download_tariffs(data_root, verbose, 'teti_gtd');
    catch ME
        warning('tariffwar:io:downloadFailed', 'Tariff download failed: %s', ME.message);
    end

    % 5. GDP
    if verbose, fprintf('\n[5/5] %s\n', steps{5}); end
    try
        tariffwar.io.download_gdp(data_root, verbose);
    catch ME
        warning('tariffwar:io:downloadFailed', 'GDP download failed: %s', ME.message);
    end

    if verbose
        fprintf('\n========================================\n');
        fprintf(' Download complete.\n');
        fprintf('========================================\n');
    end
end
