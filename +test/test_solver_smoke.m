function test_solver_smoke()
%TARIFFWAR.TEST.TEST_SOLVER_SMOKE  Smoke test: run solver on WIOD 2014.

    fprintf('\n    Running full solver on WIOD 2014...\n');

    cfg = tariffwar.defaults();
    cfg.verbose = false;

    % Load prebuilt data
    d = tariffwar.io.load_data('wiod', 2014);
    N = d.N;  S = d.S;

    % Sigma cube from prebuilt data
    sigma_S   = d.sigma.L21.sigma_S;
    sigma_k3D = repmat(reshape(sigma_S, 1, 1, S), [N, N, 1]);

    % Balance trade
    Xjik_3D = tariffwar.data.balance_trade(...
        d.Xjik_3D, sigma_k3D, d.tjik_3D, N, S, cfg);

    % Derived cubes -> Nash solve -> welfare
    [lam, Yi3D, Ri3D, e_ik3D] = tariffwar.data.compute_derived_cubes(Xjik_3D, d.tjik_3D, N, S);
    [X_sol, exitflag, out] = tariffwar.solver.nash_equilibrium(N, S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lam, d.tjik_3D, cfg);
    gains = tariffwar.welfare.compute_gains(X_sol, N, S, e_ik3D, sigma_k3D, lam, d.tjik_3D);

    fprintf('    Solver exitflag: %d, iterations: %d\n', exitflag, out.iterations);
    assert(exitflag > 0, 'Solver should converge');
    assert(numel(gains) == N, 'Should have N welfare values');
    assert(all(gains < 0), 'All welfare changes should be negative (trade war hurts everyone)');

    fprintf('    Mean welfare change: %.2f%%\n', mean(gains));
    fprintf('    Range: [%.2f%%, %.2f%%]\n', min(gains), max(gains));

    fprintf('    ');
end
