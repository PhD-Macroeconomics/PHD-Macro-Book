# Chapter 3

This folder includes codes to accompany Chapter 3 "The Solow model" of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026). 

Most of the chapter is theoretical. Figures 3.1 to 3.5 are phase diagrams illustrating the dynamics implied by the fundamental equation of the Solow model, and Online Appendix 3.A proves a discrete-time version of the Uzawa (1961) theorem; neither involves data or computation, so no code accompanies them. The published diagrams are kept in `Figures/` for reference.

Two sets of figures do require code. Figures 3.6 to 3.8 plot cross-country growth against initial income using the Penn World Table, and Figure 3.9 simulates an impulse response in a calibrated version of the model.

## What produces each figure

| Figure | Description | Code | Data |
|---|---|---|---|
| 3.1 | Dynamics in the Solow model | — theoretical | — |
| 3.2 | Endogenous growth | — theoretical | — |
| 3.3 | Poverty traps | — theoretical | — |
| 3.4 | Complex dynamics | — theoretical | — |
| 3.5 | Slow and fast convergence | — theoretical | — |
| 3.6 | Growth vs. initial GDP, all countries, 1960–2019 | `Fig_3.6-3.8_convergence/` | `Data/PWTNA2000.xlsx`, sheet `All` |
| 3.7 | Growth vs. initial GDP, OECD, 1960–2019 | `Fig_3.6-3.8_convergence/` | `Data/PWTNA2000.xlsx`, sheet `OECD` |
| 3.8 | Growth vs. initial GDP, all countries, 2000–2019 | `Fig_3.6-3.8_convergence/` | `Data/PWTNA2000.xlsx`, sheet `All` |
| 3.9 | Impulse response of capital to a technology shock | `Fig_3.9_impulse_response/` | computed |

The published figures are in `Figures/`. `Solow1R.pdf` through `Solow6R.pdf` are Figures 3.1 to 3.5 — note that Figure 3.5 has two panels, so six files cover five figures. `convergence1.pdf`, `convergence2.pdf`, and `convergence3.pdf` are Figures 3.6 to 3.8, and `IRAR.pdf` and `IR1R.pdf` are the two panels of Figure 3.9.

## Convergence (Figures 3.6–3.8)

Each figure plots the annualized growth rate of per capita real GDP over a period against the log of per capita real GDP at the start of it, with one country code drawn at each point and a fitted linear trend. Data are from the Penn World Table 10.0; the GDP variable is RGDPNA, divided by population, in 2017 US dollars.

The fitted slopes summarize the point made in Section 3.4.2:

| Figure | Sample | Countries | Slope |
|---|---|---|---|
| 3.6 | All countries, 1960–2019 | 111 | −0.0004 |
| 3.7 | Original OECD members, 1960–2019 | 20 | −0.0071 |
| 3.8 | All countries, 2000–2019 | 111 | −0.0026 |

There is essentially no relationship in the full 1960 sample, a clear negative one within the OECD (conditional convergence), and a mild negative one from 2000 onward.

### `convergence.py` (Python)

Reads `Data/PWTNA2000.xlsx` directly and writes `convergence1.pdf`, `convergence2.pdf`, `convergence3.pdf`, plus a CSV of each analysis sample.

```bash
python convergence.py
```

### `matlab/` (original MATLAB)

`convergenceplot_logscale.m`, `convergenceOECD_logscale.m`, and `convergence2000_logscale.m` produce Figures 3.6, 3.7, and 3.8 respectively. Each pulls its inputs from three data scripts that hold hardcoded arrays — for example `convergenceplot_logscale.m` calls `level60.m`, `growth6019.m`, and `label.m`. Run a plotting script from inside `matlab/` with a `figures/` subdirectory present, since the scripts save into that relative path.

The `.fig` files are the saved MATLAB figure objects.

## Impulse response (Figure 3.9)

Section 3.5.2 simulates a temporary technology shock in the Solow model with Cobb-Douglas production, an exogenous saving rate, and fixed labor. Technology jumps 1 percent above its steady-state level and decays at rate ρ = 0.9; capital starts at its steady state and follows equation (3.14). The calibration is s = 0.2, δ = 0.046, α = 1/3, with ℓ and Ā normalized to 1.

`impulse_response.py` reproduces the numbers quoted in the text — a steady state of 9.066, a peak of 9.089, and a maximum deviation of 0.25 percent — and also computes the log-linearized solution of equation (3.18) so the approximation error can be compared against the chapter's claim.

```bash
python impulse_response.py
```

No code for this figure was included in the original materials; the script was written from the equations and parameter values in the chapter.

## Requirements

Python 3 with `numpy`, `pandas`, `matplotlib`, and `openpyxl`. The MATLAB scripts need only base MATLAB.

## Notes

* **Figure 3.9 timing.** Equation (3.14) is printed as `k_{t+1} = s·A_t·k_t^α·ℓ^(1-α) + (1-δ)k_t`, but that dating produces a peak of 9.0913 and a deviation of 0.28 percent, not the 9.089 and 0.25 percent quoted in the text. The quoted values follow from using `A_{t+1}` instead, under which the first shock reaching the capital stock is the already-decayed ρε rather than ε. `impulse_response.py` defaults to the convention that reproduces the published figure and offers `--timing eq314` for the literal reading. Worth resolving before the code is circulated.
* **Data provenance.** The MATLAB data scripts hold numbers transcribed by hand from the workbook; no MATLAB script reads the Excel files. `convergence.py` removes that step by reading `PWTNA2000.xlsx` directly. The two agree to the precision at which the MATLAB arrays were stored, about 5e-6 in income levels and 5e-10 in growth rates.
* **Variable naming in the MATLAB.** `level60OECD.m` assigns its 1960 OECD income levels to a variable called `level2000a`, and `convergenceOECD_logscale.m` reads that name. The code is internally consistent and Figure 3.7 is correct, but the name is misleading.
* `Data/PWTNA2000.xlsx` is the workbook the figures actually draw on; its `All` and `OECD` sheets hold per capita income in 1960, 2000, and 2019 together with the two annualized growth rates. `PWT.xlsx` and `PWTNA.xlsx` are earlier extracts from the same source, retained for provenance but not used by any script.
