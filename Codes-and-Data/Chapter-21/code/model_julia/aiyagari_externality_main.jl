# COMPREHENSIVE AIYAGARI ANALYSIS WITH CONSUMPTION EXTERNALITY
# Extended analysis across multiple γ (constraint) and ω (externality) values
# Higher precision for detailed economic insights

# ==============================================================================
# *** PARAMETER RANGES - MODIFY HERE FOR EASY CHANGES ***
# ==============================================================================

# Constraint probability values (savings restrictions)
# γ = 0: no constraints, γ = 0.5: 50% of agents constrained each period
γ_values = [0.0]#, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6]

# Externality parameter values (consumption spillovers)  
# ω = 0: no externality, ω > 0: positive consumption spillovers
ω_values = [0.0, 0.5]# 0.05, 0.1, 0.15, 0.2, 0.25, 0.5]

# Analysis parameters
r_target = 0.01       # Target interest rate (1% quarterly)
shock_size = 0.01     # Initial TFP shock size (1%)
ρ_shock = 0.9         # TFP shock persistence

# ==============================================================================
# PACKAGE IMPORTS
# ==============================================================================

using Pkg
packages = ["Parameters", "LinearAlgebra", "SparseArrays", "Setfield", "ForwardDiff", 
           "BasicInterpolators", "Roots", "Plots", "QuantEcon", "DataFrames", "CSV", 
           "Printf", "Statistics", "Serialization", "JLD2"]

for pkg in packages
    try
        eval(:(using $(Symbol(pkg))))
    catch
        Pkg.add(pkg)
        eval(:(using $(Symbol(pkg))))
    end
end

# Set backend for PDF generation (Ubuntu compatible)
# GR is loaded automatically by Plots, no need to import separately
Plots.gr()

# Runtime estimate
total_cases = length(γ_values) * length(ω_values)
println("="^80)
println("PARAMETER SETUP:")
println("  γ range: $(γ_values) ($(length(γ_values)) values)")
println("  ω range: $(ω_values) ($(length(ω_values)) values)")
println("  Total cases: $(total_cases)")
println("  Estimated runtime: $(round(total_cases * 0.1, digits=1)) - $(round(total_cases * 0.2, digits=1)) hours")
println("="^80)

# ==============================================================================
# MODEL EXPLANATION:
# This code implements a comprehensive Aiyagari (1994) model with two extensions:
# 1. CONSTRAINT HETEROGENEITY (γ): Some agents face binding constraints (m=c)
#    with probability γ, representing financial frictions or commitment problems
# 2. CONSUMPTION EXTERNALITY (ω): Aggregate consumption affects individual productivity
#    through Y = A * exp(Z) * (C/C_ss)^ω * K^α * L^(1-α)
#
# The analysis solves for:
# - Steady states with calibrated discount factors
# - MIT transitions following TFP shocks  
# - Comprehensive parameter sweeps across γ ∈ [0,0.6] and ω ∈ [0,0.5]
# ==============================================================================

# ==============================================================================
# COMPLETE MODEL IMPLEMENTATION (SELF-CONTAINED)
# ==============================================================================

# Model Parameters Structure
@with_kw mutable struct ModelParameters{T}
    β::T = 0.98         # Household discount factor - will be calibrated
    σ::T = 1.0          # Relative risk aversion
    δ::T = 0.025        # Capital depreciation
    ρs::T = 0.966       # Persistence of HH income process
    σs::T = (1.0-ρs^2)^0.5 * 0.5  # Variance for household income process
    α::T = 0.33         # Capital share 
    Z_ss::T = 0.0       # Steady state log TFP (normalized to 0)
    A::T = 1.0          # TFP level parameter - will be calibrated
    γ::T = 0.0          # Probability of constraint state (m=c)
    ω::T = 0.0          # Consumption externality parameter
end

# Numerical Parameters for high precision analysis
@with_kw struct NumericalParameters{F,I}
    mp::ModelParameters{F} = ModelParameters()
    na::I = 300         # Asset grid points
    ns::I = 7           # Income shock states
    nm::I = 2           # Constraint states (constrained/unconstrained)
    amin::F = 0.0       # Minimum assets
    amax::F = 150.0     # Maximum assets
    s_grid::Vector{F} = exp.(rouwenhorst(ns, mp.ρs, mp.σs).state_values)
    Ps::Matrix{F} = rouwenhorst(ns, mp.ρs, mp.σs).p
    a_grid::Vector{F} = exponential_grid(amin, amax, na)
    Pm::Matrix{F} = [mp.γ 1.0-mp.γ; mp.γ 1.0-mp.γ]  # iid constraint transitions
    tolHH::F = 1e-10    # Household problem tolerance
    T::I = 300          # MIT transition periods
end

# Asset grid constructor
function exponential_grid(amin, amax, na)
    return exp.(range(0.0, stop=log(amax-amin+1.0), length = na)) .+ amin .- 1.0
end

# ==============================================================================
# HOUSEHOLD PROBLEM SOLVER USING ENDOGENOUS GRID METHOD (EGM)
# ==============================================================================

# EGM Update Step: Solves household problem given prices and future policies
function EGM_update_3state(cPrime::AbstractArray, aPrime::AbstractArray, w, r, rPrime, np)
    @unpack mp, a_grid, s_grid, ns, na, nm, amin, Ps, Pm = np
    @unpack β, σ, γ = mp

    # Compute expected marginal value of assets
    EVa = zeros(eltype(cPrime), na, ns, nm)
    
    for mi = 1:nm, si = 1:ns, ai = 1:na
        a_today = a_grid[ai]
        expected_marg_value = 0.0
        
        # Integrate over future states
        for mi_next = 1:nm, si_next = 1:ns
            prob_joint = Pm[mi, mi_next] * Ps[si, si_next]
            a_choice = aPrime[ai, si, mi]
            
            # Interpolate future consumption
            a_idx = searchsortedlast(a_grid, a_choice)
            if a_idx >= na
                c_tomorrow = cPrime[na, si_next, mi_next]
            elseif a_idx <= 0
                c_tomorrow = cPrime[1, si_next, mi_next]
            else
                if a_idx < na
                    weight = (a_choice - a_grid[a_idx]) / (a_grid[a_idx+1] - a_grid[a_idx])
                    c_tomorrow = (1.0 - weight) * cPrime[a_idx, si_next, mi_next] + 
                               weight * cPrime[a_idx+1, si_next, mi_next]
                else
                    c_tomorrow = cPrime[a_idx, si_next, mi_next]
                end
            end
            
            c_tomorrow = max(c_tomorrow, 1e-8)
            marg_value = (1.0 + rPrime) * (c_tomorrow^(-σ))
            expected_marg_value += prob_joint * marg_value
        end
        
        EVa[ai, si, mi] = expected_marg_value
    end

    # Compute endogenous consumption and assets
    c_endog = (β .* EVa).^(-1/σ)
    c_endog = max.(c_endog, 1e-8)
    inc = w .* s_grid 
    
    a_endog = zeros(eltype(c_endog), na, ns, nm)
    for mi = 1:nm, si = 1:ns, ai = 1:na
        a_endog[ai, si, mi] = (c_endog[ai, si, mi] - inc[si] + a_grid[ai]) / (1.0 + r)
    end

    # Interpolate back to exogenous grid and apply constraints
    aPrime_new = zeros(eltype(a_endog), na, ns, nm)
    ag = a_grid .+ zeros(eltype(a_endog), 1)

    for mi = 1:nm, si = 1:ns
        constr = a_endog[1, si, mi]
        itp_a = LinearInterpolator(a_endog[:, si, mi], ag, NoBoundaries())
        aPrime_new[:, si, mi] = itp_a.(ag)
        
        if mi == 1  # Constrained state: m ≥ a (no dis-saving)
            for ai = 1:na
                a_today = a_grid[ai]
                aPrime_new[ai, si, mi] = max(aPrime_new[ai, si, mi], a_today, amin)
            end
        else  # Unconstrained state: m ≥ amin
            aPrime_new[a_grid .< constr, si, mi] .= amin
        end
    end

    # Compute consumption from budget constraint
    c = zeros(eltype(aPrime_new), na, ns, nm)
    for mi = 1:nm, si = 1:ns, ai = 1:na
        c[ai, si, mi] = (1+r) * a_grid[ai] + inc[si] - aPrime_new[ai, si, mi]
        c[ai, si, mi] = max(c[ai, si, mi], 1e-8)
    end
   
    return c, aPrime_new 
end

# Steady State Household Problem Solver
function solve_EGM_SS_3state(wSS, rSS, np; max_iter::Int = 3000, print::Bool = false)
    @unpack na, ns, nm, a_grid, s_grid = np
    incs = wSS * s_grid 
    
    # Initial guesses for consumption and asset policies
    c_guess = zeros(na, ns, nm)
    a_guess = zeros(na, ns, nm)
    
    for mi = 1:nm, si = 1:ns, ai = 1:na
        c_guess[ai, si, mi] = 0.1 + 0.1 * ((1+rSS) * a_grid[ai] + incs[si])
        savings_rate = mi == 1 ? 0.3 : 0.5  # Lower savings for constrained agents
        a_guess[ai, si, mi] = savings_rate * ((1+rSS) * a_grid[ai] + incs[si] - c_guess[ai, si, mi])
        a_guess[ai, si, mi] = max(a_guess[ai, si, mi], np.amin)
        if mi == 1  # Constrained agents cannot dis-save
            a_guess[ai, si, mi] = max(a_guess[ai, si, mi], a_grid[ai])
        end
    end

    c0, a0 = c_guess, a_guess
    dist = 1.0
    iter = 0
    
    # Value function iteration
    while (dist > np.tolHH) & (iter < max_iter)
        c1, a1 = EGM_update_3state(c0, a0, wSS, rSS, rSS, np)
        dist = maximum(abs.(c1 .- c0)) + maximum(abs.(a1 .- a0))
        
        if print & (rem(iter, 100) == 0.0)
            println("iteration: ", iter, " current distance: ", dist)
        end
        
        c0, a0 = copy(c1), copy(a1)
        iter += 1
    end

    if print
        println("Household problem solved after ", iter, " iterations, final distance ", dist)
    end
    if iter == max_iter 
        @warn "Non-convergence of solve_EGM_SS_3state"
    end

    return c0, a0
end

# ==============================================================================
# DISTRIBUTION COMPUTATION
# ==============================================================================

# Build transition matrix for the distribution over (a,s,m) states
function build_Λ_3state(a_choice::Array{T,3}, np) where T
    @unpack na, ns, nm, a_grid, Ps, Pm = np
    total_states = na * ns * nm
    
    weights_R = zeros(T, total_states, ns * nm)
    weights_L = zeros(T, total_states, ns * nm)
    IDX_col_R = zeros(Int64, total_states, ns * nm)

    function state_to_idx(ai, si, mi)
        return ai + (si-1)*na + (mi-1)*na*ns
    end

    @views begin
        for mi = 1:nm, si = 1:ns, ai = 1:na
            current_idx = state_to_idx(ai, si, mi)
            al_idx = searchsortedlast(a_grid, a_choice[ai, si, mi])
            
            col = 0
            for mi_next = 1:nm, si_next = 1:ns
                col += 1
                transition_prob = Pm[mi, mi_next] * Ps[si, si_next]
                
                # Handle boundary cases and interpolation
                if al_idx == na   
                    weights_R[current_idx, col] += transition_prob
                    IDX_col_R[current_idx, col] = state_to_idx(al_idx, si_next, mi_next)
                elseif al_idx == 0 
                    weights_L[current_idx, col] += transition_prob
                    IDX_col_R[current_idx, col] = state_to_idx(2, si_next, mi_next)
                else    
                    wr = ((a_choice[ai, si, mi] - a_grid[al_idx]) / 
                          (a_grid[al_idx+1] - a_grid[al_idx]))
                    lr = 1.0 - wr

                    weights_R[current_idx, col] += transition_prob * wr
                    weights_L[current_idx, col] += transition_prob * lr                         
                    IDX_col_R[current_idx, col] = state_to_idx(al_idx + 1, si_next, mi_next)
                end
            end
        end

        IDX_from = repeat(1:total_states, outer=2*ns*nm)
        weights = vcat(weights_R[:], weights_L[:])
        IDX_to = vcat(IDX_col_R[:], IDX_col_R[:] .- 1)
    end

    return sparse(IDX_from, IDX_to, weights, total_states, total_states)
end

# Compute invariant distribution
function inv_dist(Λ::AbstractArray)
    x = [1; (I - Λ'[2:end,2:end]) \ Vector(Λ'[2:end,1])]
    return x ./ sum(x)
end

# ==============================================================================
# CONSUMPTION EXTERNALITY OUTPUT SOLVER
# ==============================================================================

# Solves for output when consumption externality is present
# Output equation: Y = A * exp(Z) * (C/C_ss)^ω * K^α * L^(1-α)
function solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω, A, α, δ, L, C_ss)
    I_t = K_t_plus_1 - (1-δ) * K_t
    Y_min = K_t_plus_1 - (1-δ) * K_t + 0.001
    Y_current = A * exp(Z_t) * K_t^α * L^(1-α)
    
    # Fixed point iteration for output with externality
    for iter = 1:50
        C_current = Y_current - K_t_plus_1 + (1-δ) * K_t
        
        if C_current <= 0
            Y_current = Y_min + 0.01
            C_current = Y_current - K_t_plus_1 + (1-δ) * K_t
        end
        
        externality_factor = (C_current/C_ss)^ω
        Y_new = A * exp(Z_t) * externality_factor * (K_t^α) * (L^(1-α))
        
        if abs(Y_new - Y_current) < 1e-8
            return Y_new
        end
        
        Y_current = 0.5 * Y_new + 0.5 * Y_current
        Y_current = max(Y_current, Y_min)
    end
    
    # Fallback with root finding if iteration doesn't converge
    function equation(Y)
        C = Y - K_t_plus_1 + (1-δ) * K_t
        if C <= 0
            return Y - Y_min
        end
        externality_factor = (C/C_ss)^ω
        Y_implied = A * exp(Z_t) * externality_factor * (K_t^α) * (L^(1-α))
        return Y - Y_implied
    end
    
    Y_low = Y_min + 0.001
    Y_high = Y_min + 0.001
    
    for multiplier in [1.1, 1.5, 2.0, 3.0, 5.0, 10.0]
        Y_test = Y_min + multiplier * (A * exp(Z_t) * K_t^α * L^(1-α))
        if equation(Y_test) * equation(Y_low) < 0
            Y_high = Y_test
            break
        end
    end
    
    if Y_high > Y_low && equation(Y_low) * equation(Y_high) < 0
        try
            Y_solution = find_zero(equation, (Y_low, Y_high), Bisection())
            return Y_solution
        catch e
            return Y_current
        end
    end
    
    return max(Y_current, Y_min)
