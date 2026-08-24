%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHAPTER 23: International Macroeconomics, PhD Macroeconomics
% ========================================================================
% Codes by Giancarlo Corsetti, Luca Dedola and Simon Lloyd
%
% Disclaimer: If you have any questions, suggestions or spot any bugs,
% please contact splloyd@gmail.com.
%
% This version: August 2026
% Tested with: MATLAB R2026a and Dynare 7.1
%
% This code: Builds Figure 23.7 in one pass. The figure has three columns,
% each a separate experiment run off MasterMod2c_Real.mod for the Complete
% Markets (CM), Financial Autarky (FA) and Bond Economy (BE) financial-
% market structures:
%   (a) phi = 1.5, home productivity AR(1) with rho = 0.97
%   (b) phi = 0.3, home productivity AR(1) with rho = 0.97
%   (c) phi = 3,   home productivity AR(2) with rho1 = 1.7, rho2 = -0.703
% This script loops over the three column definitions directly and
% assembles a single figure.
%
% Requirements: Dynare must be installed and on the MATLAB path (e.g. via
% addpath to its matlab/ subfolder) before running this script.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

% Run everything relative to this script's own folder, regardless of
% MATLAB's current working directory
% ---------------------------------------------------------------------
cd(fileparts(mfilename('fullpath')));

addpath('C:\dynare\7.1\matlab');

if isempty(which('dynare'))
    error(['Dynare was not found on the MATLAB path. Install Dynare and ' ...
        'add its matlab/ subfolder to the path (e.g. via addpath) before running this script.']);
end

% Define the mod file that contains the model codes
% -------------------------------------------------
modname = 'MasterMod2c_Real.mod';

% Define the name of the experiment that you wish to run
% ------------------------------------------------------
expname = 'Figure23-7';

    % Create directory for saving results...
    mkdir(expname);
    % ...and add it to the Matlab path, along with function folder
    addpath(genpath(['./' expname '/']));
    addpath(genpath('./functions/'));

%% DEFINE THE THREE COLUMNS OF FIGURE.PNG
% =========================================================================
Col(1).Title    = {'(a) Strong substitution effects','trade elasticity $\phi = 1.5$'};
Col(1).phiC     = 1.5;
Col(1).rhoZH    = 0.97;
Col(1).rhoZH2   = 0;

Col(2).Title    = {'(b) Strong wealth effects','trade elasticity $\phi = 0.3$'};
Col(2).phiC     = 0.3;
Col(2).rhoZH    = 0.97;
Col(2).rhoZH2   = 0;

Col(3).Title    = {'(c) Wealth effects with persistence','trade elasticity $\phi = 3$'};
Col(3).phiC     = 3;
Col(3).rhoZH    = 1.7;
Col(3).rhoZH2   = -0.703;

NC = length(Col);

% Financial market structures plotted in every column (in legend order)
% -----------------------------------------------------------------------
FinMkts = {'CM';'FA';'BE'};
NM      = length(FinMkts);

% Variables plotted down the rows of figure.png
% -----------------------------------------------------------------------
PlotVars      = {'YH';'YFs';'C';'TOT';'FLOW'};
PlotVarsLabel = {'Home Output';'Foreign Output';'Home Consumption';'Terms of Trade';{'Real NX (CM)','Current Account (BE)'}};
NV            = length(PlotVars);

PlotShock = 'eps_ZH';
PlotHor   = 41;

