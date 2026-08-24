# Chapter 21

This folder includes codes to accompany Chapter 21 "Inequality" written by Per Krusell and Jose-Victor Rios-Rull of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026) 

These codes were written by Per Krusell and José-Víctor Ríos-Rull.
The SCF pipeline is the SCF+ update maintained by Moritz Kuhn and
José-Víctor Ríos-Rull, cited in the chapter as Kuhn and Ríos-Rull (2025).

Everything in the chapter falls into three groups:

1. **SCF-based facts** (Figures 21.1, 21.3, 21.7, 21.8 and Table 21.1) —
   built from the Survey of Consumer Finances with the Stata pipeline in
   `code/scf_stata/`, then plotted with the Julia scripts in
   `code/figures_julia/`.
2. **A quantitative Aiyagari model** with borrowing constraints and a
   consumption externality (Figure 21.11) — Julia, in `code/model_julia/`.
3. **Figures reproduced from published work** (21.4, 21.5, 21.6) and two
   schematic drawings (21.2, 21.10). These have no code here; see
   "Figures not produced by this code" below.

---

## Contents

```
code/
  scf_stata/        Stata: SCF data construction and distributional statistics
  figures_julia/    Julia: the descriptive figures of Section 21.1
  model_julia/      Julia: the Aiyagari model with externality (Fig. 21.11)
data/               Input data and saved model output
figures/            Every figure, as it appears in the chapter
```

---

## Map from exhibit to code

| Exhibit | Source code | Input data | Output |
|---|---|---|---|
| Fig. 21.1 — Histogram of the income distribution | `code/figures_julia/fig21_01_histogram.jl` | `scf2022.dta` (see below), or `data/scf_2022_income_data.csv` | `figures/fig21_01_income_histogram.png` |
| Fig. 21.2 — Lorenz curve (schematic) | — (LaTeX/TikZ drawing) | none | `figures/fig21_02_lorenz_schematic.pdf` |
| Fig. 21.3 — Lorenz curves, labor earnings / residential and total wealth | `code/figures_julia/fig21_03_lorenz.jl` | `data/SCFP2022.csv` | `figures/fig21_03_lorenz_combined.pdf` |
| Table 21.1 — 2022 per-household shares | `code/scf_stata/QR2022_nh.do` (earnings, income, wealth); BLS CEX Table 1101 in `data/` (consumption); `code/cps_asec/hours_shares_asec.py` (hours); `code/gini_from_shares.py` (the Gini column) | `scf2022.dta` | LaTeX table, written into the chapter source |
| Fig. 21.4 — (Log) hours by wage ventile | — reproduced from Boppart, Krusell and Olsson | none | `figures/fig21_04_hours_by_wage_ventile.png` |
| Fig. 21.5 — Portfolio shares, Sweden | — reproduced from Bach, Calvet and Sodini (2020) | none | `figures/fig21_05_portfolio_shares_sweden.png` |
| Fig. 21.6 — Excess returns on portfolios | — reproduced from Hubmer, Krusell and Smith (2018) | none | `figures/fig21_06_excess_returns.pdf` |
| Fig. 21.7 — Wealth-to-income and capital-to-GDP ratios | `code/scf_stata/wealth_capital_income_ratios.do` (wealth series), `code/figures_python/fig21_07_exact_geometry.py` (the published plot); `code/figures_python/fig21_07_wealth_income_ratios.py` documents the capital series and can recompute it from `data/fred/` | SCF waves 1989–2022; `data/figure21_7_data.csv`; `data/fred/` | `figures/fig21_07_wealth_income_ratios.pdf` |
| Fig. 21.8 — Earnings and wealth trends, 1989–2022 | `code/scf_stata/QR2022_nh.do`, plotted by `code/figures_julia/fig21_08_earnings_wealth_trends.jl` | SCF waves 1989–2022 | `figures/fig21_08a_earnings_trends.pdf`, `figures/fig21_08b_wealth_trends.pdf` |
| Fig. 21.9 — Skill premium over time | `code/figures_julia/fig21_09_skill_premium.jl` | `data/KORV_data_OOS2023.csv` | `figures/fig21_09_skill_premium.pdf` |
| Fig. 21.10 — Savings decision rule (schematic) | — (hand-drawn) | none | `figures/fig21_10_savings_decision_rule.pdf` |
| Fig. 21.11 — Impact responses to a 1% TFP shock | `code/model_julia/aiyagari_externality_main.jl` → `postprocess_results.jl` → `fig21_11_impact_responses.jl` | `data/model_output/all_results_current.jld2` | `figures/fig21_11_impact_responses.png` |

