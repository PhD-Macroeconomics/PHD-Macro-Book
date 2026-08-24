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
% This code: Sets the deep/calibrated parameters of the real (no-capital)
% two-country model into the "params" struct -- preferences, technology,
% shock persistence, and CES consumption-aggregator shares/elasticity.
% Run as a script (not a function) by model_definition_real.m, so that the
% "params" struct it builds is added directly to the caller's workspace.
%
% NOTE: phiC, rhoZH/rhoZFs and rhoZH2/rhoZFs2 set here are just defaults.
% RUN_Figure.m overrides all of them per column (via set_param_value,
% after Dynare has parsed the model) to produce the three trade-elasticity/
% persistence experiments shown in Figure 23.7. This script only affects
% the steady state (which does not depend on phiC or shock persistence)
% and the values used when MasterMod2c_Real.mod is first parsed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Deep parameters
% =========================================================================
params.betta   = 0.99;      % Home discount factor (quarterly)
params.bettas  = params.betta;  % Foreign discount factor (symmetric)
params.uz      = 0.01;      % Home Uzawa discount-factor elasticity (Bond Economy stationarity)
params.uzs     = params.uz; % Foreign Uzawa discount-factor elasticity (symmetric)
params.sig     = 2;         % Home coefficient of relative risk aversion (1/EIS)
params.sigs    = params.sig;% Foreign coefficient of relative risk aversion (symmetric)
params.rhoZH   = 1.7;       % Home productivity AR(1) coefficient (default; overridden by RUN_Figure.m per column)
params.rhoZFs  = params.rhoZH;  % Foreign productivity AR(1) coefficient (symmetric)
params.rhoZH2  = -0.703;    % Home productivity AR(2) coefficient (default; overridden by RUN_Figure.m per column)
params.rhoZFs2 = params.rhoZH2; % Foreign productivity AR(2) coefficient (symmetric)
params.ZHbar   = 1;         % Home steady-state productivity
params.ZFsbar  = 1;         % Foreign steady-state productivity

%% Additional deep parameters for production model
% =========================================================================
params.ps      = 1;         % Home inverse Frisch elasticity of labour supply
params.pss     = params.ps; % Foreign inverse Frisch elasticity of labour supply (symmetric)
params.xi      = 1;         % Home labour share in production
params.xis     = params.xi; % Foreign labour share in production (symmetric)

% We'll also calibrate zl(s) to match a SS time spent on labour of 1/3
% i.e. solver treats zl(s) as variable, and all L(s) replaced by
% params.L(s)bar. In Output, zl(s) still stored as params, and an
% ssvals.L(s) also defined based on params.L(s)bar
params.Lbar    = 1/3;   % Steady state labour supply target
params.Lsbar   = 1/3;   % Steady state labour supply target

%% CES parameters - these are effectively our steady state targets
% =========================================================================
params.phiC    = 3;         % Trade (Armington) elasticity (default; overridden by RUN_Figure.m per column)
params.aH      = 0.7;       % Home consumption weight on home tradables (home bias)
params.aF      = 1-params.aH;   % Home consumption weight on foreign tradables
params.aFs     = params.aH;     % Foreign consumption weight on foreign tradables (symmetric)
params.aHs     = 1-params.aFs;  % Foreign consumption weight on home tradables

params.Ces = 1;             % Flag: use CES (rather than Cobb-Douglas) consumption aggregator...
if params.phiC==1
    params.Ces = 0;         % ...unless phiC=1, i.e. the CES aggregator degenerates to Cobb-Douglas
end
