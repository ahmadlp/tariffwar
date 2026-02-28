function cubes = compute_cubes(Z, F, R, N, S)
%TARIFFWAR.DATA.COMPUTE_CUBES  Build N x N x S data cubes from aggregated matrices.
%
%   cubes = tariffwar.data.compute_cubes(Z, F, R, N, S)
%
%   Computes all required 3D cubes from the aggregated flow data.
%   Verbatim reproduction of Step_01_Baseline.m cube computations.
%
%   Outputs struct with fields:
%     .Xijs3D    - N x N x S trade flow cube
%     .Lijs3D    - N x N x S trade share (lambda) cube
%     .Yi3D      - N x N x S GDP cube
%     .Ri3D      - N x N x S total output cube
%     .betajs3D  - N x N x S expenditure share cube
%
%   See also: tariffwar.data.prepare_wiod

    X = [Z, F];

    ls = ones(S, 1);
    l5 = ones(5, 1);

    % Build summation matrices
    AUX1 = kron(eye(N), ls);    % sum over sectors: ijsk -> ijs
    AUX2 = kron(eye(N), l5);    % sum over final demand categories
    AUX  = [AUX1; AUX2];

    % Trade flow cube: Xijs3D(i,j,s) = flow of good s from i to j
    cubes.Xijs3D = permute(reshape(X * AUX, S, N, N), [2 3 1]);

    % Total purchases by j in sector s
    Xjs3D = repmat(sum(cubes.Xijs3D, 1), [N 1 1]);

    % Total expenditures of country j
    Xj3D = repmat(sum(Xjs3D, 3), [1 1 S]);

    % Trade shares: lambda_ijs = Xijs / Xjs
    cubes.Lijs3D = cubes.Xijs3D ./ Xjs3D;

    % Output by sector
    Ris3D = permute(repmat(reshape(R, S, N), [1 1 N]), [2 3 1]);

    % Total output
    cubes.Ri3D = repmat(sum(Ris3D, 3), [1 1 S]);

    % Value added = output - intermediate inputs
    VAis = (R') - sum(Z, 1);
    VAis = (VAis > 0) .* VAis;  % remove small negative values
    Yis3D = permute(repmat(reshape(VAis, S, N), [1 1 N]), [2 3 1]);
    cubes.Yi3D = repmat(sum(Yis3D, 3), [1 1 S]);

    % Final consumption shares (betas)
    Fijs3D = permute(reshape(F * kron(eye(N), l5), S, N, N), [2 3 1]);
    Fjs3D = repmat(sum(Fijs3D, 1), [N 1 1]);
    Fj3D = repmat(sum(Fjs3D, 3), [1 1 S]);
    cubes.consjs3D = Fjs3D ./ Fj3D;

    % Expenditure shares (used in Step_02 as beta_ik3D)
    cubes.betajs3D = Xjs3D ./ Xj3D;
end
