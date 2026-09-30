# Chapter 18

This folder includes codes to accompany Chapter 18 "Nominal frictions and business cycles" written by Alisdair McKay and Morten Ravn of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026). 

## Constructing the chapter's figures

MATLAB programs and supporting data for Figures 1–3 of Chapter 18.

| Folder | Entry script | Figure |
| --- | --- | --- |
| `fig_1/` | `main_figure_1.m` | Output and inflation responses to a cost-push shock under commitment and discretionary monetary policy. |
| `fig_2/` | `main_figure_2.m` | Empirical responses to a monetary policy shock compared with a basic New Keynesian model and a model with sticky wages and prices. |
| `fig_3/` | `main_figure_3.m` | Lead–lag correlations between labor share and inflation, using HP-filtered data for the full sample and two subsamples. |

Use MATLAB and run each entry script with its folder as the current directory. Figure 1 also requires Dynare on the MATLAB path; Figure 2 uses Bayesian VAR estimation using helper functions in `fig_2/_auxiliary_functions`.


Figure 2 uses the supplied `Data/processeddata.mat`, runs estimation and both model simulations, and saves intermediate results and output/inflation CSV tables in `fig_2/Results/`. See [fig_2/README](fig_2/README) for data provenance and preprocessing notes.

Figure 3 uses the supplied `fig_3/Inflation_data.xlsx` and local filtering helpers. On case-sensitive filesystems, the workbook name in the script (`inflation_data.xlsx`) must match the supplied filename.


