%% ProjectWrapper
%% Resetter
% Clears workspace of variables and figures on start
beep off
clearvars
close ALL

%% Settings - Run on launch
% Constants are defined through a class for easy access
settings = Settings;

%% File loading
% This section does... 
sourceDir = "DataSets/";
sourceFiles = ["Stockholm Bromma smhi-opendata 20200404.csv", ...
               "Kiruna Flygplats smhi-opendata 20200404.csv", ...
               "Falsterbo smhi-opendata 20200404.csv"];

if (~exist(sourceDir, 'dir'))
    fprintf("DataSets dir not found!\n\n")
    return
end

Sets(1:length(sourceFiles)) = WeatherSet;
for k = 1 : length(Sets) % Iterate to load all chosen data sets
    Sets(1,k).FileName = sourceFiles(k);
    
    Sets(1,k).DataSet = readtable(sourceDir + sourceFiles(k));
    Sets(1,k).DataSet.Properties.VariableNames = {'Date', 'Time', 'Degrees', 'Quality'};
    Sets(1,k).DataSet.Date.Format = 'default';
    Sets(1,k).DataSet.Date = Sets(1,k).DataSet.Date + Sets(1,k).DataSet.Time;
    Sets(1,k).DataSet.Time = []; % Remove now unneeded time column
    
    Sets(1,k).DataSet = Sets(1,k).DataSet(Sets(1,k).DataSet.Date >= ...
        datetime(2005,01,01),:);
    
    Sets(1,k).Clean = timetable(Sets(1,k).DataSet.Date, ...
        Sets(1,k).DataSet.Degrees, Sets(1,k).DataSet.Quality);
    Sets(1,k).Clean.Properties.VariableNames = {'Degrees', 'Quality'};
    
    Sets(1,k).ShortName = extractBefore(Sets(1,k).FileName, ' smhi-');
end

clear sourceDir sourceFiles k; % Remove variables not to be used again
%% Data parsing
% Transform the data and calculate daily average temperatures

for k = 1 : length(Sets) % Iterate to parse all chosen data sets
    Sets(1,k).InSample = datetime(2006,01,01):datetime(2009,12,31);
    Sets(1,k).OutOfSample = datetime(2010,01,01):datetime(2019,12,31);
    Sets(1,k).InSample(month(Sets(1,k).InSample) == 2 & ...
        day(Sets(1,k).InSample) == 29) = []; % Clean leap days
    Sets(1,k).OutOfSample(month(Sets(1,k).OutOfSample) == 2 & ...
        day(Sets(1,k).OutOfSample) == 29) = []; % Clean leap days
    
    Sets(1,k).Clean = DailyAverage(Sets(1,k).Clean(:,1), settings.avgType);
    Sets(1,k).Clean(month(Sets(1,k).Clean.Time) == 2 & ...
        day(Sets(1,k).Clean.Time) == 29,:) = [];
end

% Check for nans
for k = 1 : length(Sets)
    n = sum(isnan(Sets(1,k).Clean.Degrees));
    if n ~= 0
        fprintf(2, sprintf('Set %s contains %d NaN values.\n', ...
            Sets(1,k).ShortName, n))
    end
end

clear k n
%% Deseasoning
% Remove the seasonal component of the temperature
seasonFunction = @(a, t) a(1) + a(2) * t + ...
    a(3) * sin(2 * pi / 365 * (t - a(4)));

X = zeros(4, length(Sets));
FVAL = zeros(1,length(Sets));
guess = [18, 0.0005, 5, 0];
for k = 1 : length(Sets) % Iterate to deseason all chosen data sets
    [X(:, k), FVAL(1,k)] = ...
        Deseason(transpose(Sets(1,k).Clean.Degrees(Sets(1,k).InSample)), ...
        seasonFunction, length(Sets(1,k).InSample), guess, ...
        settings.fminconOptions);
    % TODO: Add try/catch in Deseason
end

for k = 1 : length(Sets)
    Sets(1,k).Deseasoned = Sets(1,k).Clean(Sets(1,k).InSample,:);
    Sets(1,k).Deseasoned.Degrees = Sets(1,k).Deseasoned.Degrees - ...
        transpose(seasonFunction(X(:,k), 0:length(Sets(1,k).InSample)-1));
end

clear k guess
%% Generation of DAT and Deseasoned plots
% Allows for specific settings for the plots. 
% Used to generate figures for the written thesis report.
close ALL

% Settings for figures
showFigures = true;
saveFigures = true;
showSeason = true;
showTref = false;
showLinTrend = true;
setPeriod = "In"; % Alternatives: "In", "InOut"

status = zeros(1,length(Sets));
for k = 1 : length(Sets) % Iterate to generate DAT figures
    [status(k)] = GenerateDATPlot(Sets(1,k), seasonFunction, X(:,k), ...
        showFigures, saveFigures, showSeason, showTref, showLinTrend, ...
        setPeriod);
    %fprintf(sprintf('DAT plot status: %d.\n', status(1,k)))
end

for k = 1 : length(Sets) % Iterate to generate deseasoned figures
    [status(k)] = GenerateDeseasonedPlots(Sets(1,k), ...
        showFigures, saveFigures);
    %fprintf(sprintf('Deseasoned plot status: %d.\n', status(1,k)))
end

clear k showFigures saveFigures showSeason showTref showLinTrend ...
    setPeriod status
%%


Theta = []; % Initial parameter guess. Use last known optimum

for k = 1 : length(Sets)
    [Set_f(1,k), Theta_f(1,k)] = EM(Sets(1,k), Theta(k), 1000, true);
end


