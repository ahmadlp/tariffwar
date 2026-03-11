repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);

results = tariffwar.pipeline.run('icio', 2022, 'IS', ...
    'Display', 'off', ...
    'save_map', true);

fprintf('CSV written to: %s\n', results.csv_file);
fprintf('Map written to: %s\n', results.map_file);
