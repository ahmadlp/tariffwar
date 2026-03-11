function [Gains]=welfare_gains(X, N , S, e_ik3D, sigma_k3D,  lambda_jik3D, tjik_3D_app)
%TARIFFWAR.WELFARE.WELFARE_GAINS  Compute welfare gains from Nash tariffs.
%
%   Gains = tariffwar.welfare.welfare_gains(X, N, S, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_app)
%
%   Given the Nash equilibrium solution vector X, computes the percent
%   change in real income (welfare) for each country.
%   Welfare_hat = E_hat / P_hat, where E_hat is the nominal income change
%   and P_hat is the CES aggregate price index change.
%
%   Inputs:
%     X             - 3N x 1 solution vector [wi_h; Yi_h; tjik]
%     N, S          - number of countries, sectors
%     e_ik3D        - expenditure shares (Cobb-Douglas weights)
%     sigma_k3D     - CES elasticity parameters
%     lambda_jik3D  - initial bilateral trade shares
%     tjik_3D_app   - applied (factual) tariff rates
%
%   Returns Gains (N x 1): percent welfare change per country.
%
%   See also: tariffwar.solver.nash_equilibrium, tariffwar.pipeline.run

% Extract unknowns from the Nash equilibrium solution vector
wi_h=abs(X(1:N));          % N x 1 wage changes (hat)
wi_h3D=repmat(wi_h,[1 N S]); % replicate into exporter wage cube
Ei_h=abs(X(N+1:N+N));     % N x 1 income/expenditure changes (hat)

% Reconstruct the Nash tariff cube from the N x 1 tariff vector
 tjik = abs(X(N+N+1:end));
 tjik_2D = repmat(tjik', N, 1);
 tjik_3D = repmat(eye(N) + tjik_2D.*(eye(N)==0), [1 1 S]) -1 ;
 tjik_h3D = (1+tjik_3D)./(1+tjik_3D_app);  % tariff change relative to factual
% --- Price index change (CES aggregation across exporters) ---
% AUX0: bilateral trade cost change raised to (1 - sigma)
AUX0=((tjik_h3D.*wi_h3D).^(1-sigma_k3D));
% price_sum: CES price index numerator (sum over exporters, weighted by initial shares)
price_sum = max(sum(lambda_jik3D.*AUX0,1), eps);
% Pjk_h: sectoral price index change for importer j in sector k
Pjk_h = price_sum.^(1./(1-sigma_k3D(1,:,:)));
Pjk_h(isnan(Pjk_h) | isinf(Pjk_h)) = 1;  % neutral price change for undefined pairs

% --- Aggregate price index (Cobb-Douglas across sectors) ---
% Pi_h: overall price index change = product of sectoral price changes weighted by expenditure shares
Pi_h = exp( sum(e_ik3D(1,:,:).*log(max(Pjk_h, eps)),3) )';

% --- Welfare = real income change ---
% Wi_h: ratio of nominal income change to price index change
Wi_h = Ei_h./Pi_h;
Gains = 100*(Wi_h-1);  % convert to percent
end
