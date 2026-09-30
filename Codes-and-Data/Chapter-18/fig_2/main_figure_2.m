close all
clear 
clc

warning('off','MATLAB:dispatcher:nameConflict')

addpath('_auxiliary_functions')

if ~exist('Results', 'dir'), mkdir('Results'); end

%% main estimation and model solution scripts
estimate;
BasicModel;
StickyWageStickyPriceModel;





%% plotting


load('Results/BasicModel.mat','Mod');
load('Results/StickyWageModel.mat','SWMod');
load('Results/RR_IRFs.mat','RR');


irfh=20;
shadecolor = repmat(0.85,1,3);


f = figure('Position',[240 539 800 240]);

% output figure
subplot(1,3,2);
hold on
box on




jbfill((0:irfh),...
     RR.IRF_ub(1:irfh+1,1)',RR.IRF_lb(1:irfh+1,1)',shadecolor,shadecolor,0,1);

p= plot(0:irfh,RR.IRF_med(1:irfh+1,1));
p.LineStyle = '-';
p.LineWidth = 2;
p.Color =  zeros(1,3); 
l1 = p;

p = plot(0:irfh,Mod.y(1:irfh+1));
p.LineStyle = '--';
p.LineWidth = 2;
p.Color = 0*ones(1,3);
l2 = p;

p = plot(0:irfh,SWMod.y(1:irfh+1));
p.LineStyle = ':';
p.LineWidth = 2;
p.Color = 0.3*ones(1,3);
l3 = p;

xl = [-0.50 irfh];
p = plot(xl,[0 0]);
p.LineStyle = '-';
p.LineWidth = 0.5;
p.Color = 0.7*ones(1,3);

xlim(xl);
% yl = ylim();
% ylim([yl(1) 0.2])
hold off
title('Output','interpreter','latex','FontSize',14)
ax = gca();
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 14;
ylabel('Percent','interpreter','latex','FontSize',14)
xlabel('Quarters','interpreter','latex','FontSize',14)

T = table((0:irfh)',RR.IRF_med(1:irfh+1,1),RR.IRF_ub(1:irfh+1,1),RR.IRF_lb(1:irfh+1,1),Mod.y(1:irfh+1),SWMod.y(1:irfh+1));
T.Properties.VariableNames = {'horiz','Empirical_med','Empirical_upper','Empirical_lower','Model','StickyWage'};
writetable(T,'Results/Fig2output.csv');

% Inflation Figure 
subplot(1,3,3);
hold on
box on


jbfill((0:irfh),...
     RR.IRF_ub(1:irfh+1,2)',RR.IRF_lb(1:irfh+1,2)',shadecolor,shadecolor,0,1);

p= plot(0:irfh,RR.IRF_med(1:irfh+1,2));
p.LineStyle = '-';
p.LineWidth = 2;
p.Color = zeros(1,3); 

p = plot(0:irfh,Mod.pi(1:irfh+1));
p.LineStyle = '--';
p.LineWidth = 2;
p.Color = 0*ones(1,3);


p = plot(0:irfh,SWMod.pi(1:irfh+1));
p.LineStyle = ':';
p.LineWidth = 2;
p.Color = 0.3*ones(1,3);



xl = [-0.50 irfh];
p = plot(xl,[0 0]);
p.LineStyle = '-';
p.LineWidth = 0.5;
p.Color = 0.7*ones(1,3);

xlim(xl);
% yl = ylim();
% ylim([yl(1) 0.2])
hold off
title('Inflation','interpreter','latex','FontSize',14)
ax = gca();
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 14;
ylabel('Percent','interpreter','latex','FontSize',14)
xlabel('Quarters','interpreter','latex','FontSize',14)


T = table((0:irfh)',RR.IRF_med(1:irfh+1,2),RR.IRF_ub(1:irfh+1,2),RR.IRF_lb(1:irfh+1,2),Mod.pi(1:irfh+1),SWMod.pi(1:irfh+1));
T.Properties.VariableNames = {'horiz','Empirical_med','Empirical_upper','Empirical_lower','Model','StickyWage'};
writetable(T,'Results/Fig2inflation.csv');



% Interest Rate Figure 
subplot(1,3,1);
hold on
box on


jbfill((0:irfh),...
     RR.IRF_ub(1:irfh+1,3)',RR.IRF_lb(1:irfh+1,3)',shadecolor,shadecolor,0,1);

p= plot(0:irfh,RR.IRF_med(1:irfh+1,3));
p.LineStyle = '-';
p.LineWidth = 2;
p.Color = zeros(1,3); 
l1 = p;

p = plot(0:irfh,Mod.i(1:irfh+1));
p.LineStyle = '--';
p.LineWidth = 2;
p.Color = 0*ones(1,3);
l2 = p;

p = plot(0:irfh,SWMod.i(1:irfh+1));
p.LineStyle = ':';
p.LineWidth = 2;
p.Color = 0.3*ones(1,3);
l3 = p;



xl = [-0.50 irfh];
p = plot(xl,[0 0]);
p.LineStyle = '-';
p.LineWidth = 0.5;
p.Color = 0.7*ones(1,3);

xlim(xl);
% yl = ylim();
% ylim([yl(1) 0.2])
hold off
title('Nominal Interest Rates','interpreter','latex','FontSize',14)
ax = gca();
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 14;
ylabel('Percent','interpreter','latex','FontSize',14)
xlabel('Quarters','interpreter','latex','FontSize',14)


% Legend
L = legend([l1,l2, l3],'Empirical estimate', 'Basic model', 'Sticky-wage model');
L.Interpreter = 'latex';
L.FontSize = 12;
L.Box = 'off';
L.Location = 'NorthEast';

