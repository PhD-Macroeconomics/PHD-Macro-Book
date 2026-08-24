using DataFrames, CSV, ReadStatTables
using Plots, StatsBase, Statistics
using JLD2  # For saving data

# Function to read SCF data (handles Stata .dta format)
function read_scf_data(filename)
    println("Reading SCF data from: $filename")
    
    # Read the Stata .dta file
    df = DataFrame(readstat(filename))
    
    println("Data dimensions: $(size(df))")
    println("Column names: $(names(df))")
    
    # Check if this file has implicates
    if "impl" in names(df)
        println("Number of implicates: $(length(unique(df.impl)))")
    else
        println("No implicate variable found - this may be a summary file")
    end
    
    return df
end

# Function to explore and select the right data file
function explore_data_files()
    available_files = ["scf2022.dta", "o22i6.dta"]
    
    println("Exploring available data files...")
    
    for file in available_files
        if isfile(file)
            println("\n" * "="^50)
            println("File: $file")
            try
                temp_df = DataFrame(readstat(file))
                println("Dimensions: $(size(temp_df))")
                
                # Check for SCF key variables (using actual SCF variable codes)
                scf_key_vars = ["X5729", "NETWORTH", "X42001", "X42000", "X8022", "X5901", "Y1", "X19"]
                readable_names = ["total_income", "net_worth", "weight", "alt_weight", "age", "education", "case_id", "implicate"]
                
                found_vars = []
                for (var, name) in zip(scf_key_vars, readable_names)
                    if var in names(temp_df)
                        push!(found_vars, "$var ($name)")
                    end
                end
                println("SCF variables found: $found_vars")
                
                # Show first few rows of income if available
                if "X5729" in names(temp_df)
                    income_sample = temp_df.X5729[1:min(5, nrow(temp_df))]
                    println("Sample X5729 (income) values: $income_sample")
                end
                
                # Check for implicates
                if "X19" in names(temp_df)
                    n_implicates = length(unique(temp_df.X19))
                    println("Number of implicates: $n_implicates")
                end
                
            catch e
                println("Error reading file: $e")
            end
        else
            println("File not found: $file")
        end
    end
    
    # Return the best file to use
    if isfile("scf2022.dta")
        return "scf2022.dta"
    elseif isfile("o22i6.dta") 
        return "o22i6.dta"
    else
        error("No suitable data files found")
    end
end

