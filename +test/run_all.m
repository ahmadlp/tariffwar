function results = run_all()
%TARIFFWAR.TEST.RUN_ALL  Run all package tests.
%
%   results = tariffwar.test.run_all()
%
%   Runs all test functions and reports pass/fail for each.
%   Returns a struct with test names and outcomes.

    tests = { ...
        'test_config', ...
        'test_elasticity', ...
        'test_concordance', ...
        'test_data_loading', ...
        'test_cubes', ...
        'test_solver_smoke'};

    fprintf('\n========================================\n');
    fprintf(' tariffwar test suite\n');
    fprintf('========================================\n\n');

    n_pass = 0;
    n_fail = 0;
    n_skip = 0;

    results = struct('name', {}, 'status', {}, 'message', {});

    for i = 1:numel(tests)
        tname = tests{i};
        fprintf('  [%d/%d] %s ... ', i, numel(tests), tname);

        try
            fh = str2func(['tariffwar.test.' tname]);
            fh();
            fprintf('PASS\n');
            n_pass = n_pass + 1;
            results(end+1).name = tname;
            results(end).status = 'pass';
            results(end).message = '';
        catch ME
            if contains(ME.message, 'notImplemented') || contains(ME.message, 'not yet implemented')
                fprintf('SKIP (%s)\n', ME.message);
                n_skip = n_skip + 1;
                results(end+1).name = tname;
                results(end).status = 'skip';
                results(end).message = ME.message;
            else
                fprintf('FAIL\n');
                fprintf('    %s\n', ME.message);
                n_fail = n_fail + 1;
                results(end+1).name = tname;
                results(end).status = 'fail';
                results(end).message = ME.message;
            end
        end
    end

    fprintf('\n========================================\n');
    fprintf(' Results: %d passed, %d failed, %d skipped\n', n_pass, n_fail, n_skip);
    fprintf('========================================\n\n');
end
