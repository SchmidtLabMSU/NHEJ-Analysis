clear all
close all
clc

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
timeWindow = 3; %size of a time window for analysis
thresholdFactor = 0.9; %threshold adjustment, ideally (0.7 - 1.5)
movingAverage = 1; % 1 - do a moving average filtering. 0 - skip moving avering filtering.

%% Processing
time = data{:,1}; %time data
n = length(data{1,2:end}); %number of trials

%allocation
startPoint = NaN(1,n);
endPoint = NaN(1,n);
duration = NaN(1,n);
thresholdValue = zeros(1,n);

allDataPoints = data{:,2:end}; %pick all data points for all trial
avgDataPoints = mean(allDataPoints,2); %average value of fraction bound from all replicas
%avgDataPoints = allDataPoints;

for i = 1:n
    dataPoints = data{:, i+1}; %pick all data points for one trial

    % moving average filtering
    if movingAverage == 1
        b = (1/3) * ones(1,3);
        a = 1;
        dataPoints = filter(b, a, dataPoints);
    end

    thresholdValue(i) = (mean(avgDataPoints(1:timePointOfTreatment)) + (std(avgDataPoints(1:timePointOfTreatment)))) * thresholdFactor; %threshold as a mean value plus standard deviation from the average data points before the drug treatment.
    for j = timePointOfTreatment + 1:length(time) - (timeWindow - 1) %for every data point after the treatment (adjusted for the time window size)
        if isnan(startPoint(i))
            if median(dataPoints(j:j + (timeWindow - 1))) > thresholdValue(i) %if the median value of points within the time window is higher than threshold
                startPoint(i) = time(j-1); %store as a start position (the first index of the time window)
                %startPoint(i) = time(j);
            end
        elseif isnan(endPoint(i))
            if median(dataPoints(j:j + (timeWindow - 1))) < thresholdValue(i) %if the median value of points within the time window is lower than threshold
                %endPoint(i) = time(j + floor(timeWindow / 2)); %store as an end position (the middle index of the time window)
                endPoint(i) = time(j+1);
            end
        end
        if ~isnan(startPoint(i)) && ~isnan(endPoint(i)) %if start and end points exist
            duration(i) = endPoint(i) - startPoint(i); %calculate duration
        end
    end
end

%% Plotting
for i = 1:n
    h = figure(i);
    plot(time, data{:,i+1}, 'LineWidth', 3); hold on;
    plot([startPoint(i) startPoint(i)], [0 1], 'LineWidth', 2.5, 'Color', 'black'); hold on;
    plot([endPoint(i) endPoint(i)], [0 1], 'LineWidth', 2.5, 'Color', 'black'); hold on;
    plot([time(1) time(end)], [thresholdValue(i) thresholdValue(i)], '--', 'LineWidth', 2.5, 'Color', 'black'); hold off;
    title([filename(1:end-5), ': Trial ',num2str(i)]);
    xticks(0:10:160);
    yticks(0:10:100);
    xlim([0 100]);
    set(gcf,'Position',[100 100 675 400]);
    xlabel('Time [min]');
    ylabel('Fraction bound [%]');
    set(gca, 'FontSize', 17, 'FontWeight', 'bold', 'YMinorTick', 'off', 'XMinorTick', 'on', 'box', 'on', LineWidth = 2);
    set(h,'PaperPositionMode','Auto');
    disp('-----------------------------------------');
    disp([filename(1:end-5) ': Trial ' num2str(i)]);
    disp(['Start point: ' num2str(startPoint(i)) ' min']);
    disp(['End point: ' num2str(endPoint(i)) ' min']);
    disp(['Duration: ' num2str(duration(i)) ' min']);
end

disp('-----------------------------------------');
disp('Overall Statistics');
if ~isnan(startPoint)
    disp(['Start point: ' num2str(mean(startPoint)) ' ' char(177) ' ' num2str(std(startPoint)) ' min']);
else
    disp('Some of the start points were not detected.');
end
if ~isnan(endPoint)
    disp(['End point: ' num2str(mean(endPoint)) ' ' char(177) ' ' num2str(std(endPoint)) ' min']);
else
    disp('Some of the end points were not detected.');
end
if ~isnan(duration)
    disp(['Duration: ' num2str(mean(duration)) ' ' char(177) ' ' num2str(std(duration)) ' min']);
else
    disp('Some of the duration were not calculated.');
end