---

## 1. SCF pipeline (Stata)

The SCF statistics behind Table 21.1 and Figures 21.7 and 21.8 come from
the SCF+ update maintained by Moritz Kuhn and José-Víctor Ríos-Rull; the
chapter cites this as Kuhn and Ríos-Rull (2025). The do-files are
included here as run.

| File | Purpose |
|---|---|
| `makeupdata_nh.do` | Builds the analysis file `scf2022.dta` from the Federal Reserve's raw 2022 SCF public-use files |
| `scflabel.do`, `joindata.do` | Variable labelling and merging of the five implicates |
| `QR2022_nh.do` | Main statistics program: quantiles, shares, Gini coefficients, concentration and skewness by earnings / income / wealth. Produces the numbers in Table 21.1 and the series plotted in Figure 21.8 |
| `wealth_capital_income_ratios.do` | Wealth-to-income and capital-to-output ratios by SCF wave (Figure 21.7) |
| `lorenz_curves.do` | Lorenz curves by wave |
| `top_shares.do` | Top wealth and income shares |
| `hours_shares_gini.do` | SCF illustration of how an hours row would be built. **Not the source of the published rows** — those are CPS ASEC, see `code/cps_asec/`. Retained for reference |
| `writelatextablesflex_nh.do` | Helper that writes the LaTeX tables |

The earnings, income and wealth rows of Table 21.1 come from
`QR2022_nh.do`; the consumption row is taken straight from the BLS table
cited in the note to Table 21.1. The two hours-worked rows need a
warning of their own — see the next section.

### The two hours rows

The two "Hours worked" rows of Table 21.1 come from the **CPS ASEC**,
not the SCF, and are produced by `code/cps_asec/hours_shares_asec.py`.
See `code/cps_asec/README.md` for the download link (Census public use,
no registration), the variable mapping, and the sample definitions.

This matters because `QR2022_nh.do`, which produces every other row of
the table, contains no hours variables at all, and the SCF cannot
reproduce these rows under any sample definition: about 28 percent of
SCF households report zero annual hours. `makeupdata_nh.do` does build
household hours variables (`headannualhours`, `spouseannualhours`), and
`code/scf_stata/hours_shares_gini.do` turns them into group shares —
but that file is **an SCF illustration of the method, retained for
reference only**. It is not the source of the published rows. Use the
CPS ASEC script.

### Figure 21.7, and the two scripts in `code/figures_python/`

Figure 21.7 has two scripts because the figure was redrawn late, to the
printed artwork's measured geometry:

- **`fig21_07_exact_geometry.py` produces the published figure.** It is
  built 1:1 to the artwork box measured off the page proof (297.4 ×
  148.4 pt, all four spines, 8 pt type), so the output drops in without
  scaling. It reads `data/figure21_7_data.csv` and writes
  `figures/fig21_07_wealth_income_ratios.{pdf,eps,png}`.
- **`fig21_07_wealth_income_ratios.py` is where the data are
  documented.** It plots the same three series in the earlier,
  unconstrained style, and with `--recompute` rebuilds the
  capital-to-GDP series from the FRED files in `data/fred/` rather than
  reading the stored column. It writes to
  `figures/fig21_07_draft_style.*`, so running it cannot overwrite the
  published figure.

The capital-to-GDP series is the **current-cost** measure: BEA net
stock of fixed assets (FRED `K1WTOTL1ES000`, millions) over nominal GDP
(`GDPA`, billions). This is the same basis as Figure 2.2 of Chapter 2,
so the two chapters agree. Both wealth-to-income series come from the
Stata pipeline above and are carried in the CSV because that pipeline
needs the full SCF wave files, which are too large to ship.

## 2. Descriptive figures (Julia)

Written for Julia 1.9+ with `Plots`, `StatsPlots`, `DataFrames`, `CSV`,
`StatsBase`, `Statistics`, and `ReadStatTables` (only needed for the
histogram, which reads Stata `.dta` directly). Each script is run from
the directory holding its input and writes its figure to the working
directory.

