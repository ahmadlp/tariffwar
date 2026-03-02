function cfg = defaults()
%TARIFFWAR.DEFAULTS  Solver defaults and paths.
%
%   cfg = tariffwar.defaults()

    pkg_root      = fileparts(mfilename('fullpath'));
    cfg.mat_dir   = fullfile(pkg_root, 'mat');
    cfg.data_root = fullfile(pkg_root, 'raw_data');
    cfg.verbose   = true;

    % Nash equilibrium solver
    cfg.solver.TolFun      = 1e-6;
    cfg.solver.TolX        = 1e-8;
    cfg.solver.MaxIter     = 50;
    cfg.solver.MaxFunEvals = Inf;
    cfg.solver.algorithm   = 'levenberg-marquardt';
    cfg.solver.Display     = 'iter';
    cfg.solver.T0_scale.wi   = 0.9;
    cfg.solver.T0_scale.Yi   = 1.1;
    cfg.solver.T0_scale.tjik = 1.25;

    % Retry: random scalar initial guesses (no algorithm switching)
    cfg.solver.max_retries     = 3;
    cfg.solver.T0_range.wi     = [0.7, 1.3];
    cfg.solver.T0_range.Yi     = [0.7, 1.3];
    cfg.solver.T0_range.tjik   = [1.1, 1.5];

    % Stall detection
    cfg.solver.stall_window    = 3;
    cfg.solver.min_progress    = 0.10;

    % Balanced trade solver (separate from Nash)
    cfg.balance_trade.TolFun              = 1e-6;
    cfg.balance_trade.TolX                = 1e-8;
    cfg.balance_trade.MaxIter             = 50;
    cfg.balance_trade.MaxFunEvals         = Inf;
    cfg.balance_trade.algorithm           = 'trust-region-dogleg';
    cfg.balance_trade.algorithm_fallback  = 'levenberg-marquardt';
    cfg.balance_trade.Display             = 'iter';
    cfg.balance_trade.T0_range.wi         = [0.7, 1.3];
    cfg.balance_trade.T0_range.Yi         = [0.7, 1.3];

    % Stall detection (balanced trade)
    cfg.balance_trade.stall_window        = 3;
    cfg.balance_trade.min_progress        = 0.10;
end
