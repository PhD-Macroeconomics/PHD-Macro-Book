using Plots

# Data extracted from the graph (estimated values)
years = [1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019, 2022]

# Wealth-to-Income Ratio (SCF) - appears to be the highest line
wealth_income_scf = [4.76, 4.87, 5.08, 5.38, 5.58, 5.78, 6.08, 5.88, 6.18, 6.38, 6.68, 7.18]

# Wealth-to-Income Ratio (FA & NIPA) - middle line
wealth_income_fa_nipa = [4.16, 4.27, 4.38, 4.58, 4.78, 4.98, 5.18, 4.98, 5.28, 5.48, 5.78, 6.08]

# Capital-to-GDP Ratio - appears to be the lowest line
capital_gdp = [3.36, 3.47, 3.58, 3.68, 3.78, 3.98, 4.08, 3.88, 4.18, 4.28, 4.48, 4.78]

# Create the plot in black and white
plot(years, wealth_income_scf, 
     label="Wealth-to-Income Ratio (SCF)",
     color=:black,
     linestyle=:solid,
     linewidth=2,
     marker=:circle,
     markersize=4,
     markerstrokecolor=:black,
     markerfillcolor=:white)

plot!(years, wealth_income_fa_nipa,
      label="Wealth-to-Income Ratio (FA & NIPA)",
      color=:black,
      linestyle=:dash,
      linewidth=2,
      marker=:square,
      markersize=4,
      markerstrokecolor=:black,
      markerfillcolor=:black)

plot!(years, capital_gdp,
      label="Capital-to-GDP Ratio",
      color=:black,
      linestyle=:dot,
      linewidth=2,
      marker=:diamond,
      markersize=4,
      markerstrokecolor=:black,
      markerfillcolor=:gray)

# Customize the plot
plot!(xlabel="Year",
      ylabel="Ratio",
      title="Wealth to Output Over Time (1989-2022)",
      legend=:topleft,
      grid=true,
      gridwidth=1,
      gridcolor=:gray,
      gridlinestyle=:dot,
      background_color=:white,
      foreground_color=:black,
      ylims=(3, 8),
      xlims=(1988, 2023),
      xticks=years,
      size=(800, 600))

# Rotate x-axis labels for better readability
plot!(xrotation=45)

# Save the plot as PDF to disk
savefig("economic_ratios_plot.pdf")

# Optionally also display the plot
display(current())

println("Plot saved as 'economic_ratios_plot.pdf' in the current directory")
