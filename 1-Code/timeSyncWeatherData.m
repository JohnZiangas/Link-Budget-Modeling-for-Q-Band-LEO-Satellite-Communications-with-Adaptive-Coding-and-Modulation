function [syncWeatherDataTable, time_1s, Ts_1s] = timeSyncWeatherData(dataFolder, finalSatTable)
%TIMESYNCWEATHERDATA  Synchronizes 1-second weather data with satellite pass times.
%
% This function:
%   1. Imports raw weather station data from the specified folder.
%   2. Extracts relevant meteorological measurements (10-min resolution).
%   3. Linearly interpolates the measurements to 1-second resolution.
%   4. Matches interpolated weather data with the exact timestamps of
%      satellite passes provided in finalSatTable.
%   5. Returns a table with synchronized weather data for each satellite pass.
%
% INPUTS:
%   dataFolder     : Path to folder containing raw weather measurement files.
%   finalSatTable  : Table containing satellite pass data.
%                    finalSatTable.Time must be a cell array of datetime vectors.
%
% OUTPUT:
%   syncWeatherDataTable : Table containing synchronized weather data
%                          (Surface Temperature, Surface Pressure, Humidity, Dew Point)
%                          for each satellite pass.
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

    disp('  --- Running timeSyncWeatherData.m ---')

    % --- STEP 1: IMPORT RAW WEATHER STATION DATA
    disp(' ');
    weatherDataTable = getWeatherMeasurments(dataFolder);
    
    % --- STEP 2: EXTRACT TIME SERIES AND MEASUREMENTS FROM THE RAW DATA
    % time10 : 10-minute timestamps (strings in 'HH:mm' format)
    % Ts     : Surface temperature (°C or K depending on data source)
    % Ps     : Surface pressure (hPa)
    % Hum    : Relative humidity (%)
    % Td     : Dew point temperature (°C)
    % Function which sorts the raw data and returns the needed measurments.
    [time10, Ts, Ps, Hum, Td] = getWeatherData(weatherDataTable);
    
    % --- STEP 3: INTERPOLATE TO 1-SECOND RESOLUTION
    disp('  [1/2] Interpolating 10-minute measurements into 1-second resolution...');

    % Preallocate cell arrays: one cell per 10-minute interval
    numInt  = numel(time10);             % typically 144 intervals for a full day
    Ts_1s   = cell(numInt,1);
    Ps_1s   = cell(numInt,1);
    Hum_1s  = cell(numInt,1);
    Td_1s   = cell(numInt,1);

    % For each 10-min interval, interpolate measurements linearly to 1-second steps
    for i = 1:numInt
        [Ts_1s{i}, Ps_1s{i}, Hum_1s{i}, Td_1s{i}] = interpMetLinear(time10, Ts, Ps, Hum, Td, i, 1, 'InputFormat','HH:mm');
    end

    disp('      ✓ Data successfully interpolated.');

    % --- STEP 4: MATCHING THE DATA WITH THE SATELLITE PASSES

    disp('  [2/2] Matching interpolated data with satellite pass times...');

    % Convert coarse 10-minute times to datetime objects (HH:mm:ss format)
    time10      = datetime(time10, 'InputFormat','HH:mm', 'Format','HH:mm:ss');
    nTimeBlocks = numel(time10);
    
    % Preallocate cell array to hold 600 seconds BEFORE each coarse time
    % (Offset excludes the exact coarse time; use 600:-1:0 to include it)
    time_1s = cell(nTimeBlocks,1);
    offsets = seconds(0:599);
    
    for i = 1:nTimeBlocks
        time_1s{i} = time10(i) + offsets(:); % 600×1 datetime vector per block
    end

    % Extract satellite pass time arrays
    timeArray = finalSatTable.Time; % cell array of datetime vectors
    nPasses = numel(timeArray);
    
    % Preallocate storage for matches
    syncWeatherData = cell(nPasses, 4);
    matching_Ts     = cell(nPasses, 1);
    matching_Ps     = cell(nPasses, 1);
    matching_Hum    = cell(nPasses, 1);
    matching_Td     = cell(nPasses, 1);
    

    % Match each 1-second weather block with satellite pass times
    for i = 1:numel(time_1s)
    
        % Extract current weather block's time vector & measurements
        timeBlock_dt    = time_1s{i};
        TsBlock_dt      = Ts_1s{i};
        PsBlock_dt      = Ps_1s{i};
        HumBlock_dt     = Hum_1s{i};
        TdBlock_dt      = Td_1s{i};
    

        % Convert block timestamps to time-of-day (to avoid timezone issues)
        timeBlock_tod = timeofday(timeBlock_dt);
    
        % Compare with each satellite pass
        for j = 1:nPasses
            pass_dt  = timeArray{j};              % datetime vector for this pass
            pass_tod = timeofday(pass_dt);        % time-of-day version
    
            % Find matching timestamps (exact seconds match)
            L = ismember(timeBlock_tod, pass_tod);
    
            if any(L)
                %fprintf("\t\tBlock %d | Pass %d → %d matching timestamps identified\n", ...
                 %       i, j, nnz(L));
    
                % Append matched measurements to this pass
                matching_Ts{j} = [matching_Ts{j}; TsBlock_dt(L)];
                matching_Ps{j} = [matching_Ps{j}; PsBlock_dt(L)];
                matching_Td{j} = [matching_Td{j}; TdBlock_dt(L)];
                matching_Hum{j} = [matching_Hum{j}; HumBlock_dt(L)];
            end

            % Store updated matches in syncWeatherData cell array
            syncWeatherData{j, 1} = matching_Ts{j};
            syncWeatherData{j, 2} = matching_Ps{j};
            syncWeatherData{j, 4} = matching_Td{j};
            syncWeatherData{j, 3} = matching_Hum{j};

        end
    end

    % Convert cell array to output table
    syncWeatherDataTable = cell2table(syncWeatherData, ...
                                      "VariableNames", {'Surface Tempature', ...
                                                        'Surface Pressure', ...
                                                        'Humidity', ...
                                                        'Dew Point'});
