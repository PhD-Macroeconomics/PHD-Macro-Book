# Main script to solve for inputs from the HANK model.


push!(LOAD_PATH, "fig4_helpers");
using utils
using Parameters
using LinearAlgebra: I, ⋅, Diagonal
using Roots: find_zero
using Plots: plot, plot!, savefig
# using DelimitedFiles

mkpath("Results")

forward_maxit = 10000; βtol = 1e-6;
using HouseholdAR1: grid, σ, eulerBack, initialize_Va, β_bracket




## Compute steady state

include("fig4_helpers/SteadyState.jl")


r = 0.01;
Y = 1.0;
β = 0.97;



function SolveEGM(grid,Va_0,β,r,Y)
    #loop until convergence
    tol = 1e-10
    test = true

    for it in 1:10000
        Va_1  = eulerBack(grid,Va_0,β,r,Y)[1];

        if (it-1) % 50 == 0
            test = maximum(abs.(Va_0 .- Va_1)./(abs.(Va_0) .+ abs.(Va_1) .+ tol))
            println("it = $it, test = $test")
            if test  < tol
                break
            end
        end

        Va_0 = Va_1;
    end

    return eulerBack(grid,Va_0,β,r,Y)

end


Va, a, c = SolveEGM(grid,initialize_Va(r,Y,grid),β,r,Y);
D = steady_state_forward_step(a,grid,maxit=forward_maxit);

xlim_top = 25.;
# plot(grid.a,a[:,1]- grid.a,xlim=(0.,xlim_top),xlabel="Assets",ylabel="Net saving, a' - a",label="Low income")
# plot!(grid.a,a[:,2]- grid.a,label="High income")
# savefig("Results/fig4_NetSavingRule.png")

plot(grid.a,a[:,1],color=:black,line=(:solid,2),xlim=(0.,xlim_top),ylim=(0.,xlim_top),xlabel="Assets",ylabel="Saving policy rule a' = g(a,y)",label="Low income",legend=:bottomright)
plot!(grid.a,a[:,2],color=:black,line=(:dash,2),label="High income")
plot!(grid.a,grid.a,color=:black,line=(:dot,1),label="45-degree line")
savefig("Results/fig4_GrossSavingRule.png")

# Wealth plot
n = 12;
pltgrid = range(grid.amin,grid.amax,length =n);
x_i, x_pi = interpolate_coord_robust(pltgrid,grid.a);


Dplt = zeros(n);
for i = 1:grid.na
    Dplt[x_i[i]] += x_pi[i] * sum(D[i,:]);
    Dplt[x_i[i]] += (1 .- x_pi[i]) * sum(D[i,:]);
end

plot(pltgrid,Dplt,xlim=(grid.amin,xlim_top),color=:black,line=(:solid,2),xlabel="Assets",ylabel="Distribution of consumers")
savefig("Results/fig4_WealthDist.png")



