function [ceq] = nash_equations(X, N ,S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_app)
%TARIFFWAR.SOLVER.NASH_EQUATIONS  System of equations for the Nash tariff war equilibrium.
%
%   Defines the nonlinear system F(X)=0 whose root gives the Nash equilibrium.
%   Implements Equations 6, 7, and 14 from Lashkaripour (2021, AER).
%
%   The system has 3N unknowns packed into vector X:
%     X(1:N)       - wi_h:  wage changes (hat algebra)
%     X(N+1:2N)    - Yi_h:  income changes (hat algebra)
%     X(2N+1:3N)   - tjik:  optimal uniform tariff levels
%
%   Returns ceq (1 x 3N): equation residuals [ERR1, ERR2, ERR3].
%
% ------------------------------------------------------------------
%        Description of Inputs
% ------------------------------------------------------------------
%   N: number of countries;  S: number of industries
%   Yi3D: national expenditure ~ national income (N x N x S, replicated)
%   Ri3D: national wage revenues ~ sales net of tariffs (N x N x S, replicated)
%   e_ik3D: industry-level expenditure share (Cobb-Douglas weight)
%   lambda_jik3D: within-industry trade share (j's share of k's spending in sector s)
%   sigma_k3D: industry-level CES parameter (sigma-1 = trade elasticity)
%   tjik_3D_app: applied (factual) tariff rates (N x N x S)
% ------------------------------------------------------------------
%
%   See also: tariffwar.solver.nash_equilibrium, tariffwar.solver.solver_options

% Extract unknowns from solution vector X
% abs(.) prevents complex numbers during fsolve line search
wi_h=abs(X(1:N));       % N x 1 wage changes
Yi_h=abs(X(N+1:N+N));   % N x 1 income changes

% Construct 3D cubes from 1D vectors (replicate across trading partners and sectors)
wi_h3D=repmat(wi_h,[1 N S]);    % exporter wage cube
Yi_h3D=repmat(Yi_h,[1 N S]);    % importer income cube
Yj_h3D=permute(Yi_h3D,[2 1 3]); % swap importer/exporter dimensions
Yj3D=permute(Yi3D,[2 1 3]);     % factual income with swapped dimensions

% Construct 3D cube of Nash tariff levels from the N x 1 tariff vector
 tjik = abs(X(N+N+1:end));                              % N x 1 optimal tariff levels
 tjik_2D = repmat(tjik', N, 1);                          % replicate across exporters
 tjik_3D = repmat(eye(N) + tjik_2D.*(eye(N)==0), [1 1 S]) -1 ; % zero on diagonal, tjik off-diagonal
 tjik_h3D = (1+tjik_3D)./(1+tjik_3D_app);               % tariff change (hat) relative to factual

% ------------------------------------------------------------------
%       Equation 6: Wage income = Total sales net of tariffs
% ------------------------------------------------------------------
% AUX0: updated trade cost term: initial share * (tariff_hat * wage_hat)^(1 - sigma)
AUX0 = lambda_jik3D.*((tjik_h3D.*wi_h3D).^(1-sigma_k3D));
% AUX1: CES price index denominator (sum over all exporters j, for each importer k in sector s)
AUX1 = repmat(sum(AUX0,1),[N 1 1]);
% AUX2: updated bilateral trade shares (j's share of k's spending in sector s)
AUX2 = AUX0./max(AUX1, eps);
% AUX3: export revenue of country j in importer k's sector s, net of tariffs
AUX3 = AUX2.*e_ik3D.*(Yj_h3D.*Yj3D)./((1+tjik_3D));
% ERR1: wage equation residual -- total export revenue minus wage bill
ERR1 = sum(sum(AUX3,3),2) - wi_h.*Ri3D(:,1,1);
% Normalization: replace last equation with world wage anchor (weighted average wage = 1)
ERR1(N,1) = sum(Ri3D(:,1,1).*(wi_h-1));

% ------------------------------------------------------------------
%       Equation 7: National income = wage income + tariff revenue
% ------------------------------------------------------------------
% AUX5: tariff revenue collected by importer k on imports from j in sector s
AUX5 = AUX2.*e_ik3D.*(tjik_3D./(1+tjik_3D)).*Yj_h3D.*Yj3D;
% ERR2: income equation residual -- tariff revenue + wage income - total income
ERR2 = sum(sum(AUX5,3),1)' + (wi_h.*Ri3D(:,1,1)) - Yi_h.*Yi3D(:,1,1);

% ------------------------------------------------------------------
%       Equation 14: Optimal tariff (first-order condition)
% ------------------------------------------------------------------

% AUX6: foreign sales only (zero out the domestic diagonal)
AUX6 = AUX3.*repmat(1-eye(N),[1 1 S]);
% AUX7: inverse export supply elasticity -- measures how j's trade share responds to i's tariff
AUX7 = sum(AUX6.*(1-AUX2),2) ./ max(repmat(sum(sum(AUX6,2),3), [1 1 S]), eps);
% AUX8: trade-weighted average inverse supply elasticity across sectors
AUX8 = sum(( sigma_k3D(:,1,:) - 1 ).*AUX7,3);
% ERR3: optimal tariff residual -- Nash tariff = 1 + 1/(weighted elasticity)
% Floor AUX8 at 1 (not eps) to prevent ERR3 from exploding for autarkic
% countries with negligible foreign trade (1/eps ~ 4.5e15 destroys solver).
% Floor of 1 caps optimal tariff at 200% -- economically reasonable for autarky.
ERR3 = tjik - (1 + 1./max(AUX8, 1));
% ------------------------------------------------------------------

ceq= [ERR1' ERR2' ERR3'];

end
