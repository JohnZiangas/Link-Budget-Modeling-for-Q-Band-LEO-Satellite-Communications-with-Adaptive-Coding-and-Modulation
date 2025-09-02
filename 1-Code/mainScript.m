%===============================================================================
% mainScript.m
%
% Description:
%
%   Main Simulation Script Overview
%   
%   This script is the main execution file for simulating a complete scenario 
%   involving link budget analysis and adaptive coding and modulation (ACM) 
%   for LEO SATCOM links. 
%
%   The workflow begins by time-synchronizing and generating 1-second synthetic 
%   data from the 10-minute meteorological measurements provided by the 
%   National Observatory of Athens. It then computes the carrier-to-noise 
%   density ratio (C/No), which is used to determine the appropriate coding 
%   and modulation scheme for an entire satellite pass.
%
%   The simulation is organized into the following modular scripts:
%
%   1) timeSyncWeatherData.m  
%      Imports raw meteorological data and interpolates them from 
%      10-minute intervals into 1-second synthetic data.
%
%   2) CNO.m  
%      Computes the carrier-to-noise density ratio (C/No) for both 
%      uplink and downlink.
%
%   3) ACM.m  
%      Determines and recommends the optimal coding and modulation 
%      scheme for the selected satellite pass.
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

clc;
clear;
close all;

% Display simulation start banner
disp('---------------------------------------------');
disp('Link-Budget Analysis for LEO SATCOM.');
disp(['Simulation started at: ', datestr(now)]);
disp('---------------------------------------------');
disp(' ');

% Datafolder containing the path to the file with the raw rainfall data.
dataFolder = '...\1-Data';  % <-- change if needed

% Load the UL EPL table.
load("SatTable_43GHz.mat", "finalSatTable");
SatTable_UL = finalSatTable;

% Load the DL EPL table.
load("1-Data\SatTable.mat", "finalSatTable");
SatTable_DL = finalSatTable;

fc_UL = 43e9; % Uplink frequency [Hz]
fc_DL = 42e9; % Downlink frequency [Hz]

%%

% Get the weather data from the weather stations

tic;
disp('Step 1 of 3: Importing the measurments from the weather station...');
[syncWeatherData] = timeSyncWeatherData(dataFolder, SatTable_UL);
disp(' ');
elapsedTime = toc;

fprintf('✓ Weather data succesfully created (%.2f seconds).', elapsedTime);
disp(' ');
disp(' ');

%%

% Calculates the external noise and internal noise of the ground station
% and satellite and then computes the carrier-to-noise power spectral density (C/No) 

tic;
disp('Step 2 of 3: Calculating the Uplink/Downlink C/No...');
[Co_UL_Table, Co_DL_Table] = CNO(SatTable_UL, SatTable_DL, syncWeatherData, fc_UL, fc_DL);
disp(' ');
elapsedTime = toc;

fprintf('✓ Uplink/Downlink C/No succefully calculated (%.2f seconds).', elapsedTime);
disp(' ');
disp(' ');

%%

% Based on the C/No we find the best modulation and coding to be used for
% the satellite pass.

tic;
disp('Step 3 of 3: Find the adaptive modulation...');
[M_sel_cells_UL, Rc_sel_cells_UL, Rb_info_cells_UL, margin_cells_UL, forced_cells_UL, ...
 M_sel_cells_DL, Rc_sel_cells_DL, Rb_info_cells_DL, margin_cells_DL, forced_cells_DL] = ACM(Co_DL_Table, Co_UL_Table);
disp(' ');
elapsedTime = toc;
fprintf('✓ All ACM calculations completed successfully (%.2f seconds).', elapsedTime);
disp(' ');


%%

% Final message

disp('---------------------------------------------');
disp('All results are ready for the LSTM model input.');
disp(['Simulation completed successfully at: ', datestr(now)]);
disp('---------------------------------------------');