function [y_z_hybrid,pi_z_hybrid,ib_z_hybrid,nu_z_hybrid,policy_error,instr_error] = cnfctl_sims(A_y,A_pi,A_ib,...
    Theta_pi,Theta_y,Theta_ib,pi_z,y_z,ib_z);

% system size

T = size(A_y,1);

% number of identified shocks

h = size(Theta_pi,2);

% get outcome sequences

nu_z_hybrid = zeros(h,T);
y_z_hybrid  = NaN(T,T);
pi_z_hybrid = NaN(T,T);
ib_z_hybrid = NaN(T,T);
error_z_all = NaN(T,T);

nu_z_hybrid(1:h,1) = -(A_pi(1:h,:) * Theta_pi + A_y(1:h,:) * Theta_y ...
    + A_ib(1:h,:) * Theta_ib)^(-1) * (A_pi(1:h,:) * pi_z ...
    + A_y(1:h,:) * y_z + A_ib(1:h,:) * ib_z);

y_z_hybrid(:,1)  = y_z + Theta_y * nu_z_hybrid(:,1);
pi_z_hybrid(:,1) = pi_z + Theta_pi * nu_z_hybrid(:,1);
ib_z_hybrid(:,1) = ib_z + Theta_ib * nu_z_hybrid(:,1);
error_z_all(:,1) = A_y * y_z_hybrid(:,1) + A_pi * pi_z_hybrid(:,1) + A_ib * ib_z_hybrid(:,1);

for t = 2:T-h+1

    nu_z_hybrid(1:h,t) = -(A_pi(t:h+t-1,:) * [zeros(t-1,h);Theta_pi(1:T-t+1,:)] + A_y(t:h+t-1,:) * [zeros(t-1,h);Theta_y(1:T-t+1,:)] ...
        + A_ib(t:h+t-1,:) * [zeros(t-1,h);Theta_ib(1:T-t+1,:)])^(-1) * (A_pi(t:h+t-1,:) * pi_z_hybrid(:,t-1) ...
        + A_y(t:h+t-1,:) * y_z_hybrid(:,t-1) + A_ib(t:h+t-1,:) * ib_z_hybrid(:,t-1));
    
    y_z_hybrid(:,t)  = y_z_hybrid(:,t-1) + [zeros(t-1,h);Theta_y(1:T-t+1,:)] * nu_z_hybrid(:,t);
    pi_z_hybrid(:,t) = pi_z_hybrid(:,t-1) + [zeros(t-1,h);Theta_pi(1:T-t+1,:)] * nu_z_hybrid(:,t);
    ib_z_hybrid(:,t) = ib_z_hybrid(:,t-1) + [zeros(t-1,h);Theta_ib(1:T-t+1,:)] * nu_z_hybrid(:,t);
    error_z_all(:,t) = A_y * y_z_hybrid(:,t) + A_pi * pi_z_hybrid(:,t) + A_ib * ib_z_hybrid(:,t);

end

y_z_hybrid  = y_z_hybrid(:,T-h+1);
pi_z_hybrid = pi_z_hybrid(:,T-h+1);
ib_z_hybrid = ib_z_hybrid(:,T-h+1);

nu_z_hybrid = nu_z_hybrid';

% get policy error

policy_error = A_y * y_z_hybrid + A_pi * pi_z_hybrid + A_ib * ib_z_hybrid;

% get share of instrument movements accounted for by surprise shocks

Ib_ib_fudge = NaN(T,h*T);
Ib_ib_fudge(:,1:h) = Theta_ib(:,1:h);
for i_hor = 1:T-1
    Ib_ib_fudge(:,i_hor*h+1:i_hor*h+h) = [zeros(i_hor,h);Theta_ib(1:T-i_hor,1:h)];
end

instr_surprise = zeros(T,1);
for t = 2:T
    instr_surprise(t) = Ib_ib_fudge(t,:) * [zeros(h,1);nu_z_hybrid(h+1:end)];
end

instr_error = zeros(T,1);
for t = 1:T
    instr_error(t) = instr_surprise(t);
end