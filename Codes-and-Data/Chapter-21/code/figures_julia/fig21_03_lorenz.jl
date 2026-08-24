# SCF Lorenz Curves - CSV Format
# Works with Julia 1.9+

using Plots
using Statistics
using Printf

# Use GR backend consistently
gr() 
println("Using GR backend for PDF outputs")

# Check for PDF-to-EPS conversion tools on Ubuntu
function check_eps_tools()
    println("\nChecking PDF-to-EPS conversion tools...")
    
    tools_available = []
    
    # Check for pdftops (poppler-utils)
    try
        run(`which pdftops`)
        println("✅ pdftops (poppler-utils) available")
        push!(tools_available, "pdftops")
    catch
        println("❌ pdftops not found")
    end
    
    # Check for Ghostscript
    try
        run(`which gs`)
        println("✅ Ghostscript available")
        push!(tools_available, "ghostscript")
    catch
        println("❌ Ghostscript not found")
    end
    
    # Check for Inkscape
    try
        run(`which inkscape`)
        println("✅ Inkscape available")
        push!(tools_available, "inkscape")
    catch
        println("❌ Inkscape not found")
    end
    
    if isempty(tools_available)
        println("\n⚠️  No PDF-to-EPS conversion tools found!")
        println("To install on Ubuntu, run:")
        println("  sudo apt update")
        println("  sudo apt install poppler-utils ghostscript inkscape")
        println("\nProceeding with PDF generation only...")
        return false
    else
        println("\n✅ PDF-to-EPS conversion available using: $(join(tools_available, ", "))")
        return true
    end
end

# Check tools at startup
eps_conversion_available = check_eps_tools()

# Function to convert PDF to EPS using system tools (Ubuntu/Linux)
function pdf_to_eps_system(pdf_filename)
    eps_filename = replace(pdf_filename, ".pdf" => ".eps")
    
    # Method 1: Try pdftops (part of poppler-utils)
    try
        run(`pdftops -eps $pdf_filename $eps_filename`)
        if isfile(eps_filename) && filesize(eps_filename) > 0
            println("  ✅ EPS converted successfully using pdftops: $eps_filename")
            return true
        end
    catch e
        println("  pdftops method failed: $e")
    end
    
    # Method 2: Try gs (Ghostscript)
    try
        run(`gs -dNOPAUSE -dBATCH -sDEVICE=epswrite -sOutputFile=$eps_filename $pdf_filename`)
        if isfile(eps_filename) && filesize(eps_filename) > 0
            println("  ✅ EPS converted successfully using Ghostscript: $eps_filename")
            return true
        end
    catch e
        println("  Ghostscript method failed: $e")
    end
    
    # Method 3: Try inkscape
    try
        run(`inkscape --export-type=eps $pdf_filename`)
        # Inkscape creates filename with .eps extension automatically
        potential_eps = replace(pdf_filename, ".pdf" => ".eps")
        if isfile(potential_eps) && filesize(potential_eps) > 0
            println("  ✅ EPS converted successfully using Inkscape: $potential_eps")
            return true
        end
    catch e
        println("  Inkscape method failed: $e")
    end
    
    println("  ❌ All PDF-to-EPS conversion methods failed for $pdf_filename")
    return false
end

# Function to try multiple EPS export methods with system fallback
function save_eps_multiple_methods(plot_obj, filename_base)
    eps_success = false
    
    # Method 1: Direct Plots.eps function
    try
        Plots.eps(plot_obj, filename_base)
        if isfile("$filename_base.eps") && filesize("$filename_base.eps") > 0
            println("  ✅ EPS saved (Method 1): $filename_base.eps")
            return true
        end
    catch e
        println("  Method 1 failed: $(typeof(e))")
    end
    
    # Method 2: savefig with .eps extension
    try
        savefig(plot_obj, "$filename_base.eps")
        sleep(0.2)
        if isfile("$filename_base.eps") && filesize("$filename_base.eps") > 0
            println("  ✅ EPS saved (Method 2): $filename_base.eps")
            return true
        end
    catch e
        println("  Method 2 failed: $(typeof(e))")
    end
    
    # Method 3: Convert PDF to EPS using system tools (only if available)
    if eps_conversion_available
        println("  Trying PDF-to-EPS conversion...")
        pdf_file = "$filename_base.pdf"
        if isfile(pdf_file)
            eps_success = pdf_to_eps_system(pdf_file)
            if eps_success
                return true
            end
        else
            println("  PDF file not found for conversion: $pdf_file")
        end
    else
        println("  Skipping PDF-to-EPS conversion (no tools available)")
    end
    
    println("  ❌ All EPS methods failed for $filename_base")
    return false
