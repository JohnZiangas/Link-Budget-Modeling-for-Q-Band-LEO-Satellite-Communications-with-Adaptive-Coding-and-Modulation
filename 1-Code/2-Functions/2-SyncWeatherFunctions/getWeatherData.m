function [time10, Ts, Ps, Hum, Td] = getWeatherData(weatherDataTable)
%GETWEATHERDATA   Interactively select a weather station and date, and
%                 extract relevant meteorological variables.
%
% Inputs:
%   weatherDataTable - Table containing weather station file names, sheet
%                      names, and nested tables with measurements by date.
%
% Outputs:
%   time10  - Time column (HH:mm format or datetime) for the selected date/station.
%   Ts      - Surface temperature (TempOut) for the selected date/station.
%   Ps      - Surface pressure (Bar) for the selected date/station.
%   Hum     - Relative humidity (OutHum) for the selected date/station.
%   Td      - Dew point temperature (DewPt) for the selected date/station.
%
% Author:
%   Ioannis Ziangas (Undergraduate Student)
%
% Supervisor: 
%   Panagiotis Zervas (Associate Professor)
%
% Affiliation:
%   University of the Peloponnese
%   Department of Electrical & Computer Engineering
%
% Course:
%   ECE_TEL851 – Information Theory (Academic Period 2025)
%
% GitHub Link of the Project:
%   https://github.com/JohnZiangas/Link-Budget-Modeling-for-Q-Band-LEO-Satellite-Communications-with-Adaptive-Coding-and-Modulation
%
% MIT License
% 
% Copyright (c) 2025 Ioannis Ziangas
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
% =============================================================================

    disp('    --- Running getWeatherData.m ---')
    disp('    [1/3] Importing basic station information from the input table...')

    % --- STEP 1: EXTRACT BASIC STATION INFO FROM THE INPUT TABLE
    fileName         = string(weatherDataTable.File);   % File names containing data
    weatherStations  = string(weatherDataTable.Sheet);  % Station names (sheet names)
    nWeatherStations = numel(weatherStations);          % Number of stations available
    
    disp('        ✓ Succesufully imported.')
    disp('    [2/3] Displaying available weather stations and corresponding data dates...');

    % --- STEP 2: DISPLAY THE AVAILABLE WEATHER STATION(S)

    % Character counter for later backspacing in console
    msg = 0;
    hdr = sprintf('\t\t\tAvailable Weather Stations:\n');
    fprintf('%s', hdr);
    msg = msg + strlength(hdr);
    
    for i = 1:nWeatherStations
        lineStr = sprintf('\t\t\t\t[%d] %s\t|\t%s\n', i, fileName(i), weatherStations(i));
        fprintf('%s', lineStr);
        msg     = msg + strlength(lineStr);
    end
    
    % --- STEP 3: PROMPT USER TO SELECT A WEATHER STATION

    % Prompt loop (counts prompt + user input + invalid lines)
    trigger = 0;
    while trigger ~= 1

        % Build the input prompt (e.g., "Enter weather station number (1 - 5): ")
        promptStr   = sprintf('\t\t\t\tEnter weather station number (%d - %d): ', 1, nWeatherStations);
        fprintf('%s', promptStr);
        msg         = msg + strlength(promptStr);
    
        % Read input as a string (so we can count characters typed)
        userStr = input('', 's');
        msg     = msg + strlength(userStr) + 1;
    
        % Convert to number and validate
        idxWeatherStation = str2double(userStr);
        if isempty(idxWeatherStation) || isnan(idxWeatherStation) || ...
           idxWeatherStation < 1 || idxWeatherStation > nWeatherStations
            errStr  = sprintf('\t\t\t\t\t[ERROR] Invalid weather station selection.\n');
            fprintf('%s', errStr);
            msg     = msg + strlength(errStr);
            trigger = 0; % Retry
        else
            trigger = 1; % Valid selection
        end
    end
    
    % Remove the printed prompt from the console (backspace characters)
    fprintf(repmat(sprintf('\b'), 1, msg));

    % Confirm selection    
fprintf("\t\t\tSelected weather station:\n\t\t\t\t%s | %s\n", ...
        fileName(idxWeatherStation), weatherStations(idxWeatherStation));
    
    % --- STEP 4: SELECT A DATE FROM THE CHOSEN WEATHER STATION
    nDates  = numel(weatherDataTable.DataByDate{idxWeatherStation, 1}.Date);    % Count available dates
    dates   = string(weatherDataTable.DataByDate{idxWeatherStation, 1}.Date);   % Date list
    msg     = 0; % Reset character counter
    
    fprintf('\t\t\tAvailable Dates:\n');
    msg = msg + strlength(sprintf('\t\t\tAvailable Dates:\n'));
    
    % Display all available dates
    for i = 1:nDates
        lineStr = sprintf('\t\t\t\t[%d] %s\n', i, dates(i));
        fprintf('%s', lineStr);
        msg     = msg + strlength(lineStr);
    end
    
    % Prompt user to select a date
    trigger = 0;
    while trigger ~= 1
        promptStr = sprintf('\t\t\t\tEnter date number (%d - %d): ', 1, nDates);
        fprintf('%s', promptStr);
        msg       = msg + strlength(promptStr);
    
        % Read raw string so we can count typed chars and the newline
        userStr = input('', 's');
        msg = msg + strlength(userStr) + 1;  % +1 for the Enter (newline)
    
        % Convert and validate
        idxDate = str2double(userStr);
        if isempty(idxDate) || isnan(idxDate) || idxDate < 1 || idxDate > nDates
            errStr = sprintf('\t\t\t\t\t[ERROR] Invalid date selection.\n');
            fprintf('%s', errStr);
            msg    = msg + strlength(errStr);
            trigger = 0; % Retry
        else
            trigger = 1; % Valid
        end
    end
    
    % Clear prompt and confirm selection
    fprintf(repmat(sprintf('\b'), 1, msg));
    fprintf("\t\t\tThe selected date is:\n\t\t\t\t%s\n", dates(idxDate));

    disp('        ✓ Weather station and date successfully selected.');
    disp('    [3/3] Extracting the required weather measurements for the selected station and date...');
    
    % --- STEP 5: EXTRACT VARIABLES FOR THE SELECTED STATION/DATE
    
    % Extract time column (HH:mm or datetime)
    time10 = weatherDataTable.DataByDate{idxWeatherStation, 1}.AllMeasurements{idxDate, 1}.Time;

    % Surface temperature (°C)
    Ts = weatherDataTable.DataByDate{idxWeatherStation, 1}.AllMeasurements{idxDate, 1}.TempOut;
    
    % Surface pressure (Bar)
    Ps = weatherDataTable.DataByDate{idxWeatherStation, 1}.AllMeasurements{idxDate, 1}.Bar;
    
    % Relative humidity (%)
    Hum = weatherDataTable.DataByDate{idxWeatherStation, 1}.AllMeasurements{idxDate, 1}.OutHum;

    % Dew point temperature (°C)
    Td = weatherDataTable.DataByDate{idxWeatherStation, 1}.AllMeasurements{idxDate, 1}.DewPt;

    disp('        ✓ Succesfully exported the data.');
    disp('    --- Finished getWeatherData.m ---');
    disp(' ');
end