using DataFrames, CSV, ReadStatTables
using Plots, StatsBase, Statistics
using JLD2

# Simple function to create SCF income histogram
function create_scf_histogram()
    println("Reading SCF data...")
    
    # Try to read the data files
    df = nothing
    for filename in ["scf2022.dta", "o22i6.dta"]
        if isfile(filename)
            println("Found and reading: $filename")
            try
                df = DataFrame(readstat(filename))
                println("Successfully loaded data with dimensions: $(size(df))")
                break
            catch e
                println("Error reading $filename: $e")
                continue
            end
        end
    end
    
    if df === nothing
        error("No data files found or readable! Need scf2022.dta or o22i6.dta")
    end
    
    # Find income variable
    income_col = nothing
    for col in ["X5729", "income"]
        if col in names(df)
            income_col = col
            println("✓ Using income variable: $col")
            break
        end
    end
    
    if income_col === nothing
        error("No income variable found! Expected X5729 or income")
    end
    
    # Find weight variable
    weight_col = nothing
    for col in ["X42001", "X42000", "wgt", "weight"]
        if col in names(df)
            weight_col = col
            println("✓ Using weight variable: $col")
            break
        end
    end
    
    if weight_col === nothing
        println("No weight variable found, using equal weights")
        df.weight = ones(nrow(df))
        weight_col = "weight"
    end
    
    # Get the data
    income_data = getproperty(df, Symbol(income_col))
    weight_data = getproperty(df, Symbol(weight_col))
    
    println("Original data size: $(length(income_data))")
    
    # Clean the data - remove missing, zero, negative, and extreme values
    valid_mask = (!).(ismissing.(income_data)) .&& 
                 (!).(ismissing.(weight_data)) .&&
                 (income_data .> 0) .&& 
                 (income_data .< 10_000_000) .&&
                 (weight_data .> 0) .&&
                 (.!isnan.(income_data)) .&&
                 (.!isinf.(income_data)) .&&
                 (.!isnan.(weight_data)) .&&
                 (.!isinf.(weight_data))
    
    clean_income = Float64.(income_data[valid_mask])
    clean_weights = Float64.(weight_data[valid_mask])
    
    println("Clean data size: $(length(clean_income))")
    
    if length(clean_income) == 0
        error("No valid data remaining after cleaning!")
    end
    
    # Convert to thousands for better display
    income_thousands = clean_income ./ 1000
    
    println("Income range: \$$(round(Int, minimum(clean_income))) - \$$(round(Int, maximum(clean_income)))")
    
    # Create histogram with $2000 intervals
    max_income_k = maximum(income_thousands)
    
    # Use $2000 intervals as requested
    bin_width = 2.0  # $2000 intervals
    max_bin = min(500, ceil(Int, max_income_k/bin_width) * bin_width)
    
    bins = collect(0:bin_width:max_bin)
    println("Using \$2000 intervals: $(bins[1]) to $(bins[end]) (width: \$$(bin_width*1000))")
    println("Total number of bins: $(length(bins)-1)")
    
    # Truncate extreme values for visualization
    display_income = min.(income_thousands, max_bin)
    
    println("Data types: income=$(typeof(display_income)), weights=$(typeof(clean_weights))")
    println("Array lengths: income=$(length(display_income)), weights=$(length(clean_weights))")
    
    # Try StatsBase weighted histogram first
    hist_data = nothing
    hist_counts = nothing
    bin_centers = nothing
    weighted_success = false
    
    try
        println("Attempting StatsBase weighted histogram...")
        w = StatsBase.weights(clean_weights)
        hist_data = fit(Histogram, display_income, w, bins)
        weighted_success = true
        println("✓ StatsBase weighted histogram succeeded!")
    catch e
        println("StatsBase failed: $e")
        println("Trying manual weighted histogram approach...")
        
        # Manual weighted histogram approach
        hist_counts = zeros(length(bins)-1)
        for i in 1:length(display_income)
            bin_idx = searchsortedfirst(bins, display_income[i]) - 1
            if bin_idx >= 1 && bin_idx <= length(hist_counts)
                hist_counts[bin_idx] += clean_weights[i]
            end
        end
        
        # Create manual histogram object
        bin_centers = [(bins[i] + bins[i+1])/2 for i in 1:length(bins)-1]
        weighted_success = true
        println("✓ Manual weighted histogram succeeded!")
    end
    
    if weighted_success
        # Create the plot with proper survey weighting
        if hist_data !== nothing
            # Use StatsBase histogram
            p = plot(hist_data, 
                     color=:black,
                     fillcolor=:white,
                     linecolor=:black,
                     linewidth=2,
                     xlabel="Household Income (thousands of dollars)",
                     ylabel="Weighted Frequency",
                     title="Household Income Distribution - SCF 2022 (Survey Weighted)",
                     legend=false,
                     grid=false,
                     background_color=:white,
                     size=(1000, 600))
        else
            # Use manual histogram with bar plot
            p = bar(bin_centers, hist_counts,
                   bar_width=bin_width*0.9,
                   color=:white,
                   linecolor=:black,
                   linewidth=2,
                   xlabel="Household Income (thousands of dollars)",
                   ylabel="Weighted Frequency",
                   title="Household Income Distribution - SCF 2022 (Survey Weighted)",
                   legend=false,
                   grid=false,
                   background_color=:white,
                   size=(1000, 600))
        end
        
        # Calculate weighted summary statistics using correct syntax
        w = StatsBase.weights(clean_weights)
        median_income = StatsBase.median(display_income, w)
        mean_income = StatsBase.mean(display_income, w)
        
        # Add vertical lines for median and mean
        if median_income <= max_bin
            vline!([median_income], color=:red, linestyle=:dash, linewidth=2, alpha=0.8, label="Median: \$$(round(Int, median_income))k")
        end
        
        if mean_income <= max_bin
            vline!([mean_income], color=:blue, linestyle=:dot, linewidth=2, alpha=0.8, label="Mean: \$$(round(Int, mean_income))k")
        end
        
        plot!(legend=:topright)
        
        # Save the plot
        savefig(p, "scf_2022_income_histogram_weighted.png")
        println("✓ Weighted histogram saved as: scf_2022_income_histogram_weighted.png")
        
        # Display the plot
        display(p)
        
        # Save data
        processed_data = DataFrame(
            income = clean_income,
            income_thousands = income_thousands,
            weight = clean_weights
        )
        
        CSV.write("scf_2022_income_data.csv", processed_data)
        @save "scf_2022_income_data.jld2" processed_data
        
        println("✓ Data saved as:")
        println("  - scf_2022_income_data.csv")
        println("  - scf_2022_income_data.jld2")
        
        # Print summary statistics with correct weighted percentile syntax
        println("\n📊 Summary Statistics (Survey Weighted):")
        println("Sample size: $(length(clean_income))")
        println("Median income: \$$(round(Int, median_income * 1000))")
        println("Mean income: \$$(round(Int, mean_income * 1000))")
        
        # Calculate weighted percentiles with correct syntax
        p25 = StatsBase.quantile(display_income, w, 0.25)
        p75 = StatsBase.quantile(display_income, w, 0.75)
        println("25th percentile: \$$(round(Int, p25 * 1000))")
        println("75th percentile: \$$(round(Int, p75 * 1000))")
        
        return "weighted_success"
        
    else
        println("Creating unweighted histogram with \$2000 intervals...")
        
        # Fallback with same bins but unweighted
        p = histogram(display_income, 
                     bins=bins,
                     color=:white,
                     linecolor=:black,
                     linewidth=2,
                     xlabel="Household Income (thousands of dollars)",
                     ylabel="Frequency",
                     title="Household Income Distribution - SCF 2022 (Unweighted, \$2k Bins)",
                     legend=false,
                     grid=false,
                     background_color=:white,
                     size=(1000, 600))
        
        # Add summary lines
        median_income = median(display_income)
        mean_income = mean(display_income)
        
        vline!([median_income], color=:red, linestyle=:dash, linewidth=2, alpha=0.8, label="Median: \$$(round(Int, median_income))k")
        vline!([mean_income], color=:blue, linestyle=:dot, linewidth=2, alpha=0.8, label="Mean: \$$(round(Int, mean_income))k")
        plot!(legend=:topright)
        
        savefig(p, "scf_2022_income_histogram_unweighted.png")
        println("✓ Unweighted histogram saved as: scf_2022_income_histogram_unweighted.png")
        
        # Display the plot
        display(p)
        
        # Save data
        processed_data = DataFrame(
            income = clean_income,
            income_thousands = income_thousands,
            weight = clean_weights
        )
        
        CSV.write("scf_2022_income_data.csv", processed_data)
        @save "scf_2022_income_data.jld2" processed_data
        
        println("✓ Data saved as:")
        println("  - scf_2022_income_data.csv")
        println("  - scf_2022_income_data.jld2")
        
        # Print summary statistics
        println("\n📊 Summary Statistics (Unweighted):")
        println("Sample size: $(length(clean_income))")
        println("Median income: \$$(round(Int, median_income * 1000))")
        println("Mean income: \$$(round(Int, mean_income * 1000))")
        println("25th percentile: \$$(round(Int, StatsBase.percentile(display_income, 25) * 1000))")
        println("75th percentile: \$$(round(Int, StatsBase.percentile(display_income, 75) * 1000))")
        
        return "unweighted_fallback"
    end
end

# Run the analysis
println("Starting SCF Income Analysis...")
result = create_scf_histogram()
println("\n🎉 Analysis complete! Result: $result")
