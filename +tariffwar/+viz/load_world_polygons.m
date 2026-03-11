function data = load_world_polygons()
%TARIFFWAR.VIZ.LOAD_WORLD_POLYGONS  Load projected world polygons for map export.
%
%   data = tariffwar.viz.load_world_polygons()

    persistent cached_data

    if isempty(cached_data)
        asset_file = fullfile(tariffwar.repo_root(), '+tariffwar', '+viz', ...
            'assets', 'world_polygons.json');
        if ~isfile(asset_file)
            error('tariffwar:viz:missingAsset', ...
                'World polygon asset not found: %s', asset_file);
        end
        cached_data = jsondecode(fileread(asset_file));
    end

    data = cached_data;
end
