function [Gains]=welfare_gains_baseline(X, N , S, e_ik3D, sigma_k3D,  lambda_jik3D, tjik_3D_app)
%TARIFFWAR.WELFARE.WELFARE_GAINS_BASELINE  Compute welfare gains from Nash tariffs.
%
%   Verbatim copy of Welfare_Gains_Baseline.m from Replication_Files.
%   Computes percent welfare change for each country using hat algebra.

wi_h=abs(X(1:N));% Nx1, mod to avoid complex numbers...
wi_h3D=repmat(wi_h,[1 N S]); % construct 3D cubes from 1D vectors
Ei_h=abs(X(N+1:N+N));

% Construct 3D cube of Nash tariffs
 tjik = abs(X(N+N+1:end));
 tjik_2D = repmat(tjik', N, 1);
 tjik_3D = repmat(eye(N) + tjik_2D.*(eye(N)==0), [1 1 S]) -1 ;
 tjik_h3D = (1+tjik_3D)./(1+tjik_3D_app);
 fprintf('Average Nash tariff under the baseline model = %0.2f%% \n',100*mean(tjik_3D(:)) )

% Calculate the change in price indexes
AUX0=((tjik_h3D.*wi_h3D).^(1-sigma_k3D));
price_sum = max(sum(lambda_jik3D.*AUX0,1), eps);
Pjk_h = price_sum.^(1./(1-sigma_k3D(1,:,:)));
Pjk_h(isnan(Pjk_h) | isinf(Pjk_h)) = 1;  % neutral price change for undefined pairs
Pi_h = exp( sum(e_ik3D(1,:,:).*log(max(Pjk_h, eps)),3) )';

% Calculate the change in welfare
Wi_h = Ei_h./Pi_h;
Gains = 100*(Wi_h-1);
end
