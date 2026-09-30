% 3-equation model simulation
% Alisdair McKay
% Jan 4, 2023
close all; clear; clc;

% model equations
% NKPC:   p = kappa * x + beta *  p(+1);
% IS:     x = x(+1) - (1/sigma)*(i - p(+1));
% policy: i = gamma*i(-1) + (1-gamma)*(psi_p*p +psi_x * x) + eta;
% AR(1):  eta = rho * eta(-1) + eps;


gamma = 0.65;
psi_p = 1.5;
psi_x = 0.125;
rho = 0.5;
sigma = 5;
beta = 0.99;
theta = 1- 1/8;
xi_p = (1-theta)*(1-beta*theta)/theta;
kappa = (sigma + 1)*xi_p;


% stack variables in Y and express the equations as
% A Y(+1) + B Y + C Y(-1) + D eps = 0

T = 300;
n = 4;

A = zeros(n,n);
B = zeros(n,n);
C = zeros(n,n);
D = zeros(n,1);

% variables ordered x p i eta
ix = 1; ip = 2; ii = 3; ieta = 4;

% coefficients in equations
% NKPC:   0 = kappa * x + beta *  p(+1) - p;
j = 1;
B(j,ix) = kappa;
A(j,ip) = beta;
B(j,ip) = -1;

% IS:     0 = x(+1) - (1/sigma)*(i - p(+1)) - x;
j = 2;
A(j,ix) = 1;
B(j,ii) = -1/sigma;
A(j,ip) = 1/sigma;
B(j,ix) = -1;

% policy: 0 = gamma*i(-1) + (1-gamma)*(psi_p*p+psi_x*x) + eta - i;
j = 3;
C(j,ii) = gamma;
B(j,ip) = (1-gamma)*psi_p;
B(j,ix) = (1-gamma)*psi_x;
B(j,ieta) = 1;
B(j,ii) = -1;

% AR(1):  0 = rho * eta(-1) + eps - eta;
j = 4;
C(j,ieta) = rho;
B(j,ieta) = -1;
D(j) = 1;


% Solve the VMA representation of the equations 
% F *  Yvec + G * epsvec = 0
% where Yvec is n*T x 1 and epsvec is T x 1
F = zeros(n*T,n*T);
G = zeros(n*T,n);
for t = 1:T
    for j = 1:n
        joffset = (j-1)*T+t;
        for i = 1:n
            ioffset = (i-1)*T+t;
            F(joffset,ioffset) =  B(j,i);
            if t<T
                F(joffset,ioffset+1) = A(j,i);
            end
            if t > 1
                F(joffset,ioffset-1) = C(j,i);
            end
        end
        G(joffset,t) = D(j);
    end
end


Theta = -F\G;

% IRFs to transitory shock to eps
x = Theta((ix-1)*T+1:ix*T,1);
p = Theta((ip-1)*T+1:ip*T,1);
i = Theta((ii-1)*T+1:ii*T,1);
eta = Theta((ieta-1)*T+1:ieta*T,1);


% test that model equations hold
Y = zeros(n,1); Ylag = zeros(n,1); Yprm = zeros(n,1); eps = 1;
for t = 1:T
    Ylag = Y;
    Y([ix,ip,ii,ieta]) = [x(t),p(t),i(t),eta(t)];
    if t < T
        Yprm([ix,ip,ii,ieta]) = [x(t+1),p(t+1),i(t+1),eta(t+1)];
    else
        Yprm = zeros(n,1);
    end
    
    err = A*Yprm + B*Y + C*Ylag + D*eps;
    assert(all(err < 1e-7))
    
    eps = 0;
end



%% save results
scale = 0.75;
x = scale * x; p = scale * p; i = scale * i; eta = scale * eta;
Mod.y = x; Mod.pi = p; Mod.i = i;
save("Results/BasicModel.mat","Mod");
