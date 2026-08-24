function [ssvals,params] = model_definition_real(options)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHAPTER 23: International Macroeconomics, PhD Macroeconomics
% ========================================================================
% Codes by Giancarlo Corsetti, Luca Dedola and Simon Lloyd
%
% Disclaimer: If you have any questions, suggestions or spot any bugs,
% please contact splloyd@gmail.com.
%
% This version: August 2026
%
% This code: Translates the human-readable "options" struct set up by the
% calling script (financial-market structure, simulation order, plotting
% choices, and the experiment parameter to be varied) into the numeric
% parameters and steady state Dynare needs. Calls parameterisation_real.m
% for the deep/calibrated parameters and solvesteadystate_real.m for the
% non-stochastic steady state, then writes both to PARAMS.mat and
% STEADYSTATE.mat, which MasterMod2c_Real.mod loads at parse time via its
% own "load PARAMS" / "load STEADYSTATE" commands.
%
% Called by: RUN_Figure.m (once per column/financial-market combination).
%
% Inputs:
%   options - struct with fields FinM ('CM'/'FA'/'BE'), Sim ('First'/
%             'Second'/'Simul'), Plot ('Impulse'/'Impact'), PlotShock
%             (the shock whose IRFs will later be plotted), and
%             params (a struct with exactly one field: the name and grid
%             of values of the parameter being varied across columns,
%             e.g. options.params.phiC).
% Outputs:
%   ssvals  - non-stochastic steady state of the model (see
%             solvesteadystate_real.m).
%   params  - full parameter struct, including the deep parameters from
%             parameterisation_real.m, the financial-market/simulation/
%             plot switches below, and the calibrated params.zl/zls,
%             params.omeg/omegs added by solvesteadystate_real.m.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define the switches based on defined options
% =========================================================================
% Translate the human-readable FinM/Sim/Plot choices into the integer
% flags used elsewhere (params.iFinM/iSim feed the -DFinM=/-DSim= macro
% flags passed to "dynare ..." in RUN_Figure.m; params.iPlot is for
% reference/consistency but not read by MasterMod2c_Real.mod itself).
if strcmp(options.FinM,'CM') == 1
    params.iFinM = 1;
elseif strcmp(options.FinM,'FA') == 1
    params.iFinM = 2;
elseif  strcmp(options.FinM,'BE') == 1
    params.iFinM = 3;
else
    disp('Please choose a valid fin. mkt. structure: CE, FA, BE');
end

if strcmp(options.Sim,'First') == 1
    params.iSim = 1;
elseif strcmp(options.Sim,'Second') == 1
    params.iSim = 2;
elseif strcmp(options.Sim,'Simul') == 1
    params.iSim = 0;
else
    disp('Please choose valid simulation option: Simul, First, Second');
end

if strcmp(options.Plot,'Impulse') == 1
    params.iPlot = 1;
elseif strcmp(options.Plot,'Impact') == 1
    params.iPlot = 0;
else
    disp('Please choose a valid plotting option: Impulse, Impact');
end

%% Define parameters
% =========================================================================
% Runs parameterisation_real.m as a script (not a function call), so the
% "params" struct it builds is added directly to this workspace.
parameterisation_real;

%% solve steady state with these parameters
% =========================================================================
[ssvals,params] = solvesteadystate_real(params);

%% Define the parameter that is being varied in experiments
% =========================================================================
% params.EXP names the single field of options.params (e.g. 'phiC'), and
% params.EXPVALS holds its grid of values. RUN_Figure.m's own column loop
% does not use these directly (it overrides phiC/rhoZH/rhoZH2 explicitly
% per column via set_param_value), but they are kept for consistency with
% the single-parameter-sweep pattern used elsewhere in this codebase.
params.EXP = fieldnames(options.params);
params.EXPVALS = eval(['options.params.' char(params.EXP)]);

%% Define the shock processes
% =========================================================================
% shocks_active_ records which of the two productivity shocks
% (options.PlotShock) will later be extracted and plotted by RUN_Figure.m.
% NOTE: params.sig_z/sig_zs below are NOT declared in MasterMod2c_Real.mod's
% "parameters" block, so they are not actually read by Dynare -- the .mod
% file's own shocks block always simulates both eps_ZH and eps_ZFs with
% unit standard deviation whenever Sim>0. PlotShock instead controls which
% shock's IRFs RUN_Figure.m reads out of oo_.irfs (e.g. YH_eps_ZH).
if options.PlotShock == 'eps_ZH'
    shocks_active_ = [1;0];
elseif options.PlotShock == 'eps_ZFs'
    shocks_active_ = [0;1];
else
    disp('Please choose valid shock option: eps_ZH, eps_ZFs');
end
params.sig_z     = shocks_active_(1)*0.01*((1-params.rhoZH^2))^.5;
params.sig_zs    = shocks_active_(2)*0.01*((1-params.rhoZFs^2))^.5;

% Save for MasterMod2c_Real.mod's "load PARAMS" / "load STEADYSTATE"
save PARAMS params
save STEADYSTATE ssvals

end
