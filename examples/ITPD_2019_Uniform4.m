repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);

results = tariffwar.pipeline.run('itpd', 2019, 'U4', 'Display', 'off');

fprintf('CSV written to: %s\n', results.csv_file);