end

"""
Load CSV SCF data manually
"""
function load_scf_csv_manual(filename="SCFP2022.csv")
    println("Loading SCF data from CSV file...")
    
    # Read all lines
    lines = readlines(filename)
    println("Read $(length(lines)) lines from file")
    
    # Parse header - split by comma
    header_line = lines[1]
    headers = split(header_line, ',')
    # Clean up headers
    headers = [strip(h) for h in headers]
    
    println("Found $(length(headers)) columns")
    println("First 10 columns: $(headers[1:10])")
    
    # Find required column indices
    required_cols = ["WGT", "WAGEINC", "BUSSEFARMINC", "NETWORTH", "HOUSES"]
    col_indices = Dict{String, Int}()
    
    for (i, header) in enumerate(headers)
        if header in required_cols
            col_indices[header] = i
            println("✅ Found $header at column $i")
        end
    end
    
    # Check if all required columns found
    missing_cols = setdiff(required_cols, keys(col_indices))
    if !isempty(missing_cols)
        println("❌ Missing required columns: $missing_cols")
        println("Available columns containing these strings:")
        for missing_col in missing_cols
            for (i, header) in enumerate(headers)
                if occursin(lowercase(missing_col[1:3]), lowercase(header))
                    println("  Column $i: $header")
                end
            end
        end
        error("Missing required columns: $missing_cols")
    end
    
    println("✅ All required columns found!")
    
    # Initialize data arrays
    n_rows = length(lines) - 1  # Subtract header
    data = Dict{String, Vector{Float64}}()
    for col in required_cols
        data[col] = Vector{Float64}(undef, n_rows)
    end
    
    println("Parsing $n_rows data rows...")
    
    # Parse data rows
    for (row_idx, line) in enumerate(lines[2:end])
        if row_idx % 5000 == 0
            println("  Processed $row_idx rows...")
        end
        
        # Split by comma
        fields = split(line, ',')
        
        # Extract required columns
        for col in required_cols
            col_idx = col_indices[col]
            if col_idx <= length(fields)
                val_str = strip(fields[col_idx])
                if isempty(val_str) || val_str in ["NA", ".", "NaN", "NULL", ""]
                    data[col][row_idx] = NaN
                else
                    try
                        data[col][row_idx] = parse(Float64, val_str)
                    catch
                        data[col][row_idx] = NaN
                    end
                end
            else
                data[col][row_idx] = NaN
            end
        end
    end
    
    println("✅ Data loading complete!")
    
    # Print summary
    for col in required_cols
        valid_count = sum(.!isnan.(data[col]))
        if valid_count > 0
            mean_val = mean(filter(!isnan, data[col]))
            println("$col: $valid_count valid values, mean = $(round(mean_val, digits=2))")
        else
            println("$col: No valid values found!")
        end
    end
    
    return data
end