%%

figure;
hold on;

% --- Colors ---
TsColor = [0 0.4470 0.7410];      % blue
TdColor = [0.4660 0.6740, 0.1880]; % green
PsColor = [0.8500 0.3250 0.0980]; % red-orange

% Choose how many 10-min blocks to show
imax = min(143, numel(time10));   % safety

% ================= LEFT AXIS: Ts & Td =================
yyaxis left

% 1-sec lines (plot all segments; don't hide handles for the FIRST call)
% Then hide for the rest to keep legend clean
for k = 1:imax
    h1 = plot(timeofday(time_1s{k}), Ts_1s{k}, '-', ...
        'LineWidth', 1.2, 'Color', TsColor);
    h2 = plot(timeofday(time_1s{k}), Td_1s{k}, '-', ...
        'LineWidth', 1.2, 'Color', TdColor);
    if k == 1
        hTs1s_vis = h1;  % keep one visible handle
        hTd1s_vis = h2;
    else
        set([h1 h2], 'HandleVisibility','off');
    end
end

% 10-min markers (keep one visible handle; hide the rest)
hTs10 = plot(timeofday(time10(1:imax)), Ts(1:imax), 'o', ...
    'LineWidth', 1.2, 'MarkerSize', 6, 'Color', TsColor);
hTd10 = plot(timeofday(time10(1:imax)), Td(1:imax), 'x', ...
    'LineWidth', 1.2, 'MarkerSize', 6, 'Color', TdColor);

ylabel("Temperature [C]", 'Interpreter','latex', 'FontSize', 18);

% ================= RIGHT AXIS: Ps =================
yyaxis right

for k = 1:imax
    h3 = plot(timeofday(time_1s{k}), Ps_1s{k}, '-', ...
        'LineWidth', 1.2, 'Color', PsColor);
    if k == 1
        hPs1s_vis = h3;  % keep one visible handle
    else
        set(h3, 'HandleVisibility','off');
    end
end

hPs10 = plot(timeofday(time10(1:imax)), Ps(1:imax), 's', ...
    'LineWidth', 1.2, 'MarkerSize', 6, 'Color', PsColor);

ylabel("Surface Pressure $$P_{s}$$ [hPa]", 'Interpreter','latex', 'FontSize', 18);

% ================= MANUAL LEGEND (dummy handles for exact styling) =======
% Create dummy handles with the exact styles you want in the legend
yyaxis left
dTs1s = plot(nan, nan, '-', 'Color', TsColor, 'LineWidth', 1.2, 'DisplayName','Temperature $$T_{s}$$ (1-sec)');
dTs10 = plot(nan, nan, 'o', 'Color', TsColor, 'LineWidth', 1.2, 'MarkerSize', 6, 'DisplayName','Temperature $$T_{s}$$ (10-min)');
dTd1s = plot(nan, nan, '-', 'Color', TdColor, 'LineWidth', 1.2, 'DisplayName','Dew Point $$T_{d}$$ (1-sec)');
dTd10 = plot(nan, nan, 'x', 'Color', TdColor, 'LineWidth', 1.2, 'MarkerSize', 6, 'DisplayName','Dew Point $$T_{d}$$ (10-min)');

yyaxis right
dPs1s = plot(nan, nan, '-', 'Color', PsColor, 'LineWidth', 1.2, 'DisplayName','Surface Pressure $$P_{s}$$ (1-sec)');
dPs10 = plot(nan, nan, 's', 'Color', PsColor, 'LineWidth', 1.2, 'MarkerSize', 6, 'DisplayName','Surface Pressure $$P_{s}$$ (10-min)');

L = legend([dTs1s dTs10 dTd1s dTd10 dPs1s dPs10]);
set(L, 'Interpreter','latex', 'FontSize', 8, 'Location','best');

% ================= AXES / TITLE / GRID =================
xlabel("Time [HH:mm:ss]", 'Interpreter','latex', 'FontSize', 18);
title("Meteorological Parameters During Satellite Pass", 'Interpreter','latex', 'FontSize', 24);

grid on;
ax = gca;
ax.GridAlpha = 0.6;
ax.GridLineWidth = 0.8;
ax.MinorGridLineStyle = ':';
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.FontSize = 12;
ax.FontName = 'Times New Roman';
ax.TickLabelInterpreter = 'latex';


set(gcf, 'Color','w');
box on;

    disp('      ✓ Interpolated Data successfully time-synchronized.');
    disp('  --- Finished timeSyncWeatherData.m ---');

end
