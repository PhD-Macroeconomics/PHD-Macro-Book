

include(joinpath(@__DIR__, "figure_4_helpers", "ModelUtils.jl"))
using Parameters, .ModelUtils
using SparseArrays
import Plots




@with_kw struct Par
    α = 0.33   # capital share
    β = 0.994  # discount factor
    γ = 0.3    # scale of utility of G (gamma0 in Python)
    δ = 0.019  # depreciation rate
    ψ = 2.0    # inverse Frisch elasticity
    ρ_A = 0.975# persistence of TFP
    ρ_η = 0.9  # persistence of fiscal shock
end

@endogenousvariables K C Y L G R W A η
@exogenousvariables ε_A ε_η

"""Steady state in the order declared by @endogenousvariables (R is the rental rate)."""
function get_ss(par::Par)
    @unpack α, β, γ, δ, ψ, ρ_A, ρ_η = par
    

    A = η = 1.0
    R = 1 / β - 1 + δ
    Y_K = R / α
    K_L = Y_K^(1 / (α - 1))
    C_L = (Y_K - δ) * K_L / (1 + γ * η)
    L = ((1 - α) * Y_K * K_L / C_L)^(1 / (1 + ψ))
    C = C_L * L
    K = K_L * L
    Y = A * K^α * L^(1 - α)
    W = (1 - α) * Y / L
    G = γ * η * C
    return [K; C; Y; L; G; R; W; A; η]
end

"""Construct a T-period economy with steady-state initial lags and terminal leads."""
function model(par::Par=Par(); T::Int=300)
    steadystate = Dict("initial" => get_ss(par), "exog" => zeros(2))
    m = ModelEnv(par=par, vars=vardict, steadystate=steadystate, T=T)
    checksteadystate(m, f)
    return m
end

"""The nine equilibrium equations, stacked by equation and then by date."""
function f(m::ModelEnv, X, E)
    @unpack K, C, Y, L, G, R, W, A, η = contemp(X, m)
    @unpack C_p, R_p = lead(X, m)
    @unpack K_l, A_l, η_l = lag(X, m)
    @unpack ε_A, ε_η = exogenous(E, m)
    @unpack α, β, γ, δ, ψ, ρ_A, ρ_η = m.par

    return [Y .- A .* K_l.^α .* L.^(1 - α);
            Y .- C .- K .+ (1 - δ) .* K_l .- G;
            A .- (1 - ρ_A) .- ρ_A .* A_l .- ε_A;
            η .- (1 - ρ_η) .- ρ_η .* η_l .- ε_η;
            1 ./ C .- β .* (1 .+ R_p .- δ) ./ C_p;
            W ./ C .- L.^ψ;
            R .- α .* Y ./ K_l;
            W .- (1 - α) .* Y ./ L;
            γ .* η ./ G .- 1 ./ C]
end

"""
    solve(; par=Par(), T=300, shock_size=1.0, shock_date=0, irf_accum=12)

Linear fiscal response to an innovation in η. Dates are zero-based. The
cumulative multiplier is sum(ΔY)/sum(ΔG) over irf_accum quarters starting at
shock_date, without discounting. Unit shocks are a linear normalization.

Xss and Xlin contain steady-state and response levels. dX, response, and
investment contain deviations from steady state. A future-dated innovation
is anticipated from date 0. std_η does not automatically scale the innovation.
"""
function solve(; par::Par=Par(), T::Int=300,
               shock_size::Real=1.0, shock_date::Int=0, irf_accum::Int=12)
    
    # check inputs are valid
    0 <= shock_date < T || throw(ArgumentError("Require 0 ≤ shock_date < T"))
    1 <= irf_accum <= T - shock_date ||
        throw(ArgumentError("Accumulation window must fit within the solution horizon"))
    
    # Model setup
    m = model(par; T=T)
    Xss, E = longsteadystate(m)
    E[first(varindex(:ε_η, m, :exog)) + shock_date] = shock_size

    # Solving
    dX = -(sparse(get_fX(f, m)) \ (get_fE(f, m) * E))
    Xlin = Xss + dX
    response = contemp(dX, m)
    
    # Calculate investment deviations, which were not part of the original system
    # Initial capital is at steady state, hence its initial deviation is zero.
    investment = response.K - (1 - par.δ) * [0.0; response.K[1:end-1]]
    
    # calculate multiplier
    t = shock_date + 1
    window = t:t+irf_accum-1
    total_G = sum(response.G[window])
    cumul_multiplier = iszero(total_G) ? NaN : sum(response.Y[window]) / total_G
    impact_multiplier = iszero(response.G[t]) ? NaN : response.Y[t] / response.G[t]
    
    
    return (; m, Xss, E, Xlin, dX, response, investment, shock_date, irf_accum,
            cumul_multiplier, impact_multiplier)
