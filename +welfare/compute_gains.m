function gains = compute_gains(X_sol, N, S, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D)
%TARIFFWAR.WELFARE.COMPUTE_GAINS  Compute welfare gains from Nash tariffs.
%
%   gains = tariffwar.welfare.compute_gains(X_sol, N, S, ...)
%
%   Returns an N x 1 vector of percent welfare changes for each country.
%   Delegates to the verbatim welfare_gains_baseline algorithm.
%
%   See also: tariffwar.welfare.welfare_gains_baseline

    gains = tariffwar.welfare.welfare_gains_baseline(...
        X_sol, N, S, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D);
end
