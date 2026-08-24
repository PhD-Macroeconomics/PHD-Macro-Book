# Chapter 16

This folder includes codes to accompany Chapter 16 "Asset prices" written by Monika Piazzesi and Martin Schneider of the book [Macroeconomics](https://phdmacrobook.org/), by Marina Azzimonti, Per Krusell, Alisdair McKay, and Toshihiko Mukoyama, plus contributing authors (Oxford University Press, 2026). 

The codes construct the chapter's consumption, return, and valuation-ratio series from NIPA/FRED/Shiller data, run the Mehra-Prescott calibration, and reproduce Figures 16.1, 16.4, and 16.5 and Tables 16.1 and 16.2. Data construction and analysis is done in MATLAB; the final book-formatted figures are drawn in Python from the MATLAB output.

## The codes

**MATLAB (data construction and analysis)**

* `annualdata.m` — builds the annual series (consumption growth, inflation, real risk-free and stock returns, price-dividend ratios for stocks and housing) from the NIPA, FRED, and Shiller data below, prints the moments in Table 16.1 ("Sample moments of aggregate consumption growth and real returns") and runs the return-forecasting regressions in Table 16.2 ("Return forecasting regressions"), and writes `Fig_1_data.csv`, `Fig_5_data_excessreturn.csv`, and `Fig_5_data_4DP.csv` for the Python figure scripts. It also saves its own (non-final) plots directly: `annualcgrowth.pdf`, `predict.pdf`, `price_cashflows.pdf`.
* `mpcal.m` — solves the two-state Mehra-Prescott (1985) consumption-based asset pricing model over a grid of risk-aversion and discount-factor values, saves its own plot `mehraprescott.pdf`, and writes `Fig_4_data.csv` (the upper envelope of the risk-free rate/equity premium frontier) for the Python figure script.
* `multiyear.m`, `multiyear_a.m` — helper functions that compound one-period gross returns into N-year returns; called by `annualdata.m`.
* `olsgmm.m` — OLS regression with GMM (Newey-West) corrected standard errors; called by `annualdata.m` for the Table 16.2 regressions.

**Python (final book figures, built from the MATLAB output above)**

* `Fig1.py` — reads `Fig_1_data.csv`, produces Figure 16.1 (`fig1.pdf`).
* `Fig4.py` — reads `Fig_4_data.csv`, produces Figure 16.4 (`fig4.pdf`).
* `Fig5.py` — reads `Fig_5_data_excessreturn.csv` and `Fig_5_data_4DP.csv`, produces Figure 16.5 (`fig5.pdf`).

All three import a shared [`figureoptions.py`](../figureoptions.py) module (for consistent fonts/layout) from the parent `Codes-and-Data` folder.

**Data inputs**

* `NIPATable1_1_4.xlsx`, `NIPATable2_1.xlsx`, `NIPATable2_4_3.xlsx`, `NIPATable2_4_4.xlsx`, `NIPATable2_4_5.xlsx` — BEA NIPA tables (GDP and its deflator, population, and consumption expenditures/prices/quantities by product type).
* `SFFixed2_1.xlsx` — BEA Fixed Asset table (residential structures, used for the housing valuation ratio).
* `DGS1.xlsx`, `DGS10.xlsx` — FRED 1-year and 10-year Treasury rates.
* `ie_data.xls` — Robert Shiller's stock price/dividend/earnings dataset.
* `chapt26.xlsx` — Shiller's earlier risk-free and long-rate series (used to extend the FRED series back to 1929).

## Instructions to run them

1. In MATLAB, run `annualdata.m`. This prints Tables 16.1 and 16.2 to the console and writes `Fig_1_data.csv`, `Fig_5_data_excessreturn.csv`, `Fig_5_data_4DP.csv`, `annualcgrowth.pdf`, `predict.pdf`, and `price_cashflows.pdf`.
2. In MATLAB, run `mpcal.m`. This writes `Fig_4_data.csv` and `mehraprescott.pdf`.
3. Run `Fig1.py`, `Fig4.py`, and `Fig5.py` in Python to produce the final versions of Figures 16.1, 16.4, and 16.5 (`fig1.pdf`, `fig4.pdf`, `fig5.pdf`).

## Notes

* `annualcgrowth.pdf`, `predict.pdf`, `price_cashflows.pdf`, and `mehraprescott.pdf` are MATLAB's own preview plots of the same data as `fig1.pdf`, `fig4.pdf`, and `fig5.pdf` — the Python-generated versions are the ones used in the book.
* `annualdata.asv` and `mpcal.asv` are MATLAB autosave files, not part of the code.
