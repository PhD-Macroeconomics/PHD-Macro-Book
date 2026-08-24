# Black and white plots for inequality measures - Earnings and Wealth
using Plots, StatsPlots

# Years
years = [1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022]

# EARNINGS DATA
# Inequality measures (Table a)
earnings_gini = [0.61, 0.63, 0.62, 0.61, 0.62, 0.62, 0.64, 0.65, 0.67, 0.68, 0.65, 0.68]
earnings_cov = [4.47, 4.19, 3.53, 2.86, 2.88, 3.00, 3.60, 3.26, 3.69, 4.46, 2.57, 3.15]
earnings_var_logs = [1.42, 1.36, 1.25, 1.20, 1.29, 1.27, 1.29, 1.41, 1.50, 1.60, 1.51, 1.56]

# Distribution shape measures (Table b)
earnings_mean_median = [1.51, 1.61, 1.58, 1.57, 1.68, 1.66, 1.72, 1.85, 1.96, 2.08, 1.91, 2.02]
earnings_mean_location = [65, 65, 65, 66, 68, 67, 69, 70, 70, 72, 70, 72]
earnings_99_50 = [9.92, 10.8, 10.79, 10.87, 12.5, 11.24, 13.42, 15.91, 17.46, 19.16, 15.63, 19.93]
earnings_90_50 = [3.12, 3.39, 3.20, 3.18, 3.30, 3.48, 3.41, 3.79, 4.15, 4.20, 4.13, 4.23]
earnings_50_30 = [3.94, 3.58, 3.69, 2.80, 2.46, 2.75, 2.77, 3.30, 3.21, 3.48, 2.86, 3.21]

# WEALTH DATA
# Inequality measures (Table a)
wealth_gini = [0.79, 0.79, 0.79, 0.80, 0.81, 0.81, 0.82, 0.85, 0.85, 0.86, 0.85, 0.83]
wealth_cov = [5.51, 6.11, 6.28, 6.47, 5.25, 5.68, 6.01, 6.35, 6.81, 7.83, 7.52, 7.63]
wealth_var_logs = [4.29, 3.91, 3.49, 4.02, 4.19, 4.38, 4.39, 4.65, 4.80, 5.27, 5.04, 5.04]

# Distribution shape measures (Table b)
wealth_mean_median = [4.02, 3.76, 3.68, 3.95, 4.58, 4.82, 4.60, 6.42, 6.49, 7.08, 6.13, 5.50]
wealth_mean_location = [80, 80, 82, 81, 81, 80, 82, 83, 83, 84, 84, 83]
wealth_99_50 = [49.32, 46.72, 42.36, 53.02, 67.62, 68.27, 69.21, 88.5, 96.81, 106.37, 91.31, 70.66]
wealth_90_50 = [7.82, 7.20, 6.58, 6.88, 8.59, 8.97, 7.54, 12.37, 11.56, 12.18, 9.98, 10.05]
wealth_50_30 = [4.53, 3.85, 3.54, 4.02, 3.75, 3.98, 4.56, 5.24, 5.50, 5.15, 5.08, 3.74]

# Set plot defaults for black and white
default(fontfamily="Computer Modern", 
        linewidth=2.5, 
        framestyle=:box, 
        grid=true,
        gridwidth=1,
        gridcolor=:lightgray,
        gridalpha=0.6,
        background_color=:white,
        foreground_color=:black)

# EARNINGS PLOTS
# Create comprehensive earnings plot with multiple subplots
earnings_plot = plot(layout=(3,2), size=(1200, 1000), dpi=300, 
                    plot_title="Earnings Distribution Measures (1989-2022)")

# Subplot 1: Inequality Measures - Gini & Coefficient of Variation
plot!(earnings_plot[1], years, earnings_gini, 
      label="Gini Coefficient", color=:black, linewidth=3, linestyle=:solid)
