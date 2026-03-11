repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(repo_root);

results = tariffwar.pipeline.run('wiod', 2014, 'IS', 'Display', 'off');

fprintf('CSV written to: %s\n', results.csv_file);
