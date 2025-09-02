function [M_sel_cells_UL, Rc_sel_cells_UL, Rb_info_cells_UL, margin_cells_UL, forced_cells_UL, ...
          M_sel_cells_DL, Rc_sel_cells_DL, Rb_info_cells_DL, margin_cells_DL, forced_cells_DL] = ...
            ACM(Co_DL_Table, Co_UL_Table)
%ACM.m  Wrapper function for Adaptive Coding and Modulation (ACM) calculation
% Runs ACM selection separately for the uplink (UL) and downlink (DL).
%
% Inputs:
%     Co_DL_Table : Cell array with downlink C/No time series data [dB-Hz]
%     Co_UL_Table : Cell array with uplink   C/No time series data [dB-Hz]
%
% Outputs:
%   M_sel_cells_UL   : Selected modulation orders for uplink (per pass)
%   Rc_sel_cells_UL  : Selected coding rates for uplink (per pass)
%   Rb_info_cells_UL : Achievable information bit rates [bps] for uplink
%   margin_cells_UL  : Link margin time series [dB] for uplink
%   forced_cells_UL  : Boolean flags where fallback/forcing occurred (UL)
%
%   M_sel_cells_DL   : Selected modulation orders for downlink (per pass)
%   Rc_sel_cells_DL  : Selected coding rates for downlink (per pass)
%   Rb_info_cells_DL : Achievable information bit rates [bps] for downlink
%   margin_cells_DL  : Link margin time series [dB] for downlink
%   forced_cells_DL  : Boolean flags where fallback/forcing occurred (DL)
%
% Notes:
%   - Uses square QAM constellations only (M_list).
%   - Employs hysteresis and dwell timers to avoid rapid switching.
%   - Margin thresholds (H_up_dB, H_down_dB) control switching behavior.
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

    disp('   --- Running ACM.m ---')
    disp('  [1/3] Setting up parameters...');
    % --- STEP 1: System Parameters
    B = 250e6;      % RF channel bandwidth [Hz]
    alpha = 0.9;    % roll-off factor
    
    % Modulation and Coding Schemes (MODCODs)
    M_list  = [4 16 64 256];   % Modulation orders (square QAM only)
    Rc_list = [1/2 3/4 9/10];  % Code rates
    
    % Adaptive Coding Modulation (ACM) configuration
    Delta_impl_dB = 1.2;  % Implementation loss relative to Shannon limit [dB]
    H_up_dB       = 0.5;  % Extra link margin needed before stepping UP [dB]
    H_down_dB     = 0.2;  % Margin shortfall before stepping DOWN [dB]
    min_dwell     = 3;    % Minimum dwell time [s] before allowing upward change
    
    disp('        ✓ Parameters successfully set up.');
    disp('  [2/3] Calculating and creating ACM for uplink...');
    % --- STEP 2: ACM calculations
    % Run ACM calculation for uplink
    [M_sel_cells_UL, Rc_sel_cells_UL, Rb_info_cells_UL, margin_cells_UL, forced_cells_UL] = ...
        ACMCalc(Co_UL_Table, B, alpha, M_list, Rc_list, Delta_impl_dB, H_up_dB, H_down_dB, min_dwell);
    disp('        ✓ Uplink ACM successfully created.');

    % Run ACM calculation for downlink
    disp('  [3/3] Calculating and creating ACM for downlink...');
    [M_sel_cells_DL, Rc_sel_cells_DL, Rb_info_cells_DL, margin_cells_DL, forced_cells_DL] = ...
        ACMCalc(Co_DL_Table, B, alpha, M_list, Rc_list, Delta_impl_dB, H_up_dB, H_down_dB, min_dwell);
    disp('        ✓ Downlink ACM successfully created.');
    disp('  --- Finished ACM.m ---');
end