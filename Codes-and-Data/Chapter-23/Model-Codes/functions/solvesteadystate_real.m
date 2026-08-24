function [ssvals,params]    = solvesteadystate_real(params,ssinit)

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
% This code: Solves the non-stochastic, symmetric, zero-trade-imbalance
% steady state of the real (no-capital) two-country model for a given
% parameterisation (params), via fsolve on the 16-equation system defined
% in the nested function steadystate_no_k below. Also back out the two
% calibrated parameters (zl, zls, the labour-disutility scale factors, and
% omeg, omegs, the Uzawa discount-factor scale factors) that are pinned
% down jointly with the steady state.
%
% Called by: model_definition_real.m (to build the initial steady state
% used when Dynare first parses MasterMod2c_Real.mod), and directly by
% RUN_Figure.m (to re-solve the steady state after re-parameterising phiC
% for each column -- note the steady state does not depend on phiC itself,
% since terms of trade are unity in steady state, but is re-solved anyway
% for consistency/clarity).
%
% Inputs:
%   params  - struct of deep parameters (see parameterisation_real.m),
%             plus params.iFinM (1=CM, 2=FA, 3=BE) selecting which
%             equation pins down the steady state (see eq1 below).
%   ssinit  - (optional) a previous steady state (as returned by this same
%             function) used to build a better fsolve initial guess. Any
%             call omitting ssinit falls back to a generic guess.
%
% Outputs:
%   ssvals  - steady-state values of every variable declared in
%             MasterMod2c_Real.mod's "var" block, in the same (logged,
%             where the .mod file takes exp() of the variable) units the
%             .mod file expects.
%   params  - the input params struct, augmented with the calibrated
%             params.zl/zls and params.omeg/omegs.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SOLVE THE STEADY STATE OF THE MODEL GIVEN THE PARAMETERS IN PARAMS
% NOTE: THE PARAMETERS WILL BE UPDATED TOO TO MATCH STEADY STATE WISHES

%% Fixed Steady States
% =========================================================================
% Steady-state values that follow directly from the parameters, without
% needing the solver below.
% (2) Home Discount Factor
DF  = params.betta;
% (3) Foreign Discount Factor
DFs = params.bettas;
% (5) Home Euler for Home Bond
R   = 1/params.betta;
% (6) Foreign Euler for Foreign Bond
Rs  = 1/params.bettas;
% (29) Home Endowment (steady state of the productivity AR(2) process)
ZH  = params.ZHbar;
% (30) Foreign Endowment (steady state of the productivity AR(2) process)
ZFs = params.ZFsbar;
% (32) Home Current Account
CA  = 0;

% NOTE: we will set BH=0, even under asymmetry! may want to do differently
% (4) Home Bond Position
BH  = 0;

% Add to SSVALS structure, taking log where necessary to match MOD file
ssvals.DF  = DF;            ssvals.DFs  = DFs;
ssvals.R   = log(R);        ssvals.Rs   = log(Rs);
ssvals.ZH  = log(ZH);       ssvals.ZFs  = log(ZFs);
ssvals.lZH = log(ZH);       ssvals.lZFs = log(ZFs);
ssvals.BH  = BH;            ssvals.CA   = CA;
ssvals.TB  = 0;             ssvals.WGAP = 0;
ssvals.FLOW = 0;

%% Solve remaining model as a system
% =========================================================================
% The remaining 16 steady-state variables (consumption, tradables
% quantities/prices, terms of trade/RER, wages, output, and the labour-
% disutility scale factors zl/zls) are solved jointly via fsolve on the
% system defined in steadystate_no_k below.
% If model has no capital...
    if nargin == 2
        % Build the fsolve initial guess from a previous steady state
        % (ssinit), e.g. when re-solving after changing phiC in
        % RUN_Figure.m's column loop.
        x0 = [exp(ssinit.C),exp(ssinit.Cs),exp(ssinit.CHH),exp(ssinit.CHF),exp(ssinit.CFH),exp(ssinit.CFF),...
            exp(ssinit.RER),exp(ssinit.TOT),exp(ssinit.PH),exp(ssinit.PFs),exp(ssinit.YH),exp(ssinit.PFs),1,1,...
            exp(ssinit.W),exp(ssinit.Ws)];
    else
        % No previous steady state supplied: fall back to a generic guess.
        x0 = [0.25, 0.25, params.aH, params.aF, params.aHs, params.aFs, 1, 1, 1, 1, ...
            0.4, 0.4, 1, 1, 0.8, 0.8]';
    end

    % solve the thing
    XXX = fsolve(@(XXX) steadystate_no_k(XXX),x0);

    % Add to SSVALS structure, taking log where necessary to match MOD file
    ssvals.C    = log(XXX(1));    ssvals.Cs   = log(XXX(2));
    ssvals.CHH  = log(XXX(3));    ssvals.CHF  = log(XXX(4));
    ssvals.CFH  = log(XXX(5));    ssvals.CFF  = log(XXX(6));
    ssvals.RER  = log(XXX(7));    ssvals.TOT  = log(XXX(8));
    ssvals.PH   = log(XXX(9));    ssvals.PFs  = log(XXX(10));
    ssvals.YH   = log(XXX(11));   ssvals.YFs  = log(XXX(12));
    params.zl   = (XXX(13));      params.zls  = (XXX(14));
    ssvals.L    = log(params.Lbar); ssvals.Ls = log(params.Lsbar);
    ssvals.W    = log(XXX(15));   ssvals.Ws   = log(XXX(16));

    % (31) Relative Consumption
