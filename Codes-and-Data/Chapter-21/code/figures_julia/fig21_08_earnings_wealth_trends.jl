# Black and white version - Julia code for generating earnings and wealth trend graphs
# Optimized for academic papers and journals that prefer monochrome figures
using Plots, StatsPlots

# Data from the SCF table
years = [1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022]

# Earnings data (in thousands USD)
earnings_avg = [72.6, 73.4, 74.8, 81.2, 92.2, 88.3, 91.2, 84.8, 81.3, 91.1, 90.0, 98.4]
earnings_p30 = [12.2, 12.7, 12.9, 18.4, 22.3, 19.3, 19.1, 13.9, 12.9, 12.6, 16.5, 15.1]
earnings_p50 = [48.0, 45.5, 47.5, 51.7, 55.0, 53.2, 52.9, 45.8, 41.4, 43.7, 47.1, 48.6]
earnings_p90 = [149.9, 154.2, 151.7, 164.2, 181.4, 185.4, 180.2, 173.3, 171.7, 183.6, 194.4, 205.7]

# Wealth data (in thousands USD)
wealth_avg = [435.7, 386.9, 411.3, 515.8, 664.4, 704.9, 795.8, 674.6, 672.3, 849.9, 863.9, 1059.0]
wealth_p30 = [23.9, 26.7, 31.5, 32.5, 38.6, 36.7, 37.9, 20.1, 18.8, 23.3, 27.7, 51.5]
wealth_p50 = [108.3, 102.8, 111.7, 130.5, 145.0, 146.1, 172.9, 105.0, 103.6, 120.0, 141.0, 192.7]
wealth_p90 = [846.7, 740.2, 735.3, 897.9, 1246.0, 1310.3, 1303.1, 1298.9, 1197.7, 1461.9, 1406.8, 1936.9]

# Set plot defaults for black and white
default(fontfamily="Computer Modern", 
        linewidth=2.5, 
        framestyle=:box, 
        label=nothing, 
        grid=true,
        gridwidth=1,
        gridcolor=:lightgray,
        gridalpha=0.6,
        background_color=:white)

# Create earnings plot (black and white version)
earnings_plot = plot(years, earnings_avg, 
                    label="Average", 
                    color=:black, 
                    linewidth=4,
                    linestyle=:solid,
                    title="Earnings Trends (1989-2022)",
                    xlabel="Year",
                    ylabel="Earnings (thousands USD)",
                    legend=:topleft,
                    size=(800, 600),
                    dpi=300)

plot!(earnings_plot, years, earnings_p30, 
      label="30th Percentile", 
      color=:black, 
      linewidth=3,
      linestyle=:dash)

plot!(earnings_plot, years, earnings_p50, 
      label="50th Percentile (Median)", 
      color=:black, 
      linewidth=3,
      linestyle=:dashdot)

plot!(earnings_plot, years, earnings_p90, 
      label="90th Percentile", 
      color=:black, 
      linewidth=3,
      linestyle=:dot)

# Add different markers for better visibility in B&W
scatter!(earnings_plot, years, earnings_avg, 
         color=:black, markershape=:circle, markersize=5, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:black, label=nothing)
scatter!(earnings_plot, years, earnings_p30, 
         color=:black, markershape=:square, markersize=4, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:white, label=nothing)
scatter!(earnings_plot, years, earnings_p50, 
         color=:black, markershape=:diamond, markersize=5, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:gray, label=nothing)
scatter!(earnings_plot, years, earnings_p90, 
         color=:black, markershape=:utriangle, markersize=4, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:black, label=nothing)

# Create wealth plot (black and white version)
wealth_plot = plot(years, wealth_avg, 
                  label="Average", 
                  color=:black, 
                  linewidth=4,
                  linestyle=:solid,
                  title="Wealth Trends (1989-2022)",
                  xlabel="Year",
                  ylabel="Wealth (thousands USD)",
                  legend=:topleft,
                  size=(800, 600),
                  dpi=300)

plot!(wealth_plot, years, wealth_p30, 
      label="30th Percentile", 
      color=:black, 
      linewidth=3,
      linestyle=:dash)

plot!(wealth_plot, years, wealth_p50, 
      label="50th Percentile (Median)", 
      color=:black, 
      linewidth=3,
      linestyle=:dashdot)

plot!(wealth_plot, years, wealth_p90, 
      label="90th Percentile", 
      color=:black, 
      linewidth=3,
      linestyle=:dot)

# Add different markers for better visibility in B&W
scatter!(wealth_plot, years, wealth_avg, 
         color=:black, markershape=:circle, markersize=5, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:black, label=nothing)
scatter!(wealth_plot, years, wealth_p30, 
         color=:black, markershape=:square, markersize=4, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:white, label=nothing)
scatter!(wealth_plot, years, wealth_p50, 
         color=:black, markershape=:diamond, markersize=5, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:gray, label=nothing)
scatter!(wealth_plot, years, wealth_p90, 
         color=:black, markershape=:utriangle, markersize=4, 
         markerstrokewidth=2, markerstrokecolor=:black, 
         markerfillcolor=:black, label=nothing)

# Save plots as PDF files
savefig(earnings_plot, "earnings_trends_1989_2022.pdf")
savefig(wealth_plot, "wealth_trends_1989_2022.pdf")

# Display plots
display(earnings_plot)
display(wealth_plot)

println("Graphs saved as:")
println("- earnings_trends_1989_2022.pdf")
println("- wealth_trends_1989_2022.pdf")

# Optional: Create a combined plot for comparison (black and white)
combined_plot = plot(layout=(2,1), size=(800, 1000), dpi=300)

# Earnings subplot
plot!(combined_plot[1], years, earnings_avg, 
      label="Average", color=:black, linewidth=4, linestyle=:solid,
      title="Earnings Trends (1989-2022)",
      ylabel="Earnings (thousands USD)")
plot!(combined_plot[1], years, earnings_p30, 
      label="30th Percentile", color=:black, linewidth=3, linestyle=:dash)
plot!(combined_plot[1], years, earnings_p50, 
      label="50th Percentile", color=:black, linewidth=3, linestyle=:dashdot)
plot!(combined_plot[1], years, earnings_p90, 
      label="90th Percentile", color=:black, linewidth=3, linestyle=:dot)

# Wealth subplot  
plot!(combined_plot[2], years, wealth_avg, 
      label="Average", color=:black, linewidth=4, linestyle=:solid,
      title="Wealth Trends (1989-2022)",
      xlabel="Year", ylabel="Wealth (thousands USD)")
plot!(combined_plot[2], years, wealth_p30, 
      label="30th Percentile", color=:black, linewidth=3, linestyle=:dash)
plot!(combined_plot[2], years, wealth_p50, 
      label="50th Percentile", color=:black, linewidth=3, linestyle=:dashdot)
plot!(combined_plot[2], years, wealth_p90, 
      label="90th Percentile", color=:black, linewidth=3, linestyle=:dot)

# Save combined plot
savefig(combined_plot, "earnings_wealth_combined_trends.pdf")
display(combined_plot)

println("Combined graph saved as: earnings_wealth_combined_trends.pdf")