# Function to create weighted income histogram
function create_income_histogram(df; save_data=true)
    println("Creating income histogram...")
    
    # Check for SCF income variable (X5729 is total income in SCF)
    income_col = nothing
    for col in ["X5729", "income"]
        if col in names(df)
            income_col = col
            println("Using income variable: $col")
            break
        end
    end
    
    if income_col === nothing
        error("No income variable found! Expected X5729 or income")
    end
    
    # Check what weight variable is available (X42001 is main weight, X42000 is alternative)
    weight_col = nothing
    for col in ["X42001", "X42000", "wgt", "wgt1", "weight", "WEIGHT"]
        if col in names(df)
            weight_col = col
            println("Using weight variable: $col")
            break
        end
    end
    
    if weight_col === nothing
        println("No weight variable found, using equal weights")
        df.weight = ones(nrow(df))
        weight_col = "weight"
    end
    
    # Check for implicate variable (X19 in SCF)
    implicate_col = nothing
    for col in ["X19", "impl", "implicate"]
        if col in names(df)
            implicate_col = col
            println("Using implicate variable: $col")
            break
        end
    end
    
    # Get income values
    income_values = getproperty(df, Symbol(income_col))
    weights = getproperty(df, Symbol(weight_col))
    
    # Filter out missing income values and extreme outliers
    # SCF uses specific codes: 0 = inapplicable, -1 = nothing, etc.
    valid_mask = (!).(ismissing.(income_values)) .&& 
                 (income_values .> 0) .&& 
                 (income_values .< 10_000_000) .&&
                 (!).(ismissing.(weights))
    
    df_clean = df[valid_mask, :]
    println("Clean data dimensions: $(size(df_clean))")
    
    # Handle implicates if they exist
    if implicate_col !== nothing
        # For multiple implicates, use implicate 1 for the histogram
        implicate_values = getproperty(df_clean, Symbol(implicate_col))
        df_imp1 = df_clean[implicate_values .== 1, :]
        println("Using implicate 1, dimensions: $(size(df_imp1))")
    else
        # No implicates, use all data
        df_imp1 = df_clean
        println("No implicates found, using all data: $(size(df_imp1))")
    end
    
    # Create income bins (in thousands for better readability)
    income_thousands = getproperty(df_imp1, Symbol(income_col)) ./ 1000
    weights = getproperty(df_imp1, Symbol(weight_col))
    
    # Create weighted histogram
    # Define bins from 0 to 500k with reasonable intervals
    bins = 0:25:500  # 25k intervals up to 500k
    
    # Calculate weighted frequencies
    hist_data = fit(Histogram, income_thousands, weights=weights, bins=bins)
    
    # Create the plot
    p = plot(hist_data, 
             color=:black,
             fillcolor=:white,
             linecolor=:black,
             linewidth=2,
             xlabel="Household Income (thousands of dollars)",
             ylabel="Weighted Frequency",
             title="Household Income Distribution - SCF 2022",
             legend=false,
             grid=false,
             background_color=:white,
             size=(800, 600))
    
    # Add some summary statistics to the plot
    median_income = StatsBase.median(income_thousands, weights=weights)
    mean_income = StatsBase.mean(income_thousands, weights=weights)
    
    # Add vertical lines for median and mean
    vline!([median_income], color=:black, linestyle=:dash, linewidth=2, alpha=0.7)
    vline!([mean_income], color=:black, linestyle=:dot, linewidth=2, alpha=0.7)
    
    # Add annotations
    annotate!([(median_income + 20, maximum(hist_data.weights) * 0.8, 
               text("Median: \$$(round(Int, median_income))k", 10, :left))])
    annotate!([(mean_income + 20, maximum(hist_data.weights) * 0.7, 
               text("Mean: \$$(round(Int, mean_income))k", 10, :left))])
    
    # Save the plot
    savefig(p, "scf_2022_income_histogram.png")
    println("Histogram saved as: scf_2022_income_histogram.png")
    
    # Save relevant data if requested
    if save_data
        # Create a data frame with available variables
        relevant_data = DataFrame(income = df_imp1.income)
        
        # Add other variables if they exist
        optional_vars = ["id", "age", "race", "educ", "married", "networth"]
        for var in optional_vars
            if var in names(df_imp1)
                relevant_data[!, Symbol(var)] = getproperty(df_imp1, Symbol(var))
            end
        end
        
        # Add weight variable
        relevant_data[!, Symbol("weight")] = weights
        
        # Save as CSV
        CSV.write("scf_2022_income_data.csv", relevant_data)
        
        # Save as JLD2 (Julia's native format)
        @save "scf_2022_income_data.jld2" relevant_data
        
        println("Relevant data saved as:")
        println("  - scf_2022_income_data.csv")
        println("  - scf_2022_income_data.jld2")
        
        # Print summary statistics
        println("\nSummary Statistics (Weighted):")
        println("Sample size: $(nrow(relevant_data))")
        println("Median income: \$(round(Int, median_income * 1000))")
        println("Mean income: \$(round(Int, mean_income * 1000))")
        println("25th percentile: \$(round(Int, StatsBase.percentile(income_thousands, 25, weights=weights) * 1000))")
        println("75th percentile: \$(round(Int, StatsBase.percentile(income_thousands, 75, weights=weights) * 1000))")
    end
    
    return p, df_imp1
end

