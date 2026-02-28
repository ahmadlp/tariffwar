function cfg = defaults()
%TARIFFWAR.DEFAULTS  Solver defaults and paths.
%
%   cfg = tariffwar.defaults()

    pkg_root      = fileparts(mfilename('fullpath'));
    cfg.mat_dir   = fullfile(pkg_root, 'mat');
    cfg.data_root = fullfile(pkg_root, 'raw_data');
    cfg.verbose   = true;

    cfg.solver.TolFun      = 1e-12;
    cfg.solver.TolX        = 1e-14;
    cfg.solver.MaxIter     = Inf;
    cfg.solver.MaxFunEvals = Inf;
    cfg.solver.algorithm   = 'trust-region-dogleg';
    cfg.solver.Display     = 'iter';
    cfg.solver.T0_scale.wi   = 0.9;
    cfg.solver.T0_scale.Yi   = 1.1;
    cfg.solver.T0_scale.tjik = 1.25;
end
