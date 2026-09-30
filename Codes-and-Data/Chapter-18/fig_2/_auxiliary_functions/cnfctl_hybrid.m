function [y_z_hybrid,pi_z_hybrid,ib_z_hybrid,nu_z_hybrid,policy_error,instr_error] = cnfctl_hybrid(max_hor,lambda,A_y,A_pi,A_ib,...
    Theta_pi,Theta_y,Theta_ib,pi_z,y_z,ib_z);

% system size

T = size(A_y,1);

% re-scale lambda

max_z_error = max(abs(A_y * y_z + A_pi * pi_z + A_ib * ib_z));
lambda = lambda * max_z_error^2; % to equal weight on error in standard deviation units and rule inaccuracy relative to baseline

% number of identified shocks

h = size(Theta_pi,2);

% IRF matrices for contemporaneous and future shocks

Pi_ib_fudge = NaN(T,h*(1+max_hor));
Pi_ib_fudge(:,1:h) = Theta_pi(:,1:h);
for i_hor = 1:max_hor
    Pi_ib_fudge(:,i_hor*h+1:i_hor*h+h) = [zeros(i_hor,h);Theta_pi(1:T-i_hor,1:h)];
end
Y_ib_fudge = NaN(T,h*(1+max_hor));
Y_ib_fudge(:,1:h) = Theta_y(:,1:h);
for i_hor = 1:max_hor
    Y_ib_fudge(:,i_hor*h+1:i_hor*h+h) = [zeros(i_hor,h);Theta_y(1:T-i_hor,1:h)];
end
Ib_ib_fudge = NaN(T,h*(1+max_hor));
Ib_ib_fudge(:,1:h) = Theta_ib(:,1:h);
for i_hor = 1:max_hor
    Ib_ib_fudge(:,i_hor*h+1:i_hor*h+h) = [zeros(i_hor,h);Theta_ib(1:T-i_hor,1:h)];
end

% ridge penalty matrix

% P = eye(h*(1+max_hor));
% for i = 1:h
%     P(i,i) = 0;
% end
P = zeros(h*(1+max_hor),h*(1+max_hor));
for i = 2:(1+max_hor)
    for j = 1:h
        P((i-1)*h+j,(i-1)*h+j) = sqrt(Ib_ib_fudge(:,j)'*Ib_ib_fudge(:,j));
    end
end
% P = Ib_ib_fudge;
% P(:,1:h) = 0;
% P = P(2:end,:);

% get optimal shock sequence

nu_z_hybrid = - ((A_pi * Pi_ib_fudge + A_y * Y_ib_fudge + A_ib * Ib_ib_fudge)' * (A_pi * Pi_ib_fudge + A_y * Y_ib_fudge + A_ib * Ib_ib_fudge) + lambda * (P'*P))^(-1) ...
                * ((A_pi * Pi_ib_fudge + A_y * Y_ib_fudge + A_ib * Ib_ib_fudge)' * (A_pi * pi_z + A_y * y_z + A_ib * ib_z));

% get outcomes

y_z_hybrid  = y_z + Y_ib_fudge * nu_z_hybrid;
pi_z_hybrid = pi_z + Pi_ib_fudge * nu_z_hybrid;
ib_z_hybrid = ib_z + Ib_ib_fudge * nu_z_hybrid;

% get policy error

policy_error = A_y * y_z_hybrid + A_pi * pi_z_hybrid + A_ib * ib_z_hybrid;

% get share of instrument movements accounted for by surprise shocks

instr_surprise = zeros(T,1);
for t = 2:T
    instr_surprise(t) = Ib_ib_fudge(t,:) * [zeros(h,1);nu_z_hybrid(h+1:end)];
end

instr_error = zeros(T,1);
for t = 1:T
    instr_error(t) = instr_surprise(t);
end

% instr_error = zeros(T,1);
% for i_hor = 1:max_hor
%     instr_error(i_hor+1) = mean(nu_z_hybrid(i_hor*h+1:(i_hor+1)*h)) * 100;
% end