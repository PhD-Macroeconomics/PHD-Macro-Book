## Running Open-Economy Macro Model Codes

### Simon Lloyd

Reproduces **Figure 23.7** ("International transmission of a positive home
productivity shock") from Chapter 23, by Giancarlo Corsetti, Luca Dedola and 
Simon Lloyd.

The figure shows impulse responses to a positive, persistent 1% home
productivity shock in a two-country, real (no-capital), tradable-goods
model, under three financial-market structures — Complete Markets,
Financial Autarky, and a stationarity-inducing Bond Economy — across three
columns of the trade (Armington) elasticity and shock-persistence
parameterisation:

- **(a)** trade elasticity φ = 1.5, home productivity AR(1) with ρ = 0.97
- **(b)** trade elasticity φ = 0.3, home productivity AR(1) with ρ = 0.97
- **(c)** trade elasticity φ = 3, home productivity AR(2) with ρ₁ = 1.7, ρ₂ = -0.703

### Contents

```
RUN_Figure.m               Main (and only) script to run. Produces the
                            full figure in one pass.
MasterMod2c_Real.mod       Dynare model file: the two-country tradables
                            model, with Complete Markets / Financial
                            Autarky / Bond Economy selectable at parse
                            time via a macro flag.
functions/
  model_definition_real.m    Translates run options into Dynare-ready
                              parameters and initial steady state.
  parameterisation_real.m    Deep/calibrated parameter values (discount
                              factors, risk aversion, trade elasticity,
                              shock persistence, consumption shares, ...).
  solvesteadystate_real.m    Solves the model's non-stochastic, symmetric
                              steady state via fsolve.
README.md                  This file.
```

### Requirements

- **MATLAB** (tested with R2026a), including the **Optimization Toolbox**
  (`solvesteadystate_real.m` calls `fsolve`).
- **Dynare** (tested with version 7.1), installed and added to the MATLAB
  path (e.g. `addpath('<path-to-dynare>\matlab')`). `RUN_Figure.m` checks
  for this and raises a clear error if Dynare cannot be found.

### How to run

1. Make sure Dynare is on your MATLAB path (see Requirements above).
2. Open `RUN_Figure.m` in MATLAB and run it (the script relocates itself
   to its own folder on start, so it does not matter what MATLAB's
   current working directory is beforehand).
3. The script solves and simulates the model nine times (3 columns × 3
   financial-market structures), then assembles the results into a
   single figure. This takes a few minutes.
4. The reproduced figure is saved to `Figure23-7/Real_IRF_Figure.png`
   (and `.eps`), and compares directly against `figure.png`.

Everything else the script needs is created automatically when 
`RUN_Figure.m` runs and can be safely deleted between runs; 
none of it needs to be tracked or edited by hand.

### What the script does

For each of the three columns above, `RUN_Figure.m` re-parameterises and
re-solves `MasterMod2c_Real.mod` under each of the three financial-market
structures (9 runs total), extracts the impulse responses of home and
foreign output, home consumption, the terms of trade, and real net
exports/current account to a home productivity shock, and plots them in
a 5-row × 3-column layout matching Figure 23.7 (Complete Markets: solid
black; Financial Autarky: solid grey; Bond Economy: dashed black).

### Contact

Questions, suggestions, or bug reports: splloyd@gmail.com.
