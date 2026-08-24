using CSV, DataFrames, Plots

# Load the data
df = CSV.read("UPDATED KORV DATA_OOS2023.csv", DataFrame)

# Extract columns L (Year) and M (Skill Premium)
x = df[:, 12]  # Column L is 12th (1-based index in Julia)
y = df[:, 13]  # Column M is 13th

# Plot
plot(x, y;
     xlabel = "Year",
     ylabel = "Skill Premium",
     marker = :circle,
     line = :solid,
     legend = false,
     grid = true,
     size = (600, 400))

# Save to EPS and PDF
savefig("skill_premium_plot_updated.eps")
savefig("skill_premium_plot_updated.pdf")
