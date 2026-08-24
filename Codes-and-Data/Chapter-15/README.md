# Chapter 15

This folder includes codes to accompany Chapter 15 "Government and public policies" written by Marina Azzimonti, Jonathan Heathcote, and Kjetil Storesletten of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026). 

These codes were written by Marina Azzimonti, , Jonathan Heathcote, and Kjetil Storesletten.

The chapter has two kinds of figures. Figures 15.1–15.5 and 15.9 are descriptive, built from published data on U.S. and OECD government finances; the underlying series are in `Data/`, and the sources are documented in Online Appendix 15.A.1. Figures 15.6, 15.7, 15.8, and 15.A.1 are computed from the worker–capitalist model of Sections 15.3.2–15.3.4; the code that solves that model is in the three `Fig_*_code/` folders.

Each model folder contains the original MATLAB code and a Python translation that reproduces the same results. The two are independent — run whichever you prefer.

## What produces each figure

| Figure | Description | Code | Data |
|---|---|---|---|
| 15.1 | Government spending across countries | — | `Data/Data_Ch_15.xlsx`, sheet `Fig 15.1` |
| 15.2 | Revenues and outlays | — | `Data/Data_Ch_15.xlsx`, sheet `Fig 15.2` |
| 15.3 | Taxes by category | — | sheets `Fig 15.3` (as published) and `Fig 15.3T` (transposed) |
| 15.4 | Deficits, net interest, and total debt | — | sheets `Fig15.4-Left` / `Fig15.4LeftT` and `Fig 15.4 -Right` |
| 15.5 | Expenditures by category and by function | — | sheets `Fig15.5-Left` / `-LeftT` and `Fig15.5-Right` / `-RightT` |
| 15.6 | How allocations vary with $\tau_k$ | `Fig_8_code/` | computed |
| 15.7 | Eliminating capital income taxes | `Fig_7_code/` | computed |
| 15.8 | The Laffer curve | `Fig_8_code/` | computed |
| 15.9 | Pre- and post-government income | — | `Data/Data_fig_15_9.xlsx`, sheet `Data_Fig15.9` |
| 15.A.1 | Eliminating capital income taxes, with wealth effects | `Fig_15.A.1_code/` | computed |

The `T` sheets hold the same series as their unsuffixed counterparts, transposed into columns with one row per year. They are the convenient form for plotting; the unsuffixed sheets preserve the layout of the published source tables.

## The model code

All three model folders share the same environment: a representative firm with Cobb–Douglas technology, workers who supply labor but own no capital, and capitalists who own capital but do not work. The government levies proportional taxes on labor and capital income to fund purchases equal to a fixed share of output.

### `Fig_8_code/` — Figures 15.6 and 15.8

Steady-state comparisons only; every object has a closed form, so there is no solver.

* `per_GHH.m` — MATLAB original. Sweeps $\tau_k$ over $[0,1]$, adjusting $\tau_l$ at each point to hold $G/Y$ fixed (equation 15.14), and records hours, output, the consumption of each household type, and the excess cost of taxation. Writes `tauk.pdf` (Figure 15.6) and `Laffer.pdf` (Figure 15.8). Despite the folder name it produces both figures.
* `per_GHH.py` — Python translation. Same calculations, plus `fig_15_6_data.csv` and `fig_15_8_data.csv` so the numbers are available without opening a plot. Prints checks against values quoted in the text.

```bash
python per_GHH.py
```

### `Fig_7_code/` — Figure 15.7

The transition after an unexpected, permanent elimination of the capital income tax, with the labor tax raised from 0.2529 to 0.2985 so that $G/Y$ is unchanged in the new steady state. Preferences are Greenwood–Hercowitz–Huffman, so labor supply has no wealth effects. Solving for the path of capital requires a numerical method: the equilibrium is a system of $2T-1$ equations — $T$ intratemporal first-order conditions and $T-1$ Euler equations — in the capital and hours paths.

