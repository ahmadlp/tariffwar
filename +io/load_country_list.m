function countries = load_country_list(cfg)
%TARIFFWAR.IO.LOAD_COUNTRY_LIST  Load country names for a dataset.
%
%   countries = tariffwar.io.load_country_list(cfg)
%
%   Returns an N x 1 cell array of country names/codes for the given dataset.
%
%   See also: tariffwar.io.load_dataset

    switch cfg.dataset
        case 'wiod'
            fpath = fullfile(cfg.data_root, 'Country_List.xlsx');
            if ~isfile(fpath)
                fpath = fullfile(cfg.data_root, 'Data_Preparation_Files', 'Country_List.xlsx');
            end
            if ~isfile(fpath)
                error('tariffwar:io:countryListNotFound', ...
                    'Country list not found. Expected: %s', fpath);
            end
            countries = readcell(fpath);
            % Ensure column vector of strings
            if size(countries, 2) > 1
                countries = countries(:, 1);
            end

        case 'icio'
            % For ICIO, extract country list from the first available CSV
            icio_dir = fullfile(cfg.data_root, 'Data_Preparation_Files', 'ICIO_Data');
            csv_files = dir(fullfile(icio_dir, 'ICIO2023_*.csv'));
            if isempty(csv_files)
                error('tariffwar:io:icioNotFound', ...
                    'No ICIO CSV found. Run tariffwar.io.download_icio() first.');
            end
            csv_path = fullfile(icio_dir, csv_files(1).name);
            raw = readtable(csv_path, 'ReadVariableNames', true, 'ReadRowNames', true);
            row_names = raw.Properties.RowNames;
            row_parts = cellfun(@(x) strsplit(x, '_'), row_names, 'UniformOutput', false);
            countries = unique(cellfun(@(x) x{1}, row_parts, 'UniformOutput', false), 'stable');

        case 'itpd'
            % For ITPD-S, extract country list from the CSV
            itpd_dir = fullfile(cfg.data_root, 'Data_Preparation_Files', 'ITPD_Data');
            csv_files = dir(fullfile(itpd_dir, '*.csv'));
            if isempty(csv_files)
                error('tariffwar:io:itpdNotFound', ...
                    'No ITPD-S CSV found. Run tariffwar.io.download_itpd() first.');
            end
            csv_path = fullfile(itpd_dir, csv_files(1).name);
            opts = detectImportOptions(csv_path);
            opts.SelectedVariableNames = opts.VariableNames(1:2); % exporter, importer
            T = readtable(csv_path, opts);
            all_codes = [T{:,1}; T{:,2}];
            if iscell(all_codes), all_codes = string(all_codes); end
            countries = cellstr(unique(all_codes, 'stable'));

        otherwise
            error('tariffwar:io:unknownDataset', ...
                'Unknown dataset: ''%s''.', cfg.dataset);
    end
end
