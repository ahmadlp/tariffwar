function Xijs_new3D = balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg)
%TARIFFWAR.DATA.BALANCE_TRADE  Solve for trade-balanced flows (D=0).
%
%   Xijs_new3D = tariffwar.data.balance_trade(Xijs3D, sigma_k3D, tjik_3D, N, S, cfg)
%
%   Solves the DEK balanced trade exercise that removes trade deficits.
%   Uses fsolve with 2*N unknowns (wages + incomes) to find new equilibrium
%   flows under zero deficits.
%
%   This is a verbatim reproduction of Step_02_Baseline.m.
%
%   See also: tariffwar.solver.balanced_trade_baseline, tariffwar.data.prepare_wiod

    % Build derived cubes from Xijs3D
    Xjik_3D = Xijs3D;
    [lambda_jik3D, Yi3D, Ri3D, beta_ik3D] = ...
        tariffwar.data.compute_derived_cubes(Xjik_3D, tjik_3D, N, S);

    % Solve balanced trade
    X0 = [ones(N, 1); ones(N, 1)];
    bt_fn = @tariffwar.solver.balanced_trade_baseline;
    syst = @(X) bt_fn(X, N, S, Yi3D, Ri3D, beta_ik3D, sigma_k3D, lambda_jik3D, tjik_3D);

    display_opt = 'iter';
    tolfun_opt  = 1e-10;
    tolx_opt    = 1e-10;
    if nargin >= 6 && isstruct(cfg)
        if isfield(cfg, 'solver')
            if isfield(cfg.solver, 'Display'); display_opt = cfg.solver.Display; end
            if isfield(cfg.solver, 'TolFun');  tolfun_opt  = cfg.solver.TolFun; end
            if isfield(cfg.solver, 'TolX');    tolx_opt    = cfg.solver.TolX; end
        end
    end
    options = optimset('Display', display_opt, ...
        'MaxFunEvals', 50000000, 'MaxIter', 100000, ...
        'TolFun', tolfun_opt, 'TolX', tolx_opt);

    [x_fsolve, fval_fsolve] = fsolve(syst, X0, options);
    max_resid = max(abs(fval_fsolve));

    if cfg.verbose
        fprintf('[tariffwar.data] Balance trade max residual: %.2e\n', max_resid);
    end

    % Extract solution
    wi_h = abs(x_fsolve(1:N));
    Yi_h = abs(x_fsolve(N+1:2*N));

    % Construct 3D cubes from solution
    wi_h3D = repmat(wi_h, [1 N S]);
    Yi_h3D = repmat(Yi_h, [1 N S]);
    Yj_h3D = permute(Yi_h3D, [2 1 3]);
    Yj3D   = permute(Yi3D, [2 1 3]);

    % Compute new trade flows under balanced trade
    AUX0 = lambda_jik3D .* (wi_h3D .^ (1 - sigma_k3D));
    AUX1 = repmat(sum(AUX0, 1), [N 1 1]);
    AUX2 = AUX0 ./ max(AUX1, eps);
    Xijs_new3D = AUX2 .* beta_ik3D .* (Yj_h3D .* Yj3D);
end