* `TaxIncrease.m` — driver. Sets parameters, solves the initial steady state, defines the reform, and calls `ComputeModel`. **Run this first**; it writes `Results.mat` and `parameters.mat`.
* `solveSteadyState.m` — steady-state residual, called by `fsolve`.
* `ComputeModel.m` — solves the system by Newton's method with a numerical Jacobian.
* `PlotResults.m` — converts the solution to percent deviations from the pre-reform steady state and draws the figures. Run after `TaxIncrease.m`.
* `createfigure_temp.m`, `createfigure_temp_tax.m` — figure helpers for the allocation and policy panels. `createfigure_temp_prices.m` draws wages, hours, the interest rate, and investment; it is not used for any published figure and is called from a commented-out line in `PlotResults.m`.
* `tax_reform.py` — Python translation of all of the above in one file. Writes `transition_data.csv`, `Allocations.pdf`, and `Policies.pdf`.
* `Allocations.pdf`, `Policies.pdf` — the right- and left-hand panels of Figure 15.7.

```bash
# MATLAB
TaxIncrease        % then
PlotResults

# Python
python tax_reform.py
```

### `Fig_15.A.1_code/` — Figure 15.A.1

The same reform under $u(c,\ell) = \log c - \ell^{1+1/\phi}/(1+1/\phi)$, so that wealth effects are present. Substitution and income effects offset exactly and hours stay flat, so output and $G$ end up higher than in Figure 15.7 — the reform is less costly in this specification. See Online Appendix 15.A.2.

The files mirror `Fig_7_code/` and differ in only three places: steady-state hours are normalized to 1 in `TaxIncrease.m` and `solveSteadyState.m`, and the intratemporal first-order condition in `ComputeModel.m` is divided by workers' consumption. In `tax_reform.py` all three are controlled by the `WEALTH_EFFECTS` switch at the top of the file, so the two Python scripts differ by one line.

Outputs are `AllocationsWE.pdf` and `PoliciesWE.pdf`, which together form Figure 15.A.1.

## Calibration

Identical across all three model folders (Section 15.3.2):

| Parameter | Value | Meaning |
|---|---|---|
| $\alpha$ | 0.33 | capital share |
| $\beta$ | 0.97 | discount factor |
| $\delta$ | 0.07 | depreciation rate |
| $\phi$ | 1 | Frisch elasticity of labor supply |
| $\tau_c$ | 0 | consumption tax, switched off to isolate $\tau_k$ against $\tau_l$ |
| $g$ | 0.2 | government purchases as a share of output |
| $\tau_k$ | 0.25 → 0 | capital income tax, before and after the reform |
| $\tau_l$ | 0.2529 → 0.2985 | labor income tax, set residually by equation (15.14) |

The reform experiments simulate 100 periods and display 10 pre-reform periods before the change.

## Requirements

MATLAB with the Optimization Toolbox (for `fsolve`), or Python 3 with `numpy`, `scipy`, `pandas`, and `matplotlib`.

## Notes

* Run `TaxIncrease.m` before `PlotResults.m`: the latter loads `Results.mat` and `parameters.mat`, which the former creates. Neither file is stored here, so the MATLAB path regenerates them from scratch.
* `ComputeModel.m` saves `Results.mat` with a capital R while `PlotResults.m` loads `results.mat` with a lowercase r. This is fine on Windows but will fail on a case-sensitive filesystem (Linux, and macOS if configured that way).
* `Fig_7_code/PlotResults.m` also writes `../Fig7Data.mat`, one level above the code folder. That path is a holdover from an earlier flat layout; the file it produces is the input to the published version of Figure 15.7.
* The excess cost of taxation in panel D of Figure 15.6 diverges as $\tau_k \to 1$, because output collapses to zero and the denominator goes with it. Both the MATLAB and Python code return `Inf` at exactly $\tau_k = 1$; the panel is clipped at 200 so the point is off-scale either way.
* The Python translations were checked against the MATLAB results: `per_GHH.py` reproduces the steady-state sweep to machine precision, and `tax_reform.py` reproduces the published transition paths to within the original solver's tolerance (agreement to roughly 0.02% on series that move by 10 percentage points or more).