# Function to create income distribution by demographic groups
function create_demographic_analysis(df)
    println("Creating demographic analysis...")
    
    # Find income, weight, race, and implicate variables
    income_col = "X5729" in names(df) ? "X5729" : ("income" in names(df) ? "income" : nothing)
    weight_col = "X42001" in names(df) ? "X42001" : ("X42000" in names(df) ? "X42000" : ("wgt" in names(df) ? "wgt" : nothing))
    race_col = "X6809" in names(df) ? "X6809" : ("race" in names(df) ? "race" : nothing)
    implicate_col = "X19" in names(df) ? "X19" : ("impl" in names(df) ? "impl" : nothing)
    
    if income_col === nothing || weight_col === nothing || race_col === nothing
        println("Missing required variables for demographic analysis")
        println("Need: income (X5729), weight (X42001), race (X6809)")
        return nothing
    end
    
    # Filter clean data
    income_values = getproperty(df, Symbol(income_col))
    race_values = getproperty(df, Symbol(race_col))
    weight_values = getproperty(df, Symbol(weight_col))
    
    valid_mask = (!).(ismissing.(income_values)) .&& 
                 (income_values .> 0) .&& 
                 (income_values .< 10_000_000) .&&
                 (!).(ismissing.(race_values)) .&&
                 (!).(ismissing.(weight_values))
    
    df_clean = df[valid_mask, :]
    
    # Handle implicates
    if implicate_col !== nothing
        implicate_values = getproperty(df_clean, Symbol(implicate_col))
        df_clean = df_clean[implicate_values .== 1, :]
    end
    
    # Create income by race plot
    p_race = plot(title="Income Distribution by Race - SCF 2022",
                  xlabel="Race Category", 
                  ylabel="Median Income (thousands)",
                  legend=false,
                  color=:black,
                  fillcolor=:white,
                  background_color=:white)
    
    race_labels = ["White non-Hispanic", "Black/African-American", "Hispanic", "Other"]
    race_medians = []
    
    for race_code in 1:4
        race_data_mask = getproperty(df_clean, Symbol(race_col)) .== race_code
        race_data = df_clean[race_data_mask, :]
        
        if nrow(race_data) > 0
            race_income = getproperty(race_data, Symbol(income_col))
            race_weights = getproperty(race_data, Symbol(weight_col))
            median_inc = StatsBase.median(race_income ./ 1000, weights=race_weights)
            push!(race_medians, median_inc)
        else
            push!(race_medians, 0)
        end
    end
    
    bar!(1:4, race_medians, 
         color=:white, 
         linecolor=:black, 
         linewidth=2,
         xticks=(1:4, race_labels))
    
    # Rotate x-axis labels for better readability
    plot!(xrotation=45)
    
    savefig(p_race, "scf_2022_income_by_race.png")
    println("Race analysis saved as: scf_2022_income_by_race.png")
    
    return p_race
end

# Main execution function
function main()
    try
        # Step 1: Explore available data files
        data_file = explore_data_files()
        
        # Step 2: Read the data
        df = read_scf_data(data_file)
        
        # Step 3: Check if we have the required variables
        # Look for income variable (X5729 is total income in SCF)
        income_var = nothing
        for var in ["X5729", "income"]
            if var in names(df)
                income_var = var
                break
            end
        end
        
        if income_var === nothing
            println("ERROR: No income variable found!")
            println("Expected: X5729 (SCF total income) or income")
            println("Available variables starting with X57: $(filter(x -> startswith(x, "X57"), names(df)))")
            return
        end
        
        println("✓ Found income variable: $income_var")
        
        # Step 4: Create income histogram
        histogram_plot, clean_data = create_income_histogram(df, save_data=true)
        
        # Step 5: Create demographic analysis (if race variable exists)
        race_var = "X6809" in names(df) ? "X6809" : ("race" in names(df) ? "race" : nothing)
        if race_var !== nothing
            println("✓ Found race variable: $race_var")
            demo_plot = create_demographic_analysis(df)
        else
            println("Race variable not found (expected X6809), skipping demographic analysis")
        end
        
        # Display the main histogram
        display(histogram_plot)
        
        println("\nAnalysis complete!")
        println("Files created:")
        println("  - scf_2022_income_histogram.png")
        if race_var !== nothing
            println("  - scf_2022_income_by_race.png")
        end
        println("  - scf_2022_income_data.csv")
        println("  - scf_2022_income_data.jld2")
        
    catch e
        println("Error: $e")
        println(stacktrace())
        println("\nTroubleshooting:")
        println("1. Make sure you have scf2022.dta or o22i6.dta in your current directory")
        println("2. The SCF data should contain variable X5729 (total income)")
        println("3. Install required packages if needed:")
        println("   using Pkg; Pkg.add([\"ReadStatTables\", \"DataFrames\", \"Plots\", \"StatsBase\"])")
    end
end

# Run the analysis
main()