plot!(earnings_plot[1], years, earnings_cov ./ 10, 
      label="Coeff. of Variation (÷10)", color=:black, linewidth=3, linestyle=:dash)
scatter!(earnings_plot[1], years, earnings_gini, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(earnings_plot[1], years, earnings_cov ./ 10, 
         color=:black, markershape=:square, markersize=3, label=nothing)
title!(earnings_plot[1], "Inequality Measures")
ylabel!(earnings_plot[1], "Index Value")

# Subplot 2: Variance of Logs
plot!(earnings_plot[2], years, earnings_var_logs, 
      label="Variance of Logs", color=:black, linewidth=3, linestyle=:solid)
scatter!(earnings_plot[2], years, earnings_var_logs, 
         color=:black, markershape=:diamond, markersize=4, label=nothing)
title!(earnings_plot[2], "Variance of Logs")
ylabel!(earnings_plot[2], "Variance")

# Subplot 3: Mean-to-Median Ratio & Mean Location
plot!(earnings_plot[3], years, earnings_mean_median, 
      label="Mean-to-Median Ratio", color=:black, linewidth=3, linestyle=:solid)
plot!(earnings_plot[3], years, earnings_mean_location ./ 50, 
      label="Mean Location (÷50)", color=:black, linewidth=3, linestyle=:dash)
scatter!(earnings_plot[3], years, earnings_mean_median, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(earnings_plot[3], years, earnings_mean_location ./ 50, 
         color=:black, markershape=:utriangle, markersize=3, label=nothing)
title!(earnings_plot[3], "Central Tendency")
ylabel!(earnings_plot[3], "Ratio / Scaled Location")

# Subplot 4: High-End Ratios (99-50 and 90-50)
plot!(earnings_plot[4], years, earnings_99_50, 
      label="99th-50th Ratio", color=:black, linewidth=3, linestyle=:solid)
plot!(earnings_plot[4], years, earnings_90_50, 
      label="90th-50th Ratio", color=:black, linewidth=3, linestyle=:dash)
scatter!(earnings_plot[4], years, earnings_99_50, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(earnings_plot[4], years, earnings_90_50, 
         color=:black, markershape=:square, markersize=3, label=nothing)
title!(earnings_plot[4], "Upper Tail Inequality")
ylabel!(earnings_plot[4], "Percentile Ratio")

# Subplot 5: Lower-End Ratio (50-30)
plot!(earnings_plot[5], years, earnings_50_30, 
      label="50th-30th Ratio", color=:black, linewidth=3, linestyle=:solid)
scatter!(earnings_plot[5], years, earnings_50_30, 
         color=:black, markershape=:diamond, markersize=4, label=nothing)
title!(earnings_plot[5], "Lower Tail Inequality")
ylabel!(earnings_plot[5], "Percentile Ratio")
xlabel!(earnings_plot[5], "Year")

# Subplot 6: Combined normalized view (all measures scaled 0-1)
earnings_gini_norm = (earnings_gini .- minimum(earnings_gini)) ./ (maximum(earnings_gini) - minimum(earnings_gini))
earnings_cov_norm = (earnings_cov .- minimum(earnings_cov)) ./ (maximum(earnings_cov) - minimum(earnings_cov))
earnings_var_logs_norm = (earnings_var_logs .- minimum(earnings_var_logs)) ./ (maximum(earnings_var_logs) - minimum(earnings_var_logs))
earnings_mean_median_norm = (earnings_mean_median .- minimum(earnings_mean_median)) ./ (maximum(earnings_mean_median) - minimum(earnings_mean_median))

plot!(earnings_plot[6], years, earnings_gini_norm, 
      label="Gini (normalized)", color=:black, linewidth=2, linestyle=:solid)
plot!(earnings_plot[6], years, earnings_cov_norm, 
      label="CoV (normalized)", color=:black, linewidth=2, linestyle=:dash)
plot!(earnings_plot[6], years, earnings_var_logs_norm, 
      label="Var Logs (normalized)", color=:black, linewidth=2, linestyle=:dashdot)
plot!(earnings_plot[6], years, earnings_mean_median_norm, 
      label="Mean/Median (normalized)", color=:black, linewidth=2, linestyle=:dot)
title!(earnings_plot[6], "Normalized Trends (0-1 Scale)")
ylabel!(earnings_plot[6], "Normalized Value")
xlabel!(earnings_plot[6], "Year")

# WEALTH PLOTS
# Create comprehensive wealth plot with multiple subplots
wealth_plot = plot(layout=(3,2), size=(1200, 1000), dpi=300, 
                  plot_title="Wealth Distribution Measures (1989-2022)")

# Subplot 1: Inequality Measures - Gini & Coefficient of Variation
plot!(wealth_plot[1], years, wealth_gini, 
      label="Gini Coefficient", color=:black, linewidth=3, linestyle=:solid)
plot!(wealth_plot[1], years, wealth_cov ./ 10, 
      label="Coeff. of Variation (÷10)", color=:black, linewidth=3, linestyle=:dash)
scatter!(wealth_plot[1], years, wealth_gini, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(wealth_plot[1], years, wealth_cov ./ 10, 
         color=:black, markershape=:square, markersize=3, label=nothing)
title!(wealth_plot[1], "Inequality Measures")
ylabel!(wealth_plot[1], "Index Value")

# Subplot 2: Variance of Logs
plot!(wealth_plot[2], years, wealth_var_logs, 
      label="Variance of Logs", color=:black, linewidth=3, linestyle=:solid)
scatter!(wealth_plot[2], years, wealth_var_logs, 
         color=:black, markershape=:diamond, markersize=4, label=nothing)
title!(wealth_plot[2], "Variance of Logs")
ylabel!(wealth_plot[2], "Variance")

# Subplot 3: Mean-to-Median Ratio & Mean Location
plot!(wealth_plot[3], years, wealth_mean_median, 
      label="Mean-to-Median Ratio", color=:black, linewidth=3, linestyle=:solid)
plot!(wealth_plot[3], years, wealth_mean_location ./ 20, 
      label="Mean Location (÷20)", color=:black, linewidth=3, linestyle=:dash)
scatter!(wealth_plot[3], years, wealth_mean_median, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(wealth_plot[3], years, wealth_mean_location ./ 20, 
         color=:black, markershape=:utriangle, markersize=3, label=nothing)
title!(wealth_plot[3], "Central Tendency")
ylabel!(wealth_plot[3], "Ratio / Scaled Location")

# Subplot 4: High-End Ratios (99-50 and 90-50)
plot!(wealth_plot[4], years, wealth_99_50, 
      label="99th-50th Ratio", color=:black, linewidth=3, linestyle=:solid)
plot!(wealth_plot[4], years, wealth_90_50, 
      label="90th-50th Ratio", color=:black, linewidth=3, linestyle=:dash)
scatter!(wealth_plot[4], years, wealth_99_50, 
         color=:black, markershape=:circle, markersize=4, label=nothing)
scatter!(wealth_plot[4], years, wealth_90_50, 
         color=:black, markershape=:square, markersize=3, label=nothing)
title!(wealth_plot[4], "Upper Tail Inequality")
ylabel!(wealth_plot[4], "Percentile Ratio")

# Subplot 5: Lower-End Ratio (50-30)
plot!(wealth_plot[5], years, wealth_50_30, 
      label="50th-30th Ratio", color=:black, linewidth=3, linestyle=:solid)
scatter!(wealth_plot[5], years, wealth_50_30, 
         color=:black, markershape=:diamond, markersize=4, label=nothing)
title!(wealth_plot[5], "Lower Tail Inequality")
ylabel!(wealth_plot[5], "Percentile Ratio")
xlabel!(wealth_plot[5], "Year")

# Subplot 6: Combined normalized view (all measures scaled 0-1)
wealth_gini_norm = (wealth_gini .- minimum(wealth_gini)) ./ (maximum(wealth_gini) - minimum(wealth_gini))
wealth_cov_norm = (wealth_cov .- minimum(wealth_cov)) ./ (maximum(wealth_cov) - minimum(wealth_cov))
wealth_var_logs_norm = (wealth_var_logs .- minimum(wealth_var_logs)) ./ (maximum(wealth_var_logs) - minimum(wealth_var_logs))
wealth_mean_median_norm = (wealth_mean_median .- minimum(wealth_mean_median)) ./ (maximum(wealth_mean_median) - minimum(wealth_mean_median))

plot!(wealth_plot[6], years, wealth_gini_norm, 
      label="Gini (normalized)", color=:black, linewidth=2, linestyle=:solid)
plot!(wealth_plot[6], years, wealth_cov_norm, 
      label="CoV (normalized)", color=:black, linewidth=2, linestyle=:dash)
plot!(wealth_plot[6], years, wealth_var_logs_norm, 
      label="Var Logs (normalized)", color=:black, linewidth=2, linestyle=:dashdot)
plot!(wealth_plot[6], years, wealth_mean_median_norm, 
      label="Mean/Median (normalized)", color=:black, linewidth=2, linestyle=:dot)
title!(wealth_plot[6], "Normalized Trends (0-1 Scale)")
ylabel!(wealth_plot[6], "Normalized Value")
xlabel!(wealth_plot[6], "Year")

# Save plots
savefig(earnings_plot, "earnings_inequality_measures_bw.pdf")
savefig(wealth_plot, "wealth_inequality_measures_bw.pdf")

# Display plots
display(earnings_plot)
display(wealth_plot)

println("Inequality measures plots saved as:")
println("- earnings_inequality_measures_bw.pdf")
println("- wealth_inequality_measures_bw.pdf")

# Optional: Create simple 2x3 grid showing key measures only
simple_plot = plot(layout=(2,3), size=(1200, 800), dpi=300)

# Row 1: Earnings
plot!(simple_plot[1], years, earnings_gini, 
      label="Earnings", color=:black, linewidth=3, linestyle=:solid,
      title="Gini Coefficient", ylabel="Gini Index")
plot!(simple_plot[2], years, earnings_mean_median, 
      label="Earnings", color=:black, linewidth=3, linestyle=:solid,
      title="Mean-to-Median Ratio", ylabel="Ratio")
plot!(simple_plot[3], years, earnings_90_50, 
      label="Earnings", color=:black, linewidth=3, linestyle=:solid,
      title="90th-50th Percentile Ratio", ylabel="Ratio")

# Row 2: Wealth
plot!(simple_plot[4], years, wealth_gini, 
      label="Wealth", color=:black, linewidth=3, linestyle=:dash,
      xlabel="Year", ylabel="Gini Index")
plot!(simple_plot[5], years, wealth_mean_median, 
      label="Wealth", color=:black, linewidth=3, linestyle=:dash,
      xlabel="Year", ylabel="Ratio")
plot!(simple_plot[6], years, wealth_90_50, 
      label="Wealth", color=:black, linewidth=3, linestyle=:dash,
      xlabel="Year", ylabel="Ratio")

# Add markers
for i in 1:6
    if i <= 3
        scatter!(simple_plot[i], years, i==1 ? earnings_gini : (i==2 ? earnings_mean_median : earnings_90_50), 
                color=:black, markershape=:circle, markersize=3, label=nothing)
    else
        scatter!(simple_plot[i], years, i==4 ? wealth_gini : (i==5 ? wealth_mean_median : wealth_90_50), 
                color=:black, markershape=:square, markersize=3, label=nothing)
    end
end

savefig(simple_plot, "earnings_wealth_key_measures_bw.pdf")
display(simple_plot)

println("Simplified comparison plot saved as: earnings_wealth_key_measures_bw.pdf")
