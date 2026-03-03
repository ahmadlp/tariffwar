function data = load_data(dataset, year, varargin)
%TARIFFWAR.IO.LOAD_DATA  Load a pre-built analysis file.
%
%   data = tariffwar.io.load_data('wiod', 2014)
%   data = tariffwar.io.load_data('icio', 2020, 'mat_dir', './mat')
%
%   Loads WIOD2014.mat, ICIO2020.mat, ITPD2005.mat, etc. produced by
%   tariffwar.pipeline.build_all.
%
%   Returns a struct with:
%     .Xjik_3D         N x N x S unbalanced trade flows
%     .tjik_3D          N x N x S applied tariff rates (decimal)
%     .sigma            struct with one field per elasticity source
%     .N, .S            scalars
%     .services_sector  scalar (= S)
%     .countries        N x 1 cell
%     .sectors          S x 1 cell
%     .dataset          string
%     .year             scalar
%
%   Each sigma field (e.g. data.sigma.IS) contains:
%     .epsilon_S        S x 1 trade elasticity vector
%     .sigma_S          S x 1 CES parameter (= epsilon + 1)
%     .source           string (full source name)
%
%   See also: tariffwar.pipeline.build_all

    p = inputParser;
    addRequired(p, 'dataset', @ischar);
    addRequired(p, 'year', @isnumeric);
    addParameter(p, 'mat_dir', ...
        fullfile(fileparts(fileparts(mfilename('fullpath'))), 'mat'), @ischar);
    parse(p, dataset, year, varargin{:});

    fname = fullfile(p.Results.mat_dir, ...
        sprintf('%s%d.mat', upper(dataset), year));

    if ~isfile(fname)
        error('tariffwar:io:dataNotFound', ...
            'Data file not found: %s\nRun tariffwar.pipeline.build_all() first.', fname);
    end

    loaded = load(fname, 'data');
    data = loaded.data;
end
