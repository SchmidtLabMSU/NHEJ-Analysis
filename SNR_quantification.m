clear all; close all; clc;


%% Opening files
[filename, pathname] = uigetfile( ...
{  '*.jpg;*.jpeg;*.tif;*.png;*.gif;*.bmp','All Image Files';}, ...
   'Pick Halo image', ...
   'MultiSelect', 'off');

if isequal(filename, 0) %if no file is selected
    error('No files are loaded.');
end

img = im2double(imread([pathname filename])); %load image

[filename, pathname] = uigetfile( ...
{  '*.jpg;*.jpeg;*.tif;*.tiff;*.png;*.gif;*.bmp','All Image Files';}, ...
   'Pick nuclei mask', ...
   'MultiSelect', 'off');

if isequal(filename, 0) %if no file is selected
    error('No files are loaded.');
end

mask = im2double(imread([pathname filename])); %load image

%% Processing
img_cell = img.*mask;
img_cell = im2uint16(img_cell);

nBins = round(((max(img_cell(:)) - min(img_cell(img_cell>0))) /50));
h = histogram(img_cell(img_cell>0), nBins); % calculate histogram with n bins

counts = h.Values; % get values from histogram
counts = counts./max(counts);
edges = h.BinEdges; % get intensity values for histogram counts

% create variable x for intensity values of histogram counts
x = [];
for i = 1:length(edges)-1
    x = [x (edges(i+1)+edges(i))/2];
end

[maxCounts, maxCountsPosition] = max(counts); % get position of maximum counts

mygauss = @(x,xdata) x(1)*exp(-((xdata-x(2)).^2/(2*x(3).^2))); % Gauss function x(1) = amplitude (a), x(2) = mean (u), x(3) = standard deviation (sigma)

% initial guess of gauss function
amplitude = maxCounts;
meanValue = x(maxCountsPosition);
sigma = 50;
gaussCurve = mygauss([amplitude meanValue sigma], x);

% Optimization for gauss function fitting to histogram
sig = Inf; % initial criterial value
s = 50:1:500; % vector of possible sigma values for optimization
u = meanValue-100:1:meanValue+250;
a = amplitude-100:1:amplitude;
for i = 1:length(s)
    for j = 1:length(u)
        for k = 1:length(a)
            tempFun = mygauss([a(k) u(j) s(i)], x); % temporary gauss function
            distValue = sum((counts - tempFun).^2) / length(x); % what is the criterial distance
            if distValue < sig % if it is lower
               sig = distValue; % overwrite it
               opt_s = s(i); % and store this sigma value
               opt_u = u(j);
               opt_a = a(k);
            end
        end
    end
end

step = x(2)-x(1);
add_points = x(1);
for i = 1:20
    add_points = [add_points add_points(end)-step];
end
add_points = fliplr(add_points);
x_new = [add_points(1:end-1) x];

curveFit = mygauss([opt_a opt_u opt_s], x_new);

disp(['Mean value = ' num2str(opt_u)]);
disp(['Standard deviation = ' num2str(opt_s)]);
disp(['SNR = ' num2str(opt_u/opt_s)]);

%% Plot histogram
figure(1) % plotting the histogram
bar(x, counts, 1)
hold on
plot(x_new, curveFit, 'LineWidth', 3.5)
hold off
ylim([0 1.05]);
xlim([0 7000]);
xticks(0:1000:7000);
ylabel('Norm. counts');
xlabel('Fluorescence intensity (A.U.)');
set(gca, 'FontSize', 17, 'FontWeight', 'bold', 'YMinorTick', 'off', 'XMinorTick', 'off', 'box', 'on', LineWidth = 1.5);

