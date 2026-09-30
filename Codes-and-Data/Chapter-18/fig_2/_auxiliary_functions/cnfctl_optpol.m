function [y_z_optol,pi_z_optpol,ib_z_optpol,instr_error] = cnfctl_optpol(max_hor,lambda,W_pi,W_y,...
    Theta_pi,Theta_y,Theta_ib,pi_z,y_z,ib_z);

% system size

T = size(W_pi,1);

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

P = zeros(h*(1+max_hor),h*(1+max_hor));
for i = 2:(1+max_hor)
    for j = 1:h
        P((i-1)*h+j,(i-1)*h+j) = sqrt(Ib_ib_fudge(:,j)'*Ib_ib_fudge(:,j));
    end
end
P = P(h+1:end,h+1:end);

% get optimal shock sequence

A_mat = [eye(T), zeros(T,T), -Theta_pi, -Pi_ib_fudge(:,h+1:end), zeros(T,T), zeros(T,T); ...
    zeros(T,T), eye(T), -Theta_y, -Y_ib_fudge(:,h+1:end), zeros(T,T), zeros(T,T); ...
    W_pi, zeros(T,T), zeros(T,h), zeros(T,max_hor*h), eye(T), zeros(T,T); ...
    zeros(T,T), W_y, zeros(T,h), zeros(T,max_hor*h), zeros(T,T), eye(T); ...
    zeros(h,T), zeros(h,T), zeros(h,h), zeros(h,max_hor*h), Theta_pi', Theta_y'; ...
    zeros(max_hor*h,T), zeros(max_hor*h,T), zeros(max_hor*h,h), -lambda * P, Pi_ib_fudge(:,h+1:end)', Y_ib_fudge(:,h+1:end)'];

b_mat = [pi_z; y_z; zeros(T,1); zeros(T,1); zeros(h,1); zeros(max_hor*h,1)];

sol = A_mat^(-1) * b_mat;

nu_z_optpol = sol(2*T+1:2*T+h*(1+max_hor));

% get outcomes

y_z_optol  = y_z + Y_ib_fudge * nu_z_optpol;
pi_z_optpol = pi_z + Pi_ib_fudge * nu_z_optpol;
ib_z_optpol = ib_z + Ib_ib_fudge * nu_z_optpol;

% get share of instrument movements accounted for by surprise shocks

instr_surprise = zeros(T,1);
for t = 2:T
    instr_surprise(t) = Ib_ib_fudge(t,:) * [zeros(h,1);nu_z_optpol(h+1:end)];
end

instr_error = zeros(T,1);
for t = 1:T
    instr_error(t) = instr_surprise(t);
end

end