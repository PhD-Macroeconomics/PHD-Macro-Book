///////////////////////////////////////////////////////////////////////////
// CHAPTER 23: International Macroeconomics, PhD Macroeconomics
// ========================================================================
// Codes by Giancarlo Corsetti, Luca Dedola and Simon Lloyd
//
// Disclaimer: If you have any questions, suggestions or spot any bugs,
// please contact splloyd@gmail.com.
//
// This version: August 2026
// Tested with: Dynare 7.1
//
// This code: Mod file for the real (no-capital) two-country tradable-goods
// model, with three alternative financial-market structures selectable at
// parse time via the -DFinM= macro flag: Complete Markets (FinM=1),
// Financial Autarky (FinM=2), and a stationarity-inducing Bond Economy
// with Uzawa preferences (FinM=3). The -DSim= macro flag selects between
// a deterministic simulation (Sim=0), first-order (Sim=1) or second-order
// (Sim=2) stochastic simulation. Equation numbers in comments below
// cross-reference the corresponding numbered equations in the textbook
// chapter; gaps in the numbering (e.g. no (7),(8),(13),(21),(22),(25),(26))
// correspond to equations that only appear in other model variants (e.g.
// with capital) and are not part of this file.
//
// Called by: RUN_Figure.m, via "dynare MasterMod2c_Real.mod -DFinM=...
// -DSim=... noclearall". Expects PARAMS.mat and STEADYSTATE.mat (written
// by functions/model_definition_real.m) to already exist in the working
// directory before being parsed.
//
///////////////////////////////////////////////////////////////////////////

////////// DEFINE SWITCHES (IF UNDEFINED) \\\\\\\\\\
@#ifndef FinM
    @#define FinM = 1
    disp('============================================================')
    disp('Picked COMPLETE MARKETS by default.')
    disp('============================================================')
    pause
@#endif

@#ifndef Sim 
    @#define Sim = 1
    disp('==========================================================================================================')
    disp('Picked FIRST-ORDER approximation by default.')
    disp('==========================================================================================================')
    pause
@#endif

////////// VARIABLES \\\\\\\\\\
var
    C, Cs,                      % Aggregate consumption
    CHH, CHF, CFH, CFF,         % Tradables good consumption
    PH, PFs,                    % Tradables good prices (relative to domestic aggregate)
    TOT, RER,                   % Terms of Trade & Real Exchange Rate
    L, Ls,                      % Labour
    W, Ws,                      % Real Wage
    YH, YFs,                    % Tradables Output
    DF, DFs,                    % Uzawa Discount Factor
    R, Rs,                      % Consumption-Based Risk-Free Interest Rates
    RC,                         % Relative consumption
    BH, CA,                     % Home Bond Position
    TB,                         % (Real) Trade Balance
    ZH, ZFs,                    % Tradables Productivity
    lZH, lZFs,                  % Lagged Tradables Productivity
    WGAP,                       % Wealth/Risk-Sharing Gap: (C/Cs)^sig / RER, = 1 under Complete Markets
    FLOW;                       % Cross-Border Flow (Notional CM; Actual FA/BE)

////////// EXOGENOUS SHOCKS \\\\\\\\\\
varexo
    eps_ZH, eps_ZFs;            % Productivity Shocks

////////// PARAMETERS \\\\\\\\\\
parameters
    betta, bettas,              % Discount factor
    omeg, omegs,                % Discount factor (for Uzawa)
    uz, uzs,                    % Uzawa Coefficient
    phiC,                       % Consumption Trade Elasticities
    aH, aF, aHs, aFs,           % Consumption Shares
    ps, pss,                    % Inverse Frisch Elasticity of Labour Supply
    zl, zls,                    % Constant on Labour
    sig, sigs,                  % Coefficient of Relative Risk Aversion
    xi, xis,                    % Labour Share
    rhoZH, rhoZFs,              % Productivity Persistence (1st Lag)
    rhoZH2, rhoZFs2,            % Productivity Persistence (2nd Lag)
    ZHbar, ZFsbar;              % Steady-state Productivity
    
// Set parameters
load PARAMS
for ii = 1:M_.param_nbr
    par_n = deblank(M_.param_names(ii,:));
    if isfield(params,par_n)
        set_param_value(par_n{1},eval(['params.' par_n{1}]));
    else
        disp(['Unassigned parameter: ' par_n])
    end
end

////////// MODEL \\\\\\\\\\
model;
///////////////////////////////////////////////////////////////////////////
//// FINANCIAL MARKET BLOCK
@#if FinM == 1
    //// COMPLETE MARKETS
    // (1) Risk Sharing: Complete Markets
    1   = (exp(C)/exp(Cs))^(-sig)*exp(RER);
    // (2) Home Discount Factor
    DF  = betta;
    // (3) Foreign Discount Factor
    DFs = bettas;
    // (4) Home Bond Position
    BH  = 0;                                 
@#else
@#if FinM == 2
    //// FINANCIAL AUTARKY
    // (1) Trade Balance
    0   = exp(TOT)*(exp(CHF)) - exp(CFH);
    // (2) Home Discount Factor
    DF  = betta;
    // (3) Foreign Discount Factor
    DFs = bettas;
    // (4) Home Bond Position
    BH  = 0;
@#else
@#if FinM == 3
    //// BOND ECONOMY (with Uzawa)
    // (1) Risk Sharing: Home Euler for Foreign Risk-Free Rate
    1   = DF*((exp(C(+1))/exp(C))^(-sig))*(exp(RER(+1))/exp(RER))*exp(Rs);
    // (2) Home Uzawa Discount Factor
    (DF)     = omeg*(exp(C))^(-uz);
    // (3) Foreign Uzawa Discount Factor
    (DFs)    = omegs*(exp(Cs))^(-uzs);
    // (4) Home Budget Constraint: Pins Down Home Bond Position
    exp(W)*exp(L) + exp(R(-1))*BH(-1) = exp(C) + BH;
