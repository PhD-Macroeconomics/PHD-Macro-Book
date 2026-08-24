# EMERGENCY FIX - HANDLE MIXED DATA TYPES PROPERLY
# Run this in your current Julia session

println("🔧 EMERGENCY FIX - HANDLING MIXED DATA TYPES")

# FIXED create_summary_table function - no transpose needed
function create_summary_table_emergency()
    println("Creating summary statistics table (EMERGENCY FIX)...")
    
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

# FIXED comprehensive plots function
function create_comprehensive_plots_emergency()
    println("Creating comprehensive visualization...")
    
    # Plot 1: Impact responses across all cases
    p_impacts = plot(layout=(2,2), size=(1000, 800))
    
    for γ in γ_values
        K_impacts = Float64[]
        C_impacts = Float64[]
        Y_impacts = Float64[]
        ω_plot = Float64[]
        
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
            plot!(p_impacts[1], ω_plot, K_impacts, label="γ=$(γ)", linewidth=2, marker=:circle,
                  title="Capital Impact Response", xlabel="ω", ylabel="% deviation")
            plot!(p_impacts[2], ω_plot, C_impacts, label="γ=$(γ)", linewidth=2, marker=:circle,
                  title="Consumption Impact Response", xlabel="ω", ylabel="% deviation")
            plot!(p_impacts[3], ω_plot, Y_impacts, label="γ=$(γ)", linewidth=2, marker=:circle,
                  title="Output Impact Response", xlabel="ω", ylabel="% deviation")
        end
    end
    
    # Plot maximum deviations
    for γ in γ_values
        max_K_devs = Float64[]
        ω_plot = Float64[]
        
        for ω in ω_values
            key = (γ, ω)
            if haskey(all_results, key) && !get(all_results[key], :failed, false)
                res = all_results[key]
                push!(max_K_devs, res[:max_K_dev]*100)
                push!(ω_plot, ω)
            end
        end
        
        if length(ω_plot) > 0
            plot!(p_impacts[4], ω_plot, max_K_devs, label="γ=$(γ)", linewidth=2, marker=:circle,
                  title="Maximum Capital Deviation", xlabel="ω", ylabel="% max deviation")
        end
    end
    
    return p_impacts
end

