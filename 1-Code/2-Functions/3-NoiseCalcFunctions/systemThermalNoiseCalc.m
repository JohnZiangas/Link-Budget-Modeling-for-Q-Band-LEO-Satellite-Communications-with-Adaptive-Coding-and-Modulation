function [TsysRX_GS_Table, TsysTX_GS_Table, TsysRX_SAT_Table, TsysTX_SAT_Table] = systemThermalNoiseCalc(finalSatTable, syncWeatherData, fc)
% systemThermalNoiseCalc.m
%
% DESCRIPTION:
%   This function orchestrates the calculation of the overall system thermal 
%   noise temperatures for both the ground station and the satellite. It combines 
%   contributions from three main sources:
%      1. Antenna sky noise temperature (from atmosphere, rain, cosmic background).
%      2. Receiver and transmitter equipment noise temperatures.
%      3. Attenuator noise and insertion loss.
%
%   The output provides the total system noise temperatures for the ground station 
%   and satellite receivers and transmitters, expressed as time series for each 
%   satellite pass.
%
% INPUTS:
%   finalSatTable   : Table containing satellite pass information, including:
%                       - Time       : Time series [datetime].
%                       - Elevation  : Elevation angle [deg].
%                       - Rp         : Rain rate [mm/s].
%                       - EPL        : Excess path loss [dB].
%   syncWeatherData : Table containing synchronized surface weather measurements:
%                       - Surface Temperature [°C].
%                       - Surface Pressure [hPa].
%                       - Dew Point [°C].
%
% OUTPUTS:
%   TsysRX_GS_Table  : Cell array of ground station receiver system noise temperature [K].
%   TsysTX_GS_Table  : Cell array of ground station transmitter system noise temperature [K].
%   TsysRX_SAT_Table : Cell array of satellite receiver system noise temperature [K].
%   TsysTX_SAT_Table : Cell array of satellite transmitter system noise temperature [K].
%
% PROCESSING STEPS:
%   1. Calls skyNoiseCalc to compute antenna noise temperature (TA) for GS and SAT.
%   2. Calls RXTXNoiseCalc to retrieve equipment noise figures for RX/TX chains.
%   3. Calls attenuatorNoiseCalc to include attenuator contributions and compute 
%      final total system noise temperatures.
%
% NOTES:
%   - This function serves as the "top-level wrapper" that ties all the sub-models 
%     (antenna, equipment, attenuator) together into the full noise temperature 
%     calculation.
%   - Results are structured as cell arrays indexed per satellite pass.
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

    disp('       --- Running systemThermalNoiseCalc.m ---');
    disp(' ');
    % --- STEP 1: Calculate effective antenna noise temperatures (TA)
    % Includes atmospheric emission, rain, and cosmic background effects.
    [TA_GS_Table, TA_SAT_Table] = skyNoiseCalc(finalSatTable, syncWeatherData, fc);
    
    disp(' ');

    % --- STEP 2: Calculate RX/TX equipment noise contributions
    % Returns receiver and transmitter noise temperatures for GS and SAT chains.
    [TeRX_GS, TeTX_GS, TeRX_SAT, TeTX_SAT] = RXTXNoiseCalc();
    
    disp(' ');

    % --- STEP 3: Combine antenna, attenuator, and equipment noise
    % Uses Friis formula for attenuators to calculate the final system noise temperature.
    [TsysRX_GS_Table, TsysTX_GS_Table, TsysRX_SAT_Table, TsysTX_SAT_Table] = ...
        attenuatorNoiseCalc(TA_GS_Table, TA_SAT_Table, TeRX_GS, TeTX_GS, TeRX_SAT, TeTX_SAT);


%% 

    % y = finalSatTable.Time;
    % 
    % 
    % x_label = 'Time [HH:MM]';
    % y_label1 = 'Noise Temperature of the RX GS system [K]';
    % y_label2 = 'Noise Temperature of the RX SAT system [K]';
    % title = 'GS Vs. SAT';
    % 
    % for i = 1:19
    %     plot_xx_y_paper(timeofday(y{i}), TsysRX_GS_Table{i}, TsysRX_SAT_Table{i}, x_label, y_label1, y_label2, title);
    % end
    % 
    % x_label = 'Time [HH:MM]';
    % y_label1 = 'Noise Temperature of the TX GS system [K]';
    % y_label2 = 'Noise Temperature of the TX SAT system [K]';
    % title = 'GS Vs. SAT';
    % 
    % for i = 1:19
    %     plot_xx_y_paper(y{i}, TsysTX_GS_Table{i}, TsysTX_SAT_Table{i}, x_label, y_label1, y_label2, title);
    % end
    disp(' ');
    disp('          ✓ Successfully calculated the thermal noise temperature of the system.');
    disp('      --- Finished systemThermalNoiseCalc.m ---');
end