function [X_sol, exitflag, output] = nash_equilibrium(N, S, Yi3D, Ri3D, e_ik3D, ...
    sigma_k3D, lambda_jik3D, tjik_3D, cfg)
%TARIFFWAR.SOLVER.NASH_EQUILIBRIUM  Solve for Nash equilibrium tariffs.
%
%   [X_sol, exitflag, output] = tariffwar.solver.nash_equilibrium(N, S, ...)
%
%   Solves the baseline Nash tariff war equilibrium using fsolve.
%   The system has 3*N unknowns:
%     - N wage multipliers (wi_h)
%     - N income multipliers (Yi_h)
%     - N uniform tariff levels (tjik)
%
%   See also: tariffwar.solver.trade_war_baseline

    % Build initial guess
    T0 = [cfg.solver.T0_scale.wi   * ones(N, 1); ...
          cfg.solver.T0_scale.Yi   * ones(N, 1); ...
          cfg.solver.T0_scale.tjik * ones(N, 1)];

    % Build solver options
    opts = tariffwar.solver.solver_options(cfg);

    % Cache function handle to avoid package-resolution overhead per evaluation
    solver_fn = @tariffwar.solver.trade_war_baseline;

    % Pass raw equations to fsolve (no rescaling).
    % The original replication code (Main_Table1.m) passes raw equations.
    % ERR1(N) is a normalization equation whose magnitude scales with
    % sum(Ri), not Ri_N — rescaling by Ri_N creates a massive mismatch
    % when country N is small, stalling convergence for large N.
    target = @(X) solver_fn(X, N, S, Yi3D, Ri3D, e_ik3D, ...
        sigma_k3D, lambda_jik3D, tjik_3D);

    % Solve
    [X_sol, fval, exitflag, output] = fsolve(target, T0, opts);
    output.max_residual = max(abs(fval));

    if exitflag <= 0 && cfg.verbose
        warning('tariffwar:solver:noConvergence', ...
            'fsolve did not converge (exitflag = %d).', exitflag);
    end
end
