# Script to simulate the stochastic growth model.
# Note that the simulation in panel (a) differs from what is in the book because we use a different sequence
# of random numbers in the simulation (the original figure was made in Matlab)

using Random
using Plots

# Solve Lyapunov equation
# For this stable model, iterate Sigma = P * Sigma * P' + B to convergence.
function lyapunov_symm(P, B; tolerance = 1e-12)
    Sigma = zeros(size(B))
    for iteration in 1:100_000
        Sigma_new = P * Sigma * P' + B
        if maximum(abs.(Sigma_new - Sigma)) < tolerance
            return Sigma_new
        end
        Sigma = Sigma_new
    end
    error("The covariance iteration did not converge.")
end

pdf_normal(x, mu, stdev) = exp.(-(x .- mu).^2 / (2 * stdev^2)) / (stdev * sqrt(2 * pi))


results_dir = joinpath(@__DIR__, "Results")
mkpath(results_dir)

## Parameters
sigma = 1
beta = 0.99
alpha = 0.3
delta = 0.02
rho = 0.95
shock_std = 0.005

## Steady state

# f_K = 1/beta
# f_K = alpha * Abar * Kbar^(alpha-1) + 1 - delta
Abar = 1
Kbar = ((1/beta - 1 + delta)/(alpha * Abar))^(1/(alpha-1))
Ybar = Abar * Kbar^alpha
Cbar = Ybar - delta * Kbar

## Linear solution
# Use solution for linear savings policy rule in text.

u_C = Cbar^(-sigma)
u_CC = -sigma * Cbar^(-sigma-1)
f_K = 1/beta
f_KK = alpha * (alpha-1) * Abar * Kbar^(alpha-2)
quadr = [1, -(1 + 1/beta + u_C*f_KK/(u_CC * f_K)), 1/beta]
# The smaller root of the quadratic gives the stable policy rule.
g_K = (-quadr[2] - sqrt(quadr[2]^2 - 4*quadr[1]*quadr[3])) / (2*quadr[1])

f_A = Kbar^alpha
f_KA = alpha * Kbar^(alpha-1)
g_A = ((1-rho) * f_A - rho * u_C * f_KA / (u_CC * f_K)) / (f_K - g_K + 1 - rho + u_C*f_KK/(u_CC * f_K))
@show g_K g_A

# Check against Dynare output.
g_A_dyn = 1.901658 / rho
g_K_dyn = 0.964530
@assert abs(g_A - g_A_dyn) < 1e-6
@assert abs(g_K - g_K_dyn) < 1e-6

## Simulation
# Start from steady state and simulate deviations from steady state:
# A' - Abar = rho * (A - Abar) + epsilon'
# K' - Kbar = g_K * (K - Kbar) + g_A * (A - Abar)

T = 50_000                      # Number of periods to simulate.
Random.seed!(83024)             # Reproducible in Julia; draws differ from MATLAB.
epsilon = shock_std * randn(T)  # Generate the shocks.
A = zeros(T)
K = zeros(T)
A[1] = epsilon[1]
for t in 1:(T-1)
    A[t+1] = rho * A[t] + epsilon[t+1]
    K[t+1] = g_K * K[t] + g_A * A[t]
end

# Add the steady state.
A = A .+ Abar
K = K .+ Kbar

# Production function gives output.
Y = A .* K.^alpha

# Aggregate resource constraint gives consumption:
# K' + C = Y + (1-delta) * K.
# Final consumption is unavailable because next period's capital is unknown.
C = Y + (1-delta)*K - [K[2:end]; NaN]

SimData = [A/Abar K/Kbar Y/Ybar C/Cbar] .- 1
Ksim = K

