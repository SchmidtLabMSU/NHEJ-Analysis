clear all; close all; clc;

%% Data loading
[filename, pathname] = uigetfile( ...
{'*.xls;*.xlsx'}, ...
   'Pick excel file');

if isequal(filename, 0) %if files are loaded
    error('No files are loaded.');
end

data = readtable([pathname filename]); %read data

%% Input variables
timePointOfTreatment = 20; %time point in minutes when the treatment was done
lastPoint = 80 - timePointOfTreatment;
titleFigure = 'Lig4-KO - dLig4'; %title of the figure

%% Plot
x = categorical(data{:,1}'); %drug concentration
x = reordercats(x,{'XRCC4', 'DNA-PKcs', 'Ku70'});
y(1,1:height(data)) = 0 - timePointOfTreatment; %first point
y(2,:) = data{:,2}' - timePointOfTreatment; %START
y(3,:) = data{:,4}' - y(2,:); %DURATION
y(4,:) = lastPoint - y(3,:) - y(2,:); %last point

%errors for plotting error bars
err = [];
err(1,:) = data{:,5}';
err(2,:) = data{:,6}';

hFig = figure(1); %make figure

%replace colormap
map = [0.5882 0.8157 0.8902;
    0.8235 0.9412 0.7255;
    0.8471 0.4588 0.6118;
    0.3961 0.4706 0.8392];
set(gca, 'ColorOrder', map, 'NextPlot','ReplaceChildren');

set(0, 'DefaultAxesFontName', 'Arial');
set(0, 'defaultTextFontName', 'Arial');
barh(x, y', 'stacked', 'EdgeColor', 'k', 'ShowBaseLine', 'off', LineWidth = 2, BarWidth = 0.8); %plot stacked horizontal bargraph
hold on
%plot error bars
for i = 1:height(data)
    errorbar(y(2,i), x(i), err(1,i), err(1,i), '.', 'horizontal', 'Color', 'k', 'LineWidth', 2);
    hold on
    errorbar(lastPoint - y(4,i), x(i), err(2,i), err(2,i), '.', 'horizontal', 'Color', 'k', 'LineWidth', 2);
    hold on
end
hold off
%adjusting the figure
set(gcf,'Position',[100 100 700 290]);
xticks(0-timePointOfTreatment:10:lastPoint);
title(titleFigure);
xlim([-25 65]);
xlabel('Time (min)', 'FontSize', 14, 'FontWeight', 'bold');
%ylabel('Calicheamicin (nM)', 'FontSize', 14,'FontWeight', 'bold');
set(gca, 'FontSize', 17, 'FontWeight', 'bold', 'YMinorTick', 'off', 'XMinorTick', 'on', 'box', 'on', LineWidth = 2);
legend('Before treatment', 'Delay', 'DNA repair', 'Recovered', 'FontSize', 13, 'FontWeight', 'bold',  'Location', 'north', 'Orientation', 'horizontal', 'Box', 'off');
figurepos = get(gcf,'Position');
savefig(hFig, [pathname, filename(1:end-5), '.fig']) %saving figure
saveas(hFig,[pathname, filename(1:end-5), '.svg']) %saving as svg