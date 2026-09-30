# Chapter 7

This folder includes codes to accompany Chapter 7 "Uncertainty" of the book Macroeconomics, by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026).

Julia scripts illustrating the models behind Figures 3 and 4.

- `main_figure_3.jl` solves and simulates the stochastic growth model, plotting sample paths, impulse responses, the distribution of capital, and saving policy rules. The simulated path differs from the book because the sequence of random numbers is different.
- `main_figure_4.jl` solves the household saving problem with income risk using the endogenous grid method, computes the stationary distribution, and plots saving policies and the wealth distribution. Supporting routines are in `fig4_helpers/`.

Install the required packages once in Julia:

```julia
using Pkg
Pkg.add(["Plots", "Parameters", "Roots"])
```

Run the scripts from this directory:

```sh
julia main_figure_3.jl
julia main_figure_4.jl
```

Figures are saved as PNG files in `Results/`.
