function [Z, F, R, N, S] = aggregate_sectors(Z, F, N_raw, S_raw, agg_matrix_path)
%TARIFFWAR.DATA.AGGREGATE_SECTORS  Aggregate sectors via Kronecker product.
%
%   [Z, F, R, N, S] = tariffwar.data.aggregate_sectors(Z, F, N_raw, S_raw, agg_matrix_path)
%
%   Applies sector aggregation using a binary aggregation matrix AggS.
%   Country aggregation uses identity (no aggregation).
%
%   The aggregation is: CC = kron(AggC, AggS)
%     Z_agg = CC * Z * CC'
%     F_agg = CC * F * FF'  where FF = kron(AggC, I_5) for 5 final demand categories
%
%   Inputs:
%     Z               - (N_raw*S_raw) x (N_raw*S_raw) intermediate flow matrix
%     F               - (N_raw*S_raw) x (N_raw*5) final demand matrix
%     N_raw           - raw number of countries
%     S_raw           - raw number of sectors
%     agg_matrix_path - path to CSV with S_agg x S_raw binary aggregation matrix
%
%   Outputs:
%     Z  - (N*S) x (N*S) aggregated intermediate flow matrix
%     F  - (N*S) x (N*5) aggregated final demand matrix
%     R  - (N*S) x 1 total output vector
%     N  - number of countries (unchanged)
%     S  - number of aggregated sectors
%
%   See also: tariffwar.data.prepare_wiod

    % Load aggregation matrix
    AggS = dlmread(agg_matrix_path);
    S = size(AggS, 1);
    N = N_raw;

    % Country aggregation = identity (no country aggregation)
    AggC = eye(N);

    % Build Kronecker aggregation matrices
    CC = kron(AggC, AggS);       % for intermediate flows
    FF = kron(AggC, eye(5));      % for final demand (5 categories)

    % Apply aggregation
    Z = CC * Z * CC';
    F = CC * F * FF';
    R = sum([Z, F], 2);
end
