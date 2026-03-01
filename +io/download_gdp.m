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

    out_dir = fullfile(data_root, 'Cleaned_Data_Files');
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
        data = webread(url);
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
    country_code = cell(n, 1);
    country_name = cell(n, 1);
    year_vec     = zeros(n, 1);
    gdp_val      = NaN(n, 1);

    for i = 1:n
        r = records{i};
        country_code{i} = r.country.id;
        country_name{i} = r.country.value;
        year_vec(i)     = str2double(r.date);
        if ~isempty(r.value)
            gdp_val(i) = r.value;
        end
    end

    % Save as CSV
    csv_path = fullfile(out_dir, 'WDI_GDP_constant2015USD.csv');
    fid = fopen(csv_path, 'w');
    fprintf(fid, 'CountryCode,CountryName,Year,GDP_constant2015USD\n');
    for i = 1:n
        if ~isnan(gdp_val(i))
            fprintf(fid, '%s,"%s",%d,%.2f\n', ...
                country_code{i}, country_name{i}, year_vec(i), gdp_val(i));
        end
    end
    fclose(fid);

    if verbose
        fprintf('[tariffwar.io] GDP data saved: %s\n', csv_path);
        fprintf('[tariffwar.io] Records: %d (non-null GDP values)\n', sum(~isnan(gdp_val)));
    end
end
