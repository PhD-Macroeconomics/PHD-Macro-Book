close all
clear all
clc

dynare Commit.mod
dynare Discretion.mod

com = load('Commit/Output/Commit_results.mat');
dis = load('Discretion/Output/Discretion_results.mat');

f = figure('Position',[240 539 800 240]);



% Output Figure ------------
subplot(1,2,1);
hold on
box on


time = 0:19;
p = plot(time,com.oo_.irfs.y_eta);
p.LineStyle = '-';
p.LineWidth = 2;
p.Color = 0.5*ones(1,3);


p = plot(time,dis.oo_.irfs.y_eta);
p.LineStyle = '--';
p.LineWidth = 2;
p.Color = 0*ones(1,3);

outdata_left = [time; com.oo_.irfs.y_eta; dis.oo_.irfs.y_eta]';

xl = [-0.50 10];
p = plot(xl,[0 0]);
p.LineStyle = '-';
p.LineWidth = 0.5;
p.Color = 0.7*ones(1,3);

xlim(xl);
yl = ylim();
ylim([yl(1) 0.2])
hold off
title('Output','interpreter','latex','FontSize',14)
ax = gca();
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 14;
ylabel('Percent Deviation From Target','interpreter','latex','FontSize',14)
xlabel('Quarters','interpreter','latex','FontSize',14)


% Inflation Figure ------------
subplot(1,2,2);
hold on
box on

p = plot(time,com.oo_.irfs.pi_eta);
p.LineStyle = '-';
p.LineWidth = 2;
p.Color = 0.5*ones(1,3);


p = plot(time,dis.oo_.irfs.pi_eta);
p.LineStyle = '--';
p.LineWidth = 2;
p.Color = 0*ones(1,3);

outdata_right = [time; com.oo_.irfs.pi_eta; dis.oo_.irfs.pi_eta]';

xl = [-0.5 10];
p = plot(xl,[0 0]);
p.LineStyle = '-';
p.LineWidth = 0.5;
p.Color = 0.7*ones(1,3);

xlim(xl);
% ylim([-1 0.1])
hold off
title('Inflation','interpreter','latex','FontSize',14)
ax = gca();
ax.TickLabelInterpreter = 'latex';
ax.FontSize = 14;
ylabel('Percent Deviation From Target','Interpreter','latex','FontSize',14)
xlabel('Quarters','Interpreter','latex','FontSize',14)

L = legend('Commitment', 'Discretionary');
L.Interpreter = 'latex';
L.FontSize = 14;
L.Box = 'off';




%% loss functions
beta = 0.99;
lambda = 0.1;
discount = beta.^time;

loss_dis = sum(discount .* (dis.oo_.irfs.pi_eta.^2 + lambda * dis.oo_.irfs.y_eta.^2))
loss_com = sum(discount .* (com.oo_.irfs.pi_eta.^2 + lambda * com.oo_.irfs.y_eta.^2))
