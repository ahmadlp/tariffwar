function xwalk = country_crosswalk(source_dataset, target_dataset)
%TARIFFWAR.CONCORDANCE.COUNTRY_CROSSWALK  Map countries between datasets.
%
%   xwalk = tariffwar.concordance.country_crosswalk(source_dataset, target_dataset)
%
%   Returns a struct with:
%     .source_idx  - indices into source country list
%     .target_idx  - indices into target country list
%     .n_common    - number of overlapping countries
%
%   For same-dataset comparisons across years: identity mapping.
%   For cross-dataset comparisons: maps via ISO 3166 alpha-3 codes.
%
%   See also: tariffwar.io.load_country_list

    switch [source_dataset '_to_' target_dataset]

        case 'wiod_to_wiod'
            xwalk.source_idx = (1:44)';
            xwalk.target_idx = (1:44)';
            xwalk.n_common = 44;

        case {'wiod_to_icio', 'icio_to_wiod', 'wiod_to_itpd', 'itpd_to_wiod', ...
              'icio_to_icio', 'icio_to_itpd', 'itpd_to_icio', 'itpd_to_itpd'}
            % Cross-dataset country mapping — requires ISO code lookup
            % Will be populated when ICIO and ITPD-S country lists are loaded
            error('tariffwar:concordance:notImplemented', ...
                'Country crosswalk for %s → %s not yet implemented.', ...
                source_dataset, target_dataset);

        otherwise
            error('tariffwar:concordance:unknownPair', ...
                'Unknown dataset pair: %s → %s', source_dataset, target_dataset);
    end
end