## Unconditional variance and histogram
# [A'; K'] = P * [A; K] + Q * epsilon' + constant,
# where epsilon has unit variance.
P = [rho 0; g_A g_K]
Q = [shock_std; 0]
Sigma = lyapunov_symm(P, Q * Q')

## IRFs

T = 41  # Number of periods to simulate.
epsilon = [shock_std; zeros(T-1)]
A = zeros(T)
K = zeros(T)
A[1] = epsilon[1]
for t in 1:(T-1)
    A[t+1] = rho * A[t] + epsilon[t+1]
    K[t+1] = g_K * K[t] + g_A * A[t]
end

# Add the steady state.
A = A .+ Abar
K = K .+ Kbar

# Production function gives output.
Y = A .* K.^alpha

# Aggregate resource constraint gives consumption.
C = Y + (1-delta)*K - [K[2:end]; NaN]
IRFs = [A/Abar K/Kbar Y/Ybar C/Cbar] .- 1

## Plotting
t = 200
names = ["TFP", "Capital", "Output", "Consumption"]

f = plot(1:t, SimData[1:t, :], size = (400, 300),
    label = permutedims(names), legend = :bottomright,
    color = [:black :black :gray :gray],
    linestyle = [:solid :dashdot :solid :dash], linewidth = [1 1 2 1.5],
    ylabel = "% deviation from steady state", xlabel = "simulated quarters")
savefig(f, joinpath(results_dir, "fig3_StochasticGrowthSimulatedPath.png"))


## Histogram
nbins = 60
# Explicit edges give 60 equal-width bins; extend the last edge to include max(Ksim).
edges = collect(range(minimum(Ksim), maximum(Ksim), length = nbins+1))
edges[end] = nextfloat(edges[end])
ncount = zeros(Int, nbins)
for i in 1:nbins
    ncount[i] = count(k -> edges[i] <= k < edges[i+1], Ksim)
end
centers = (edges[1:end-1] + edges[2:end]) / 2
h = ncount / length(Ksim) ./ diff(edges)
d = pdf_normal(centers, Kbar, sqrt(Sigma[2, 2]))

# Retain the original density in capital levels, with a rescaled horizontal axis.
f = bar(centers/Kbar .- 1, h, size = (400, 300),
    bar_width = diff(edges)/Kbar, color = :gray80, linecolor = :transparent,
    legend = false, xlabel = "K, % deviation from steady state",
    ylabel = "distribution of capital")
plot!(f, centers/Kbar .- 1, d, linewidth = 2, color = :black)
savefig(f, joinpath(results_dir, "fig3_StochasticGrowthHistogram.png"))

## Diagram
A_grid = [0.95, 1.05]
K_lims = 1 .+ g_A * (A_grid .- 1) / (1-g_K) / Kbar
K_grid = Kbar * collect(K_lims[1]:0.01:K_lims[2])
# Broadcasting a column against a row gives one column per TFP level.
Kprime = Kbar .+ g_K * (K_grid .- Kbar) .+ g_A * (A_grid .- Abar)'

x = K_grid/Kbar .- 1
y = Kprime/Kbar .- 1
f = plot(x, [x y], size = (400, 300),
    color = [:gray :black :black], linewidth = 2,
    linestyle = [:dash :solid :solid],
    label = ["45 degree line" "" ""], legend = :bottomright,
    xlims = extrema(x), ylims = extrema(x),
    xlabel = "K, % deviation from steady state", ylabel = "% deviation from steady state")
annotate!(f, x[round(Int, length(x)*0.35)], 0, text("High TFP", 9))
annotate!(f, x[round(Int, length(x)*0.65)], 0, text("Low TFP", 9))
savefig(f, joinpath(results_dir, "fig3_StochasticGrowthDiagramLevel.png"))


## Diagram in differences
f = plot(x, y .- x, size = (400, 300),
    color = :black, linewidth = 2, legend = false, xlims = extrema(x),
    xlabel = "K, % deviation from steady state", ylabel = "K' - K, % of steady state")
annotate!(f, 0, g_A*(A_grid[2]-Abar)/Kbar, text("High TFP", 9, :bottom))
annotate!(f, 0, g_A*(A_grid[1]-Abar)/Kbar, text("Low TFP", 9, :top))
savefig(f, joinpath(results_dir, "fig3_StochasticGrowthDiagramDiff.png"))

## Impulse response
f = plot(0:(size(IRFs, 1)-1), IRFs, size = (400, 300),
    label = permutedims(names), legend = :topright,
    color = [:black :black :gray :gray],
    linestyle = [:solid :dashdot :solid :dash], linewidth = [1 1 3 1.5],
    xlims = (0, 40), ylabel = "% deviation from steady state", xlabel = "horizon in quarters")
savefig(f, joinpath(results_dir, "fig3_StochasticGrowth_IRFs.png"))