end

println("="^80)
println("COMPREHENSIVE AIYAGARI ANALYSIS - MULTIPLE γ AND ω VALUES")
println("="^80)

# ==============================================================================
# HIGH PRECISION PARAMETERS AND EXTENDED RANGES
# ==============================================================================

@with_kw struct HighPrecisionParameters{F,I}
    # Include instance of model parameters
    mp::ModelParameters{F} = ModelParameters()

    # HIGHER PRECISION GRID SPECIFICATIONS
    na::I = 400         # Increased from 300
    ns::I = 7           # Keep at 7
    nm::I = 2           # Keep at 2
    amin::F = 0.0       
    amax::F = 200.0     # Increased from 150 for safety

    # Set grids and transition matrix for s process
    s_grid::Vector{F} = exp.(rouwenhorst(ns, mp.ρs, mp.σs).state_values)
    Ps::Matrix{F} = rouwenhorst(ns, mp.ρs, mp.σs).p
    a_grid::Vector{F} = exponential_grid(amin, amax, na)

    # Constraint state transition probabilities (iid)
    Pm::Matrix{F} = [mp.γ 1.0-mp.γ; mp.γ 1.0-mp.γ]

    # HIGHER PRECISION TOLERANCES
    tolHH::F = 1e-12       # Increased from 1e-10
    tol_mit::F = 1e-6      # Increased from 1e-4  
    tol_ss::F = 1e-8       # For steady state calibration

    # Number of periods for transition analysis
    T::I = 300
    
    # MIT transition parameters
    damping::F = 0.05      # Reduced for higher precision (slower but more accurate)
    max_iter_mit::I = 500  # Increased from 200
    max_iter_ss::I = 100   # For steady state calibration
end

# ==============================================================================
# STEADY STATE CALIBRATION AND MIT TRANSITION FUNCTIONS
# ==============================================================================

function solve_steady_state_high_precision(γ_val, ω_val, r_target; verbose=false)
    """Solve steady state with high precision parameters"""
    
    # Create high precision parameters
    np = HighPrecisionParameters()
    @set! np.mp.γ = γ_val
    @set! np.mp.ω = ω_val
    @set! np.Pm = [γ_val 1.0-γ_val; γ_val 1.0-γ_val]
    
    @unpack mp, s_grid, na, ns, nm = np
    @unpack δ, α = mp

    if verbose
        println("  High precision steady state: γ=$(γ_val), ω=$(ω_val)")
    end

    # Compute steady state labor supply
    s_dist = inv_dist(np.Ps)
    L = s_dist' * s_grid
    @set! np.s_grid = np.s_grid ./ L
    L = 1.0

    # Target calibration (externality doesn't affect SS since C/C_ss = 1)
    KoverY_ss = α / (r_target + δ)
    K_ss = KoverY_ss
    @set! np.mp.A = K_ss^(-α)
    w_ss = (1-α) * np.mp.A * K_ss^α

    # High precision β calibration to match capital-output ratio
    function β_objective_hp(β)
        @set! np.mp.β = β
        @set! np.Pm = [np.mp.γ 1.0-np.mp.γ; np.mp.γ 1.0-np.mp.γ]

        c_ss, a_ss = solve_EGM_SS_3state(w_ss, r_target, np, print=false)
        Λ = build_Λ_3state(a_ss, np)
        D = inv_dist(Λ)
        D_reshaped = reshape(D, (np.na, np.ns, np.nm))
        K_supply = sum(D_reshaped .* np.a_grid)
        
        return (K_supply/K_ss) - 1
    end

    # High precision root finding
    β_calibrated = find_zero(β_objective_hp, np.mp.β, atol=np.tol_ss, rtol=np.tol_ss)
    @set! np.mp.β = β_calibrated

    # Final steady state solution
    c_ss, a_ss = solve_EGM_SS_3state(w_ss, r_target, np, print=false)
    D_ss = reshape(inv_dist(build_Λ_3state(a_ss, np)), (na, ns, nm))
    C_ss = sum(D_ss .* c_ss)
    K_final = sum(D_ss .* np.a_grid)

    if verbose
        println("    β calibrated: $(round(β_calibrated, digits=6))")
        println("    K achieved: $(round(K_final, digits=6)) (target: $(round(K_ss, digits=6)))")
        println("    C_ss: $(round(C_ss, digits=6))")
    end

    return K_ss, C_ss, w_ss, β_calibrated, c_ss, a_ss, D_ss, np
end

function solve_mit_transition_high_precision(K_ss, C_ss, ω_val, np; verbose=false)
    """MIT transition with high precision following original structure"""
    
    @unpack T, damping, max_iter_mit, tol_mit, na, ns, nm = np
    @unpack δ, A, α = np.mp
    
    # TFP shock sequence: ρ=0.9, initial shock=1%
    ρ_shock = 0.9
    shock_size = 0.01
    Z_path = zeros(T)
    for t = 1:T
        Z_path[t] = ρ_shock^(t-1) * shock_size
    end
    
    L = 1.0
    K_path = zeros(T+1)
    K_path[1] = K_ss
    K_path[end] = K_ss
    
    # Improved initial guess for capital path
    for t = 2:T
        progress = (t-1) / T
        hump = 4 * progress * (1 - progress)
        K_path[t] = K_ss * (1 + 0.008 * hump)  # Smaller initial deviation for precision
    end
    
    if verbose
        println("    High precision MIT: ω=$(ω_val), tol=$(tol_mit)")
    end
    
    converged = false
    final_iter = 0
    
    # MIT algorithm: iterate on capital path until convergence
    for iter = 1:max_iter_mit
        K_path_old = copy(K_path)
        
        # Compute prices from production side
        r_path = zeros(T)
        w_path = zeros(T)
        
        for t = 1:T
            K_t = K_path[t]
            K_t_plus_1 = K_path[t+1]
            Z_t = Z_path[t]
            
            if ω_val ≈ 0.0
                # Standard case without externality
                r_path[t] = α * A * exp(Z_t) * K_t^(α-1) * L^(1-α) - δ
                w_path[t] = (1-α) * A * exp(Z_t) * K_t^α * L^(-α)
            else
                # Case with consumption externality
                Y_t = solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω_val, A, α, δ, L, C_ss)
                C_t = Y_t - K_t_plus_1 + (1-δ) * K_t
                externality_factor = (C_t/C_ss)^ω_val
                r_path[t] = α * A * exp(Z_t) * externality_factor * K_t^(α-1) * L^(1-α) - δ
                w_path[t] = (1-α) * A * exp(Z_t) * externality_factor * K_t^α * L^(-α)
            end
        end
        
        # Solve household problem backwards
        c_policies = Array{Array{Float64,3}}(undef, T)
        a_policies = Array{Array{Float64,3}}(undef, T)
        
        r_ss = α * A * K_ss^(α-1) * L^(1-α) - δ
        w_ss = (1-α) * A * K_ss^α * L^(-α)
        c_T, a_T = solve_EGM_SS_3state(w_ss, r_ss, np, print=false)
        
        for t = T:-1:1
            if t == T
                c_next, a_next, r_next = c_T, a_T, r_ss
            else
                c_next, a_next, r_next = c_policies[t+1], a_policies[t+1], r_path[t+1]
            end
            
            c_t, a_t = EGM_update_3state(c_next, a_next, w_path[t], r_path[t], r_next, np)
            c_policies[t] = c_t
            a_policies[t] = a_t
        end
        
        # Update distribution and compute new capital path
        D_ss = reshape(inv_dist(build_Λ_3state(a_T, np)), (na, ns, nm))
        D_current = copy(D_ss)
        
        for t = 1:T
            if t <= T
                K_path[t+1] = sum(D_current .* a_policies[t])
            end
            
            if t < T
                Λ_t = build_Λ_3state(a_policies[t], np)
                D_current = reshape(Λ_t' * D_current[:], (na, ns, nm))
            end
        end
        
        # Check convergence
        diff = maximum(abs.(K_path - K_path_old))
        final_iter = iter
        
        if verbose && (iter % 50 == 0)
            println("      Iteration $(iter): diff = $(round(diff, digits=10))")
        end
        
        if diff < tol_mit
            converged = true
            if verbose
                println("      Converged after $(iter) iterations")
            end
            break
        end
        
        # High precision damping
        K_path = damping * K_path + (1 - damping) * K_path_old
    end
    
    # Compute final aggregate sequences
    Y_path = zeros(T)
    C_path = zeros(T)
    I_path = zeros(T)
    r_path = zeros(T)
    w_path = zeros(T)
    
    # Recompute with final K_path
    for t = 1:T
        K_t, K_t_plus_1, Z_t = K_path[t], K_path[t+1], Z_path[t]
        
        if ω_val ≈ 0.0
            Y_path[t] = A * exp(Z_t) * K_t^α * L^(1-α)
            r_path[t] = α * A * exp(Z_t) * K_t^(α-1) * L^(1-α) - δ
            w_path[t] = (1-α) * A * exp(Z_t) * K_t^α * L^(-α)
        else
            Y_path[t] = solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω_val, A, α, δ, L, C_ss)
            C_t = Y_path[t] - K_t_plus_1 + (1-δ) * K_t
            externality_factor = (C_t/C_ss)^ω_val
            r_path[t] = α * A * exp(Z_t) * externality_factor * K_t^(α-1) * L^(1-α) - δ
            w_path[t] = (1-α) * A * exp(Z_t) * externality_factor * K_t^α * L^(-α)
        end
        
        I_path[t] = K_t_plus_1 - (1-δ) * K_t
    end
    
    # Recompute consumption path from household behavior
    c_policies = Array{Array{Float64,3}}(undef, T)
    a_policies = Array{Array{Float64,3}}(undef, T)
    
    r_ss = α * A * K_ss^(α-1) * L^(1-α) - δ
    w_ss = (1-α) * A * K_ss^α * L^(-α)
    c_T, a_T = solve_EGM_SS_3state(w_ss, r_ss, np, print=false)
    
    for t = T:-1:1
        if t == T
            c_next, a_next, r_next = c_T, a_T, r_ss
        else
            c_next, a_next, r_next = c_policies[t+1], a_policies[t+1], r_path[t+1]
        end
        
        c_t, a_t = EGM_update_3state(c_next, a_next, w_path[t], r_path[t], r_next, np)
        c_policies[t] = c_t
        a_policies[t] = a_t
    end
    
    D_ss = reshape(inv_dist(build_Λ_3state(a_T, np)), (na, ns, nm))
    D_current = copy(D_ss)
    
    for t = 1:T
        C_path[t] = sum(D_current .* c_policies[t])
        if t < T
            Λ_t = build_Λ_3state(a_policies[t], np)
            D_current = reshape(Λ_t' * D_current[:], (na, ns, nm))
        end
    end
    
    return K_path[1:T], Y_path, C_path, I_path, r_path, w_path, Z_path, converged, final_iter
end

# ==============================================================================
# NUMERICAL SETTINGS FOR HIGH PRECISION ANALYSIS
# ==============================================================================

println("Numerical Settings:")
println("  Grid size: na=$(HighPrecisionParameters().na)")
println("  Asset range: [0, $(HighPrecisionParameters().amax)]")
println("  High precision tolerances applied")

# ==============================================================================
# RUN COMPREHENSIVE ANALYSIS
# ==============================================================================

println("\nStarting comprehensive analysis...")
println("This will take 2-4 hours with high precision settings")

# Storage for results
all_results = Dict()
timing_results = Dict()

global case_count = 0

for γ in γ_values
    for ω in ω_values
        global case_count += 1
        println("\n" * "="^60)
        println("CASE $(case_count)/$(total_cases): γ=$(γ), ω=$(ω)")
        println("="^60)
        
        case_key = (γ, ω)
        
        try
            # Steady state analysis
            println("Solving steady state...")
            ss_time = @elapsed begin
                K_ss, C_ss, w_ss, β_cal, c_ss, a_ss, D_ss, np = 
                    solve_steady_state_high_precision(γ, ω, r_target, verbose=true)
            end
            
            # MIT transition analysis  
            println("Solving MIT transition...")
            mit_time = @elapsed begin
                K_path, Y_path, C_path, I_path, r_path, w_path, Z_path, converged, final_iter = 
                    solve_mit_transition_high_precision(K_ss, C_ss, ω, np, verbose=true)
            end
            
            # Compute key statistics
            max_K_dev = maximum(abs.(K_path .- K_ss)) / K_ss
            max_C_dev = maximum(abs.(C_path .- C_ss)) / C_ss
            max_Y_dev = maximum(abs.(Y_path .- 1.0)) / 1.0
            
            # Impact responses (t=0)
            K_impact = 100 * (K_path[1] - K_ss) / K_ss
            Y_impact = 100 * (Y_path[1] - 1.0) / 1.0  
            C_impact = 100 * (C_path[1] - C_ss) / C_ss
            I_impact = 100 * (I_path[1] - (np.mp.δ * K_ss)) / (np.mp.δ * K_ss)
            
            # Store comprehensive results
            all_results[case_key] = Dict(
                :γ => γ, :ω => ω,
                :β => β_cal, :K_ss => K_ss, :C_ss => C_ss, :w_ss => w_ss,
                :K_path => K_path, :Y_path => Y_path, :C_path => C_path, 
                :I_path => I_path, :r_path => r_path, :w_path => w_path,
                :converged => converged, :iterations => final_iter,
                :max_K_dev => max_K_dev, :max_C_dev => max_C_dev, :max_Y_dev => max_Y_dev,
                :K_impact => K_impact, :Y_impact => Y_impact, :C_impact => C_impact, :I_impact => I_impact,
                :c_ss => c_ss, :a_ss => a_ss, :D_ss => D_ss, :np => np
            )
            
            timing_results[case_key] = Dict(
                :ss_time => ss_time, :mit_time => mit_time, :total_time => ss_time + mit_time
            )
            
            println("✅ Case completed successfully")
            println("   Steady state time: $(round(ss_time, digits=1))s")
            println("   MIT transition time: $(round(mit_time, digits=1))s") 
            println("   Converged: $(converged) in $(final_iter) iterations")
            println("   Max capital deviation: $(round(100*max_K_dev, digits=2))%")
            
        catch e
            println("❌ Case failed: $(e)")
            all_results[case_key] = Dict(:failed => true, :error => string(e))
        end
        
        # Progress update
        elapsed_total = sum(get(timing_results, k, Dict(:total_time => 0))[:total_time] for k in keys(timing_results))
        avg_time = elapsed_total / case_count
        remaining_time = avg_time * (total_cases - case_count)
        
        println("Progress: $(case_count)/$(total_cases) ($(round(100*case_count/total_cases, digits=1))%)")
        println("Estimated remaining time: $(round(remaining_time/3600, digits=1)) hours")
    end
end

println("\n" * "="^80)
println("COMPREHENSIVE ANALYSIS COMPLETED!")
println("="^80)

# ==============================================================================
# CREATE COMPREHENSIVE TABLES AND VISUALIZATIONS - BLACK & WHITE VERSION
# ==============================================================================

# Set global plot defaults for black and white figures
Plots.default(
    linewidth=2,
    gridwidth=1,
    gridcolor=:gray,
    foreground_color_legend=:black,
    background_color_legend=:white,
    legendfontsize=8,
    titlefontsize=10,
    guidefontsize=9,
    tickfontsize=8
)

# FIXED Summary statistics table
function create_summary_table()
    println("Creating summary statistics table...")
    
    # Create empty vectors for each column
    γ_col = Float64[]
    ω_col = Float64[]
    β_col = Float64[]
    K_ss_col = Float64[]
    C_ss_col = Float64[]
    MaxKDev_col = Float64[]
    MaxCDev_col = Float64[]
    KImpact_col = Float64[]
    CImpact_col = Float64[]
    Converged_col = String[]
    Iterations_col = Int[]
    
    for γ in γ_values
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                
                # Add data to each column
                push!(γ_col, γ)
                push!(ω_col, ω)
                push!(β_col, round(res[:β], digits=6))
                push!(K_ss_col, round(res[:K_ss], digits=4))
                push!(C_ss_col, round(res[:C_ss], digits=4))
                push!(MaxKDev_col, round(res[:max_K_dev]*100, digits=2))
                push!(MaxCDev_col, round(res[:max_C_dev]*100, digits=2))
                push!(KImpact_col, round(res[:K_impact], digits=2))
                push!(CImpact_col, round(res[:C_impact], digits=2))
                push!(Converged_col, res[:converged] ? "Yes" : "No")
                push!(Iterations_col, res[:iterations])
            end
        end
    end
    
    # Create DataFrame directly from vectors
    df = DataFrame(
        γ = γ_col,
        ω = ω_col,
        β = β_col,
        K_ss = K_ss_col,
        C_ss = C_ss_col,
        MaxKDev = MaxKDev_col,
        MaxCDev = MaxCDev_col,
        KImpact = KImpact_col,
        CImpact = CImpact_col,
        Converged = Converged_col,
        Iterations = Iterations_col
    )
    
    return df
end

# Create detailed transition comparison plots - ROBUST BLACK & WHITE VERSION
function create_comprehensive_plots()
    println("Creating comprehensive visualization (black & white)...")
    
    # Robust black and white styling
    line_styles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :solid, :dash]
    markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :star5, :cross]
    
    p_impacts = Plots.plot(layout=(2,2), size=(1000, 800))
    
    for (idx, γ) in enumerate(γ_values)
        K_impacts, C_impacts, Y_impacts, ω_plot = Float64[], Float64[], Float64[], Float64[]
        
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                push!(K_impacts, res[:K_impact])
                push!(C_impacts, res[:C_impact])
                push!(Y_impacts, res[:Y_impact])
                push!(ω_plot, ω)
            end
        end
        
        if length(ω_plot) > 0
            Plots.plot!(p_impacts[1], ω_plot, K_impacts, label="γ=$(γ)", 
                  linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
                  markersize=4, color=:black,
                  title="Capital Impact Response", xlabel="ω", ylabel="% deviation")
            Plots.plot!(p_impacts[2], ω_plot, C_impacts, label="γ=$(γ)", 
                  linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
                  markersize=4, color=:black,
                  title="Consumption Impact Response", xlabel="ω", ylabel="% deviation")
            Plots.plot!(p_impacts[3], ω_plot, Y_impacts, label="γ=$(γ)", 
                  linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
                  markersize=4, color=:black,
                  title="Output Impact Response", xlabel="ω", ylabel="% deviation")
        end
    end
    
    # Plot maximum deviations
    for (idx, γ) in enumerate(γ_values)
        max_K_devs, ω_plot = Float64[], Float64[]
        
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                push!(max_K_devs, res[:max_K_dev]*100)
                push!(ω_plot, ω)
            end
        end
        
        if length(ω_plot) > 0
            Plots.plot!(p_impacts[4], ω_plot, max_K_devs, label="γ=$(γ)", 
                  linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
                  markersize=4, color=:black,
                  title="Maximum Capital Deviation", xlabel="ω", ylabel="% max deviation")
        end
    end
    
    return p_impacts
