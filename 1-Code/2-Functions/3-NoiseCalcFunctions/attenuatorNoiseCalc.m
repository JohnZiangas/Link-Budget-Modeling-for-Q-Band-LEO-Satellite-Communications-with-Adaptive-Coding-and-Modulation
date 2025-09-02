function [TsysRX_GS_Table, TsysTX_GS_Table, TsysRX_SAT_Table, TsysTX_SAT_Table] = attenuatorNoiseCalc(TA_GS_Table, TA_SAT_Table, TeRX_GS, TeTX_GS, TeRX_SAT, TeTX_SAT)
% attenuatorNoiseCalc.m
%
% DESCRIPTION:
%   This function calculates the system noise temperatures for both the ground 
%   station and the satellite, taking into account the thermal noise contribution 
%   of an attenuator placed between the antenna and the receiver/transmitter chain. 
%   The attenuator degrades the signal-to-noise ratio (SNR) by introducing 
%   insertion loss and adding thermal noise. 
%
% INPUTS:
%   TA_GS_Table  : Cell array containing the effective antenna noise temperatures 
%                  [K] for the ground station, per satellite pass.
%   TA_SAT_Table : Cell array containing the effective antenna noise temperatures 
%                  [K] for the satellite, per satellite pass.
%   TeRX_GS      : Receiver noise temperature of the ground station [K].
%   TeTX_GS      : Transmitter noise temperature of the ground station [K].
%   TeRX_SAT     : Receiver noise temperature of the satellite [K].
%   TeTX_SAT     : Transmitter noise temperature of the satellite [K].
%
% OUTPUTS:
%   TsysRX_GS_Table  : Cell array of system noise temperatures [K] for the ground 
%                      station receiver during each pass.
%   TsysTX_GS_Table  : Cell array of system noise temperatures [K] for the ground 
%                      station transmitter during each pass.
%   TsysRX_SAT_Table : Cell array of system noise temperatures [K] for the satellite 
%                      receiver during each pass.
%   TsysTX_SAT_Table : Cell array of system noise temperatures [K] for the satellite 
%                      transmitter during each pass.
%
% PROCESSING STEPS:
%   1. Define attenuator noise temperature and attenuation (both GS and SAT).
%   2. Convert attenuation from dB to linear scale.
%   3. For each time sample of each pass:
%        - Compute the effective input noise temperature at the feed output 
%          using Friis’ formula for attenuators.
%        - Add receiver and transmitter equipment noise to form the total 
%          system noise temperature.
%   4. Store results in output tables.
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

    disp('          --- Running attenuatorNoiseCalc.m ---')
    % Importing the data.
    disp('             [1/2] Initializing ground station and satellite parameters...');

    % --- STEP 1: Initialize output cell arrays for each pass
    TsysRX_GS_Table = cell(numel(TA_GS_Table), 1);
    TsysTX_GS_Table = cell(numel(TA_GS_Table), 1);
    TsysRX_SAT_Table = cell(numel(TA_GS_Table), 1);
    TsysTX_SAT_Table = cell(numel(TA_GS_Table), 1);

    % --- STEP 2: Define Ground Station/Satellite Attenuator Parameters
    % Ground Station
    T_ATT_GS = 300; % Noise temperature of the attenuator [K].
    L_ATT_GS = 2;   % Amount of attenuation [dB].
    L_ATT_GS_LINEAR = 10^(L_ATT_GS/10); % Convert dB → linear scale
    
    % Satellite
    T_ATT_SAT = 300; % Noise temperature of the attenuator [K].
    L_ATT_SAT = 2;   % Amount of attenuation [dB].
    L_ATT_SAT_LINEAR = 10^(L_ATT_SAT/10); % Convert dB → linear scale

    disp('                 ✓ Parameters successfully initialized.');
    disp('             [2/2] Calculating attenuator noise temperature...');

    % --- STEP 3: Calculate the attenuator noise temperature
    % Loop over each satellite pass
    for i = 1:numel(TA_GS_Table)

        % Loop through each time step within the current pass
        for j = 1:numel(TA_SAT_Table{i})

            % Effective input noise temperature after GS attenuator:
            % Friis formula for attenuators:
            % Tin = (TA / L) + ((L - 1) * T_att / L)
            Tin_GS = (TA_GS_Table{i}(j)/L_ATT_GS_LINEAR) + (((L_ATT_GS_LINEAR - 1) * T_ATT_GS) / L_ATT_GS_LINEAR);
            
            % Effective input noise temperature after SAT attenuator
            Tin_SAT = (TA_SAT_Table{i}(j)/L_ATT_SAT_LINEAR) + (((L_ATT_SAT_LINEAR - 1) * T_ATT_SAT) / L_ATT_SAT_LINEAR);

            % Add equipment noise contributions to obtain system noise temperature
            TsysRX_GS   = Tin_GS + TeRX_GS;   % GS Receiver
            TsysTX_GS   = Tin_GS + TeTX_GS;   % GS Transmitter
            TsysRX_SAT  = Tin_SAT + TeRX_SAT; % SAT Receiver
            TsysTX_SAT  = Tin_SAT + TeTX_SAT; % SAT Transmitter
            
            % Append results to output tables
            TsysRX_GS_Table{i}   = [TsysRX_GS_Table{i}; TsysRX_GS];
            TsysTX_GS_Table{i}   = [TsysTX_GS_Table{i}; TsysTX_GS];
            TsysRX_SAT_Table{i}  = [TsysRX_SAT_Table{i}; TsysRX_SAT];
            TsysTX_SAT_Table{i}  = [TsysTX_SAT_Table{i}; TsysTX_SAT];
        end
    end

    disp('                 ✓ Attenuator noise temperature successfully calculated.');
    disp('          --- Finished attenuatorNoiseCalc.m ---');

end