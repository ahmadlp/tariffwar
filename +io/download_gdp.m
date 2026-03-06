function download_gdp(data_root, verbose)
%TARIFFWAR.IO.DOWNLOAD_GDP  Download World Bank WDI GDP data.
%
%   tariffwar.io.download_gdp()
%   tariffwar.io.download_gdp(data_root)
%   tariffwar.io.download_gdp(data_root, verbose)
%
%   Downloads GDP (constant 2015 US$) from the World Bank World Development
%   Indicators API. Indicator: NY.GDP.MKTP.KD
%
%   Coverage: 189+ countries, 1960–present.
%   No authentication required.
%
%   See also: tariffwar.io.download_all

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'raw_data');
    end
    if nargin < 2, verbose = true; end

    out_dir = fullfile(data_root, 'gdp');
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % Skip if GDP CSV already exists
    existing = dir(fullfile(out_dir, 'WDI_GDP*.csv'));
    if ~isempty(existing)
        if verbose
            fprintf('[tariffwar.io] WDI GDP CSV already present. Skipping.\n');
        end
        return;
    end

    % World Bank API — JSON format, all countries, 1995-2025
    url = 'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.KD?format=json&date=1995:2025&per_page=20000';

    if verbose
        fprintf('[tariffwar.io] Downloading GDP data from World Bank WDI...\n');
        fprintf('[tariffwar.io] Indicator: NY.GDP.MKTP.KD (GDP, constant 2015 US$)\n');
    end

    try
        opts = weboptions('Timeout', 60);
        data = webread(url, opts);
    catch ME
        error('tariffwar:io:downloadFailed', ...
            'Failed to download WDI GDP data: %s\nURL: %s', ME.message, url);
    end

    % Parse JSON response
    % The WB API returns {metadata, data_array}
    if iscell(data) && numel(data) >= 2
        records = data{2};
    else
        error('tariffwar:io:parseError', 'Unexpected WDI API response format.');
    end

    % Convert to table and save as CSV
    n = numel(records);
    country_code  = cell(n, 1);
    country_iso3  = cell(n, 1);
    country_name  = cell(n, 1);
    year_vec      = zeros(n, 1);
    gdp_val       = NaN(n, 1);

    for i = 1:n
        r = records(i);  % parenthesis indexing for struct array
        country_code{i} = r.country.id;
        country_name{i} = r.country.value;
        % ISO 3166-1 alpha-3 code (matches trade data country codes)
        if isfield(r, 'countryiso3code') && ~isempty(r.countryiso3code)
            country_iso3{i} = r.countryiso3code;
        else
            country_iso3{i} = '';
        end
        year_vec(i)     = str2double(r.date);
        if ~isempty(r.value)
            gdp_val(i) = r.value;
        end
    end

    % --- Add Taiwan (excluded from WB API /country/all endpoint) ---
    % Source: Penn World Table 11.0 via FRED (RGDPNATWA666NRUG).
    % Real GDP at constant national prices, millions of 2021 US$.
    % Converted to approximate constant 2015 US$ by multiplying by
    % (Taiwan nominal GDP 2015 in USD) / (PWT rgdpna 2015).
    % Taiwan 2015 nominal GDP: NTD 17,055,080M / 31.898 TWD/USD = $534,742M.
    twn_pwt_years = 1995:2023;
    twn_pwt_vals = [  % PWT 11.0 rgdpna (millions 2021 USD)
        490710.53; 521754.91; 554024.94; 574655.81; 613309.81; ...  % 1995-1999
        645823.31; 636771.94; 671675.81; 700051.69; 748716.69; ...  % 2000-2004
        789023.19; 834554.50; 891726.19; 898852.06; 884353.94; ...  % 2005-2009
        974959.94; 1010780.38; 1033235.00; 1058896.50; 1108868.38; ... % 2010-2014
        1125121.75; 1149481.75; 1187545.38; 1220639.63; 1258039.25; ... % 2015-2019
        1300644.50; 1386752.88; 1422647.75; 1440848.50 ...          % 2020-2023
    ];
    twn_scale = 534742e6 / (1125121.75e6);  % scale PWT 2021$ -> approx 2015$
    n_twn = 0;
    for ti = 1:numel(twn_pwt_years)
        yr_twn = twn_pwt_years(ti);
        n = n + 1;
        country_code{n}  = 'TW';
        country_iso3{n}  = 'TWN';
        country_name{n}  = 'Taiwan';
        year_vec(n)      = yr_twn;
        gdp_val(n)       = twn_pwt_vals(ti) * 1e6 * twn_scale;  % convert to USD
        n_twn = n_twn + 1;
    end
    if verbose
        fprintf('[tariffwar.io] Added %d Taiwan (TWN) GDP records (PWT 11.0 source).\n', n_twn);
    end

    % Save as CSV
    csv_path = fullfile(out_dir, 'WDI_GDP_constant2015USD.csv');
    fid = fopen(csv_path, 'w');
    fprintf(fid, 'CountryCode,CountryCode_ISO3,CountryName,Year,GDP_constant2015USD\n');
    for i = 1:n
        if ~isnan(gdp_val(i))
            fprintf(fid, '%s,%s,"%s",%d,%.2f\n', ...
                country_code{i}, country_iso3{i}, country_name{i}, year_vec(i), gdp_val(i));
        end
    end
    fclose(fid);

    if verbose
        fprintf('[tariffwar.io] GDP data saved: %s\n', csv_path);
        fprintf('[tariffwar.io] Records: %d (non-null GDP values)\n', sum(~isnan(gdp_val)));
    end
end
