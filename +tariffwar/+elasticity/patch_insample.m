function patch_insample(varargin)
%TARIFFWAR.ELASTICITY.PATCH_INSAMPLE  Replace L21/IS_ICIO/IS_ITPD with unified IS sigma field.
%
%   tariffwar.elasticity.patch_insample()
%   tariffwar.elasticity.patch_insample('dataset', 'icio')
%   tariffwar.elasticity.patch_insample('verbose', true)
%
%   Loads each .mat file, removes old L21/IS_ICIO/IS_ITPD sigma fields,
%   adds a single IS field with dataset-appropriate in-sample elasticities
%   from insample.m, mapped to the target sector classification via
%   concordance chain, and re-saves. Does NOT rebuild trade or tariff cubes.
%
%   See also: tariffwar.elasticity.sources.insample, tariffwar.pipeline.build_all

    p = inputParser;
    addParameter(p, 'dataset', 'all', @ischar);
    addParameter(p, 'verbose', true, @islogical);
    parse(p, varargin{:});

    verbose = p.Results.verbose;
    ds_filter = p.Results.dataset;

    mat_dir = fullfile(tariffwar.repo_root(), 'mat');

    if ~isfolder(mat_dir)
        error('patch_insample:noMatDir', 'Mat directory not found: %s', mat_dir);
    end

    % Load the unified in-sample source
    raw = tariffwar.elasticity.sources.insample();

    % Old field names to remove
    old_fields = {'L21', 'IS_ICIO', 'IS_ITPD'};

    files = dir(fullfile(mat_dir, '*.mat'));
    n_patched = 0;

    for f = 1:numel(files)
        fpath = fullfile(mat_dir, files(f).name);
        loaded = load(fpath, 'data');
        data = loaded.data;
        ds = data.dataset;
        S  = data.S;

        % Filter by dataset if requested
        if ~strcmp(ds_filter, 'all') && ~strcmp(ds, ds_filter)
            continue;
        end

        % Remove old sigma fields
        for oi = 1:numel(old_fields)
            if isfield(data.sigma, old_fields{oi})
                data.sigma = rmfield(data.sigma, old_fields{oi});
            end
        end

        % Select dataset-appropriate WIOD-16 epsilon vector
        switch ds
            case 'wiod', epsilon_wiod = raw.epsilon_wiod;
            case 'icio', epsilon_wiod = raw.epsilon_icio;
            case 'itpd', epsilon_wiod = raw.epsilon_itpd;
            otherwise, continue;
        end

        % Map WIOD-16 to target dataset sectors
        switch ds
            case 'wiod', epsilon_S = epsilon_wiod;
            case 'icio', epsilon_S = tariffwar.concordance.wiod16_to_icio(S) * epsilon_wiod;
            case 'itpd', epsilon_S = tariffwar.concordance.wiod16_to_itpd(S) * epsilon_wiod;
        end

        % Fallback for uncovered sectors
        epsilon_S(epsilon_S == 0) = 4;

        s_field.epsilon_S = epsilon_S;
        s_field.sigma_S   = epsilon_S + 1;
        s_field.source    = 'in_sample';
        data.sigma.IS = s_field;

        save(fpath, 'data', '-v7.3');
        n_patched = n_patched + 1;
        if verbose
            fprintf('Patched %s (ds=%s, S=%d)\n', files(f).name, ds, S);
        end
    end

    if verbose
        fprintf('\nDone. Patched %d / %d .mat files.\n', n_patched, numel(files));
    end
end