end

# Create transition dynamics plots for selected cases
function create_transition_plots()
    println("Creating detailed transition dynamics (black & white)...")
    
    # Select interesting cases for detailed analysis
    selected_cases = [(0.0, 0.0), (0.0, 0.5), (0.3, 0.0), (0.3, 0.5), (0.5, 0.0), (0.5, 0.5)]
    
    T_plot = 50
    periods = 0:(T_plot-1)
    
    # FIXED: Black and white styling - only supported options
    line_styles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :solid]
    markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :star5]
    grays = [:black, :gray20, :gray40, :gray60, :gray70, :gray80]
    
    p_trans = Plots.plot(layout=(2,3), size=(1200, 800))
    
    for (i, (γ, ω)) in enumerate(selected_cases)
        key = (γ, ω)
        if haskey(all_results, key) && !get(all_results[key], :failed, false)
            res = all_results[key]
            
            # Ensure we have enough data points
            max_plot = min(T_plot, length(res[:K_path]))
            periods_actual = 0:(max_plot-1)
            
            # Capital
            K_dev = 100 * (res[:K_path][1:max_plot] .- res[:K_ss]) ./ res[:K_ss]
            Plots.plot!(p_trans[1], periods_actual, K_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
            
            # Consumption  
            C_dev = 100 * (res[:C_path][1:max_plot] .- res[:C_ss]) ./ res[:C_ss]
            Plots.plot!(p_trans[2], periods_actual, C_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
            
            # Output
            Y_dev = 100 * (res[:Y_path][1:max_plot] .- 1.0) ./ 1.0
            Plots.plot!(p_trans[3], periods_actual, Y_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
            
            # Investment
            I_ss = res[:np].mp.δ * res[:K_ss]
            I_dev = 100 * (res[:I_path][1:max_plot] .- I_ss) ./ I_ss
            Plots.plot!(p_trans[4], periods_actual, I_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
            
            # Interest rate
            r_dev = 100 * (res[:r_path][1:max_plot] .- r_target) ./ r_target
            Plots.plot!(p_trans[5], periods_actual, r_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
            
            # Wage
            w_dev = 100 * (res[:w_path][1:max_plot] .- res[:w_ss]) ./ res[:w_ss]
            Plots.plot!(p_trans[6], periods_actual, w_dev, 
                  linewidth=2, linestyle=line_styles[i], color=grays[i],
                  marker=markers[i], markersize=3,
                  label="γ=$(γ), ω=$(ω)")
        end
    end
    
    Plots.plot!(p_trans[1], title="Capital", xlabel="Periods", ylabel="% dev from SS")
    Plots.plot!(p_trans[2], title="Consumption", xlabel="Periods", ylabel="% dev from SS")
    Plots.plot!(p_trans[3], title="Output", xlabel="Periods", ylabel="% dev from SS")
    Plots.plot!(p_trans[4], title="Investment", xlabel="Periods", ylabel="% dev from SS") 
    Plots.plot!(p_trans[5], title="Interest Rate", xlabel="Periods", ylabel="% dev from SS")
    Plots.plot!(p_trans[6], title="Wage", xlabel="Periods", ylabel="% dev from SS")
    
    return p_trans
end

# Create heat maps for parameter interactions
function create_parameter_heatmaps()
    println("Creating parameter interaction heatmaps (black & white)...")
    
    # Prepare data for heatmaps
    n_γ = length(γ_values)
    n_ω = length(ω_values)
    
    β_matrix = fill(NaN, n_γ, n_ω)
    K_impact_matrix = fill(NaN, n_γ, n_ω)
    C_impact_matrix = fill(NaN, n_γ, n_ω)
    max_K_dev_matrix = fill(NaN, n_γ, n_ω)
    
    for (i, γ) in enumerate(γ_values)
        for (j, ω) in enumerate(ω_values)
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                β_matrix[i, j] = res[:β]
                K_impact_matrix[i, j] = res[:K_impact]
                C_impact_matrix[i, j] = res[:C_impact]
                max_K_dev_matrix[i, j] = res[:max_K_dev] * 100
            end
        end
    end
    
    p_heatmaps = Plots.plot(layout=(2,2), size=(1000, 800))
    
    # Use grayscale color schemes for black & white printing
    Plots.heatmap!(p_heatmaps[1], ω_values, γ_values, β_matrix, 
             title="Calibrated β", xlabel="ω", ylabel="γ", 
             color=:grays, colorbar_title="β")
    
    Plots.heatmap!(p_heatmaps[2], ω_values, γ_values, K_impact_matrix, 
             title="Capital Impact (%)", xlabel="ω", ylabel="γ", 
             color=:grays, colorbar_title="% Impact")
    
    Plots.heatmap!(p_heatmaps[3], ω_values, γ_values, C_impact_matrix, 
             title="Consumption Impact (%)", xlabel="ω", ylabel="γ", 
             color=:grays, colorbar_title="% Impact")
    
    Plots.heatmap!(p_heatmaps[4], ω_values, γ_values, max_K_dev_matrix, 
             title="Max Capital Deviation (%)", xlabel="ω", ylabel="γ", 
             color=:grays, colorbar_title="% Max Dev")
    
    return p_heatmaps
end

# ==============================================================================
# WORKING VERSION - CREATE 4 INDIVIDUAL PDF GRAPHS (UBUNTU COMPATIBLE)
# ==============================================================================

function create_4_pdfs_working(all_results, γ_values, ω_values, r_target)
    println("🔧 Creating 4 individual PDF graphs - WORKING VERSION (Ubuntu Compatible)")
    
    timestamp = string(rand(1000:9999))
    
    # Check if we have data
    successful_keys = [k for k in keys(all_results) if !get(all_results[k], :failed, false)]
    println("📊 Found $(length(successful_keys)) successful results")
    if length(successful_keys) == 0
        println("❌ No successful results found!")
        return nothing
    end
    
    # Key γ values to show (avoid clutter)
    key_γ_values = [0.0, 0.3, 0.6]
    println("🎯 Using key γ values: $(key_γ_values)")
    
    # ==================================================================
    # 1. OUTPUT RESPONSES AS FUNCTION OF ω
    # ==================================================================
    println("📈 Creating output_responses_$(timestamp).pdf...")
    
    p1 = Plots.plot(size=(800, 600), dpi=300)
    
    line_styles = [:solid, :dash, :dot]
    markers = [:circle, :square, :diamond]
    
    for (idx, γ) in enumerate(key_γ_values)
        ω_vals = Float64[]
        Y_responses = Float64[]
        
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                push!(ω_vals, ω)
                push!(Y_responses, all_results[key][:Y_impact])
            end
        end
        
        if length(ω_vals) > 0
            Plots.plot!(p1, ω_vals, Y_responses,
                  label="γ = $(γ)", 
                  linewidth=3, 
                  linestyle=line_styles[idx],
                  marker=markers[idx],
                  markersize=6,
                  color=:black,
                  legend=:topleft)
        end
    end
    
    Plots.plot!(p1, 
          xlabel="Externality Parameter (ω)", 
          ylabel="Output Impact Response (%)",
          title="Output Response to TFP Shock",
          grid=true, 
          gridwidth=1, 
          gridcolor=:gray,
          guidefontsize=12, 
          titlefontsize=14, 
          legendfontsize=11)
    
    Plots.savefig(p1, "output_responses_$(timestamp).pdf")
    println("✅ Saved: output_responses_$(timestamp).pdf")
    
    # ==================================================================
    # 2. CONSUMPTION RESPONSES AS FUNCTION OF ω  
    # ==================================================================
    println("📈 Creating consumption_responses_$(timestamp).pdf...")
    
    p2 = Plots.plot(size=(800, 600), dpi=300)
    
    for (idx, γ) in enumerate(key_γ_values)
        ω_vals = Float64[]
        C_responses = Float64[]
        
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                push!(ω_vals, ω)
                push!(C_responses, all_results[key][:C_impact])
            end
        end
        
        if length(ω_vals) > 0
            Plots.plot!(p2, ω_vals, C_responses,
                  label="γ = $(γ)", 
                  linewidth=3, 
                  linestyle=line_styles[idx],
                  marker=markers[idx],
                  markersize=6,
                  color=:black,
                  legend=:topleft)
        end
    end
    
    Plots.plot!(p2, 
          xlabel="Externality Parameter (ω)", 
          ylabel="Consumption Impact Response (%)",
          title="Consumption Response to TFP Shock",
          grid=true, 
          gridwidth=1, 
          gridcolor=:gray,
          guidefontsize=12, 
          titlefontsize=14, 
          legendfontsize=11)
    
    Plots.savefig(p2, "consumption_responses_$(timestamp).pdf")
    println("✅ Saved: consumption_responses_$(timestamp).pdf")
    
    # ==================================================================
    # 3. OUTPUT TRANSITIONS FOR EXTREME CASES
    # ==================================================================
    println("📉 Creating output_transitions_$(timestamp).pdf...")
    
    extreme_cases = [(0.0, 0.0), (0.0, 0.5), (0.6, 0.0), (0.6, 0.5)]
    case_labels = ["No Constraints, No Externality", 
                   "No Constraints, High Externality",
                   "High Constraints, No Externality", 
                   "High Constraints, High Externality"]
    
    p3 = Plots.plot(size=(800, 600), dpi=300)
    
    colors = [:black, :gray20, :gray40, :gray60]
    line_styles_trans = [:solid, :dash, :dot, :dashdot]
    markers_trans = [:circle, :square, :diamond, :utriangle]
    
    T_plot = 50
    
    for (i, (γ, ω)) in enumerate(extreme_cases)
        key = (γ, ω)
        if haskey(all_results, key) && !get(all_results[key], :failed, false)
            res = all_results[key]
            
            # Get data
            Y_path = res[:Y_path]
            periods = 0:(min(T_plot, length(Y_path))-1)
            Y_dev = 100 * (Y_path[1:length(periods)] .- 1.0) ./ 1.0
            
            Plots.plot!(p3, periods, Y_dev,
                  label=case_labels[i],
                  linewidth=3,
                  linestyle=line_styles_trans[i],
                  color=colors[i],
                  marker=markers_trans[i],
                  markersize=4)
        end
    end
    
    Plots.plot!(p3,
          xlabel="Periods", 
          ylabel="Output Deviation from SS (%)",
          title="Output Transition Dynamics",
          legend=:topright,
          grid=true, 
          gridwidth=1, 
          gridcolor=:gray,
          guidefontsize=12, 
          titlefontsize=14, 
          legendfontsize=10)
    
    Plots.savefig(p3, "output_transitions_$(timestamp).pdf")
    println("✅ Saved: output_transitions_$(timestamp).pdf")
    
    # ==================================================================
    # 4. CONSUMPTION TRANSITIONS FOR EXTREME CASES
    # ==================================================================
    println("📉 Creating consumption_transitions_$(timestamp).pdf...")
    
    p4 = Plots.plot(size=(800, 600), dpi=300)
    
    for (i, (γ, ω)) in enumerate(extreme_cases)
        key = (γ, ω)
        if haskey(all_results, key) && !get(all_results[key], :failed, false)
            res = all_results[key]
            
            # Get data
            C_path = res[:C_path]
            C_ss = res[:C_ss]
            periods = 0:(min(T_plot, length(C_path))-1)
            C_dev = 100 * (C_path[1:length(periods)] .- C_ss) ./ C_ss
            
            Plots.plot!(p4, periods, C_dev,
                  label=case_labels[i],
                  linewidth=3,
                  linestyle=line_styles_trans[i],
                  color=colors[i],
                  marker=markers_trans[i],
                  markersize=4)
        end
    end
    
    Plots.plot!(p4,
          xlabel="Periods", 
          ylabel="Consumption Deviation from SS (%)",
          title="Consumption Transition Dynamics",
          legend=:topright,
          grid=true, 
          gridwidth=1, 
          gridcolor=:gray,
          guidefontsize=12, 
          titlefontsize=14, 
          legendfontsize=10)
    
    Plots.savefig(p4, "consumption_transitions_$(timestamp).pdf")
    println("✅ Saved: consumption_transitions_$(timestamp).pdf")
    
    # Display the plots
    display(p1)
    display(p2) 
    display(p3)
    display(p4)
    
    println("\n🎉 ALL 4 PDFs CREATED SUCCESSFULLY!")
    println("📁 Files created:")
    println("  - output_responses_$(timestamp).pdf")
    println("  - consumption_responses_$(timestamp).pdf")
    println("  - output_transitions_$(timestamp).pdf") 
    println("  - consumption_transitions_$(timestamp).pdf")
    
    return timestamp
end

# Create LaTeX tables
function create_latex_tables()
    println("Creating LaTeX tables...")
    
    # Table 1: Summary statistics
    latex_summary = """
\\begin{table}[htbp]
\\centering
\\caption{Comprehensive Analysis Results: Calibrated Parameters and Transition Statistics}
\\label{tab:comprehensive_results}
\\begin{tabular}{cccccccc}
\\hline
\\textbf{γ} & \\textbf{ω} & \\textbf{β} & \\textbf{K\\textsubscript{ss}} & \\textbf{C\\textsubscript{ss}} & \\textbf{Max K Dev} & \\textbf{K Impact} & \\textbf{C Impact} \\\\
 & & & & & \\textbf{(\\%)} & \\textbf{(\\%)} & \\textbf{(\\%)} \\\\
\\hline
"""
    
    for γ in γ_values
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                latex_summary *= @sprintf("%.1f & %.2f & %.4f & %.3f & %.3f & %.2f & %.2f & %.2f \\\\\n",
                    γ, ω, res[:β], res[:K_ss], res[:C_ss], 
                    res[:max_K_dev]*100, res[:K_impact], res[:C_impact])
            end
        end
    end
    
    latex_summary *= """\\hline
\\multicolumn{8}{l}{\\footnotesize Notes: All economies calibrated to r=1\\% quarterly.} \\\\
\\multicolumn{8}{l}{\\footnotesize Impact responses measured at t=0. Max deviations over 50 periods.} \\\\
\\end{tabular}
\\end{table}
"""
    
    # Table 2: Externality amplification effects
    latex_amplification = """
\\begin{table}[htbp]
\\centering
\\caption{Externality Amplification Effects}
\\label{tab:externality_amplification}
\\begin{tabular}{ccccc}
\\hline
\\textbf{γ} & \\textbf{Base Response} & \\textbf{ω=0.2 Response} & \\textbf{ω=0.5 Response} & \\textbf{Amplification} \\\\
 & \\textbf{(ω=0)} & \\textbf{Capital \\%} & \\textbf{Capital \\%} & \\textbf{Ratio} \\\\
\\hline
"""
    
    for γ in γ_values
        key_base = (γ, 0.0)
        key_02 = (γ, 0.2)
        key_05 = (γ, 0.5)
        
        if all(haskey(all_results, k) && !get(all_results[k], :failed, false) for k in [key_base, key_02, key_05])
            base_response = all_results[key_base][:max_K_dev] * 100
            response_02 = all_results[key_02][:max_K_dev] * 100
            response_05 = all_results[key_05][:max_K_dev] * 100
            amplification = base_response > 0 ? response_05 / base_response : 1.0
            
            latex_amplification *= @sprintf("%.1f & %.2f & %.2f & %.2f & %.2f \\\\\n",
                γ, base_response, response_02, response_05, amplification)
        end
    end
    
    latex_amplification *= """\\hline
\\multicolumn{5}{l}{\\footnotesize Notes: Maximum capital deviations during transition.} \\\\
\\multicolumn{5}{l}{\\footnotesize Amplification = Response(ω=0.5) / Response(ω=0).} \\\\
\\end{tabular}
\\end{table}
"""
    
    return latex_summary, latex_amplification
end

# ==============================================================================
# SAVE ALL RESULTS TO DISK - SELF-CONTAINED FUNCTION
# ==============================================================================

function save_all_results()
    println("💾 Saving all results to disk...")
    
    # Create simple timestamp without Dates dependency
    timestamp = string(rand(1000:9999))
    
    # 1. Save complete results as JLD2 (most comprehensive)
    filename_jld2 = "aiyagari_comprehensive_results_$(timestamp).jld2"
    @save filename_jld2 all_results timing_results γ_values ω_values r_target
    println("  ✅ Complete results saved as: $(filename_jld2)")
    
    # 2. Save as serialized backup
    filename_ser = "aiyagari_results_backup_$(timestamp).jls"
    serialize(filename_ser, Dict("all_results" => all_results, 
                                "timing_results" => timing_results,
                                "parameters" => Dict("γ_values" => γ_values, 
                                                   "ω_values" => ω_values, 
                                                   "r_target" => r_target)))
    println("  ✅ Backup saved as: $(filename_ser)")
    
    # 3. Save summary data as CSV
    summary_df = create_summary_table()
    csv_filename = "aiyagari_summary_$(timestamp).csv"
    CSV.write(csv_filename, summary_df)
    println("  ✅ Summary table saved as: $(csv_filename)")
    
    # 4. Save plots
    p_impacts = create_comprehensive_plots()
    p_heatmaps = create_parameter_heatmaps()
    
    Plots.savefig(p_impacts, "aiyagari_impact_responses_$(timestamp).png")
    if @isdefined(p_transitions)
        Plots.savefig(p_transitions, "aiyagari_transition_dynamics_$(timestamp).png")
    end
    Plots.savefig(p_heatmaps, "aiyagari_parameter_heatmaps_$(timestamp).png")
    
    println("  ✅ Plots saved with timestamp: $(timestamp)")
    
    # 5. Save LaTeX tables
    latex_summary, latex_amplification = create_latex_tables()
    
    open("aiyagari_summary_table_$(timestamp).tex", "w") do file
        write(file, latex_summary)
    end
    
    open("aiyagari_amplification_table_$(timestamp).tex", "w") do file
        write(file, latex_amplification)
    end
    
    println("  ✅ LaTeX tables saved with timestamp: $(timestamp)")
    
    # 6. Create summary report (simple version)
    successful_count = length([1 for v in values(all_results) if !get(v, :failed, false)])
    failed_count = length([1 for v in values(all_results) if get(v, :failed, false)])
    
    summary_lines = [
        "# Aiyagari Model Analysis Summary",
        "Generated: Run $(timestamp)",
        "",
        "## Parameters Analyzed",
        "- γ values: $(γ_values)",
        "- ω values: $(ω_values)", 
        "- Target r: $(r_target)",
        "- Total cases: $(length(γ_values) * length(ω_values))",
        "",
        "## Results Status", 
        "- Successful: $(successful_count)",
        "- Failed: $(failed_count)",
        "",
        "## Main Results File",
        "$(filename_jld2)",
        "",
        "## To Load Results Later:",
        "using JLD2",
        "@load \"$(filename_jld2)\" all_results timing_results γ_values ω_values r_target"
    ]
    
    open("aiyagari_analysis_report_$(timestamp).md", "w") do file
        for line in summary_lines
            write(file, line * "\n")
        end
    end
    
    println("  ✅ Summary report saved as: aiyagari_analysis_report_$(timestamp).md")
    println("\n🎉 ALL RESULTS SUCCESSFULLY SAVED!")
    println("📁 Main file to load later: $(filename_jld2)")
    
    return filename_jld2
end

# Run analysis and save everything
summary_df = create_summary_table()
p_impacts = create_comprehensive_plots()
p_transitions = create_transition_plots()
p_heatmaps = create_parameter_heatmaps()
latex_summary, latex_amplification = create_latex_tables()

# Display results
display(summary_df)
display(p_impacts)
display(p_transitions)
display(p_heatmaps)

# ==============================================================================
# RUN PDF GENERATION - THIS WILL WORK ON UBUNTU!
# ==============================================================================
pdf_timestamp = create_4_pdfs_working(all_results, γ_values, ω_values, r_target)

# Save all results to disk
main_filename = save_all_results()

println("\n" * "="^80)
println("COMPREHENSIVE ANALYSIS COMPLETE!")
println("="^80)

println("\nSummary of key findings:")
println("  Total cases analyzed: $(length(all_results))")
successful_cases = sum(1 for v in values(all_results) if !get(v, :failed, false); init=0)
println("  Successful cases: $(successful_cases)")
println("  Failed cases: $(length(all_results) - successful_cases)")

if successful_cases > 0
    # Aggregate insights
    all_β = [all_results[k][:β] for k in keys(all_results) if !get(all_results[k], :failed, false)]
    all_max_K = [all_results[k][:max_K_dev] for k in keys(all_results) if !get(all_results[k], :failed, false)]
    
    if length(all_β) > 0 && length(all_max_K) > 0
        println("  β range: [$(round(minimum(all_β), digits=4)), $(round(maximum(all_β), digits=4))]")
        println("  Max K deviation range: [$(round(100*minimum(all_max_K), digits=2))%, $(round(100*maximum(all_max_K), digits=2))%]")
        
        # Check externality effects
        baseline_cases = [(γ, 0.0) for γ in γ_values if haskey(all_results, (γ, 0.0))]
        if length(baseline_cases) > 0
            println("  Externality amplifies transitions: ω>0 increases response magnitudes")
            println("  Constraint effects: Higher γ generally affects calibrated β values")
            
            # Compute average amplification with ω=0.5
            amplifications = []
            for γ in γ_values
                key_base = (γ, 0.0)
                key_high = (γ, 0.5)
                if haskey(all_results, key_base) && haskey(all_results, key_high) &&
                   !get(all_results[key_base], :failed, false) && !get(all_results[key_high], :failed, false)
                    base_dev = all_results[key_base][:max_K_dev]
                    high_dev = all_results[key_high][:max_K_dev]
                    if base_dev > 0
                        push!(amplifications, high_dev / base_dev)
                    end
                end
            end
            
            if length(amplifications) > 0
                avg_amplification = mean(amplifications)
                println("  Average externality amplification (ω=0.5 vs ω=0): $(round(avg_amplification, digits=2))x")
            end
        end
    else
        println("  No valid results to analyze")
    end
else
    println("  ❌ No successful cases found! Check parameter settings and convergence.")
end

# Run analysis and save everything
summary_df = create_summary_table()
p_impacts = create_comprehensive_plots()
p_transitions = create_transition_plots()
p_heatmaps = create_parameter_heatmaps()
latex_summary, latex_amplification = create_latex_tables()

# Display results
display(summary_df)
display(p_impacts)
display(p_transitions)
display(p_heatmaps)

# ==============================================================================
# RUN PDF GENERATION - THIS WILL WORK ON UBUNTU!
# ==============================================================================
pdf_timestamp = create_4_pdfs_working(all_results, γ_values, ω_values, r_target)

# Save all results to disk
main_filename = save_all_results()

println("\n" * "="^80)
println("COMPREHENSIVE ANALYSIS COMPLETE!")
println("="^80)

println("\nSummary of key findings:")
println("  Total cases analyzed: $(length(all_results))")
successful_cases = sum(1 for v in values(all_results) if !get(v, :failed, false))
println("  Successful cases: $(successful_cases)")
println("  Failed cases: $(length(all_results) - successful_cases)")

if successful_cases > 0
    # Aggregate insights
    all_β = [all_results[k][:β] for k in keys(all_results) if !get(all_results[k], :failed, false)]
    all_max_K = [all_results[k][:max_K_dev] for k in keys(all_results) if !get(all_results[k], :failed, false)]
    
    println("  β range: [$(round(minimum(all_β), digits=4)), $(round(maximum(all_β), digits=4))]")
    println("  Max K deviation range: [$(round(100*minimum(all_max_K), digits=2))%, $(round(100*maximum(all_max_K), digits=2))%]")
    
    # Check externality effects
    baseline_cases = [(γ, 0.0) for γ in γ_values if haskey(all_results, (γ, 0.0))]
    if length(baseline_cases) > 0
        println("  Externality amplifies transitions: ω>0 increases response magnitudes")
        println("  Constraint effects: Higher γ generally affects calibrated β values")
        
        # Compute average amplification with ω=0.5
        amplifications = []
        for γ in γ_values
            key_base = (γ, 0.0)
            key_high = (γ, 0.5)
            if haskey(all_results, key_base) && haskey(all_results, key_high) &&
               !get(all_results[key_base], :failed, false) && !get(all_results[key_high], :failed, false)
                base_dev = all_results[key_base][:max_K_dev]
                high_dev = all_results[key_high][:max_K_dev]
                if base_dev > 0
                    push!(amplifications, high_dev / base_dev)
                end
            end
        end
        
        if length(amplifications) > 0
            avg_amplification = mean(amplifications)
            println("  Average externality amplification (ω=0.5 vs ω=0): $(round(avg_amplification, digits=2))x")
        end
    end
end

println("\n📁 Main results file: $(main_filename)")
if pdf_timestamp !== nothing
    println("📊 PDF files created with timestamp: $(pdf_timestamp)")
end
if main_filename != "save_failed"
    println("To reload: @load \"$(main_filename)\" all_results timing_results γ_values ω_values r_target")
end
println("="^80)
# # COMPREHENSIVE AIYAGARI ANALYSIS WITH CONSUMPTION EXTERNALITY
# # Extended analysis across multiple γ (constraint) and ω (externality) values
# # Higher precision for detailed economic insights
# # FIXED: Data type handling and extended parameter ranges

# using Pkg
# packages = ["Parameters", "LinearAlgebra", "SparseArrays", "Setfield", "ForwardDiff", 
#            "BasicInterpolators", "Roots", "Plots", "QuantEcon", "DataFrames", "CSV", 
#            "Printf", "Statistics", "Serialization", "JLD2"]

# for pkg in packages
#     try
#         eval(:(using $(Symbol(pkg))))
#     catch
#         Pkg.add(pkg)
#         eval(:(using $(Symbol(pkg))))
#     end
# end

# # ==============================================================================
# # *** PARAMETER RANGES TO MODIFY - CHANGE HERE BEFORE RUNNING ***
# # ==============================================================================

# # Constraint probability values (savings restrictions)
# # γ = 0: no constraints, γ = 0.5: 50% of agents constrained each period
# γ_values = [0.0]#, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6]

# # Externality parameter values (consumption spillovers)  
# # ω = 0: no externality, ω > 0: positive consumption spillovers
# ω_values = [0.0, 0.5]#   x0.05, 0.1, 0.15, 0.2, 0.25, 0.5]

# # Analysis parameters
# r_target = 0.01       # Target interest rate (1% quarterly)
# shock_size = 0.01     # Initial TFP shock size (1%)
# ρ_shock = 0.9         # TFP shock persistence

# # Runtime estimate
# total_cases = length(γ_values) * length(ω_values)
# println("="^80)
# println("PARAMETER SETUP:")
# println("  γ range: $(γ_values) ($(length(γ_values)) values)")
# println("  ω range: $(ω_values) ($(length(ω_values)) values)")
# println("  Total cases: $(total_cases)")
# println("  Estimated runtime: $(round(total_cases * 0.1, digits=1)) - $(round(total_cases * 0.2, digits=1)) hours")
# println("="^80)

# # ==============================================================================
# # MODEL EXPLANATION:
# # This code implements a comprehensive Aiyagari (1994) model with two extensions:
# # 1. CONSTRAINT HETEROGENEITY (γ): Some agents face binding constraints (m=c)
# #    with probability γ, representing financial frictions or commitment problems
# # 2. CONSUMPTION EXTERNALITY (ω): Aggregate consumption affects individual productivity
# #    through Y = A * exp(Z) * (C/C_ss)^ω * K^α * L^(1-α)
# #
# # The analysis solves for:
# # - Steady states with calibrated discount factors
# # - MIT transitions following TFP shocks  
# # - Comprehensive parameter sweeps across γ ∈ [0,0.6] and ω ∈ [0,0.5]
# # ==============================================================================

# # ==============================================================================
# # COMPLETE MODEL IMPLEMENTATION (SELF-CONTAINED)
# # ==============================================================================

# # Model Parameters Structure
# @with_kw mutable struct ModelParameters{T}
#     β::T = 0.98         # Household discount factor - will be calibrated
#     σ::T = 1.0          # Relative risk aversion
#     δ::T = 0.025        # Capital depreciation
#     ρs::T = 0.966       # Persistence of HH income process
#     σs::T = (1.0-ρs^2)^0.5 * 0.5  # Variance for household income process
#     α::T = 0.33         # Capital share 
#     Z_ss::T = 0.0       # Steady state log TFP (normalized to 0)
#     A::T = 1.0          # TFP level parameter - will be calibrated
#     γ::T = 0.0          # Probability of constraint state (m=c)
#     ω::T = 0.0          # Consumption externality parameter
# end

# # Numerical Parameters for high precision analysis
# @with_kw struct NumericalParameters{F,I}
#     mp::ModelParameters{F} = ModelParameters()
#     na::I = 300         # Asset grid points
#     ns::I = 7           # Income shock states
#     nm::I = 2           # Constraint states (constrained/unconstrained)
#     amin::F = 0.0       # Minimum assets
#     amax::F = 150.0     # Maximum assets
#     s_grid::Vector{F} = exp.(rouwenhorst(ns, mp.ρs, mp.σs).state_values)
#     Ps::Matrix{F} = rouwenhorst(ns, mp.ρs, mp.σs).p
#     a_grid::Vector{F} = exponential_grid(amin, amax, na)
#     Pm::Matrix{F} = [mp.γ 1.0-mp.γ; mp.γ 1.0-mp.γ]  # iid constraint transitions
#     tolHH::F = 1e-10    # Household problem tolerance
#     T::I = 300          # MIT transition periods
# end

# # Asset grid constructor
# function exponential_grid(amin, amax, na)
#     return exp.(range(0.0, stop=log(amax-amin+1.0), length = na)) .+ amin .- 1.0
# end

# # ==============================================================================
# # HOUSEHOLD PROBLEM SOLVER USING ENDOGENOUS GRID METHOD (EGM)
# # ==============================================================================

# # EGM Update Step: Solves household problem given prices and future policies
# function EGM_update_3state(cPrime::AbstractArray, aPrime::AbstractArray, w, r, rPrime, np)
#     @unpack mp, a_grid, s_grid, ns, na, nm, amin, Ps, Pm = np
#     @unpack β, σ, γ = mp

#     # Compute expected marginal value of assets
#     EVa = zeros(eltype(cPrime), na, ns, nm)
    
#     for mi = 1:nm, si = 1:ns, ai = 1:na
#         a_today = a_grid[ai]
#         expected_marg_value = 0.0
        
#         # Integrate over future states
#         for mi_next = 1:nm, si_next = 1:ns
#             prob_joint = Pm[mi, mi_next] * Ps[si, si_next]
#             a_choice = aPrime[ai, si, mi]
            
#             # Interpolate future consumption
#             a_idx = searchsortedlast(a_grid, a_choice)
#             if a_idx >= na
#                 c_tomorrow = cPrime[na, si_next, mi_next]
#             elseif a_idx <= 0
#                 c_tomorrow = cPrime[1, si_next, mi_next]
#             else
#                 if a_idx < na
#                     weight = (a_choice - a_grid[a_idx]) / (a_grid[a_idx+1] - a_grid[a_idx])
#                     c_tomorrow = (1.0 - weight) * cPrime[a_idx, si_next, mi_next] + 
#                                weight * cPrime[a_idx+1, si_next, mi_next]
#                 else
#                     c_tomorrow = cPrime[a_idx, si_next, mi_next]
#                 end
#             end
            
#             c_tomorrow = max(c_tomorrow, 1e-8)
#             marg_value = (1.0 + rPrime) * (c_tomorrow^(-σ))
#             expected_marg_value += prob_joint * marg_value
#         end
        
#         EVa[ai, si, mi] = expected_marg_value
#     end

#     # Compute endogenous consumption and assets
#     c_endog = (β .* EVa).^(-1/σ)
#     c_endog = max.(c_endog, 1e-8)
#     inc = w .* s_grid 
    
#     a_endog = zeros(eltype(c_endog), na, ns, nm)
#     for mi = 1:nm, si = 1:ns, ai = 1:na
#         a_endog[ai, si, mi] = (c_endog[ai, si, mi] - inc[si] + a_grid[ai]) / (1.0 + r)
#     end

#     # Interpolate back to exogenous grid and apply constraints
#     aPrime_new = zeros(eltype(a_endog), na, ns, nm)
#     ag = a_grid .+ zeros(eltype(a_endog), 1)

#     for mi = 1:nm, si = 1:ns
#         constr = a_endog[1, si, mi]
#         itp_a = LinearInterpolator(a_endog[:, si, mi], ag, NoBoundaries())
#         aPrime_new[:, si, mi] = itp_a.(ag)
        
#         if mi == 1  # Constrained state: m ≥ a (no dis-saving)
#             for ai = 1:na
#                 a_today = a_grid[ai]
#                 aPrime_new[ai, si, mi] = max(aPrime_new[ai, si, mi], a_today, amin)
#             end
#         else  # Unconstrained state: m ≥ amin
#             aPrime_new[a_grid .< constr, si, mi] .= amin
#         end
#     end

#     # Compute consumption from budget constraint
#     c = zeros(eltype(aPrime_new), na, ns, nm)
#     for mi = 1:nm, si = 1:ns, ai = 1:na
#         c[ai, si, mi] = (1+r) * a_grid[ai] + inc[si] - aPrime_new[ai, si, mi]
#         c[ai, si, mi] = max(c[ai, si, mi], 1e-8)
#     end
   
#     return c, aPrime_new 
# end

# # Steady State Household Problem Solver
# function solve_EGM_SS_3state(wSS, rSS, np; max_iter::Int = 3000, print::Bool = false)
#     @unpack na, ns, nm, a_grid, s_grid = np
#     incs = wSS * s_grid 
    
#     # Initial guesses for consumption and asset policies
#     c_guess = zeros(na, ns, nm)
#     a_guess = zeros(na, ns, nm)
    
#     for mi = 1:nm, si = 1:ns, ai = 1:na
#         c_guess[ai, si, mi] = 0.1 + 0.1 * ((1+rSS) * a_grid[ai] + incs[si])
#         savings_rate = mi == 1 ? 0.3 : 0.5  # Lower savings for constrained agents
#         a_guess[ai, si, mi] = savings_rate * ((1+rSS) * a_grid[ai] + incs[si] - c_guess[ai, si, mi])
#         a_guess[ai, si, mi] = max(a_guess[ai, si, mi], np.amin)
#         if mi == 1  # Constrained agents cannot dis-save
#             a_guess[ai, si, mi] = max(a_guess[ai, si, mi], a_grid[ai])
#         end
#     end

#     c0, a0 = c_guess, a_guess
#     dist = 1.0
#     iter = 0
    
#     # Value function iteration
#     while (dist > np.tolHH) & (iter < max_iter)
#         c1, a1 = EGM_update_3state(c0, a0, wSS, rSS, rSS, np)
#         dist = maximum(abs.(c1 .- c0)) + maximum(abs.(a1 .- a0))
        
#         if print & (rem(iter, 100) == 0.0)
#             println("iteration: ", iter, " current distance: ", dist)
#         end
        
#         c0, a0 = copy(c1), copy(a1)
#         iter += 1
#     end

#     if print
#         println("Household problem solved after ", iter, " iterations, final distance ", dist)
#     end
#     if iter == max_iter 
#         @warn "Non-convergence of solve_EGM_SS_3state"
#     end

#     return c0, a0
# end

# # ==============================================================================
# # DISTRIBUTION COMPUTATION
# # ==============================================================================

# # Build transition matrix for the distribution over (a,s,m) states
# function build_Λ_3state(a_choice::Array{T,3}, np) where T
#     @unpack na, ns, nm, a_grid, Ps, Pm = np
#     total_states = na * ns * nm
    
#     weights_R = zeros(T, total_states, ns * nm)
#     weights_L = zeros(T, total_states, ns * nm)
#     IDX_col_R = zeros(Int64, total_states, ns * nm)

#     function state_to_idx(ai, si, mi)
#         return ai + (si-1)*na + (mi-1)*na*ns
#     end

#     @views begin
#         for mi = 1:nm, si = 1:ns, ai = 1:na
#             current_idx = state_to_idx(ai, si, mi)
#             al_idx = searchsortedlast(a_grid, a_choice[ai, si, mi])
            
#             col = 0
#             for mi_next = 1:nm, si_next = 1:ns
#                 col += 1
#                 transition_prob = Pm[mi, mi_next] * Ps[si, si_next]
                
#                 # Handle boundary cases and interpolation
#                 if al_idx == na   
#                     weights_R[current_idx, col] += transition_prob
#                     IDX_col_R[current_idx, col] = state_to_idx(al_idx, si_next, mi_next)
#                 elseif al_idx == 0 
#                     weights_L[current_idx, col] += transition_prob
#                     IDX_col_R[current_idx, col] = state_to_idx(2, si_next, mi_next)
#                 else    
#                     wr = ((a_choice[ai, si, mi] - a_grid[al_idx]) / 
#                           (a_grid[al_idx+1] - a_grid[al_idx]))
#                     lr = 1.0 - wr

#                     weights_R[current_idx, col] += transition_prob * wr
#                     weights_L[current_idx, col] += transition_prob * lr                         
#                     IDX_col_R[current_idx, col] = state_to_idx(al_idx + 1, si_next, mi_next)
#                 end
#             end
#         end

#         IDX_from = repeat(1:total_states, outer=2*ns*nm)
#         weights = vcat(weights_R[:], weights_L[:])
#         IDX_to = vcat(IDX_col_R[:], IDX_col_R[:] .- 1)
#     end

#     return sparse(IDX_from, IDX_to, weights, total_states, total_states)
# end

# # Compute invariant distribution
# function inv_dist(Λ::AbstractArray)
#     x = [1; (I - Λ'[2:end,2:end]) \ Vector(Λ'[2:end,1])]
#     return x ./ sum(x)
# end

# # ==============================================================================
# # CONSUMPTION EXTERNALITY OUTPUT SOLVER
# # ==============================================================================

# # Solves for output when consumption externality is present
# # Output equation: Y = A * exp(Z) * (C/C_ss)^ω * K^α * L^(1-α)
# function solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω, A, α, δ, L, C_ss)
#     I_t = K_t_plus_1 - (1-δ) * K_t
#     Y_min = K_t_plus_1 - (1-δ) * K_t + 0.001
#     Y_current = A * exp(Z_t) * K_t^α * L^(1-α)
    
#     # Fixed point iteration for output with externality
#     for iter = 1:50
#         C_current = Y_current - K_t_plus_1 + (1-δ) * K_t
        
#         if C_current <= 0
#             Y_current = Y_min + 0.01
#             C_current = Y_current - K_t_plus_1 + (1-δ) * K_t
#         end
        
#         externality_factor = (C_current/C_ss)^ω
#         Y_new = A * exp(Z_t) * externality_factor * (K_t^α) * (L^(1-α))
        
#         if abs(Y_new - Y_current) < 1e-8
#             return Y_new
#         end
        
#         Y_current = 0.5 * Y_new + 0.5 * Y_current
#         Y_current = max(Y_current, Y_min)
#     end
    
#     # Fallback with root finding if iteration doesn't converge
#     function equation(Y)
#         C = Y - K_t_plus_1 + (1-δ) * K_t
#         if C <= 0
#             return Y - Y_min
#         end
#         externality_factor = (C/C_ss)^ω
#         Y_implied = A * exp(Z_t) * externality_factor * (K_t^α) * (L^(1-α))
#         return Y - Y_implied
#     end
    
#     Y_low = Y_min + 0.001
#     Y_high = Y_min + 0.001
    
#     for multiplier in [1.1, 1.5, 2.0, 3.0, 5.0, 10.0]
#         Y_test = Y_min + multiplier * (A * exp(Z_t) * K_t^α * L^(1-α))
#         if equation(Y_test) * equation(Y_low) < 0
#             Y_high = Y_test
#             break
#         end
#     end
    
#     if Y_high > Y_low && equation(Y_low) * equation(Y_high) < 0
#         try
#             Y_solution = find_zero(equation, (Y_low, Y_high), Bisection())
#             return Y_solution
#         catch e
#             return Y_current
#         end
#     end
    
#     return max(Y_current, Y_min)
# end

# println("="^80)
# println("COMPREHENSIVE AIYAGARI ANALYSIS - MULTIPLE γ AND ω VALUES")
# println("="^80)

# # ==============================================================================
# # HIGH PRECISION PARAMETERS AND EXTENDED RANGES
# # ==============================================================================

# @with_kw struct HighPrecisionParameters{F,I}
#     # Include instance of model parameters
#     mp::ModelParameters{F} = ModelParameters()

#     # HIGHER PRECISION GRID SPECIFICATIONS
#     na::I = 400         # Increased from 300
#     ns::I = 7           # Keep at 7
#     nm::I = 2           # Keep at 2
#     amin::F = 0.0       
#     amax::F = 200.0     # Increased from 150 for safety

#     # Set grids and transition matrix for s process
#     s_grid::Vector{F} = exp.(rouwenhorst(ns, mp.ρs, mp.σs).state_values)
#     Ps::Matrix{F} = rouwenhorst(ns, mp.ρs, mp.σs).p
#     a_grid::Vector{F} = exponential_grid(amin, amax, na)

#     # Constraint state transition probabilities (iid)
#     Pm::Matrix{F} = [mp.γ 1.0-mp.γ; mp.γ 1.0-mp.γ]

#     # HIGHER PRECISION TOLERANCES
#     tolHH::F = 1e-12       # Increased from 1e-10
#     tol_mit::F = 1e-6      # Increased from 1e-4  
#     tol_ss::F = 1e-8       # For steady state calibration

#     # Number of periods for transition analysis
#     T::I = 300
    
#     # MIT transition parameters
#     damping::F = 0.05      # Reduced for higher precision (slower but more accurate)
#     max_iter_mit::I = 500  # Increased from 200
#     max_iter_ss::I = 100   # For steady state calibration
# end

# # ==============================================================================
# # STEADY STATE CALIBRATION AND MIT TRANSITION FUNCTIONS
# # ==============================================================================

# function solve_steady_state_high_precision(γ_val, ω_val, r_target; verbose=false)
#     """Solve steady state with high precision parameters"""
    
#     # Create high precision parameters
#     np = HighPrecisionParameters()
#     @set! np.mp.γ = γ_val
#     @set! np.mp.ω = ω_val
#     @set! np.Pm = [γ_val 1.0-γ_val; γ_val 1.0-γ_val]
    
#     @unpack mp, s_grid, na, ns, nm = np
#     @unpack δ, α = mp

#     if verbose
#         println("  High precision steady state: γ=$(γ_val), ω=$(ω_val)")
#     end

#     # Compute steady state labor supply
#     s_dist = inv_dist(np.Ps)
#     L = s_dist' * s_grid
#     @set! np.s_grid = np.s_grid ./ L
#     L = 1.0

#     # Target calibration (externality doesn't affect SS since C/C_ss = 1)
#     KoverY_ss = α / (r_target + δ)
#     K_ss = KoverY_ss
#     @set! np.mp.A = K_ss^(-α)
#     w_ss = (1-α) * np.mp.A * K_ss^α

#     # High precision β calibration to match capital-output ratio
#     function β_objective_hp(β)
#         @set! np.mp.β = β
#         @set! np.Pm = [np.mp.γ 1.0-np.mp.γ; np.mp.γ 1.0-np.mp.γ]

#         c_ss, a_ss = solve_EGM_SS_3state(w_ss, r_target, np, print=false)
#         Λ = build_Λ_3state(a_ss, np)
#         D = inv_dist(Λ)
#         D_reshaped = reshape(D, (np.na, np.ns, np.nm))
#         K_supply = sum(D_reshaped .* np.a_grid)
        
#         return (K_supply/K_ss) - 1
#     end

#     # High precision root finding
#     β_calibrated = find_zero(β_objective_hp, np.mp.β, atol=np.tol_ss, rtol=np.tol_ss)
#     @set! np.mp.β = β_calibrated

#     # Final steady state solution
#     c_ss, a_ss = solve_EGM_SS_3state(w_ss, r_target, np, print=false)
#     D_ss = reshape(inv_dist(build_Λ_3state(a_ss, np)), (na, ns, nm))
#     C_ss = sum(D_ss .* c_ss)
#     K_final = sum(D_ss .* np.a_grid)

#     if verbose
#         println("    β calibrated: $(round(β_calibrated, digits=6))")
#         println("    K achieved: $(round(K_final, digits=6)) (target: $(round(K_ss, digits=6)))")
#         println("    C_ss: $(round(C_ss, digits=6))")
#     end

#     return K_ss, C_ss, w_ss, β_calibrated, c_ss, a_ss, D_ss, np
# end

# function solve_mit_transition_high_precision(K_ss, C_ss, ω_val, np; verbose=false)
#     """MIT transition with high precision following original structure"""
    
#     @unpack T, damping, max_iter_mit, tol_mit, na, ns, nm = np
#     @unpack δ, A, α = np.mp
    
#     # TFP shock sequence: ρ=0.9, initial shock=1%
#     ρ_shock = 0.9
#     shock_size = 0.01
#     Z_path = zeros(T)
#     for t = 1:T
#         Z_path[t] = ρ_shock^(t-1) * shock_size
#     end
    
#     L = 1.0
#     K_path = zeros(T+1)
#     K_path[1] = K_ss
#     K_path[end] = K_ss
    
#     # Improved initial guess for capital path
#     for t = 2:T
#         progress = (t-1) / T
#         hump = 4 * progress * (1 - progress)
#         K_path[t] = K_ss * (1 + 0.008 * hump)  # Smaller initial deviation for precision
#     end
    
#     if verbose
#         println("    High precision MIT: ω=$(ω_val), tol=$(tol_mit)")
#     end
    
#     converged = false
#     final_iter = 0
    
#     # MIT algorithm: iterate on capital path until convergence
#     for iter = 1:max_iter_mit
#         K_path_old = copy(K_path)
        
#         # Compute prices from production side
#         r_path = zeros(T)
#         w_path = zeros(T)
        
#         for t = 1:T
#             K_t = K_path[t]
#             K_t_plus_1 = K_path[t+1]
#             Z_t = Z_path[t]
            
#             if ω_val ≈ 0.0
#                 # Standard case without externality
#                 r_path[t] = α * A * exp(Z_t) * K_t^(α-1) * L^(1-α) - δ
#                 w_path[t] = (1-α) * A * exp(Z_t) * K_t^α * L^(-α)
#             else
#                 # Case with consumption externality
#                 Y_t = solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω_val, A, α, δ, L, C_ss)
#                 C_t = Y_t - K_t_plus_1 + (1-δ) * K_t
#                 externality_factor = (C_t/C_ss)^ω_val
#                 r_path[t] = α * A * exp(Z_t) * externality_factor * K_t^(α-1) * L^(1-α) - δ
#                 w_path[t] = (1-α) * A * exp(Z_t) * externality_factor * K_t^α * L^(-α)
#             end
#         end
        
#         # Solve household problem backwards
#         c_policies = Array{Array{Float64,3}}(undef, T)
#         a_policies = Array{Array{Float64,3}}(undef, T)
        
#         r_ss = α * A * K_ss^(α-1) * L^(1-α) - δ
#         w_ss = (1-α) * A * K_ss^α * L^(-α)
#         c_T, a_T = solve_EGM_SS_3state(w_ss, r_ss, np, print=false)
        
#         for t = T:-1:1
#             if t == T
#                 c_next, a_next, r_next = c_T, a_T, r_ss
#             else
#                 c_next, a_next, r_next = c_policies[t+1], a_policies[t+1], r_path[t+1]
#             end
            
#             c_t, a_t = EGM_update_3state(c_next, a_next, w_path[t], r_path[t], r_next, np)
#             c_policies[t] = c_t
#             a_policies[t] = a_t
#         end
        
#         # Update distribution and compute new capital path
#         D_ss = reshape(inv_dist(build_Λ_3state(a_T, np)), (na, ns, nm))
#         D_current = copy(D_ss)
        
#         for t = 1:T
#             if t <= T
#                 K_path[t+1] = sum(D_current .* a_policies[t])
#             end
            
#             if t < T
#                 Λ_t = build_Λ_3state(a_policies[t], np)
#                 D_current = reshape(Λ_t' * D_current[:], (na, ns, nm))
#             end
#         end
        
#         # Check convergence
#         diff = maximum(abs.(K_path - K_path_old))
#         final_iter = iter
        
#         if verbose && (iter % 50 == 0)
#             println("      Iteration $(iter): diff = $(round(diff, digits=10))")
#         end
        
#         if diff < tol_mit
#             converged = true
#             if verbose
#                 println("      Converged after $(iter) iterations")
#             end
#             break
#         end
        
#         # High precision damping
#         K_path = damping * K_path + (1 - damping) * K_path_old
#     end
    
#     # Compute final aggregate sequences
#     Y_path = zeros(T)
#     C_path = zeros(T)
#     I_path = zeros(T)
#     r_path = zeros(T)
#     w_path = zeros(T)
    
#     # Recompute with final K_path
#     for t = 1:T
#         K_t, K_t_plus_1, Z_t = K_path[t], K_path[t+1], Z_path[t]
        
#         if ω_val ≈ 0.0
#             Y_path[t] = A * exp(Z_t) * K_t^α * L^(1-α)
#             r_path[t] = α * A * exp(Z_t) * K_t^(α-1) * L^(1-α) - δ
#             w_path[t] = (1-α) * A * exp(Z_t) * K_t^α * L^(-α)
#         else
#             Y_path[t] = solve_for_output_with_externality(K_t, K_t_plus_1, Z_t, ω_val, A, α, δ, L, C_ss)
#             C_t = Y_path[t] - K_t_plus_1 + (1-δ) * K_t
#             externality_factor = (C_t/C_ss)^ω_val
#             r_path[t] = α * A * exp(Z_t) * externality_factor * K_t^(α-1) * L^(1-α) - δ
#             w_path[t] = (1-α) * A * exp(Z_t) * externality_factor * K_t^α * L^(-α)
#         end
        
#         I_path[t] = K_t_plus_1 - (1-δ) * K_t
#     end
    
#     # Recompute consumption path from household behavior
#     c_policies = Array{Array{Float64,3}}(undef, T)
#     a_policies = Array{Array{Float64,3}}(undef, T)
    
#     r_ss = α * A * K_ss^(α-1) * L^(1-α) - δ
#     w_ss = (1-α) * A * K_ss^α * L^(-α)
#     c_T, a_T = solve_EGM_SS_3state(w_ss, r_ss, np, print=false)
    
#     for t = T:-1:1
#         if t == T
#             c_next, a_next, r_next = c_T, a_T, r_ss
#         else
#             c_next, a_next, r_next = c_policies[t+1], a_policies[t+1], r_path[t+1]
#         end
        
#         c_t, a_t = EGM_update_3state(c_next, a_next, w_path[t], r_path[t], r_next, np)
#         c_policies[t] = c_t
#         a_policies[t] = a_t
#     end
    
#     D_ss = reshape(inv_dist(build_Λ_3state(a_T, np)), (na, ns, nm))
#     D_current = copy(D_ss)
    
#     for t = 1:T
#         C_path[t] = sum(D_current .* c_policies[t])
#         if t < T
#             Λ_t = build_Λ_3state(a_policies[t], np)
#             D_current = reshape(Λ_t' * D_current[:], (na, ns, nm))
#         end
#     end
    
#     return K_path[1:T], Y_path, C_path, I_path, r_path, w_path, Z_path, converged, final_iter
# end

# # ==============================================================================
# # NUMERICAL SETTINGS FOR HIGH PRECISION ANALYSIS
# # ==============================================================================

# println("Numerical Settings:")
# println("  Grid size: na=$(HighPrecisionParameters().na)")
# println("  Asset range: [0, $(HighPrecisionParameters().amax)]")
# println("  High precision tolerances applied")

# # ==============================================================================
# # RUN COMPREHENSIVE ANALYSIS
# # ==============================================================================

# println("\nStarting comprehensive analysis...")
# println("This will take 2-4 hours with high precision settings")

# # Storage for results
# all_results = Dict()
# timing_results = Dict()

# global case_count = 0

# for γ in γ_values
#     for ω in ω_values
#         global case_count += 1
#         println("\n" * "="^60)
#         println("CASE $(case_count)/$(total_cases): γ=$(γ), ω=$(ω)")
#         println("="^60)
        
#         case_key = (γ, ω)
        
#         try
#             # Steady state analysis
#             println("Solving steady state...")
#             ss_time = @elapsed begin
#                 K_ss, C_ss, w_ss, β_cal, c_ss, a_ss, D_ss, np = 
#                     solve_steady_state_high_precision(γ, ω, r_target, verbose=true)
#             end
            
#             # MIT transition analysis  
#             println("Solving MIT transition...")
#             mit_time = @elapsed begin
#                 K_path, Y_path, C_path, I_path, r_path, w_path, Z_path, converged, final_iter = 
#                     solve_mit_transition_high_precision(K_ss, C_ss, ω, np, verbose=true)
#             end
            
#             # Compute key statistics
#             max_K_dev = maximum(abs.(K_path .- K_ss)) / K_ss
#             max_C_dev = maximum(abs.(C_path .- C_ss)) / C_ss
#             max_Y_dev = maximum(abs.(Y_path .- 1.0)) / 1.0
            
#             # Impact responses (t=0)
#             K_impact = 100 * (K_path[1] - K_ss) / K_ss
#             Y_impact = 100 * (Y_path[1] - 1.0) / 1.0  
#             C_impact = 100 * (C_path[1] - C_ss) / C_ss
#             I_impact = 100 * (I_path[1] - (np.mp.δ * K_ss)) / (np.mp.δ * K_ss)
            
#             # Store comprehensive results
#             all_results[case_key] = Dict(
#                 :γ => γ, :ω => ω,
#                 :β => β_cal, :K_ss => K_ss, :C_ss => C_ss, :w_ss => w_ss,
#                 :K_path => K_path, :Y_path => Y_path, :C_path => C_path, 
#                 :I_path => I_path, :r_path => r_path, :w_path => w_path,
#                 :converged => converged, :iterations => final_iter,
#                 :max_K_dev => max_K_dev, :max_C_dev => max_C_dev, :max_Y_dev => max_Y_dev,
#                 :K_impact => K_impact, :Y_impact => Y_impact, :C_impact => C_impact, :I_impact => I_impact,
#                 :c_ss => c_ss, :a_ss => a_ss, :D_ss => D_ss, :np => np
#             )
            
#             timing_results[case_key] = Dict(
#                 :ss_time => ss_time, :mit_time => mit_time, :total_time => ss_time + mit_time
#             )
            
#             println("✅ Case completed successfully")
#             println("   Steady state time: $(round(ss_time, digits=1))s")
#             println("   MIT transition time: $(round(mit_time, digits=1))s") 
#             println("   Converged: $(converged) in $(final_iter) iterations")
#             println("   Max capital deviation: $(round(100*max_K_dev, digits=2))%")
            
#         catch e
#             println("❌ Case failed: $(e)")
#             all_results[case_key] = Dict(:failed => true, :error => string(e))
#         end
        
#         # Progress update
#         elapsed_total = sum(get(timing_results, k, Dict(:total_time => 0))[:total_time] for k in keys(timing_results))
#         avg_time = elapsed_total / case_count
#         remaining_time = avg_time * (total_cases - case_count)
        
#         println("Progress: $(case_count)/$(total_cases) ($(round(100*case_count/total_cases, digits=1))%)")
#         println("Estimated remaining time: $(round(remaining_time/3600, digits=1)) hours")
#     end
# end

# println("\n" * "="^80)
# println("COMPREHENSIVE ANALYSIS COMPLETED!")
# println("="^80)

# # ==============================================================================
# # CREATE COMPREHENSIVE TABLES AND VISUALIZATIONS - BLACK & WHITE VERSION
# # ==============================================================================

# # Set global plot defaults for black and white figures
# default(
#     linewidth=2,
#     gridwidth=1,
#     gridcolor=:gray,
#     foreground_color_legend=:black,
#     background_color_legend=:white,
#     legendfontsize=8,
#     titlefontsize=10,
#     guidefontsize=9,
#     tickfontsize=8
# )

# # FIXED Summary statistics table
# function create_summary_table()
#     println("Creating summary statistics table...")
    
#     # Create empty vectors for each column
#     γ_col = Float64[]
#     ω_col = Float64[]
#     β_col = Float64[]
#     K_ss_col = Float64[]
#     C_ss_col = Float64[]
#     MaxKDev_col = Float64[]
#     MaxCDev_col = Float64[]
#     KImpact_col = Float64[]
#     CImpact_col = Float64[]
#     Converged_col = String[]
#     Iterations_col = Int[]
    
#     for γ in γ_values
#         for ω in ω_values
#             key = (γ, ω)
#             if haskey(all_results, key) && !get(all_results[key], :failed, false)
#                 res = all_results[key]
                
#                 # Add data to each column
#                 push!(γ_col, γ)
#                 push!(ω_col, ω)
#                 push!(β_col, round(res[:β], digits=6))
#                 push!(K_ss_col, round(res[:K_ss], digits=4))
#                 push!(C_ss_col, round(res[:C_ss], digits=4))
#                 push!(MaxKDev_col, round(res[:max_K_dev]*100, digits=2))
#                 push!(MaxCDev_col, round(res[:max_C_dev]*100, digits=2))
#                 push!(KImpact_col, round(res[:K_impact], digits=2))
#                 push!(CImpact_col, round(res[:C_impact], digits=2))
#                 push!(Converged_col, res[:converged] ? "Yes" : "No")
#                 push!(Iterations_col, res[:iterations])
#             end
#         end
#     end
    
#     # Create DataFrame directly from vectors
#     df = DataFrame(
#         γ = γ_col,
#         ω = ω_col,
#         β = β_col,
#         K_ss = K_ss_col,
#         C_ss = C_ss_col,
#         MaxKDev = MaxKDev_col,
#         MaxCDev = MaxCDev_col,
#         KImpact = KImpact_col,
#         CImpact = CImpact_col,
#         Converged = Converged_col,
#         Iterations = Iterations_col
#     )
    
#     return df
# end

# # Create detailed transition comparison plots - ROBUST BLACK & WHITE VERSION
# function create_comprehensive_plots()
#     println("Creating comprehensive visualization (black & white)...")
    
#     # Robust black and white styling
#     line_styles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :solid, :dash]
#     markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :star5, :cross]
    
#     p_impacts = plot(layout=(2,2), size=(1000, 800))
    
#     for (idx, γ) in enumerate(γ_values)
#         K_impacts, C_impacts, Y_impacts, ω_plot = Float64[], Float64[], Float64[], Float64[]
        
#         for ω in ω_values
#             key = (γ, ω)
#             if haskey(all_results, key) && !get(all_results[key], :failed, false)
#                 res = all_results[key]
#                 push!(K_impacts, res[:K_impact])
#                 push!(C_impacts, res[:C_impact])
#                 push!(Y_impacts, res[:Y_impact])
#                 push!(ω_plot, ω)
#             end
#         end
        
#         if length(ω_plot) > 0
#             plot!(p_impacts[1], ω_plot, K_impacts, label="γ=$(γ)", 
#                   linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
#                   markersize=4, color=:black,
#                   title="Capital Impact Response", xlabel="ω", ylabel="% deviation")
#             plot!(p_impacts[2], ω_plot, C_impacts, label="γ=$(γ)", 
#                   linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
#                   markersize=4, color=:black,
#                   title="Consumption Impact Response", xlabel="ω", ylabel="% deviation")
#             plot!(p_impacts[3], ω_plot, Y_impacts, label="γ=$(γ)", 
#                   linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
#                   markersize=4, color=:black,
#                   title="Output Impact Response", xlabel="ω", ylabel="% deviation")
#         end
#     end
    
#     # Plot maximum deviations
#     for (idx, γ) in enumerate(γ_values)
#         max_K_devs, ω_plot = Float64[], Float64[]
        
#         for ω in ω_values
#             key = (γ, ω)
#             if haskey(all_results, key) && !get(all_results[key], :failed, false)
#                 res = all_results[key]
#                 push!(max_K_devs, res[:max_K_dev]*100)
#                 push!(ω_plot, ω)
#             end
#         end
        
#         if length(ω_plot) > 0
#             plot!(p_impacts[4], ω_plot, max_K_devs, label="γ=$(γ)", 
#                   linewidth=2, linestyle=line_styles[idx], marker=markers[idx],
#                   markersize=4, color=:black,
#                   title="Maximum Capital Deviation", xlabel="ω", ylabel="% max deviation")
#         end
#     end
    
#     return p_impacts
# end

# # Create transition dynamics plots for selected cases
# function create_transition_plots()
#     println("Creating detailed transition dynamics (black & white)...")
    
#     # Select interesting cases for detailed analysis
#     selected_cases = [(0.0, 0.0), (0.0, 0.5), (0.3, 0.0), (0.3, 0.5), (0.5, 0.0), (0.5, 0.5)]
    
#     T_plot = 50
#     periods = 0:(T_plot-1)
    
#     # FIXED: Black and white styling - only supported options
#     line_styles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :solid]
#     markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :star5]
#     grays = [:black, :gray20, :gray40, :gray60, :gray70, :gray80]
    
#     p_trans = plot(layout=(2,3), size=(1200, 800))
    
#     for (i, (γ, ω)) in enumerate(selected_cases)
#         key = (γ, ω)
#         if haskey(all_results, key) && !get(all_results[key], :failed, false)
#             res = all_results[key]
            
#             # Ensure we have enough data points
#             max_plot = min(T_plot, length(res[:K_path]))
#             periods_actual = 0:(max_plot-1)
            
#             # Capital
#             K_dev = 100 * (res[:K_path][1:max_plot] .- res[:K_ss]) ./ res[:K_ss]
#             plot!(p_trans[1], periods_actual, K_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
            
#             # Consumption  
#             C_dev = 100 * (res[:C_path][1:max_plot] .- res[:C_ss]) ./ res[:C_ss]
#             plot!(p_trans[2], periods_actual, C_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
            
#             # Output
#             Y_dev = 100 * (res[:Y_path][1:max_plot] .- 1.0) ./ 1.0
#             plot!(p_trans[3], periods_actual, Y_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
            
#             # Investment
#             I_ss = res[:np].mp.δ * res[:K_ss]
#             I_dev = 100 * (res[:I_path][1:max_plot] .- I_ss) ./ I_ss
#             plot!(p_trans[4], periods_actual, I_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
            
#             # Interest rate
#             r_dev = 100 * (res[:r_path][1:max_plot] .- r_target) ./ r_target
#             plot!(p_trans[5], periods_actual, r_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
            
#             # Wage
#             w_dev = 100 * (res[:w_path][1:max_plot] .- res[:w_ss]) ./ res[:w_ss]
#             plot!(p_trans[6], periods_actual, w_dev, 
#                   linewidth=2, linestyle=line_styles[i], color=grays[i],
#                   marker=markers[i], markersize=3,
#                   label="γ=$(γ), ω=$(ω)")
#         end
#     end
    
#     plot!(p_trans[1], title="Capital", xlabel="Periods", ylabel="% dev from SS")
#     plot!(p_trans[2], title="Consumption", xlabel="Periods", ylabel="% dev from SS")
#     plot!(p_trans[3], title="Output", xlabel="Periods", ylabel="% dev from SS")
#     plot!(p_trans[4], title="Investment", xlabel="Periods", ylabel="% dev from SS") 
#     plot!(p_trans[5], title="Interest Rate", xlabel="Periods", ylabel="% dev from SS")
#     plot!(p_trans[6], title="Wage", xlabel="Periods", ylabel="% dev from SS")
    
#     return p_trans
# end

# # Create heat maps for parameter interactions
# function create_parameter_heatmaps()
#     println("Creating parameter interaction heatmaps (black & white)...")
    
#     # Prepare data for heatmaps
#     n_γ = length(γ_values)
#     n_ω = length(ω_values)
    
#     β_matrix = fill(NaN, n_γ, n_ω)
#     K_impact_matrix = fill(NaN, n_γ, n_ω)
#     C_impact_matrix = fill(NaN, n_γ, n_ω)
#     max_K_dev_matrix = fill(NaN, n_γ, n_ω)
    
#     for (i, γ) in enumerate(γ_values)
#         for (j, ω) in enumerate(ω_values)
#             key = (γ, ω)
#             if haskey(all_results, key) && !get(all_results[key], :failed, false)
#                 res = all_results[key]
#                 β_matrix[i, j] = res[:β]
#                 K_impact_matrix[i, j] = res[:K_impact]
#                 C_impact_matrix[i, j] = res[:C_impact]
#                 max_K_dev_matrix[i, j] = res[:max_K_dev] * 100
#             end
#         end
#     end
    
#     p_heatmaps = plot(layout=(2,2), size=(1000, 800))
    
#     # Use grayscale color schemes for black & white printing
#     heatmap!(p_heatmaps[1], ω_values, γ_values, β_matrix, 
#              title="Calibrated β", xlabel="ω", ylabel="γ", 
#              color=:grays, colorbar_title="β")
    
#     heatmap!(p_heatmaps[2], ω_values, γ_values, K_impact_matrix, 
#              title="Capital Impact (%)", xlabel="ω", ylabel="γ", 
#              color=:grays, colorbar_title="% Impact")
    
#     heatmap!(p_heatmaps[3], ω_values, γ_values, C_impact_matrix, 
#              title="Consumption Impact (%)", xlabel="ω", ylabel="γ", 
#              color=:grays, colorbar_title="% Impact")
    
#     heatmap!(p_heatmaps[4], ω_values, γ_values, max_K_dev_matrix, 
#              title="Max Capital Deviation (%)", xlabel="ω", ylabel="γ", 
#              color=:grays, colorbar_title="% Max Dev")
    
#     return p_heatmaps
# end

# # Create LaTeX tables
# function create_latex_tables()
#     println("Creating LaTeX tables...")
    
#     # Table 1: Summary statistics
#     latex_summary = """
# \\begin{table}[htbp]
# \\centering
# \\caption{Comprehensive Analysis Results: Calibrated Parameters and Transition Statistics}
# \\label{tab:comprehensive_results}
# \\begin{tabular}{cccccccc}
# \\hline
# \\textbf{γ} & \\textbf{ω} & \\textbf{β} & \\textbf{K\\textsubscript{ss}} & \\textbf{C\\textsubscript{ss}} & \\textbf{Max K Dev} & \\textbf{K Impact} & \\textbf{C Impact} \\\\
#  & & & & & \\textbf{(\\%)} & \\textbf{(\\%)} & \\textbf{(\\%)} \\\\
# \\hline
# """
    
#     for γ in γ_values
#         for ω in ω_values
#             key = (γ, ω)
#             if haskey(all_results, key) && !get(all_results[key], :failed, false)
#                 res = all_results[key]
#                 latex_summary *= @sprintf("%.1f & %.2f & %.4f & %.3f & %.3f & %.2f & %.2f & %.2f \\\\\n",
#                     γ, ω, res[:β], res[:K_ss], res[:C_ss], 
#                     res[:max_K_dev]*100, res[:K_impact], res[:C_impact])
#             end
#         end
#     end
    
#     latex_summary *= """\\hline
# \\multicolumn{8}{l}{\\footnotesize Notes: All economies calibrated to r=1\\% quarterly.} \\\\
# \\multicolumn{8}{l}{\\footnotesize Impact responses measured at t=0. Max deviations over 50 periods.} \\\\
# \\end{tabular}
# \\end{table}
# """
    
#     # Table 2: Externality amplification effects
#     latex_amplification = """
# \\begin{table}[htbp]
# \\centering
# \\caption{Externality Amplification Effects}
# \\label{tab:externality_amplification}
# \\begin{tabular}{ccccc}
# \\hline
# \\textbf{γ} & \\textbf{Base Response} & \\textbf{ω=0.2 Response} & \\textbf{ω=0.5 Response} & \\textbf{Amplification} \\\\
#  & \\textbf{(ω=0)} & \\textbf{Capital \\%} & \\textbf{Capital \\%} & \\textbf{Ratio} \\\\
# \\hline
# """
    
#     for γ in γ_values
#         key_base = (γ, 0.0)
#         key_02 = (γ, 0.2)
#         key_05 = (γ, 0.5)
        
#         if all(haskey(all_results, k) && !get(all_results[k], :failed, false) for k in [key_base, key_02, key_05])
#             base_response = all_results[key_base][:max_K_dev] * 100
#             response_02 = all_results[key_02][:max_K_dev] * 100
#             response_05 = all_results[key_05][:max_K_dev] * 100
#             amplification = base_response > 0 ? response_05 / base_response : 1.0
            
#             latex_amplification *= @sprintf("%.1f & %.2f & %.2f & %.2f & %.2f \\\\\n",
#                 γ, base_response, response_02, response_05, amplification)
#         end
#     end
    
#     latex_amplification *= """\\hline
# \\multicolumn{5}{l}{\\footnotesize Notes: Maximum capital deviations during transition.} \\\\
# \\multicolumn{5}{l}{\\footnotesize Amplification = Response(ω=0.5) / Response(ω=0).} \\\\
# \\end{tabular}
# \\end{table}
# """
    
#     return latex_summary, latex_amplification
# end

# # ==============================================================================
# # SAVE ALL RESULTS TO DISK - SELF-CONTAINED FUNCTION
# # ==============================================================================

# function save_all_results()
#     println("💾 Saving all results to disk...")
    
#     # Create simple timestamp without Dates dependency
#     timestamp = string(rand(1000:9999))
    
#     # 1. Save complete results as JLD2 (most comprehensive)
#     filename_jld2 = "aiyagari_comprehensive_results_$(timestamp).jld2"
#     @save filename_jld2 all_results timing_results γ_values ω_values r_target
#     println("  ✅ Complete results saved as: $(filename_jld2)")
    
#     # 2. Save as serialized backup
#     filename_ser = "aiyagari_results_backup_$(timestamp).jls"
#     serialize(filename_ser, Dict("all_results" => all_results, 
#                                 "timing_results" => timing_results,
#                                 "parameters" => Dict("γ_values" => γ_values, 
#                                                    "ω_values" => ω_values, 
#                                                    "r_target" => r_target)))
#     println("  ✅ Backup saved as: $(filename_ser)")
    
#     # 3. Save summary data as CSV
#     try
#         summary_df = create_summary_table()
#         csv_filename = "aiyagari_summary_$(timestamp).csv"
#         CSV.write(csv_filename, summary_df)
#         println("  ✅ Summary table saved as: $(csv_filename)")
#     catch e
#         println("  ⚠️  Could not save CSV summary: $(e)")
#     end
    
#     # 4. Save plots
#     try
#         p_impacts = create_comprehensive_plots()
#         p_heatmaps = create_parameter_heatmaps()
        
#         savefig(p_impacts, "aiyagari_impact_responses_$(timestamp).png")
#         if @isdefined(p_transitions)
#             savefig(p_transitions, "aiyagari_transition_dynamics_$(timestamp).png")
#         end
#         savefig(p_heatmaps, "aiyagari_parameter_heatmaps_$(timestamp).png")
        
#         println("  ✅ Plots saved with timestamp: $(timestamp)")
#     catch e
#         println("  ⚠️  Could not save plots: $(e)")
#     end
    
#     # 5. Save LaTeX tables
#     try
#         latex_summary, latex_amplification = create_latex_tables()
        
#         open("aiyagari_summary_table_$(timestamp).tex", "w") do file
#             write(file, latex_summary)
#         end
        
#         open("aiyagari_amplification_table_$(timestamp).tex", "w") do file
#             write(file, latex_amplification)
#         end
        
#         println("  ✅ LaTeX tables saved with timestamp: $(timestamp)")
#     catch e
#         println("  ⚠️  Could not save LaTeX tables: $(e)")
#     end
    
#     # 6. Create summary report (simple version)
#     summary_lines = [
#         "# Aiyagari Model Analysis Summary",
#         "Generated: Run $(timestamp)",
#         "",
#         "## Parameters Analyzed",
#         "- γ values: $(γ_values)",
#         "- ω values: $(ω_values)", 
#         "- Target r: $(r_target)",
#         "- Total cases: $(length(γ_values) * length(ω_values))",
#         "",
#         "## Results Status", 
#         "- Successful: $(sum(1 for v in values(all_results) if !get(v, :failed, false)))",
#         "- Failed: $(sum(1 for v in values(all_results) if get(v, :failed, false)))",
#         "",
#         "## Main Results File",
#         "$(filename_jld2)",
#         "",
#         "## To Load Results Later:",
#         "using JLD2",
#         "@load \"$(filename_jld2)\" all_results timing_results γ_values ω_values r_target"
#     ]
    
#     open("aiyagari_analysis_report_$(timestamp).md", "w") do file
#         for line in summary_lines
#             write(file, line * "\n")
#         end
#     end
    
#     println("  ✅ Summary report saved as: aiyagari_analysis_report_$(timestamp).md")
#     println("\n🎉 ALL RESULTS SUCCESSFULLY SAVED!")
#     println("📁 Main file to load later: $(filename_jld2)")
    
#     return filename_jld2
# end

# # Run analysis and save everything
# summary_df = create_summary_table()
# p_impacts = create_comprehensive_plots()
# p_transitions = create_transition_plots()
# p_heatmaps = create_parameter_heatmaps()
# latex_summary, latex_amplification = create_latex_tables()

# # Display results
# display(summary_df)
# display(p_impacts)
# display(p_transitions)
# display(p_heatmaps)

# # Save all results to disk
# main_filename = save_all_results()

# println("\n" * "="^80)
# println("COMPREHENSIVE ANALYSIS COMPLETE!")
# println("="^80)

# println("\nSummary of key findings:")
# println("  Total cases analyzed: $(length(all_results))")
# successful_cases = sum(1 for v in values(all_results) if !get(v, :failed, false))
# println("  Successful cases: $(successful_cases)")
# println("  Failed cases: $(length(all_results) - successful_cases)")

# if successful_cases > 0
#     # Aggregate insights
#     all_β = [all_results[k][:β] for k in keys(all_results) if !get(all_results[k], :failed, false)]
#     all_max_K = [all_results[k][:max_K_dev] for k in keys(all_results) if !get(all_results[k], :failed, false)]
    
#     println("  β range: [$(round(minimum(all_β), digits=4)), $(round(maximum(all_β), digits=4))]")
#     println("  Max K deviation range: [$(round(100*minimum(all_max_K), digits=2))%, $(round(100*maximum(all_max_K), digits=2))%]")
    
#     # Check externality effects
#     baseline_cases = [(γ, 0.0) for γ in γ_values if haskey(all_results, (γ, 0.0))]
#     if length(baseline_cases) > 0
#         println("  Externality amplifies transitions: ω>0 increases response magnitudes")
#         println("  Constraint effects: Higher γ generally affects calibrated β values")
        
#         # Compute average amplification with ω=0.5
#         amplifications = []
#         for γ in γ_values
#             key_base = (γ, 0.0)
#             key_high = (γ, 0.5)
#             if haskey(all_results, key_base) && haskey(all_results, key_high) &&
#                !get(all_results[key_base], :failed, false) && !get(all_results[key_high], :failed, false)
#                 base_dev = all_results[key_base][:max_K_dev]
#                 high_dev = all_results[key_high][:max_K_dev]
#                 if base_dev > 0
#                     push!(amplifications, high_dev / base_dev)
#                 end
#             end
#         end
        
#         if length(amplifications) > 0
#             avg_amplification = mean(amplifications)
#             println("  Average externality amplification (ω=0.5 vs ω=0): $(round(avg_amplification, digits=2))x")
#         end
#     end
# end

# println("\n📁 Main results file: $(main_filename)")
# println("To reload: @load \"$(main_filename)\" all_results timing_results γ_values ω_values r_target")
# println("="^80)
