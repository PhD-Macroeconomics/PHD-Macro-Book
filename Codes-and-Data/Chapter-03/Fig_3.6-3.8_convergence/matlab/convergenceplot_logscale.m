clear;
close all;
set(groot, 'defaultTextFontSize', 10);
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');

level60;
growth6019;
label;

x = log(level60a);
y = growth6019a;
labels = cellstr(labela);

figure('Position', [100, 100, 1000, 800]);  % [left, bottom, width, height]

% Add text labels at each data point
for i = 1:length(x)
    text(x(i), y(i), labels{i}, ... 
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle');
end
hold on;

% Fit a linear trend (1st-degree polynomial)
p = polyfit(x, y, 1);
x_fit = linspace(min(x), max(x), 100);
y_fit = polyval(p, x_fit);
ylim([-0.05 0.07]);

ylabel('average annual growth rate: 1960-2019')
xlabel('log per capita GDP 1960 (in 2017 US$)')
set(gca, 'FontSize', 12);

% Plot the trend line
plot(x_fit, y_fit, 'r.', 'LineWidth', 2);
saveas(gcf, 'figures/convergence1.fig');
saveas(gcf, 'figures/convergence1.pdf');