@#endif
@#endif
@#endif
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//// EULER EQUATIONS
// RISK-FREE INTEREST RATE
// (5) Home Euler for Home Consumption-Based Real Interest Rate
1   = DF*((exp(C(+1))/exp(C))^(-sig))*exp(R);
// (6) Foreign Euler for Foreign Consumption-Based Real Interest Rate
1   = DFs*((exp(Cs(+1))/exp(Cs))^(-sigs))*exp(Rs);
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//// AGGREGATOR-SPECIFIC BLOCK
    //// CES AGGREGATOR
    // ====================================================================
    /// CONSUMPTION
    // (9) Home Aggregate Consumption
    exp(C)   = ((aH^(1/phiC))*(exp(CHH)^((phiC-1)/phiC)) + (aF^(1/phiC))*(exp(CHF)^((phiC-1)/phiC)))^(phiC/(phiC-1));
    // (10) Foreign Aggregate Consumption
    exp(Cs)  = ((aHs^(1/phiC))*(exp(CFH)^((phiC-1)/phiC)) + (aFs^(1/phiC))*(exp(CFF)^((phiC-1)/phiC)))^(phiC/(phiC-1));

    // (11) Home Relative Consumption Demand
    exp(CHH)/exp(CHF) = (aH/aF)*((1/exp(TOT))^(-phiC));
    // (12) Foreign Relative Consumption Demand
    exp(CFH)/exp(CFF) = (aHs/aFs)*((1/exp(TOT))^(-phiC));
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//// GENERAL PRICING EQUATIONS
// (14) Home Consumption Price Index
exp(C)  = exp(PH)*exp(CHH) + exp(RER)*exp(PFs)*exp(CHF);
// (15) Foreign Consumption Price Index
exp(Cs) = exp(PH)*exp(CFH)/exp(RER) + exp(PFs)*exp(CFF);

// (16) Terms of Trade
exp(TOT) = exp(RER)*exp(PFs)/exp(PH);
///////////////////////////////////////////////////////////////////////////

//===INTERTEMPORAL CONSUMER PROBLEM===\\
// (17) Home Intratemporal Labour Choice
zl*(exp(L)^(1/ps))       = (exp(C)^(-sig))*exp(W);
// (18) Foreign Intratemporal Labour Choice
zls*(exp(Ls)^(1/pss))    = (exp(Cs)^(-sigs))*exp(Ws);

//===FIRM PROBLEM===\\\
// (19) Home Tradables Production Function
exp(YH)     = exp(ZH)*(exp(L)^(xi));
// (20) Home Labour Demand
exp(W)*exp(L)           = xi*exp(PH)*exp(YH);
// (23) Foreign Tradables Production Function
exp(YFs)    = exp(ZFs)*(exp(Ls)^(xis));
// (24) Foreign Labour Demand
exp(Ws)*exp(Ls)         = xis*exp(PFs)*exp(YFs);

//===EQUILIBRIUM===\\
// (27) Home Tradables
exp(YH)     = exp(CHH) + exp(CFH);
// (28) Foreign Tradables
exp(YFs)    = exp(CHF) + exp(CFF);

//===SHOCK PROCESSES===\\
// (29) Home Tradables Productivity
exp(ZH)  = (1-rhoZH-rhoZH2)*ZHbar + rhoZH*exp(ZH(-1)) + rhoZH2*exp(lZH(-1)) + eps_ZH;
exp(lZH) = exp(ZH(-1));
// (30) Foreign Tradables Productivity
exp(ZFs) = (1-rhoZFs-rhoZFs2)*ZFsbar + rhoZFs*exp(ZFs(-1)) + rhoZFs2*exp(lZFs(-1)) + eps_ZFs;
exp(lZFs) = exp(ZFs(-1));

// (31) Relative Consumption
exp(RC) = exp(C)/exp(Cs);
// (32) Current Account
CA      = BH - BH(-1);

// (33) Real Trade Balance
// Both terms are expressed in Home consumption units
TB      = exp(PH)*exp(CFH) - exp(RER)*exp(PFs)*exp(CHF); // X-M

// (34) Wealth Gap
exp(WGAP) = (exp(C)/exp(Cs))^(sig)*(1/exp(RER));

// (35) Notional or Actual InFlows
@#if FinM == 1 
    // Complete Markets
    FLOW = TB; 
@#else
    // Financial Autarky or Bond Economy
    FLOW = CA;
@#endif
    
end;

////////// SHOCKS \\\\\\\\\\
shocks;
    @#if Sim==0
        var eps_ZH;
        periods 1:1;
        values 0.1;
    @#endif
    @#if Sim>0
        var eps_ZH;     stderr 1;
        var eps_ZFs;    stderr 1;    
    @#endif
end;

////////// STEADY STATE \\\\\\\\\\
load STEADYSTATE
ssvec = [];
for ii = 1:M_.orig_endo_nbr
    var_n = deblank(M_.endo_names(ii,:));
    ssvec = [ssvec; eval(['ssvals.' var_n{1} ';'])];
end
oo_.steady_state = ssvec;

////////// MODEL SOLUTION \\\\\\\\\\
@#if Sim==0
    simul(periods=2001);
@#endif
@#if Sim==1
    stoch_simul(order=1,irf=200,noprint,nograph);
@#endif
@#if Sim==2
    stoch_simul(order=2,irf=1001,noprint,nograph,pruning);
@#endif