`fig21_01_histogram.jl` looks for `scf2022.dta` in the working
directory; `data/scf_2022_income_data.csv` is the extracted
income-and-weight file it produces, so the plot can be redrawn without
the full `.dta`.

Note that `fig21_07_wealth_income_ratios.jl` and
`fig21_08_earnings_wealth_trends.jl` carry the series as literal arrays
at the top of the file rather than reading them from disk. Those numbers
are the output of the Stata programs above (`wealth_capital_income_ratios.do`
and `QR2022_nh.do` respectively); the Julia files are only the
black-and-white redraws prepared for the book. `extra_inequality_measures.jl`
is the same kind of script for a set of additional inequality measures
(Gini, coefficient of variation, variance of logs, percentile ratios)
that were computed but not printed in the final chapter.
`extra_histogram_by_race.jl` is a longer variant of the histogram script
that also downloads the SCF files from the Federal Reserve and breaks the
income distribution down by race; neither breakdown appears in the
chapter.

## 3. Aiyagari model with a consumption externality (Julia)

Figure 21.11 reports the impact responses of consumption and output to a
1% TFP shock, comparing an economy without the externality (ω = 0) to
one with it (ω = 0.5).

| File | Purpose |
|---|---|
| `aiyagari_externality_main.jl` | Solves the model. Steady state by bisection on the interest rate, then a perfect-foresight MIT-shock transition. Loops over a grid of γ (probability of being savings-constrained) and ω (consumption-externality strength), both set at the top of the file. Saves results to `.jld2` and `.jls` |
| `postprocess_results.jl` | Builds the summary tables, the amplification table, and the transition/heatmap diagnostic plots from the saved results |
| `fig21_11_impact_responses.jl` | Draws the side-by-side consumption and output impact responses used as Figure 21.11 |

Packages: `Parameters`, `LinearAlgebra`, `SparseArrays`, `Setfield`,
`ForwardDiff`, `BasicInterpolators`, `Roots`, `QuantEcon`, `Plots`,
`DataFrames`, `CSV`, `Printf`, `Statistics`, `Serialization`, `JLD2`.
The main file installs anything missing on first run.

The saved output for the configuration used in the chapter is in
`data/model_output/`, so Figure 21.11 can be redrawn without re-solving
the model: run `fig21_11_impact_responses.jl` from that directory (it
picks up the most recent `.jld2` in the working directory).
`comprehensive_analysis_summary_FIXED.csv` holds the same results in
plain text.

---

## Figures not produced by this code

Five exhibits have no replication material here, by their nature. The
image files are in `figures/`, but there is no code or data behind them:

- **Figure 21.2** is a schematic Lorenz curve drawn in LaTeX to
  illustrate the definition; it plots no data.
- **Figure 21.4** is reproduced from Boppart, Krusell and Olsson.
- **Figure 21.5** is reproduced from Bach, Calvet and Sodini (2020),
  who use Swedish registry data that is not publicly redistributable.
- **Figure 21.6** is reproduced from Hubmer, Krusell and Smith (2018).
- **Figure 21.10** is a hand-drawn schematic of the savings decision
  rule; it plots no data.

The consumption row of Table 21.1 is taken directly from the BLS
Consumer Expenditure Survey, Table 1101, included as
`data/cu-income-quintiles-before-taxes-2022.pdf` and available at
<https://www.bls.gov/cex/tables/calendar-year/aggregate-group-share/cu-income-quintiles-before-taxes-2022.pdf>.

## Data inventory

| File | Size | Description | Source |
|---|---|---|---|
| `data/SCFP2022.csv` | 21 MB | SCF 2022 Summary Extract public data | Federal Reserve Board |
| `data/scf_2022_income_data.csv` | 0.7 MB | Income and survey weights extracted from `scf2022.dta`, for Figure 21.1 | derived |
| `data/KORV_data_OOS2023.csv` / `.xlsx` | small | Updated Krusell–Ohanian–Ríos-Rull–Violante series, extended out of sample to 2023; column 12 is the year and column 13 the skill premium | authors |
| `data/cu-income-quintiles-before-taxes-2022.pdf` | 0.1 MB | CEX Table 1101, consumption shares by income quintile | BLS |
| `data/model_output/all_results_current.jld2` | 6.5 MB | Solved model, all (γ, ω) pairs | this code |
| `data/model_output/comprehensive_analysis_summary_FIXED.csv` | small | Same results, plain text | this code |
