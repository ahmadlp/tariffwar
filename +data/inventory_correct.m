function [Z, F, R] = inventory_correct(DATA, N, S)
%TARIFFWAR.DATA.INVENTORY_CORRECT  Apply Leontief INV=0 correction.
%
%   [Z, F, R] = tariffwar.data.inventory_correct(DATA, N, S)
%
%   Reads raw WIOD matrix and applies the inventory correction:
%   Set INV=0 and recompute output X = inv(I-A) * F_positive.
%
%   The correction converts negative inventories into expanded output,
%   as if we extend the time period to include prior-period production
%   of the reduced inventories.
%
%   Inputs:
%     DATA  - raw WIOD matrix (at least 2464 x 2684 for N=44, S=56)
%     N     - number of countries (44 for raw WIOD)
%     S     - number of sectors (56 for raw WIOD)
%
%   Outputs:
%     Z  - (N*S) x (N*S) corrected intermediate input flow matrix
%     F  - (N*S) x (N*5) corrected final demand matrix
%     R  - (N*S) x 1 corrected total output vector
%
%   See also: tariffwar.data.build_cubes_wiod

    NS = N * S;

    % Extract intermediate inputs and full flow matrix
    Zinit = DATA(1:NS, 1:NS);
    X = DATA(1:NS, 1:NS+N*5);
    Rinit = sum(X, 2);

    % Extract final demand (includes negative inventories)
    FIN = X(1:NS, NS+1:end);

    % Keep only positive final demand (set INV=0)
    F = FIN .* (FIN > 0);
    Fsum = sum(F, 2);

    % Compute input coefficients matrix A = Z * diag(1/R)
    % Add small epsilon to avoid division by zero for inactive sectors
    eps_val = 0.000001;
    A = Zinit / diag(Rinit + eps_val * (Rinit <= eps_val));

    % Leontief inverse: new output = (I - A)^{-1} * F
    R = (eye(NS) - A) \ Fsum;

    % Recompute intermediate flows with new output
    Z = A * diag(R);
end
