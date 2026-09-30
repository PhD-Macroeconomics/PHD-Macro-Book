function [y_z_var,pi_z_var,ib_z_var,error_z_all,ib_z_surprise] = cnfctl_finite(A_y,A_pi,A_ib,...
    Theta_pi,Theta_y,Theta_ib,pi_z,y_z,ib_z);

T = size(A_y,1);
h = size(Theta_pi,2);

nu_all = zeros(h,T);
y_s_all = NaN(T,T);
pi_s_all = NaN(T,T);
ib_s_all = NaN(T,T);
error_z_all = NaN(T,T);

nu_all(1:h,1) = -(A_pi(1:h,:) * Theta_pi + A_y(1:h,:) * Theta_y ...
    + A_ib(1:h,:) * Theta_ib)^(-1) * (A_pi(1:h,:) * pi_z ...
    + A_y(1:h,:) * y_z + A_ib(1:h,:) * ib_z);

y_s_all(:,1)  = y_z + Theta_y * nu_all(:,1);
pi_s_all(:,1) = pi_z + Theta_pi * nu_all(:,1);
ib_s_all(:,1) = ib_z + Theta_ib * nu_all(:,1);
error_z_all(:,1) = A_y * y_s_all(:,1) + A_pi * pi_s_all(:,1) + A_ib * ib_s_all(:,1);

for t = 2:T-h+1

    nu_all(1:h,t) = -(A_pi(t:h+t-1,:) * [zeros(t-1,h);Theta_pi(1:T-t+1,:)] + A_y(t:h+t-1,:) * [zeros(t-1,h);Theta_y(1:T-t+1,:)] ...
        + A_ib(t:h+t-1,:) * [zeros(t-1,h);Theta_ib(1:T-t+1,:)])^(-1) * (A_pi(t:h+t-1,:) * pi_s_all(:,t-1) ...
        + A_y(t:h+t-1,:) * y_s_all(:,t-1) + A_ib(t:h+t-1,:) * ib_s_all(:,t-1));
    
    y_s_all(:,t)  = y_s_all(:,t-1) + [zeros(t-1,h);Theta_y(1:T-t+1,:)] * nu_all(:,t);
    pi_s_all(:,t) = pi_s_all(:,t-1) + [zeros(t-1,h);Theta_pi(1:T-t+1,:)] * nu_all(:,t);
    ib_s_all(:,t) = ib_s_all(:,t-1) + [zeros(t-1,h);Theta_ib(1:T-t+1,:)] * nu_all(:,t);
    error_z_all(:,t) = A_y * y_s_all(:,t) + A_pi * pi_s_all(:,t) + A_ib * ib_s_all(:,t);

end

y_z_var  = y_s_all(:,T-h+1);
pi_z_var = pi_s_all(:,T-h+1);
ib_z_var = ib_s_all(:,T-h+1);

% compute interest rate surprises

ib_z_surprise = NaN(T-h+1,1);
ib_z_surprise(1) = sum(sqrt(ib_s_all(:,1).^2));
for t = 2:T-h+1
    ib_z_surprise(t) = sum(sqrt((ib_s_all(:,t)-ib_s_all(:,t-1)).^2));
end
ib_z_surprise = [ib_z_surprise;zeros(h-1,1)];
ib_z_surprise = ib_z_surprise ./ ib_z_surprise(1);

end