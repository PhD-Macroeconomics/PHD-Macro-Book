%Marina Azzimonti October 2022
%model without public debt
clear all;

%delcare the global parameters
global BETA;    global THETA;   global DELTA;   global ALPHA;   global z;
global K0;      global T;     
global tauk taul tauc Gss yss kss lss css rss Tss
global tauk_vec taul_vec tauc_vec 

%assign parameters
BETA = 0.97;    %discount factor    

THETA = 1;   %utility function parameter
DELTA = 0.07;   %depreciation rate
ALPHA = 0.33;   %capital's share in production
z = 1;       %TFP growth factor in balanced growth path

%define taxes in ss
rho=(1-BETA)/BETA;
gJ=0.2;
tauc = 0;
tauk = 0.25;
taul = 1/(1-ALPHA)*(gJ-tauk*rho*(ALPHA/(rho+(1-tauk)*DELTA)));
%0.298; %https://taxfoundation.org/us-tax-burden-on-labor-2020/

%find initial steady state
kss_guess=2;
x0=[kss_guess];
xsol = fsolve('solveSteadyState',x0)

kss=xsol;
lss=((1-taul)/(1+tauc)*(z*(1-ALPHA)*kss^ALPHA))^(THETA/(1+ALPHA*THETA));
rss=z*ALPHA*kss^(ALPHA-1)*lss^(1-ALPHA);
wss=z*(1-ALPHA)*kss^(ALPHA)*lss^(-ALPHA);
yss=z*kss^(ALPHA)*lss^(1-ALPHA);
Rkss=1+(1-tauk)*(rss-DELTA);
cwss=((1-taul)*wss*lss)/(1+tauc);
ckss=(Rkss*kss-kss)/(1+tauc);
Gss=yss+(1-DELTA)*kss-kss-cwss-ckss;
Tss=tauc*css+taul*wss*lss+tauk*(rss-DELTA)*kss-Gss;
css=ckss+cwss;

%Calibration targets:
kss/yss;
Rkss-1;

%components of govt budget

CapRevss=tauk*(rss-DELTA)*kss/yss;
LaborRevss=taul*wss*lss/yss;
ConsRevss=tauc*css/yss;
Gss/yss;
%Tss/yss

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

K0 = kss;      %initial capital stock
T= 100;    %number of periods

%where we want to evaluate
tauk_vec= tauk*ones(T,1);
taul_vec= taul*ones(T,1); 
tauc_vec= tauc*ones(T,1);

%Need to change tauk form 0.8 to 0, taul adjusts 

%period in which shock happens, if t=1 unanticipated. If ts>1, anticipated.
ts=1;

tauk_new = 0;
%tauk_vec(ts)= tauk_new;
tauk_vec(1:T)= tauk_new;

taul_new= 1/(1-ALPHA)*(gJ-tauk_new*rho*(ALPHA/(rho+(1-tauk_new)*DELTA)));
%taul_vec(ts)= taul_new;
taul_vec(1:T)= taul_new;
        
%start with SS taxes
tauccst = tauc*ones(T,1);
taulcst = taul*ones(T,1);
taukcst = tauk*ones(T,1);

%Use initial capital stock, and guess that capital stays there
x(1:T-1,1) = K0*ones(T-1,1);

%guess that leisure is 
x(T:2*T-1,1) = lss*ones(T,1);

%Call SolveModel, and check for success.  Start with a model with constant growth rates (lam=1) 
%and move to the version you want to solve (lam=0). Use the
%solution from the model just solved as a begining guess for the next
%model.  If the routine is not finding solutions, smaller lam steps may help.

for lam = 0;%1.0:-0.2:0.2
    fprintf('=========Lambda = %3.2f ==============\n', lam);
    [err,x] = ComputeModel( 0, x, lam*tauccst+(1-lam)*tauc_vec, lam*taulcst+(1-lam)*taul_vec, ...
                      lam*taukcst+(1-lam)*tauk_vec);
    if err == 0  
        fprintf('Model solved successfully.\n');
    else
        fprintf('Could not find model solution.\n');
    end
end

%ready to solve the version of the model that uses the data
fprintf('=========Lambda = 0.0 ==============\n');
[err,x] = ComputeModel(1,x,tauc_vec,taul_vec,tauk_vec);

save parameters.mat