end

"""Plot all nine level deviations at dates 0 through irf_horizon (inclusive)."""
function plot_response(result; irf_horizon::Int=min(40, result.m.T-1))
    0 <= irf_horizon < result.m.T || throw(ArgumentError("Require 0 ≤ irf_horizon < T"))
    return plot(result.dX, result.m; irf_horizon=irf_horizon)
end

"""Copy a calibration while changing selected parameters."""
function with_parameters(par::Par; kwargs...)
    values = (; (name => getfield(par, name) for name in fieldnames(Par))...)
    return Par(; merge(values, (; kwargs...))...)
end

"""
    multiplier_analysis(; par=Par(), T=300, irf_accum=12,
                        rho_eta=range(0.8, 0.95; length=16), psi=[2.0, 0.5])

Compute the baseline fiscal IRFs and a grid of cumulative multipliers, varying
fiscal persistence ρ_η and inverse Frisch elasticity ψ as in multiplier_analysis.py.
Rows of mults index rho_eta; columns index psi. All other parameters are
inherited from par. Return baseline, rho_eta, psi, and mults.
"""
function multiplier_analysis(; par::Par=Par(), T::Int=300, irf_accum::Int=12,
                             rho_eta=range(0.8, 0.95; length=16), psi=[2.0, 0.5])
    baseline = solve(; par, T, irf_accum)
    rho_eta, psi = collect(rho_eta), collect(psi)
    (isempty(rho_eta) || isempty(psi)) && throw(ArgumentError("Parameter grids must be nonempty"))
    mults = [solve(par=with_parameters(par; ρ_η=r, ψ=p), T=T,
                   irf_accum=irf_accum).cumul_multiplier for r in rho_eta, p in psi]
   
    return (; baseline, rho_eta, psi, mults)
end

"""
Return a periods × 5 matrix of G, Y, C, I, L deviations, starting at shock_date
and divided by ΔG at that date. The impact G response is therefore 1.
The window must fit within the solution horizon and impact ΔG must be nonzero.
"""
function normalized_irfs(result; periods::Int=result.irf_accum)
    t = result.shock_date + 1
    scale = result.response.G[t]
    window = t:t+periods-1
    r = result.response
    return hcat(r.G[window], r.Y[window], r.C[window],
                result.investment[window], r.L[window]) / scale
end

"""
Save figure4_fiscal_mult_irfs.pdf and figure4_fiscal_mult_calibration.pdf in the
results directory beside this script, replacing existing files with those names.
Return both plots and paths.
"""
function save_analysis_figures(analysis)
    result = analysis.baseline
    periods = result.irf_accum
    irfs = normalized_irfs(result)
    p_irfs = Plots.plot(0:periods-1, irfs;
        label=["G" "y" "c" "I" "ℓ"],
        linestyle=[:solid :dash :solid :dash :solid],
        color=[:black :black :gray :gray :darkgray], linewidth=2,
        xlabel="Quarter", ylabel="Deviation from steady state",
        title="Impulse response functions", size=(550, 500))
    p_calibration = Plots.plot(; xlabel="ρ_η", ylabel="Fiscal multiplier",
        title="Cumulative fiscal multiplier over $periods quarters", size=(550, 500))
    for (j, p) in enumerate(analysis.psi)
        Plots.plot!(p_calibration, analysis.rho_eta, analysis.mults[:, j];
                    label="ψ = $p", color=:black, linewidth=2,
                    linestyle=isodd(j) ? :solid : :dash)
    end
    results_dir = joinpath(@__DIR__, "results")
    mkpath(results_dir)
    irf_path = joinpath(results_dir, "figure4_fiscal_mult_irfs.pdf")
    calibration_path = joinpath(results_dir, "figure4_fiscal_mult_calibration.pdf")
    Plots.savefig(p_irfs, irf_path)
    Plots.savefig(p_calibration, calibration_path)
    return (; p_irfs, p_calibration, irf_path, calibration_path)
end




#------------- Main script ----------------
analysis = multiplier_analysis()
println("Cumulative fiscal multiplier over 12 quarters = ", analysis.baseline.cumul_multiplier)
figures = save_analysis_figures(analysis)
println("Saved ", figures.irf_path, " and ", figures.calibration_path)