"""
Calculate Lorenz curve points and Gini coefficient
"""
function calculate_lorenz_gini(values, weights)
    # Remove NaN values
    valid_mask = .!isnan.(values) .& .!isnan.(weights) .& (weights .> 0)
    clean_values = values[valid_mask]
    clean_weights = weights[valid_mask]
    
    if isempty(clean_values)
        return ([0.0, 1.0], [0.0, 1.0], 0.0)
    end
    
    # Sort by values
    sorted_indices = sortperm(clean_values)
    sorted_values = clean_values[sorted_indices]
    sorted_weights = clean_weights[sorted_indices]
    
    # Calculate cumulative proportions
    cumulative_weights = cumsum(sorted_weights)
    cumulative_values = cumsum(sorted_values .* sorted_weights)
    
    total_weight = sum(sorted_weights)
    total_value = sum(sorted_values .* sorted_weights)
    
    # Handle edge case
    if total_value <= 0
        return ([0.0, 1.0], [0.0, 1.0], 0.0)
    end
    
    # Lorenz curve points
    x_lorenz = [0.0; cumulative_weights ./ total_weight]
    y_lorenz = [0.0; cumulative_values ./ total_value]
    
    # Calculate Gini coefficient
    area_under_curve = 0.0
    for i in 2:length(x_lorenz)
        width = x_lorenz[i] - x_lorenz[i-1]
        height = (y_lorenz[i] + y_lorenz[i-1]) / 2
        area_under_curve += width * height
    end
    gini = 1 - 2 * area_under_curve
    
    return (x_lorenz, y_lorenz, gini)
end

"""
Calculate weighted percentiles
"""
function weighted_percentiles(values, weights, percentiles=[10, 25, 50, 75, 90, 95, 99])
    valid_mask = .!isnan.(values) .& .!isnan.(weights) .& (weights .> 0)
    clean_values = values[valid_mask]
    clean_weights = weights[valid_mask]
    
    sorted_indices = sortperm(clean_values)
    sorted_values = clean_values[sorted_indices]
    sorted_weights = clean_weights[sorted_indices]
    
    cumulative_weights = cumsum(sorted_weights)
    total_weight = sum(sorted_weights)
    
    results = Dict{Int, Float64}()
    for p in percentiles
        target_weight = total_weight * p / 100
        idx = findfirst(x -> x >= target_weight, cumulative_weights)
        if idx !== nothing
            results[p] = sorted_values[idx]
        else
            results[p] = sorted_values[end]
        end
    end
    
    return results
end

"""
Create and save Lorenz curve plot (both PDF and EPS) - Black & White friendly
"""
function create_lorenz_plot(x_data, y_data, gini, title_text, filename)
    println("Creating plot: $filename")
    
    try
        p = plot(x_data, y_data, 
                 label="Lorenz Curve", 
                 color=:black, 
                 linewidth=3,
                 linestyle=:solid,
                 title="$title_text\nGini Coefficient: $(round(gini, digits=3))",
                 xlabel="Cumulative Population Share (%)",
                 ylabel="Cumulative Wealth Share (%)",
                 xlims=(0, 1),
                 ylims=(0, 1),
                 grid=true,
                 gridcolor=:gray,
                 gridwidth=1,
                 gridlinestyle=:dot,
                 size=(600, 500),
                 dpi=300,
                 thickness_scaling=1.2,
                 background_color=:white,
                 foreground_color=:black)
        
        # Add equality line
        plot!(p, [0, 1], [0, 1], 
              label="Perfect Equality", 
              color=:gray, 
              linestyle=:dash, 
              linewidth=2)
        
        # Fill area with pattern instead of color
        plot!(p, x_data, y_data, 
              fillrange=x_data, 
              fillalpha=0.15, 
              fillcolor=:gray, 
              label="")
        
        # Format axes as percentages
        plot!(p, 
              xformatter = x -> "$(Int(round(x*100)))%",
              yformatter = y -> "$(Int(round(y*100)))%")
        
        # Force display and process
        display(p)
        
        # Save as PDF
        println("  Saving PDF...")
        savefig(p, "$filename.pdf")
        
        # Check if PDF was created successfully
        if isfile("$filename.pdf") && filesize("$filename.pdf") > 0
            println("  ✅ PDF saved successfully: $filename.pdf")
        else
            println("  ❌ PDF save failed: $filename.pdf")
        end
        
        # Save as EPS using multiple methods
        println("  Saving EPS...")
        save_eps_multiple_methods(p, filename)
        
        return p
        
    catch e
        println("  ❌ Error creating plot $filename: $e")
        return nothing
    end
end

