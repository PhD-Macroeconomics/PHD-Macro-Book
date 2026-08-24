%Marina Azzimonti December 2022
%This function solves the system of equations specified in the subfunction EvalSystem.  
%There are T intratemperal FOCs and T-1 intertemperal FOCs, for a 2T-1 system of equations.

%The function uses Newton's method to solve the system of equations.
%The results are written to the file "Results.xls"
%This function run through TaxIncrease.m

function [err, sol] = ComputeModel(flag, x, tauc_vec, taul_vec, tauk_vec)
err = 0;
global BETA;    global THETA;   global DELTA;   global ALPHA;   global z;
global K0;      global T;      
global tauk taul tauc Gss yss kss lss css rss Tss
global tauk_vec taul_vec tauc_vec

ITR_MAX = 250;              %Maximum interations for Newton's method
EPSILON = 1.0e-10;          %Stopping value for Newton's method
J_STEP = 1.0e-08;           %Step size for computing numerical derivatives

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%If the model does not solve, you can try changing these values.          
N_ITER = 3;                 %Number of iterations before N_STEP = 1.0     
N_STEP = 0.5;               %Begining step size in Newton's Method        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fx = zeros(2*T-1,1);            %value of the equations (what we want to be zero)
j = zeros(2*T-1,2*T-1);         %jacobian matrix
j_inv = zeros(2*T-1,2*T-1);     %inverse of the jacobian matrix

iteration = 0;
loss_fx = 1;
fx = EvalSystem(x, tauc_vec, taul_vec, tauk_vec);

%Newton's method
while (loss_fx >= EPSILON) & (iteration <= ITR_MAX)     %check: are we close enough to zero? have we tried too many times?
    j = Jacobian(fx, x, J_STEP, tauc_vec, taul_vec, tauk_vec);
    j_inv = inv(j);
    if( iteration >= N_ITER) N_STEP = 1.0; end              %Once things are going well, start taking bigger steps
    x = x - N_STEP.*(j_inv*fx);                             %update guess     
    fx = EvalSystem(x, tauc_vec, taul_vec, tauk_vec);
    
    iteration = iteration + 1;
    loss_fx = max(abs(fx));                            %how big is the largest error?
    fprintf('iteration %5.2f \t',iteration);
    fprintf('error %10.6e \n', loss_fx);   
end

%check for failure
if iteration > ITR_MAX
    fprintf('Max number of iterations exceeded.');
    err = 1;
end
sol = x;      %return the solution 

%if flag =  1 then compute results and output them to a file
if flag == 1
    xk(1)=K0;
    xk(2:T,1) = x(1:T-1);
    xk(T+1)=xk(T);
    
    xl = x(T:2*T-1,1);
      
    %Using the correct capital and leisure values, find output per worker,
    %investment/GDP, hours worked per week, consumption/GDP, K/Y and the
    %interest rate.  This section can be modified to output any variables
    %of interest.
    
    results = zeros(T,6);
    y = z.*xk(1:T,1).^ALPHA .* xl.^(1-ALPHA); %GDP 
    w=z.*(1-ALPHA).*xk(1:T,1).^(ALPHA).*xl.^(-ALPHA);
    Rv=1+(1-tauk_vec).*((ALPHA.*z.*xk(1:T,1).^(ALPHA-1).*xl.^(1-ALPHA))-DELTA);
 
    cw = ((1-taul_vec).*xl.*w )./(1+tauc_vec);
    ck = (Rv.*xk(1:T,1)- xk(2:T+1,1))./(1+tauc_vec);
    
    Gov_vec=y + (1-DELTA).*xk(1:T,1) - xk(2:T+1,1)-cw-ck;
    Tr=tauc_vec.*(cw+ck)+taul_vec.*xl.*w+tauk_vec.*((ALPHA.*z.*xk(1:T,1).^(ALPHA-1).*xl.^(1-ALPHA))-DELTA).*xk(1:T,1)-Gov_vec;
    

    
    results(:,1) = y; %output
    results(:,2) = (xk(2:T+1,1)-(1-DELTA).*xk(1:T,1)); %investment
    results(:,3) = xl; %labor
    results(:,4) = cw; %consumption worker
    results(:,5) = xk(1:T,1);%capital
    results(:,6) = (ALPHA.*z.*xk(1:T,1).^(ALPHA-1).*xl.^(1-ALPHA)); %MPK
    results(:,7)=   Tr; %transfers
    results(:,8)=   w; %wages
     results(:,9)= Rv; %interest rate
     results(:,10)= Gov_vec; 
     results(:,11) = ck; %consumption capitalist
     
    %write the data out to a file

    save('Results.mat','results');
    fprintf('Progam finished. Data written to file. \n');
