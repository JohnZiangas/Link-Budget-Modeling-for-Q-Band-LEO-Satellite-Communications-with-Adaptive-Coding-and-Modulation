function [Co_UL_Table, Co_DL_Table] = CNO(SatTable_UL, SatTable_DL, syncWeatherData, fc_UL, fc_DL)
% CNOCalc.m
%
% DESCRIPTION:
%   This function calculates the carrier-to-noise power spectral density (C/No) 
%   for both uplink (UL) and downlink (DL) satellite communication links. 
%   The calculation includes:
%       - System noise temperatures (antenna + attenuator + receiver/transmitter).
%       - Free-space and excess path losses (FSPL + EPL).
%       - Antenna gains, feeder losses, and transmit powers.
%
%   The results are provided as time series for each satellite pass, enabling 
%   evaluation of link performance under varying atmospheric and geometric conditions.
%
% INPUTS:
%   finalSatTable   : Table containing satellite pass data, including:
%                       - Time       : Time series [datetime].
%                       - Elevation  : Satellite elevation angle [deg].
%                       - Rp         : Rain rate [mm/s].
%                       - EPL        : Excess path loss [dB].
%   syncWeatherData : Table containing synchronized ground weather measurements:
%                       - Surface Temperature [°C].
%                       - Surface Pressure [hPa].
%                       - Dew Point [°C].
%
% OUTPUTS:
%   Co_UL_Table : Cell array containing uplink C/No values [dB-Hz] for each pass.
%   Co_DL_Table : Cell array containing downlink C/No values [dB-Hz] for each pass.
%
% PROCESSING STEPS:
%   1. Calls systemThermalNoiseCalc to compute system noise temperatures (GS + SAT).
%   2. Calls channelLossesCalc to obtain total propagation losses (FSPL + EPL).
%   3. Computes EIRP for uplink and downlink from transmit power, feeder loss, and antenna gain.
%   4. Computes G/T (antenna gain-to-noise temperature ratio) for both GS and SAT.
%   5. Applies the C/No link budget equation for each timestep and stores results.
%
% NOTES:
%   - Boltzmann’s constant is expressed in logarithmic form: k = -228.6 dBW/K/Hz.
%   - Antenna gains and feeder losses are assumed constant; atmospheric variations 
%     are handled via EPL and noise temperature models.
%   - Output is per satellite pass (cell array structure).
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


    disp('   --- Running CNO.m ---')

    % --- STEP 1: Calculate total system noise temperatures for GS & SAT
    % Includes contributions from antenna noise, receiver/transmitter noise, and attenuators.
    [TsysRX_GS_Table_UL, TsysTX_GS_Table_UL, TsysRX_SAT_Table_UL, TsysTX_SAT_Table_UL] = systemThermalNoiseCalc(SatTable_UL, syncWeatherData, fc_UL);
    [TsysRX_GS_Table_DL, TsysTX_GS_Table_DL, TsysRX_SAT_Table_DL, TsysTX_SAT_Table_DL] = systemThermalNoiseCalc(SatTable_DL, syncWeatherData, fc_DL);
    disp(' ');
    disp('  [1/3] Calculating total channel losses for uplink...');

    % --- STEP 2: Calculate total channel losses (FSPL + EPL)
    [Ltotal_UL, d_kmUL] = channelLossesCalc(SatTable_UL, fc_UL);

    disp(' ');
    disp('        ✓ Uplink channel losses successfully calculated.');
    disp('  [2/3] Calculating total channel losses for downlink...');
    [Ltotal_DL, d_kmDL] = channelLossesCalc(SatTable_DL, fc_DL);
    disp(' ');
    disp('        ✓ Downlink channel losses successfully calculated.');

    % --- STEP 3: Calculate the C/No Carrier to Noise Power Spectral Density
    disp('  [3/3] Calculating carrier-to-noise power spectral density (C/No) for uplink...');

    % Ground Station Parameters
    G_TX_UL    = 41;   % Uplink transmit antenna gain [dBi]
    L_TX_UL    = 2;    % Uplink feeder/waveguide loss [dB]
    P_TX_UL    = 29;   % Uplink HPA transmit power [W]
    G_RX_GS    = 25;   % Downlink receive antenna gain [dBi]
    L_RX_GS    = 2;    % Downlink feeder loss [dB]

    % Satellite Parameters
    G_TX_DL    = 55;   % Downlink transmit antenna gain [dBi] (shaped beam)
    L_TX_DL    = 2;    % Downlink feeder/waveguide loss [dB]
    P_TX_DL    = 41;   % Downlink transmit power [W]
    G_RX_SAT   = 38;   % Uplink receive antenna gain [dBi]
    L_RX_SAT   = 2;    % Uplink feeder loss [dB]

    % Calculate C/No for uplink.
    Co_UL_Table = CNoCalc(TsysRX_SAT_Table_UL, Ltotal_UL, G_TX_UL, L_TX_UL, P_TX_UL, G_RX_SAT, L_RX_SAT);
    disp('        ✓ Uplink C/No successfully calculated.');

    % Calculate C/No for downlink.
    disp('  [3/3] Calculating carrier-to-noise power spectral density (C/No) for downlink...');
    Co_DL_Table = CNoCalc(TsysRX_GS_Table_DL, Ltotal_DL, G_TX_DL, L_TX_DL, P_TX_DL, G_RX_GS, L_RX_GS);
    disp('        ✓ Downlink C/No successfully calculated.');

    %%

    t = SatTable_UL.Time;

    CNO_ULColor = [0 0.4470 0.7410];      % blue
    CNO_DLColor = [0.4660 0.6740, 0.1880]; % green
    D_KMColor = [0.8500 0.3250 0.0980]; % red-orange

    % For specific picture.
    %i = 17;
    for i = 1:numel(SatTable_UL.Time)
        figure;
    
        yyaxis left;
        CNoUL = plot(timeofday(t{i}), Co_UL_Table{i}, '-', ...
        'LineWidth', 1.2, 'Color', CNO_ULColor, 'DisplayName','$C/N_{o}$ Uplink');
        hold on;
        CNoDL = plot(timeofday(t{i}), Co_DL_Table{i}, '-', ...
        'LineWidth', 1.2, 'Color', CNO_DLColor, 'DisplayName','$C/N_{o}$ Downlink');
    
        xlabel("Time [HH:mm:ss]", 'Interpreter','latex', 'FontSize', 18);
        ylabel("carrier-to-Noise Density Ratio $C/N_{o}$ [dB-Hz]", 'FontSize', 18);
    
        yyaxis right;
    
        plot(timeofday(t{i}), d_kmUL{i}, '--', ...
            'LineWidth', 1.2, 'Color', D_KMColor);
    
        %plot(y{i}, d_kmUL{i}, 'LineWidth', 1.5);
        ylabel("Slant Distance $d$ [km]", 'Interpreter','latex', 'FontSize', 18);
    
        % --- Shared axes formatting ---
        ax = gca;
        ax.FontName = 'Times New Roman';
        ax.FontSize = 10;
        ax.LineWidth = 0.8;
        ax.TickDir = 'out';
        ax.Box = 'on';
        ax.GridAlpha = 0.6;
        ax.GridLineWidth = 0.8;
        ax.MinorGridLineStyle = ':';
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        grid(ax, 'on');
    
        % ================= AXES / TITLE / GRID =================
        L = legend([CNoUL CNoDL]);
        set(L, 'Interpreter','latex', 'FontSize', 12, 'Location','best');
        
        set(gcf, 'Color','w');
        box on;
    end
    disp('  --- Finished CNO.m ---');
end