"""
Create comparison plot with two Lorenz curves - Black & White friendly
"""
function create_comparison_plot(x_data1, y_data1, gini1, label1, linestyle1,
                               x_data2, y_data2, gini2, label2, linestyle2,
                               title_text, filename)
    
    println("Creating comparison plot: $filename")
    
    try
        p = plot(x_data1, y_data1, 
                 label="$label1 (Gini: $(round(gini1, digits=3)))", 
                 color=:black, 
                 linewidth=3,
                 linestyle=linestyle1,
                 title=title_text,
                 xlabel="Cumulative Population Share (%)",
                 ylabel="Cumulative Wealth Share (%)",
                 xlims=(0, 1),
                 ylims=(0, 1),
                 grid=true,
                 gridcolor=:gray,
                 gridwidth=1,
                 gridlinestyle=:dot,
                 size=(700, 550),
                 dpi=300,
                 thickness_scaling=1.2,
                 background_color=:white,
                 foreground_color=:black)
        
        # Add second curve
        plot!(p, x_data2, y_data2, 
              label="$label2 (Gini: $(round(gini2, digits=3)))", 
              color=:gray30, 
              linewidth=3,
              linestyle=linestyle2)
        
        # Add equality line
        plot!(p, [0, 1], [0, 1], 
              label="Perfect Equality", 
              color=:gray, 
              linestyle=:dot, 
              linewidth=2)
        
        # Format axes as percentages
        plot!(p, 
              xformatter = x -> "$(Int(round(x*100)))%",
              yformatter = y -> "$(Int(round(y*100)))%")
        
        # Force display and process
        display(p)
        
        # Save as PDF
        println("  Saving PDF...")
        savefig(p, "$filename.pdf")
        
        # Check if PDF was created successfully
        if isfile("$filename.pdf") && filesize("$filename.pdf") > 0
            println("  ✅ PDF saved successfully: $filename.pdf")
        else
            println("  ❌ PDF save failed: $filename.pdf")
        end
        
        # Save as EPS using multiple methods
        println("  Saving EPS...")
        save_eps_multiple_methods(p, filename)
        
        return p
        
    catch e
        println("  ❌ Error creating comparison plot $filename: $e")
        return nothing
    end
end

"""
Format currency
"""
function format_currency(value)
    if abs(value) >= 1e6
        return @sprintf("\$%.1fM", value / 1e6)
    elseif abs(value) >= 1e3
        return @sprintf("\$%.0fK", value / 1e3)
    else
        return @sprintf("\$%.0f", value)
    end
end

