function [X_sol, exitflag, output] = nash_equilibrium(N, S, Yi3D, Ri3D, e_ik3D, ...
    sigma_k3D, lambda_jik3D, tjik_3D, cfg)
%TARIFFWAR.SOLVER.NASH_EQUILIBRIUM  Solve for Nash equilibrium tariffs.
%
%   [X_sol, exitflag, output] = tariffwar.solver.nash_equilibrium(N, S, ...)
%
%   Solves the baseline Nash tariff war equilibrium.
%   The system has 3*N unknowns:
%     - N wage multipliers (wi_h)
%     - N income multipliers (Yi_h)
%     - N uniform tariff levels (tjik)
%
%   Convergence strategy:
%     Attempt 1: fsolve with default T0 from cfg.solver.T0_scale
%     Attempts 2..max_retries+1: fsolve with random scalar initial guesses
%       wi_h  in [T0_range.wi(1),  T0_range.wi(2)]  * ones(N,1)
%       Yi_h  in [T0_range.Yi(1),  T0_range.Yi(2)]  * ones(N,1)
%       tjik  in [T0_range.tjik(1),T0_range.tjik(2)] * ones(N,1)
%     Stall monitor kills early if ||F|| stops decreasing.
%     Best solution (by exitflag, then residual) is returned.
%
%   See also: tariffwar.solver.trade_war_baseline, tariffwar.solver.stall_monitor

    % Build initial guess
    T0 = [cfg.solver.T0_scale.wi   * ones(N, 1); ...
          cfg.solver.T0_scale.Yi   * ones(N, 1); ...
          cfg.solver.T0_scale.tjik * ones(N, 1)];

    % Cache function handle
    solver_fn = @tariffwar.solver.trade_war_baseline;
    target = @(X) solver_fn(X, N, S, Yi3D, Ri3D, e_ik3D, ...
        sigma_k3D, lambda_jik3D, tjik_3D);

    % Stall monitor
    [monitor_fcn, monitor_reset] = tariffwar.solver.stall_monitor( ...
        cfg.solver.stall_window, cfg.solver.min_progress);

    % Initial-guess ranges for retries
    rng_wi   = cfg.solver.T0_range.wi;
    rng_Yi   = cfg.solver.T0_range.Yi;
    rng_tjik = cfg.solver.T0_range.tjik;

    % Track best across all attempts
    max_attempts = 1 + cfg.solver.max_retries;
    X_sol    = T0;
    exitflag = -99;
    output   = struct('iterations', 0, 'max_residual', Inf);

    for attempt = 1:max_attempts
        monitor_reset();

        if attempt == 1
            T0_cur = T0;
            lbl = 'default T0';
        else
            % Random scalar initial guess (same value for all N countries)
            a = rng_wi(1)   + diff(rng_wi)   * rand;
            b = rng_Yi(1)   + diff(rng_Yi)   * rand;
            c = rng_tjik(1) + diff(rng_tjik) * rand;
            T0_cur = [a * ones(N,1); b * ones(N,1); c * ones(N,1)];
            lbl = sprintf('random T0 [%.2f, %.2f, %.2f]', a, b, c);
        end

        if attempt > 1 && cfg.verbose
            fprintf('[nash] Attempt %d/%d: %s\n', attempt, max_attempts, lbl);
        end

        % Last attempt: no stall monitor — let it run to MaxIter
        if attempt < max_attempts
            opts = tariffwar.solver.solver_options(cfg, monitor_fcn);
        else
            opts = tariffwar.solver.solver_options(cfg);
        end
        [X_try, fval, ef, out] = fsolve(target, T0_cur, opts);
        out.max_residual = max(abs(fval));

        if ef > exitflag || (ef == exitflag && out.max_residual < output.max_residual)
            X_sol    = X_try;
            exitflag = ef;
            output   = out;
        end

        if ef > 0, break; end
    end

    if exitflag <= 0 && cfg.verbose
        warning('tariffwar:solver:noConvergence', ...
            'fsolve did not converge (exitflag = %d, max_resid = %.2e).', ...
            exitflag, output.max_residual);
    end
end