%% RUN ALL NINE MODELS (3 COLUMNS X 3 FINANCIAL-MARKET STRUCTURES)
% =========================================================================
for nc = 1:NC
    for nm = 1:NM
        finm = FinMkts{nm};
        disp('============================================================')
        disp(['Column ' num2str(nc) ' (' char(Col(nc).Title{1}) '), Financial Markets: ' finm])
        disp('============================================================')

        % Define the features of this model run
        % -------------------------------------------------------------
        model.options.FinM          = finm;
        model.options.Cap           = 'No';
        model.options.Sim           = 'First';
        model.options.PlotShock     = PlotShock;
        model.options.params.phiC   = Col(nc).phiC;
        model.options.PlotVars      = PlotVars;
        model.options.PlotVarsLabel = PlotVarsLabel;
        model.options.Plot          = 'Impulse';
        model.options.PlotHor       = PlotHor;

        % Define default parameters and an initial steady state
        [model.ss,model.params] = model_definition_real(model.options);

        % Parse the model
        disp('Parsing the model')
        modrun = ['dynare ' modname ' -DFinM=' num2str(model.params.iFinM) ' -DSim=' num2str(model.params.iSim) ' noclearall'];
        eval(modrun)

        % Impose this column's trade elasticity and productivity persistence
        % -------------------------------------------------------------
        params        = model.params;
        params.phiC   = Col(nc).phiC;    set_param_value('phiC',params.phiC);
        params.rhoZH  = Col(nc).rhoZH;   set_param_value('rhoZH',params.rhoZH);
        params.rhoZFs = Col(nc).rhoZH;   set_param_value('rhoZFs',params.rhoZFs);
        params.rhoZH2 = Col(nc).rhoZH2;  set_param_value('rhoZH2',params.rhoZH2);
        params.rhoZFs2= Col(nc).rhoZH2;  set_param_value('rhoZFs2',params.rhoZFs2);

        % Resolve the steady state (depends on phiC, not on persistence)
        ssvec = [];
        [ssvals, params] = solvesteadystate_real(params,model.ss);
        for ii = 1:M_.orig_endo_nbr
            var_n = deblank(M_.endo_names(ii,:));
            ssvec = [ssvec; eval(['ssvals.' var_n{1} ';'])];
        end
        oo_.steady_state = ssvec;

        % Simulate the model
        % NOTE: stoch_simul's 4-arg form returns the updated M_/options_/oo_
        % as outputs (they are not global inside this Dynare version), so
        % all four outputs must be captured -- otherwise oo_.irfs below
        % would silently still hold the .mod file's own default-parameter
        % IRFs from parse time, and every column would look identical.
        disp('Simulating the model with TFP Shock')
        [info,oo_,options_,M_] = stoch_simul(M_,options_,oo_,var_list_);

        % Extract and store the IRFs for this column/financial-market pair
        for nv = 1:NV
            Results(nc).(finm).([PlotVars{nv} '_irf']) = oo_.irfs.([PlotVars{nv} '_' PlotShock])(1:PlotHor)';
        end
        Results(nc).(finm).params = params;

    % End of loop over financial-market structures
    end
% End of loop over columns
end
disp('====Model Simulation Complete====');

%% MANUALLY CREATE CM FLOW
% =========================================================================
for nc = 1:NC
    p = Results(nc).CM.params;
    Results(nc).CM.FLOW_irf = (1-p.aH)*(p.sig^(-1))* ...
        ((2*p.aH*(p.sig*Col(nc).phiC-1)+1-p.sig)*Results(nc).CM.TOT_irf);
end

%% PLOT THE RESULTS
% =========================================================================
% Decide whether you wish to save the figure
% -------------------------------------------
saveFig = 1;

set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

xax = 0:1:PlotHor-1;

% Line styles matching figure.png: CM (black, solid), FA (grey, solid),
% BE (black, dashed)
colCM = [0 0 0];
colFA = [0.6 0.6 0.6];
colBE = [0 0 0];

% Force a white background regardless of MATLAB's Appearance theme
% (Preferences > Appearance > Theme), so the figure is always print-ready
% rather than following a "Dark" theme's default black background.
f = figure('units','normalized','position',[0.02 0.02 0.9 0.95],'Color','w');
tl = tiledlayout(f,NV,NC,'TileSpacing','compact','Padding','compact');

for nv = 1:NV
    for nc = 1:NC
        nexttile(tl,(nv-1)*NC+nc);
        h1 = plot(xax,Results(nc).CM.([PlotVars{nv} '_irf']),'-', 'Color',colCM,'LineWidth',2.5); hold on;
        h2 = plot(xax,Results(nc).FA.([PlotVars{nv} '_irf']),'-', 'Color',colFA,'LineWidth',2.5);
        h3 = plot(xax,Results(nc).BE.([PlotVars{nv} '_irf']),'--','Color',colBE,'LineWidth',2);
        plot(xax,zeros(size(xax)),'k','LineWidth',0.5);
        hold off; box off;
        set(gca,'FontSize',11,'Color','w','XColor','k','YColor','k');

        % Titles: column header on the top row, variable name every row
        if nv == 1
            title([Col(nc).Title, {PlotVarsLabel{nv}}],'Interpreter','latex','FontSize',14,'Color','k');
        else
            title(PlotVarsLabel{nv},'Interpreter','latex','FontSize',14,'Color','k');
        end

        % Y-axis labels only on the leftmost column
        if nc == 1
            if nv == NV
                ylabel('p.p. dev. from s.s.','Interpreter','latex','FontSize',12,'Color','k');
            else
                ylabel('\% dev. from s.s.','Interpreter','latex','FontSize',12,'Color','k');
            end
        end

        % X-axis label only on the bottom row
        if nv == NV
            xlabel('Quarters','Interpreter','latex','FontSize',12,'Color','k');
        end
    end
end

% Single shared legend below all panels
lgd = legend([h1 h2 h3],{'Complete markets','Financial autarky','Bond economy'});
lgd.Interpreter = 'latex';
lgd.Orientation = 'horizontal';
lgd.FontSize    = 14;
lgd.Layout.Tile = 'south';

if saveFig == 1
    saveas(f,['./' char(expname) '/Real_IRF_Figure.png'],'png');
    saveas(f,['./' char(expname) '/Real_IRF_Figure.eps'],'epsc');
end
