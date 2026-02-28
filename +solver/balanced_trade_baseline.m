function [ceq] = balanced_trade_baseline(X, N ,S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_app)
%TARIFFWAR.SOLVER.BALANCED_TRADE_BASELINE  Trade balance system of equations.
%
%   Verbatim copy of Balanced_Trade_Baseline.m from Replication_Files.
%   Solves for balanced trade (zero trade deficit) counterfactual.
%
% ------------------------------------------------------------------
%        Description of Variables
% ------------------------------------------------------------------
%   N: number of countries;  S: number of industries
%   Yi3D: factual income (GDP) in country i
%   e_ik3D: industry-level expenditure share (C-D weight)
%   lambda_jik3D: within-industry expenditure share
%   sigma_k3D: industry-level CES parameter (sigma-1 ~ trade elasticity)
% ------------------------------------------------------------------

wi_h=abs(X(1:N));    % abs(.) is used avoid complex numbers...
Yi_h=abs(X(N+1:N+N));
tjik_3D = tjik_3D_app;


% construct 3D cubes from 1D vectors
wi_h3D=repmat(wi_h,[1 N S]);
Yi_h3D=repmat(Yi_h,[1 N S]);
Yj_h3D=permute(Yi_h3D,[2 1 3]);
Yj3D=permute(Yi3D,[2 1 3]);

% ------------------------------------------------------------------
%        Wage Income = Total Sales net of Taxes
% ------------------------------------------------------------------
AUX0 = lambda_jik3D.*( wi_h3D.^(1-sigma_k3D));
AUX1 = repmat(sum(AUX0,1),[N 1 1]);
AUX2 = AUX0./max(AUX1, eps);
AUX3 = AUX2.*e_ik3D.*(Yj_h3D.*Yj3D)./((1+tjik_3D));
ERR1 = sum(sum(AUX3,3),2) - wi_h.*Ri3D(:,1,1);
ERR1(N,1) = sum(Ri3D(:,1,1).*(wi_h-1));  % replace one excess equation with normalization,w^=w'/w=1, where w=sum_i(wi'*Li)/sum(wi*Li)

% ------------------------------------------------------------------
%        Total Income = Total Sales
% ------------------------------------------------------------------
AUX5 = AUX2.*e_ik3D.*(tjik_3D./(1+tjik_3D)).*Yj_h3D.*Yj3D;
ERR2 = sum(sum(AUX5,3),1)' + (wi_h.*Ri3D(:,1,1)) - Yi_h.*Yi3D(:,1,1);

% ------------------------------------------------------------------

ceq= [ERR1' ERR2'];

end