ssvals.RC = log(XXX(1)/XXX(2));

%% Update PARAMS with calibrated parameters
% =========================================================================
% Uzawa discount-factor scale factors, chosen so that DF/DFs (fixed above,
% at betta/bettas) are consistent with the steady-state consumption levels
% just solved for. Only actually used by the model equations under the
% Bond Economy (FinM=3), where DF = omeg*C^(-uz).

% (2) Home Uzawa Discount Factor
params.omeg     = (DF)/(XXX(1)^(-params.uz));
% (3) Foreign Uzawa Discount Factor
params.omegs    = (DFs)/(XXX(2)^(-params.uzs));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% System of equations for model with no capital
% Returns a 16x1 vector of residuals F(XXX), zero at the steady state.
% Equation numbers in parentheses cross-reference the corresponding
% numbered equations in the textbook chapter.
function F = steadystate_no_k(XXX)

    C   = XXX(1);     Cs  = XXX(2);
    CHH = XXX(3);     CHF = XXX(4);
    CFH = XXX(5);     CFF = XXX(6);
    RER = XXX(7);     TOT = XXX(8);
    PH  = XXX(9);     PFs = XXX(10);
    YH  = XXX(11);    YFs = XXX(12);
    zl  = XXX(13);    zls = XXX(14);
    W   = XXX(15);    Ws  = XXX(16);

    %% Common equations
    % eq1 is the one equation that differs by financial-market structure
    % (params.iFinM): it is the condition that pins down the steady-state
    % split of world consumption between Home and Foreign.
    if params.iFinM == 1
        % (1) Risk Sharing: Complete Markets
        eq1 = ((C)/(Cs))^(-params.sig)*(RER) - 1;
    end
    if params.iFinM == 2
        % (1) Trade Balance
        eq1 = TOT*(CHF) - CFH;
    end
    if params.iFinM == 3
        % (1) Home Budget Constraint
        eq1 = PH*YH - C;
    end
    % (14) Home Consumption Price Index
    eq2 = (C) - ( (PH)*(CHH) + (RER)*(PFs)*(CHF) );
    % (15) Foreign Consumption Price Index
    eq3 = (Cs) - ( (PH)*(CFH)/(RER) + (PFs)*(CFF) );

    % (16) Terms of Trade
    eq4 = (TOT) - ( (RER)*(PFs)/(PH) );
    % (27) Home Goods Market Equilibrium
    eq5 = YH - (CHH + CFH);
    % (28) Foreign Goods Market Equilibrium
    eq6 = YFs - (CHF + CFF);

    % (17) Home Intratemporal Labour Choice
    eq7 = (zl*(params.Lbar^(1/params.ps)) - (C^(-params.sig))*W);
    % (18) Foreign Intratemporal Labour Choice
    eq8 = (zls*(params.Lsbar^(1/params.pss)) - (Cs^(-params.sigs))*Ws);

    % (19) Home Tradables Production Function
    eq9 = YH - (params.ZHbar*(params.Lbar^(params.xi)));
    % (20) Home Labour Demand
    eq10 = W*params.Lbar - (params.xi*PH*YH);

    % (23) Foreign Tradables Production Function
    eq11 = YFs - (params.ZFsbar*(params.Lsbar^(params.xis)));
    % (24) Foreign Labour Demand
    eq12 = Ws*params.Lsbar - (params.xis*PFs*YFs);

    %% AGGREGATOR-SPECIFIC BLOCK
        %% CES AGGREGATOR
        % ====================================================================
        % General CES Form
        % (9) Home Aggregate Consumption
        eq13 = (C)  - ((params.aH^(1/params.phiC))*((CHH)^((params.phiC-1)/params.phiC)) + (params.aF^(1/params.phiC))*((CHF)^((params.phiC-1)/params.phiC)))^(params.phiC/(params.phiC-1));
        % (10) Foreign Aggregate Consumption
        eq14 = (Cs) - ((params.aHs^(1/params.phiC))*((CFH)^((params.phiC-1)/params.phiC)) + (params.aFs^(1/params.phiC))*((CFF)^((params.phiC-1)/params.phiC)))^(params.phiC/(params.phiC-1));

        % (11) Home Relative Consumption Demand
        eq15 = (CHH)/(CHF) - (params.aH/params.aF)*((1/(TOT))^(-params.phiC));
        % (12) Foreign Relative Consumption Demand
        eq16 = (CFH)/(CFF) - (params.aHs/params.aFs)*((1/(TOT))^(-params.phiC));

    %% Create system of eqns
    F = [eq1; eq2; eq3; eq4; eq5; eq6; eq7; eq8; eq9; eq10; eq11; eq12; ...
        eq13; eq14; eq15; eq16];
end
end
