function [ceq] = trade_war_baseline(X, N ,S, Yi3D, Ri3D, e_ik3D, sigma_k3D, lambda_jik3D, tjik_3D_app)
%TARIFFWAR.SOLVER.TRADE_WAR_BASELINE  Nash equilibrium system of equations.
%
%   Verbatim copy of Trade_War_Baseline.m from Replication_Files.
%   Implements Equations 6, 7, and 14 from Lashkaripour (2021).
%
% ------------------------------------------------------------------
%        Description of Inputs
% ------------------------------------------------------------------
%   N: number of countries;  S: number of industries
%   Yi3D: national expenditure ~ national income
%   Ri3D: national wage revenues ~ sales net of tariffs
%   e_ik3D: industry-level expenditure share (C-D weight)
%   lambda_jik3D: within-industry expenditure share
%   sigma_k3D: industry-level CES parameter (sigma-1 ~ trade elasticity)
%   tjik_3D_app: applied tariff
% ------------------------------------------------------------------

wi_h=abs(X(1:N));    % abs(.) is used avoid complex numbers...
Yi_h=abs(X(N+1:N+N));

% construct 3D cubes from 1D vectors
wi_h3D=repmat(wi_h,[1 N S]);
Yi_h3D=repmat(Yi_h,[1 N S]);
Yj_h3D=permute(Yi_h3D,[2 1 3]);
Yj3D=permute(Yi3D,[2 1 3]);

%---- construct 3D cubes for change in tariffs ---------------
 tjik = abs(X(N+N+1:end));
 tjik_2D = repmat(tjik', N, 1);
 tjik_3D = repmat(eye(N) + tjik_2D.*(eye(N)==0), [1 1 S]) -1 ;
 tjik_h3D = (1+tjik_3D)./(1+tjik_3D_app);

% ------------------------------------------------------------------
%       Wage Income = Total Sales net of Taxes (Equation 6)
% ------------------------------------------------------------------
AUX0 = lambda_jik3D.*((tjik_h3D.*wi_h3D).^(1-sigma_k3D));
AUX1 = repmat(sum(AUX0,1),[N 1 1]);
AUX2 = AUX0./max(AUX1, eps);
AUX3 = AUX2.*e_ik3D.*(Yj_h3D.*Yj3D)./((1+tjik_3D));
ERR1 = sum(sum(AUX3,3),2) - wi_h.*Ri3D(:,1,1);
ERR1(N,1) = sum(Ri3D(:,1,1).*(wi_h-1));  % replace one excess equation with normalization,w^=w'/w=1, where w=sum_i(wi'*Li)/sum(wi*Li)

% ------------------------------------------------------------------
%           Total Income = Total Sales (Equation 7)
% ------------------------------------------------------------------
AUX5 = AUX2.*e_ik3D.*(tjik_3D./(1+tjik_3D)).*Yj_h3D.*Yj3D;
ERR2 = sum(sum(AUX5,3),1)' + (wi_h.*Ri3D(:,1,1)) - Yi_h.*Yi3D(:,1,1);

% ------------------------------------------------------------------
%           Optimal Tariff Formula (Equation 14)
% ------------------------------------------------------------------

AUX6 = AUX3.*repmat(1-eye(N),[1 1 S]);
AUX7 = sum(AUX6.*(1-AUX2),2) ./ max(repmat(sum(sum(AUX6,2),3), [1 1 S]), eps);
AUX8 = sum(( sigma_k3D(:,1,:) - 1 ).*AUX7,3);
% Floor AUX8 at 1 (not eps) to prevent ERR3 from exploding for autarkic
% countries with negligible foreign trade (1/eps ~ 4.5e15 destroys solver).
% Floor of 1 caps optimal tariff at 200% — economically reasonable for autarky.
ERR3 = tjik - (1 + 1./max(AUX8, 1));
% ------------------------------------------------------------------

ceq= [ERR1' ERR2' ERR3'];

end
