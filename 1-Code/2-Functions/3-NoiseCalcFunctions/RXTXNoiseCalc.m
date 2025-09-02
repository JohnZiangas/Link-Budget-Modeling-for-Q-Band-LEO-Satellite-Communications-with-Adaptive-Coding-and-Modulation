function [TeRX_GS, TeTX_GS, TeRX_SAT, TeTX_SAT] = RXTXNoiseCalc()
% SYSTEMNOISECALC
% Calculates the equivalent noise temperatures of the transmitter and
% receiver chains for both the ground station (GS) and satellite (SAT).
% Uses Friis' noise temperature formula with given component gains and noise
% temperatures.
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

    disp('          --- Running RXTXNoiseCalc.m ---')
    % Importing the data.
    disp('             [1/2] Loading the data...');
    
    % --- STEP 2: Define Constants for Ground Station and Satellite Systems
    % --- Ground Station ---
    % Transmitter chain noise temperatures [K] and gains [dB]
    T_MXTX_GS   = 2700;   % Noise temperature of transmitter mixer [K].
    T_PA_GS     = 1300;   % Noise temperature of power amplifier [K].
    T_DAC_GS    = 150;    % Noise temperature of DAC [K].
    G_MXTX_GS   = -6;     % Gain of mixer [dB].
    
    % Receiver noise temperatures [K] and gains [dB]
    T_LNA_GS    = 120;    % Noise temperature of LNA [K].
    T_MXRX_GS   = 2450;   % Noise temperature of receiver mixer [K].
    T_IF_GS     = 170;    % Noise temperature of IF stage [K].
    G_LNA_GS    = 20;     % Gain of LNA [dB].
    G_MXRX_GS   = -3;     % Gain of mixer [dB].
    
    % --- Satellite ---
    % Transmitter chain noise temperatures [K] and gains [dB]
    T_MXTX_SAT  = 3000;   % Noise temperature of transmitter mixer [K].
    T_PA_SAT    = 2600;   % Noise temperature of power amplifier [K].
    T_DAC_SAT   = 100;    % Noise temperature of DAC [K].
    G_MXTX_SAT  = 3;      % Gain of mixer [dB].
    
    % Receiver chain noise temperatures [K] and gains [dB]
    T_LNA_SAT   = 290;    % Noise temperature of LNA [K].
    T_MXRX_SAT  = 4000;   % Noise temperature of receiver mixer [K].
    T_IF_SAT    = 290;    % Noise temperature of IF stage [K].
    G_LNA_SAT   = 30;     % Gain of LNA [dB].
    G_MXRX_SAT  = 5;      % Gain of mixer [dB].
    
    % --- STEP 3: Convert Gains from dB to Linear Scale
    % Ground station
    G_MXTX_GS_LIN   = 10^(G_MXTX_GS/10);
    G_LNA_GS_LIN    = 10^(G_LNA_GS/10);
    G_MXRX_GS_LIN   = 10^(G_MXRX_GS/10);
    
    % Satellite
    G_MXTX_SAT_LIN  = 10^(G_MXTX_SAT/10);
    G_LNA_SAT_LIN   = 10^(G_LNA_SAT/10);
    G_MXRX_SAT_LIN  = 10^(G_MXRX_SAT/10);
    
    disp('                 ✓ Data successfully loaded.');
    disp('             [2/2] Caclulating the noise temperature of the receiver and transmitter...');

    % STEP 4: Calculate Equivalent Noise Temperatures
    % Friis formula is applied for noise temperature cascading:
    % Te_total = T1 + (T2 / G1) + (T3 / (G1 * G2)) + ...
    
    % --- Ground Station
    % Receiver side (LNA -> MIXER -> IF)
    TeRX_GS = T_LNA_GS + (T_MXRX_GS/G_LNA_GS_LIN) + ...
              (T_IF_GS/(G_LNA_GS_LIN * G_MXRX_GS_LIN)); % [K]
    
    % Trasnmitter side (DAC -> MIXER -> PA)
    TeTX_GS = T_DAC_GS + (T_MXTX_GS + (T_PA_GS / G_MXTX_GS_LIN)); % [K]
    
    % --- Satellite 
    % Receiver side (LNA -> MIXER -> IF)
    TeRX_SAT = T_LNA_SAT + (T_MXRX_SAT/G_LNA_SAT_LIN) + ...
               (T_IF_SAT/(G_LNA_SAT_LIN * G_MXRX_SAT_LIN)); % [K]
    
    % Trasnmitter side (DAC -> MIXER -> PA)
    TeTX_SAT = T_DAC_SAT + (T_MXTX_SAT + (T_PA_SAT / G_MXTX_SAT_LIN)); % [K]
    
    disp('                 ✓ Successfully calculated noise temperature.');
    disp('          --- Finished RXTXNoiseCalc.m ---');

end