"""
Main analysis function
"""
function analyze_scf_csv(filename="SCFP2022.csv")
    println("="^70)
    println("SCF LORENZ CURVE ANALYSIS - BLACK & WHITE PRINT VERSION")
    println("="^70)
    
    # Load data
    data = load_scf_csv_manual(filename)
    
    # Create labor income variable: wages + 0.812 * business income
    labor_income = data["WAGEINC"] .+ 0.812 .* data["BUSSEFARMINC"]
    println("\n✅ Created labor income variable: WAGEINC + 0.812 * BUSSEFARMINC")
    
    # Extract other variables
    wage_income = data["WAGEINC"]  # Just wage income for comparison
    net_worth = data["NETWORTH"]
    residential_wealth = data["HOUSES"]
    weights = data["WGT"]
    
    println("\nCalculating Lorenz curves...")
    
    # Calculate Lorenz curves for all variables
    x_labor, y_labor, gini_labor = calculate_lorenz_gini(labor_income, weights)
    x_wage, y_wage, gini_wage = calculate_lorenz_gini(wage_income, weights)
    x_networth, y_networth, gini_networth = calculate_lorenz_gini(net_worth, weights)
    x_residential, y_residential, gini_residential = calculate_lorenz_gini(residential_wealth, weights)
    
    # Calculate summary statistics
    println("Calculating summary statistics...")
    
    function weighted_mean(vals, wts)
        valid_mask = .!isnan.(vals) .& .!isnan.(wts) .& (wts .> 0)
        if sum(valid_mask) == 0
            return NaN
        end
        return sum(vals[valid_mask] .* wts[valid_mask]) / sum(wts[valid_mask])
    end
    
    labor_mean = weighted_mean(labor_income, weights)
    wage_mean = weighted_mean(wage_income, weights)
    networth_mean = weighted_mean(net_worth, weights)
    residential_mean = weighted_mean(residential_wealth, weights)
    
    labor_pct = weighted_percentiles(labor_income, weights)
    wage_pct = weighted_percentiles(wage_income, weights)
    networth_pct = weighted_percentiles(net_worth, weights)
    residential_pct = weighted_percentiles(residential_wealth, weights)
    
    # Print results
    println("\n" * "="^70)
    println("RESULTS")
    println("="^70)
    
    println("\nGINI COEFFICIENTS:")
    println("Labor Income (Wages + 0.812×Business):  $(round(gini_labor, digits=3))")
    println("Wage Income (WAGEINC only):              $(round(gini_wage, digits=3))")
    println("Net Worth:                               $(round(gini_networth, digits=3))")
    println("Residential Wealth:                      $(round(gini_residential, digits=3))")
    
    println("\nSUMMARY STATISTICS (Survey-Weighted):")
    
    println("\nLabor Income (Wages + 0.812×Business):")
    println("  Mean:           $(format_currency(labor_mean))")
    println("  Median (50th):  $(format_currency(labor_pct[50]))")
    println("  90th percentile: $(format_currency(labor_pct[90]))")
    println("  99th percentile: $(format_currency(labor_pct[99]))")
    
    println("\nWage Income (WAGEINC only):")
    println("  Mean:           $(format_currency(wage_mean))")
    println("  Median (50th):  $(format_currency(wage_pct[50]))")
    println("  90th percentile: $(format_currency(wage_pct[90]))")
    println("  99th percentile: $(format_currency(wage_pct[99]))")
    
    println("\nNet Worth:")
    println("  Mean:           $(format_currency(networth_mean))")
    println("  Median (50th):  $(format_currency(networth_pct[50]))")
    println("  90th percentile: $(format_currency(networth_pct[90]))")
    println("  99th percentile: $(format_currency(networth_pct[99]))")
    
    println("\nResidential Wealth:")
    println("  Mean:           $(format_currency(residential_mean))")
    println("  Median (50th):  $(format_currency(residential_pct[50]))")
    println("  90th percentile: $(format_currency(residential_pct[90]))")
    println("  99th percentile: $(format_currency(residential_pct[99]))")
    
    # Create plots
    println("\n" * "="^50)
    println("GENERATING PLOTS")
    println("="^50)
    
    # Individual plots (with pauses to ensure proper saving)
    println("\n1. Creating individual Lorenz curve plots...")
    
    p1 = create_lorenz_plot(x_labor, y_labor, gini_labor, 
                           "Labor Income Distribution\n(Wages + 0.812 × Business Income)", 
                           "scf_lorenz_labor_income")
    sleep(1)  # Give time for file operations
    
    p2 = create_lorenz_plot(x_wage, y_wage, gini_wage, 
                           "Wage Income Distribution\n(WAGEINC only)", 
                           "scf_lorenz_wage_income")
    sleep(1)
    
    p3 = create_lorenz_plot(x_networth, y_networth, gini_networth, 
                           "Net Worth Distribution", 
                           "scf_lorenz_net_worth")
    sleep(1)
    
    p4 = create_lorenz_plot(x_residential, y_residential, gini_residential, 
                           "Residential Wealth Distribution", 
                           "scf_lorenz_residential_wealth")
    sleep(1)
    
    # Comparison plots
    println("\n2. Creating comparison plots...")
    
    # 1. Net Worth vs Residential Wealth
    p_comp1 = create_comparison_plot(
        x_networth, y_networth, gini_networth, "Net Worth", :solid,
        x_residential, y_residential, gini_residential, "Residential Wealth", :dash,
        "Wealth Distribution Comparison:\nNet Worth vs Residential Wealth",
        "scf_comparison_networth_residential"
    )
    sleep(1)
    
    # 2. Net Worth vs Custom Labor Income
    p_comp2 = create_comparison_plot(
        x_networth, y_networth, gini_networth, "Net Worth", :solid,
        x_labor, y_labor, gini_labor, "Labor Income", :dashdot,
        "Wealth Distribution Comparison:\nNet Worth vs Labor Income",
        "scf_comparison_networth_labor"
    )
    sleep(1)
    
    # 3. Custom Labor Income vs Wage Income
    p_comp3 = create_comparison_plot(
        x_labor, y_labor, gini_labor, "Labor Income (Wages + 0.812×Business)", :solid,
        x_wage, y_wage, gini_wage, "Wage Income (WAGEINC only)", :dash,
        "Income Distribution Comparison:\nLabor Income vs Wage Income",
        "scf_comparison_labor_wage"
    )
    sleep(1)
    
    # Combined plot with all four measures - Black & White friendly
    println("\n3. Creating combined plot...")
    
    try
        p_combined = plot(x_labor, y_labor, 
                         label="Labor Income ($(round(gini_labor, digits=3)))", 
                         color=:black, 
                         linewidth=4,
                         linestyle=:solid,
                         title="US Wealth Distribution - SCF 2022\nAll Measures Comparison",
                         xlabel="Cumulative Population Share (%)",
                         ylabel="Cumulative Wealth Share (%)",
                         xlims=(0, 1),
                         ylims=(0, 1),
                         grid=true,
                         gridcolor=:gray,
                         gridwidth=1,
                         gridlinestyle=:dot,
                         size=(900, 650),
                         dpi=300,
                         thickness_scaling=1.2,
                         background_color=:white,
                         foreground_color=:black,
                         legendfontsize=10)
        
        plot!(p_combined, x_wage, y_wage, 
              label="Wage Income ($(round(gini_wage, digits=3)))", 
              color=:gray30, 
              linewidth=4,
              linestyle=:dash)
        
        plot!(p_combined, x_networth, y_networth, 
              label="Net Worth ($(round(gini_networth, digits=3)))", 
              color=:gray50, 
              linewidth=4,
              linestyle=:dashdot)
        
        plot!(p_combined, x_residential, y_residential, 
              label="Residential Wealth ($(round(gini_residential, digits=3)))", 
              color=:gray70, 
              linewidth=3,
              linestyle=:solid)
        
        plot!(p_combined, [0, 1], [0, 1], 
              label="Perfect Equality", 
              color=:gray, 
              linestyle=:dot, 
              linewidth=2)
        
        plot!(p_combined,
              xformatter = x -> "$(Int(round(x*100)))%",
              yformatter = y -> "$(Int(round(y*100)))%")
        
        # Display the combined plot
        display(p_combined)
        
        # Save combined plot as PDF
        println("Saving combined plot as PDF...")
        savefig(p_combined, "scf_lorenz_combined.pdf")
        
        if isfile("scf_lorenz_combined.pdf") && filesize("scf_lorenz_combined.pdf") > 0
            println("✅ Combined PDF saved successfully")
        else
            println("❌ Combined PDF save failed")
        end
        
        # Save combined plot as EPS using multiple methods
        println("Saving combined plot as EPS...")
        save_eps_multiple_methods(p_combined, "scf_lorenz_combined")
        
    catch e
        println("❌ Error creating combined plot: $e")
    end
    
    # Final file verification
    println("\n" * "="^50)
    println("FILE VERIFICATION")
    println("="^50)
    
    expected_files = [
        "scf_lorenz_labor_income.pdf", "scf_lorenz_labor_income.eps",
        "scf_lorenz_wage_income.pdf", "scf_lorenz_wage_income.eps",
        "scf_lorenz_net_worth.pdf", "scf_lorenz_net_worth.eps",
        "scf_lorenz_residential_wealth.pdf", "scf_lorenz_residential_wealth.eps",
        "scf_comparison_networth_residential.pdf", "scf_comparison_networth_residential.eps",
        "scf_comparison_networth_labor.pdf", "scf_comparison_networth_labor.eps",
        "scf_comparison_labor_wage.pdf", "scf_comparison_labor_wage.eps",
        "scf_lorenz_combined.pdf", "scf_lorenz_combined.eps"
    ]
    
    println("Checking generated files:")
    for file in expected_files
        if isfile(file)
            size_kb = round(filesize(file) / 1024, digits=1)
            if size_kb > 0
                println("✅ $file ($(size_kb) KB)")
            else
                println("❌ $file (0 KB - EMPTY FILE)")
            end
        else
            println("❌ $file (NOT FOUND)")
        end
    end
    
    println("\n" * "="^70)
    println("ANALYSIS COMPLETE!")
    println("="^70)
    println("📖 BLACK & WHITE PRINT-READY PLOTS GENERATED")
    println("")
    println("Line Style Guide for Combined Plot:")
    println("  ━━━━━━━━━━ Labor Income (thick solid black)")
    println("  ╌╌╌╌╌╌╌╌╌╌ Wage Income (thick dashed dark gray)")  
    println("  ━ ╌ ━ ╌ ━ ╌ Net Worth (thick dash-dot medium gray)")
    println("  ━━━━━━━━━━ Residential Wealth (medium solid light gray)")
    println("  ⋯⋯⋯⋯⋯⋯⋯⋯⋯⋯ Perfect Equality (thin dotted gray)")
    println("")
    println("All plots use grayscale colors and distinct line patterns")
    println("that will reproduce clearly in black and white printing.")
    
    # Check if EPS files were generated successfully
    eps_files = ["scf_lorenz_labor_income.eps", "scf_lorenz_wage_income.eps", 
                 "scf_lorenz_net_worth.eps", "scf_lorenz_residential_wealth.eps",
                 "scf_comparison_networth_residential.eps", "scf_comparison_networth_labor.eps",
                 "scf_comparison_labor_wage.eps", "scf_lorenz_combined.eps"]
    
    successful_eps = sum([isfile(f) && filesize(f) > 0 for f in eps_files])
    
    if successful_eps == 0
        println("\n⚠️  EPS GENERATION TROUBLESHOOTING:")
        println("No EPS files were generated successfully.")
        println("To get EPS files on Ubuntu, install conversion tools:")
        println("  sudo apt update")
        println("  sudo apt install poppler-utils ghostscript inkscape")
        println("\nThen run the script again, or manually convert PDFs:")
        println("  pdftops -eps file.pdf file.eps")
        println("  # or")
        println("  gs -dNOPAUSE -dBATCH -sDEVICE=epswrite -sOutputFile=file.eps file.pdf")
    elseif successful_eps < length(eps_files)
        println("\n⚠️  Some EPS files failed to generate.")
        println("You can manually convert the PDF files using:")
        println("  pdftops -eps file.pdf file.eps")
    else
        println("\n✅ All EPS files generated successfully!")
    end
    
    println("\n📖 FOR PUBLICATION:")
    println("• PDF files: Perfect for digital documents and LaTeX")
    println("• EPS files: Required by many academic journals")
    println("• All plots use publication-ready black & white design")
    println("• High resolution (300 DPI) suitable for print")
    
    println("="^70)
    
    return (labor_income=gini_labor, wage_income=gini_wage, net_worth=gini_networth, residential=gini_residential)
end

# Run the analysis
println("SCF Lorenz Analysis - Black & White Print Edition - Julia $(VERSION)")
println("Current directory: $(pwd())")

if isfile("SCFP2022.csv")
    println("Found SCFP2022.csv - starting analysis...")
    println("📖 Generating publication-ready black & white plots...")
    
    if !eps_conversion_available
        println("\n💡 TIP: To get EPS files, install tools first:")
        println("   sudo apt install poppler-utils ghostscript")
        println("   Then run this script again.")
        println()
    end
    
    gini_results = analyze_scf_csv("SCFP2022.csv")
    println("\nFinal Gini Coefficients:")
    println("Labor Income (Wages + 0.812×Business): $(round(gini_results.labor_income, digits=3))")
    println("Wage Income (WAGEINC only): $(round(gini_results.wage_income, digits=3))")
    println("Net Worth: $(round(gini_results.net_worth, digits=3))")
    println("Residential Wealth: $(round(gini_results.residential, digits=3))")
else
    println("SCFP2022.csv not found!")
    println("Available files: $(readdir())")
    println("\nTo run with a different filename:")
    println("gini_results = analyze_scf_csv(\"your_filename.csv\")")
end
