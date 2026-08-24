using Plots, JLD2, Dates

# ==============================================================================
# FIND AND LOAD MOST RECENT DATA FILE
# ==============================================================================

println("🔍 Searching for most recent data file...")

# Get all .jld2 files in current directory that might contain our results
current_dir = pwd()
all_files = readdir(current_dir)

# Filter for .jld2 files (assuming that's the format based on @load usage)
jld2_files = filter(f -> endswith(f, ".jld2"), all_files)

if isempty(jld2_files)
    println("❌ No .jld2 files found in current directory")
    println("Looking for alternative file patterns...")
    
    # Try other common Julia save formats
    alt_files = filter(f -> any(endswith(f, ext) for ext in [".jld", ".bson", ".dat"]), all_files)
    
    if isempty(alt_files)
        error("No suitable data files found. Please ensure data files are in the current directory.")
    else
        jld2_files = alt_files
        println("Found $(length(alt_files)) alternative format files")
    end
end

# Sort by modification time (most recent first)
file_times = [(f, mtime(joinpath(current_dir, f))) for f in jld2_files]
sort!(file_times, by=x->x[2], rev=true)

most_recent_file = file_times[1][1]
println("📂 Most recent file: $(most_recent_file)")
println("🕐 Modified: $(Dates.unix2datetime(file_times[1][2]))")

# Initialize global variables
global all_results, γ_values, ω_values

# Try to load the data
try
    # Load the data (adjust the variable names if they're different in your files)
    data = load(most_recent_file)
    
    # Extract the required variables and assign to global scope
    # Try different possible variable names
    global all_results = get(data, "all_results", get(data, :all_results, nothing))
    global γ_values = get(data, "γ_values", get(data, :γ_values, get(data, "gamma_values", nothing)))
    global ω_values = get(data, "ω_values", get(data, :ω_values, get(data, "omega_values", nothing)))
    
    if any(isnothing.([all_results, γ_values, ω_values]))
        println("Available variables in file:")
        for key in keys(data)
            println("  - $(key)")
        end
        error("Required variables not found. Please check variable names in the data file.")
    end
    
    println("✅ Successfully loaded data:")
    println("   - all_results: $(length(all_results)) entries")
    println("   - γ_values: $(γ_values)")
    println("   - ω_values: $(ω_values)")
    
catch e
    println("❌ Error loading file: $(e)")
    error("Could not load data from $(most_recent_file)")
end

# ==============================================================================
# CREATE SIDE-BY-SIDE CONSUMPTION AND OUTPUT IMPACT RESPONSE FIGURE
# ==============================================================================

println("\n🎨 Creating side-by-side Consumption and Output Impact Response figure...")

# Create a 1x2 layout for side-by-side plots
p_combined = Plots.plot(layout=(1,2), size=(1200, 500))

# Styling consistent with black & white theme
line_styles = [:solid, :dash, :dot, :dashdot, :dashdotdot, :solid, :dash]
markers = [:circle, :square, :diamond, :utriangle, :dtriangle, :star5, :cross]

for (idx, γ) in enumerate(γ_values)
    C_impacts, Y_impacts, ω_plot = Float64[], Float64[], Float64[]
    
    for ω in ω_values
        key = (γ, ω)
        if haskey(all_results, key) && !get(all_results[key], :failed, false)
            res = all_results[key]
            push!(C_impacts, res[:C_impact])
            push!(Y_impacts, res[:Y_impact])
            push!(ω_plot, ω)
        end
    end
    
    if length(ω_plot) > 0
        # Consumption Impact Response (left panel)
        Plots.plot!(p_combined[1], ω_plot, C_impacts, label="γ=$(γ)", 
              linewidth=3, linestyle=line_styles[idx], marker=markers[idx],
              markersize=6, color=:black,
              title="Consumption Impact Response", 
              xlabel="Externality Parameter (ω)", 
              ylabel="% deviation from steady state",
              legend=:topleft,
              grid=true, gridwidth=1, gridcolor=:gray,
              guidefontsize=12, titlefontsize=14, legendfontsize=11)
        
        # Output Impact Response (right panel)  
        Plots.plot!(p_combined[2], ω_plot, Y_impacts, label="γ=$(γ)", 
              linewidth=3, linestyle=line_styles[idx], marker=markers[idx],
              markersize=6, color=:black,
              title="Output Impact Response", 
              xlabel="Externality Parameter (ω)", 
              ylabel="% deviation from steady state",
              legend=:topleft,
              grid=true, gridwidth=1, gridcolor=:gray,
              guidefontsize=12, titlefontsize=14, legendfontsize=11)
    end
end

# Save the combined figure with timestamp from loaded file
file_timestamp = split(most_recent_file, ".")[1]  # Remove extension
combined_filename = "aiyagari_combined_impact_responses_from_$(file_timestamp).png"
Plots.savefig(p_combined, combined_filename)
println("✅ Side-by-side impact responses saved as: $(combined_filename)")
println("📊 Based on data from: $(most_recent_file)")

# Display the combined plot
display(p_combined)
