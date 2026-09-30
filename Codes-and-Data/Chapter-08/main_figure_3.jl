import Random
Random.seed!(29382)
using LinearAlgebra: cholesky, kron, I, inv, Symmetric
using Statistics: cov, quantile
using Plots
using MatrixEquations: lyapd
using Printf: @printf


n = 2;
T = 300;
nit = 1000;
maxh = 20;
nlags = 1;

# B0 y_t + B1 y_{t-1} + B2 y_{t-2} = eps
# y_t = -B0\B1 y_{t-1} + B2 y_{t-2} + B0^{-1} eps

B0 = [1.0 0.4; 0.2 1.0 ];
B1 = -[0.5 0.1; 0.2 0.5];



B2 = -[0.3 0.05; 0.1 0.25];
B0inv = inv(B0);



As = -reshape([B0inv B0inv*B1  B0inv*B2],n,n,3);



#------------ True LP IRFs -------------------------------------------------------------------------------------
Σu = B0inv * B0inv';  # cov mat of one-step ahead forecast errors, all structural shocks have unit variance

# AA puts the system in companion form (VAR(1) in an expanded state)
AA = zeros(3n,3n);
# first block of rows has dynamics
AA[1:n,1:n] = As[:,:,2]; 
AA[1:n,n+1:2n] = As[:,:,3];
# lower rows keep track of lags
AA[n+1:2n,1:n] = I(n);
AA[2n+1:3n,n+1:2n] = I(n);

# solve for stationary covariance using Lyapunov solver
Σyy = lyapd(AA,[[Σu;zeros(2n,n)] zeros(3n,2n)]);

# observation matrix for [y_{1,t-2} y_{2,t-2}, y_{1,t-1}, y_{2,t-1}, y_{1,t}]  out of [y_{t-2}; y_{t-1}; y_t]
#                        ---------------------------------------------------         -----------------------
#                                 this is what we condition on (observed)               full state
H = zeros(5,3n);
H[1:2,1:2] = I(2);
H[3:4,n+1:n+2] = I(2);
H[5,2n+1] = 1;

# covariance of all Y and observed Y
ΣYZ = [I(3n); H] * Σyy * [I(3n);H]';
Σ12 = ΣYZ[1:3n,3n+1:end];      # covariance of observed and full 
Σ22 = ΣYZ[3n+1:end,3n+1:end];  # variance of observed vector
L = Σ12 * inv(Σ22);            # "regress" (OLS) full on observed


TrueLPIRFs = zeros(n,maxh+3);    # we will store the IRF including some initial lags
TrueLPIRFs[:,1] = L[1:n,end];    # y_{t-2} response to y_{1,t}
TrueLPIRFs[:,2] = L[n+1:2n,end]; # y_{t-1} response to y_{1,t}
TrueLPIRFs[:,3] = L[2n+1:3n,end];# y_{t}   response to y_{1,t}
for h = 4:maxh+3  # iterate the VAR forward in time 
    TrueLPIRFs[:,h] = As[:,:,2] * TrueLPIRFs[:,h-1] + As[:,:,3] * TrueLPIRFs[:,h-2];
end
TrueLPIRFs = TrueLPIRFs[:,3:end]; # drop initial lags
TrueLPIRFs /= TrueLPIRFs[1,1];    # scale for unit shock to y_{1,t}






#-----------Simulation---------------------------------------------------------------------------------


# load helper functions
include(joinpath(@__DIR__, "figure_3_helpers", "lpvar_share.jl"))


y = zeros(n,T); # allocate to store simulated sample
irfs = zeros(maxh+1,2,nit); # allocate to store estimation results. Indices are: horizon, method, iteration


```Function to do one iteration: simulate data, fit LP, fit VAR```
function do_it!(it,y,irfs,As,T,nlags,maxh)
    generate_sample!(y,As,T);
    irfs[:,1,it] = localprojection(y[2,:],y[1,:],maxh,nlags,nlags);
    irfs[:,2,it] = var_lp_irfs(y,maxh=maxh,nlags=nlags)[:,2];
end



# Loop through iterations
for it = 1:nit
    do_it!(it,y,irfs,As,T,nlags,maxh);
end


#----------Plotting----------------------------------------------------
lo = zeros(maxh+1,2);  # Lower bound (5th percentile) for each horizon, for each method
me = similar(lo);      # Median for each horizon, for each method
hi = similar(lo);      # Upper bound (5th percentile) for each horizon, for each method
for h = 1:maxh+1
    for k = 1:2
        lo[h,k], me[h,k], hi[h,k] = quantile(irfs[h,k,:],[0.05;0.5;0.95]);
    end
end 

yl = [-0.6;0.3];
p1 = plot(0:maxh, me[:,1], ribbon=(me[:,1]-lo[:,1],hi[:,1]-me[:,1]),color=:grey,fc=:grey,fa=0.3, linewidth=3,label="",title="LP",labels="",ylims=yl);
p1 = plot!(0:maxh,TrueLPIRFs[2,:],color=:black,linestyle=:dash,label="")
p2 = plot(0:maxh, me[:,2], ribbon=(me[:,2]-lo[:,2],hi[:,2]-me[:,2]),color=:grey,fc=:grey,fa=0.3, linewidth=3,label="",title="VAR",labels="",ylims=yl);
p2 = plot!(0:maxh,TrueLPIRFs[2,:],color=:black,linestyle=:dash,label="")

yl = [-0.15;0.15];
p3 = plot(0:maxh, me[:,1] .- TrueLPIRFs[2,:],ribbon=(me[:,1]-lo[:,1],hi[:,1]-me[:,1]),color=:grey,fc=:grey,fa=0.3, linewidth=3,ylims=yl,label="",title="Rel. to truth",titlefontsize=10);
p4 = plot(0:maxh, me[:,2] .- TrueLPIRFs[2,:],ribbon=(me[:,2]-lo[:,2],hi[:,2]-me[:,2]),color=:grey,fc=:grey,fa=0.3, linewidth=3,label="",title="Rel. to truth",ylims=yl,titlefontsize=10);

l = @layout [a b; c d]
plot(p1,p2,p3,p4,layout=l)
results_dir = joinpath(@__DIR__, "results")
mkpath(results_dir)
savefig(joinpath(results_dir, "figure3_lp_vs_var_simulation.pdf"))

#MSE
bias = (irfs .- TrueLPIRFs[2,:]).^2;
mse_vec = vec(sum( bias,dims=[1;3]) / (nit * (maxh+1)));
println("Mean-square error:")
@printf("LP: %.4f    VAR: %.4f\n", mse_vec[1], mse_vec[2])