end

%--------------------------------------------------------------------------
%----------------------------------EvalSystem------------------------------
%--------------------------------------------------------------------------
function f = EvalSystem(x, tauc_vec, taul_vec, tauk_vec)
%This function evaluates the system of equations.  It is called by Jacobian
%and SolveModel

%use the global parameter values
global BETA;    global THETA;   global DELTA;   global ALPHA;   global z;
global K0;      global T;      
global tauk taul tauc Gss yss kss lss css rss Tss
global tauk_vec taul_vec tauc_vec

f = zeros(size(x,1),1);

xk = zeros(T+1,1);      %capital stocks
xl = zeros(T,1);        %labor 
y = zeros(T,1);         %output
cw = zeros(T,1);         %consumption worker
ck = zeros(T,1);         %consumption capitalist
w = zeros(T,1);         %wages

%convert data 
xk(1) = K0;
xk(2:T,1) = x(1:T-1);
xk(T+1) = xk(T);

xl(1:T,1) = x(T:2*T-1,1);

%compute output, consumption and wages
    y = z.*xk(1:T,1).^ALPHA .* xl.^(1-ALPHA); %GDP 
    w=z.*(1-ALPHA).*xk(1:T,1).^(ALPHA).*xl.^(-ALPHA);
    Rv=1+(1-tauk_vec).*((ALPHA.*z.*xk(1:T,1).^(ALPHA-1).*xl.^(1-ALPHA))-DELTA);
 
    cw = ((1-taul_vec).*xl.*w )./(1+tauc_vec);
    ck = ( Rv.*xk(1:T,1)- xk(2:T+1,1))./(1+tauc_vec);
    
    Gov_vec=y + (1-DELTA).*xk(1:T,1) - xk(2:T+1,1)-cw-ck;
    

%Compute the intratemperal FOC.  
f(1:T,1) = w.*(1-taul_vec)./(1+tauc_vec) + (-xl.^(1/THETA));

%Compute the intertemporal FOC.
%ctilde(1:T,1)=c(1:T,1) - (xl.^(1+1/THETA)./(1+1/THETA));

f(T+1:2*T-1,1) = (ck(2:T,1)./(ck(1:T-1,1))).*(1+tauc_vec(2:T,1))./(1+tauc_vec(1:T-1,1)) -  BETA.*Rv(2:T,1);

%--------------------------------------------------------------------------
%----------------------------------Jacobian--------------------------------
%--------------------------------------------------------------------------
function jac = Jacobian(fx, x, step, tauc_vec, taul_vec, tauk_vec)
%This function computes the Jacobian matrix of the function in EvalSystem at x. 
%The argument step is the size of the step used in numerical differentiation, 
%the argument fx is the value of the system evaluated at x.  The Jacobian
%is returned in the matrix jac.

%Create matrix of correct size to hold function values
n = size(x,1);
fstep = zeros(n,1);

%For each function variable, increment the variable by step, recompute
%the function value, f(x+step), and record [f(x+step)-f(x)]/step.  
for c = 1:n
    x(c) = x(c) + step;
    fstep = EvalSystem(x, tauc_vec, taul_vec, tauk_vec);
    jac(:,c) = (fstep-fx)./step;  
    x(c) = x(c) - step;
end