# FIXED transition plots function
function create_transition_plots_emergency()
    println("Creating detailed transition dynamics...")
    
    # Select interesting cases for detailed analysis
    selected_cases = [(0.0, 0.0), (0.0, 0.1), (0.0, 0.2), (0.3, 0.0), (0.3, 0.1), (0.3, 0.2)]
    
    T_plot = 50
    periods = 0:(T_plot-1)
    colors = [:blue, :red, :green, :purple, :orange, :brown]
    
    p_trans = plot(layout=(2,3), size=(1200, 800))
    
    for (i, (γ, ω)) in enumerate(selected_cases)
        key = (γ, ω)
        if haskey(all_results, key) && !get(all_results[key], :failed, false)
            res = all_results[key]
            
            # Ensure we have enough data points
            max_plot = min(T_plot, length(res[:K_path]))
            periods_actual = 0:(max_plot-1)
            
            # Capital
            K_dev = 100 * (res[:K_path][1:max_plot] .- res[:K_ss]) ./ res[:K_ss]
            plot!(p_trans[1], periods_actual, K_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
            
            # Consumption  
            C_dev = 100 * (res[:C_path][1:max_plot] .- res[:C_ss]) ./ res[:C_ss]
            plot!(p_trans[2], periods_actual, C_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
            
            # Output
            Y_dev = 100 * (res[:Y_path][1:max_plot] .- 1.0) ./ 1.0
            plot!(p_trans[3], periods_actual, Y_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
            
            # Investment
            I_ss = res[:np].mp.δ * res[:K_ss]
            I_dev = 100 * (res[:I_path][1:max_plot] .- I_ss) ./ I_ss
            plot!(p_trans[4], periods_actual, I_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
            
            # Interest rate
            r_dev = 100 * (res[:r_path][1:max_plot] .- 0.01) ./ 0.01
            plot!(p_trans[5], periods_actual, r_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
            
            # Wage
            w_dev = 100 * (res[:w_path][1:max_plot] .- res[:w_ss]) ./ res[:w_ss]
            plot!(p_trans[6], periods_actual, w_dev, linewidth=2, color=colors[i], 
                  label="γ=$(γ), ω=$(ω)")
        end
    end
    
    plot!(p_trans[1], title="Capital", xlabel="Periods", ylabel="% dev from SS", legend=:topright)
    plot!(p_trans[2], title="Consumption", xlabel="Periods", ylabel="% dev from SS", legend=:topright)
    plot!(p_trans[3], title="Output", xlabel="Periods", ylabel="% dev from SS", legend=:topright)
    plot!(p_trans[4], title="Investment", xlabel="Periods", ylabel="% dev from SS", legend=:topright) 
    plot!(p_trans[5], title="Interest Rate", xlabel="Periods", ylabel="% dev from SS", legend=:topright)
    plot!(p_trans[6], title="Wage", xlabel="Periods", ylabel="% dev from SS", legend=:topright)
    
    return p_trans
end

# Create heat maps for parameter interactions
function create_parameter_heatmaps_emergency()
    println("Creating parameter interaction heatmaps...")
    
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
    
    p_heatmaps = plot(layout=(2,2), size=(1000, 800))
    
    heatmap!(p_heatmaps[1], ω_values, γ_values, β_matrix, 
             title="Calibrated β", xlabel="ω", ylabel="γ", color=:viridis)
    
    heatmap!(p_heatmaps[2], ω_values, γ_values, K_impact_matrix, 
             title="Capital Impact (%)", xlabel="ω", ylabel="γ", color=:plasma)
    
    heatmap!(p_heatmaps[3], ω_values, γ_values, C_impact_matrix, 
             title="Consumption Impact (%)", xlabel="ω", ylabel="γ", color=:cividis)
    
    heatmap!(p_heatmaps[4], ω_values, γ_values, max_K_dev_matrix, 
             title="Max Capital Deviation (%)", xlabel="ω", ylabel="γ", color=:inferno)
    
    return p_heatmaps
end

# Create LaTeX tables
function create_latex_tables_emergency()
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
\\textbf{γ} & \\textbf{Base Response} & \\textbf{ω=0.1 Response} & \\textbf{ω=0.2 Response} & \\textbf{Amplification} \\\\
 & \\textbf{(ω=0)} & \\textbf{Capital \\%} & \\textbf{Capital \\%} & \\textbf{Ratio} \\\\
\\hline
"""
    
    for γ in γ_values
        key_base = (γ, 0.0)
        key_01 = (γ, 0.1)
        key_02 = (γ, 0.2)
        
        if all(haskey(all_results, k) && !get(all_results[k], :failed, false) for k in [key_base, key_01, key_02])
            base_response = all_results[key_base][:max_K_dev] * 100
            response_01 = all_results[key_01][:max_K_dev] * 100
            response_02 = all_results[key_02][:max_K_dev] * 100
            amplification = base_response > 0 ? response_02 / base_response : 1.0
            
            latex_amplification *= @sprintf("%.1f & %.2f & %.2f & %.2f & %.2f \\\\\n",
                γ, base_response, response_01, response_02, amplification)
        end
    end
    
    latex_amplification *= """\\hline
\\multicolumn{5}{l}{\\footnotesize Notes: Maximum capital deviations during transition.} \\\\
\\multicolumn{5}{l}{\\footnotesize Amplification = Response(ω=0.2) / Response(ω=0).} \\\\
\\end{tabular}
\\end{table}
"""
    
    return latex_summary, latex_amplification
end

# =============================================================================
# RUN THE EMERGENCY PROCESSING
# =============================================================================

println("🚨 EMERGENCY PROCESSING - ATTEMPT #2 WITH TYPE-SAFE APPROACH")

try
    # Process and save everything
    summary_df = create_summary_table_emergency()
    println("✅ Summary table created successfully!")
    
    p_impacts = create_comprehensive_plots_emergency()
    println("✅ Impact plots created successfully!")
    
    p_transitions = create_transition_plots_emergency()
    println("✅ Transition plots created successfully!")
    
    p_heatmaps = create_parameter_heatmaps_emergency()
    println("✅ Heatmaps created successfully!")
    
    latex_summary, latex_amplification = create_latex_tables_emergency()
    println("✅ LaTeX tables created successfully!")

    # Display key results
    println("\n" * "="^80)
    println("SUCCESSFULLY PROCESSED RESULTS!")
    println("="^80)
    display(summary_df)

    # Save everything immediately
    CSV.write("comprehensive_analysis_summary_FIXED.csv", summary_df)
    savefig(p_impacts, "impact_responses_comprehensive_FIXED.png")
    savefig(p_transitions, "transition_dynamics_comprehensive_FIXED.png")
    savefig(p_heatmaps, "parameter_interaction_heatmaps_FIXED.png")

    # Save LaTeX tables
    open("comprehensive_summary_table_FIXED.tex", "w") do file
        write(file, latex_summary)
    end

    open("externality_amplification_table_FIXED.tex", "w") do file
        write(file, latex_amplification)
    end

    println("\n✅ ALL FILES SAVED SUCCESSFULLY!")
    println("Files generated:")
    println("  - comprehensive_analysis_summary_FIXED.csv")
    println("  - impact_responses_comprehensive_FIXED.png") 
    println("  - transition_dynamics_comprehensive_FIXED.png")
    println("  - parameter_interaction_heatmaps_FIXED.png")
    println("  - comprehensive_summary_table_FIXED.tex")
    println("  - externality_amplification_table_FIXED.tex")

    # Show summary statistics
    successful_cases = sum(1 for v in values(all_results) if !get(v, :failed, false))
    println("\n📊 SUMMARY STATISTICS:")
    println("  Total cases analyzed: $(length(all_results))")
    println("  Successful cases: $(successful_cases)")
    println("  Failed cases: $(length(all_results) - successful_cases)")

    if successful_cases > 0
        all_β = [all_results[k][:β] for k in keys(all_results) if !get(all_results[k], :failed, false)]
        all_max_K = [all_results[k][:max_K_dev] for k in keys(all_results) if !get(all_results[k], :failed, false)]
        
        println("  β range: [$(round(minimum(all_β), digits=4)), $(round(maximum(all_β), digits=4))]")
        println("  Max K deviation range: [$(round(100*minimum(all_max_K), digits=2))%, $(round(100*maximum(all_max_K), digits=2))%]")
        
        # Compute average amplification
        amplifications = Float64[]
        for γ in γ_values
            key_base = (γ, 0.0)
            key_high = (γ, 0.2)
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
            using Statistics
            avg_amplification = mean(amplifications)
            println("  Average externality amplification (ω=0.2 vs ω=0): $(round(avg_amplification, digits=2))x")
        end
    end

    # Display the plots
    println("\n📊 DISPLAYING RESULTS...")
    display(p_impacts)
    display(p_transitions) 
    display(p_heatmaps)

    println("\n🎉 YOUR 12 HOURS OF COMPUTATION HAS BEEN SUCCESSFULLY RESCUED!")
    
catch e
    println("❌ Error in emergency processing: $(e)")
    println("🔍 Let's debug this step by step...")
    
    # Debug information
    println("Debug info:")
    if @isdefined(all_results) && length(all_results) > 0
        sample_key = first(keys(all_results))
        sample_result = all_results[sample_key]
        println("  Sample result structure:")
        for (k, v) in sample_result
            println("    $(k): $(typeof(v))")
        end
    end
    
    # Try to save raw data as backup
    try
        println("💾 Attempting to save raw data as backup...")
        using Serialization
        serialize("all_results_backup.jld", all_results)
        println("✅ Raw data saved to all_results_backup.jld")
    catch backup_error
        println("❌ Could not save backup: $(backup_error)")
    end
end
