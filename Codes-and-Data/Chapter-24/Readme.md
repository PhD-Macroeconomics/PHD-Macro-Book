# Chapter 24

This folder includes codes to accompany Chapter 24 "Sovereign debt and default risk" of the book [Macroeconomics](https://phdmacrobook.org/).

These codes were written by Juan Carlos Hatchondo and Leonardo Martinez

The codes solve and simulate the quantitative sovereign default model of Section 24.4, and reproduce Figures 24.6 and 24.7 and Table 24.3. The model is solved and simulated in Fortran; the figures and table are built from that output in MATLAB.

## The codes

* `code_sovereign_default.f90` — solves the sovereign's dynamic programming problem by value function iteration on a grid of debt and income levels.
* `simulate_sovereign_default.f90` — reads the converged solution and simulates 500 samples of 501 periods each (income, debt, consumption, bond prices, defaults).
* `figures_bond_price_consumption.m` — reads the output of `code_sovereign_default.f90` and produces Figure 24.6 (`q_book.eps`) and Figure 24.7 (`c_book.eps`).
* `table_simulations.m` — reads the output of `simulate_sovereign_default.f90`, HP-filters the simulated series, and prints the moments in Table 24.3.
* `hpfilter.m` — Hodrick-Prescott filter used by `table_simulations.m`.
* `data_graphs_chapter_24.xlsx` — underlying data for the chapter's empirical figures 24.2 - 24.5.

Also included: the calibrated parameters (`d0.txt`, `d1.txt`, `beta.txt`), grids for debt and income ('b_grid.txt', 'y_grid.txt') and the solved model files (`v.txt`, `default.txt`, `q.txt`, `b_next.txt`, `q_paid.txt`, `dev.txt`), so the simulation and figures can be produced without re-solving the model.

## Instructions to run them

1. Make sure the files specifying the cost of default (`d0.txt`, `d1.txt`) and the sovereign's discount factor (`beta.txt`) are copied to the working directory
2. Compile `code_sovereign_default.f90` and `simulate_sovereign_default.f90`. Both call routines from the IMSL Fortran Numerical Library (`DNORDF`, `DNORIN`, `DZBREN`, `DUVMIF`, `DGQRUL`, `DCSDEC`, `DCSVAL`, `RNSET`, `DRNUN`), so you will need a Fortran compiler linked against IMSL.
3. Run `code_sovereign_default.f90`. It solves the model and produces the files `v.txt`, `default.txt`, `q.txt`, `b_next.txt`, `dev.txt`, `q_paid.txt`, `b_grid.txt`, `y_grid.txt`, `bounds.txt`, `counter.txt`, and `delta.txt` to this folder.
4. In MATLAB, run `figures_bond_price_consumption.m` to produce Figures 24.6 and 24.7.
5. Run `simulate_sovereign_default.f90`. It reads the solution from step 3 plus `beta.txt`, `d0.txt`, `d1.txt`, and writes `data_sim.txt`, `def_per.txt`, and `param.txt`.
6. In MATLAB, run `table_simulations.m` to print Table 24.3. Make sure the file 'hpfilter.m' is present in the working directory.

All file paths in the code are relative filenames, so keep every file in the same working directory when compiling and running.

