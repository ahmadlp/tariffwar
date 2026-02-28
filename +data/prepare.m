function data = prepare(cfg, year)
%TARIFFWAR.DATA.PREPARE  Unified data preparation dispatcher.
%
%   data = tariffwar.data.prepare(cfg, year)
%
%   Dispatches to the appropriate dataset-specific preparation function.
%
%   See also: tariffwar.data.prepare_wiod

    switch cfg.dataset
        case 'wiod'
            data = tariffwar.data.prepare_wiod(cfg, year);

        case 'icio'
            data = tariffwar.data.prepare_icio(cfg, year);

        case 'itpd'
            data = tariffwar.data.prepare_itpd(cfg, year);

        otherwise
            error('tariffwar:data:unknownDataset', ...
                'Unknown dataset: ''%s''.', cfg.dataset);
    end
end
