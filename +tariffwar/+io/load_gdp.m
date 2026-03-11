function gdp_map = load_gdp(data_root)
%TARIFFWAR.IO.LOAD_GDP  Load World Bank GDP data as a lookup map.
%
%   gdp_map = tariffwar.io.load_gdp()
%   gdp_map = tariffwar.io.load_gdp(data_root)
%
%   Returns a containers.Map keyed by 'ISO3_YYYY' (e.g. 'USA_2014')
%   with values = GDP in constant 2015 US$ (World Bank WDI). The loader
%   first checks raw_data/gdp/ and then falls back to the bundled
%   support/gdp/ copy used by the public quickstart.
%
%   Used by tariffwar.pipeline.run to convert percent welfare changes
%   to dollar values:  Dollar_Change = 0.01 * Percent_Change * GDP
%
%   See also: tariffwar.io.download_gdp, tariffwar.pipeline.run

    if nargin < 1 || isempty(data_root)
        data_root = fullfile(tariffwar.repo_root(), 'raw_data');
    end

    csv_path = fullfile(data_root, 'gdp', 'WDI_GDP_constant2015USD.csv');
    if ~isfile(csv_path)
        csv_path = fullfile(tariffwar.repo_root(), 'support', 'gdp', ...
            'WDI_GDP_constant2015USD.csv');
    end
    if ~isfile(csv_path)
        error('tariffwar:io:noGDP', ...
            'GDP CSV not found: %s\nRun tariffwar.io.download_gdp() first.', csv_path);
    end

    T = readtable(csv_path, 'TextType', 'string');

    % Use ISO3 column for keys (matches trade data country codes)
    iso3_col = T.CountryCode_ISO3;
    year_col = T.Year;
    gdp_col  = T.GDP_constant2015USD;

    % Build map: key = 'ISO3_YYYY', value = GDP
    gdp_map = containers.Map('KeyType', 'char', 'ValueType', 'double');
    for i = 1:height(T)
        iso3 = iso3_col(i);
        if ismissing(iso3) || iso3 == "", continue; end
        key = sprintf('%s_%d', char(iso3), year_col(i));
        gdp_map(key) = gdp_col(i);
    end
end
