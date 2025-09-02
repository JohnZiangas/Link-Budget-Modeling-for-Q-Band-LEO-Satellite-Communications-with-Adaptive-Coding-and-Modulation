function CNo_Table = CNoCalc(Tsys_Table, Ltotal, G_TX, L_TX, P_TX, G_RX, L_RX)
% CNoCalc.m
%
% Computes the carrier-to-noise density ratio (C/No) for LEO SATCOM links 
% over multiple satellite passes and time steps. The calculation follows 
% standard link budget principles using transmit power, antenna gains, 
% feeder losses, total path losses, and system noise temperature.
%
% INPUTS
%   Tsys_Table : {N_pass x 1} cell array 
%                Each cell contains a vector of system noise temperatures 
%                [K] for the corresponding pass at 1-second resolution.
%
%   Ltotal   : {N_pass x 1} cell array 
%                Each cell contains a vector of total link losses [dB] 
%                (free-space loss, atmospheric loss, rain attenuation, etc.).
%
%   G_TX       : Transmit antenna gain [dBi].
%   L_TX       : Transmit feeder loss [dB].
%   P_TX       : Transmit power [W].
%   G_RX       : Receive antenna gain [dBi].
%   L_RX       : Receive feeder loss [dB].
%
% OUTPUTS
%   CNo_Table  : {N_pass x 1} cell array 
%                Each cell contains a vector of computed carrier-to-noise 
%                density ratios [dB-Hz] for each timestep in the pass.
%
% NOTES
%   - Uses Boltzmann’s constant in dB units: k_dB = -228.6 dBW/K/Hz.
%   - EIRP is computed as transmit power + antenna gain – feeder losses.
%   - G/T is computed as receive gain – feeder losses – 10*log10(Tsys).
%   - C/No is computed as: C/No = EIRP – Ltotal + G/T – k.
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


    % Initialize output cell arrays
    CNo_Table = cell(numel(Ltotal), 1);
    
    % Constants
    k_dB = -228.6; % Boltzmans constant [dBW/K/Hz].
    PdBW_TX = 10*log10(P_TX); % Convert W → dBW   
    
    %  Loop over passes and timesteps
    for i = 1:numel(Ltotal)
        for j = 1:numel(Ltotal{i})
    
            % Uplink Calculation
            % EIRP = Tx power + Tx antenna gain - feeder losses
            EIRP_UL = PdBW_TX - L_TX + G_TX; % [dBW]

            % G/T for satellite receiver
            GT_ULSAT = G_RX - L_RX - (10*log10(Tsys_Table{i}(j))); % [dB/K]

            % C/No for uplink: C/No = EIRP - Loss + G/T - k
            Co_UL = EIRP_UL - Ltotal{i}(j) + GT_ULSAT - k_dB; % [dB-Hz]
    
            % Store results
            CNo_Table{i}   = [CNo_Table{i}; Co_UL];
        end
    end
end