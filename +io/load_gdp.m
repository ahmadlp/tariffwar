function gdp = load_gdp(cfg, year)
%TARIFFWAR.IO.LOAD_GDP  Load real GDP data for a given year.
%
%   gdp = tariffwar.io.load_gdp(cfg, year)
%
%   Returns an N x 1 vector of real GDP values for the specified year.
%
%   For WIOD with legacy data: reads from REAL_GDP_DATA.xlsx
%   For other datasets or years: uses World Bank WDI (not yet implemented).
%
%   See also: tariffwar.run

    switch cfg.dataset
        case 'wiod'
            gdp = load_wiod_gdp(cfg, year);

        case {'icio', 'itpd'}
            error('tariffwar:io:notImplemented', ...
                'GDP loading for dataset ''%s'' not yet implemented.', cfg.dataset);

        otherwise
            error('tariffwar:io:unknownDataset', ...
                'Unknown dataset: ''%s''.', cfg.dataset);
    end
end


function gdp = load_wiod_gdp(cfg, year)
%LOAD_WIOD_GDP  Load GDP from the legacy REAL_GDP_DATA.xlsx for WIOD.

    fpath = fullfile(cfg.data_root, 'Cleaned_Data_Files', 'REAL_GDP_DATA.xlsx');
    if ~isfile(fpath)
        error('tariffwar:io:gdpNotFound', 'GDP file not found: %s', fpath);
    end

    % The XLSX has 44 rows per year, years 2000–2014 stacked vertically.
    % Column 4 contains real GDP values.
    raw = xlsread(fpath);
    N = 44;

    year_idx = year - 2000 + 1;  % 1-based index: 2000→1, 2014→15
    if year_idx < 1 || year_idx > 15
        error('tariffwar:io:yearOutOfRange', ...
            'WIOD GDP data only available for 2000–2014. Requested: %d', year);
    end

    row_start = (year_idx - 1) * N + 1;
    row_end   = year_idx * N;
    gdp = raw(row_start:row_end, 4);
end
