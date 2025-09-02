function [EbNo_UL_Table, EbNo_DL_Table] = EbNoCalc(Co_UL_Table, Co_DL_Table, Rb)
% EbNoCalc.m
%
%   Computes the energy-per-bit to noise density ratio (Eb/No) for both 
%   uplink and downlink across multiple satellite passes. The calculation 
%   converts the carrier-to-noise density ratio (C/No) into Eb/No by 
%   subtracting the bit rate term in dB.
%
% INPUTS
%   Co_UL_Table : {N_pass x 1} cell array
%                 Each cell contains a vector of uplink C/No values [dB-Hz] 
%                 for the corresponding pass at 1-second resolution.
%
%   Co_DL_Table : {N_pass x 1} cell array
%                 Each cell contains a vector of downlink C/No values [dB-Hz] 
%                 for the corresponding pass at 1-second resolution.
%
%   Rb          : Bit rate [bits/s].
%
% OUTPUTS
%   EbNo_UL_Table : {N_pass x 1} cell array
%                   Each cell contains a vector of uplink Eb/No values [dB].
%
%   EbNo_DL_Table : {N_pass x 1} cell array
%                   Each cell contains a vector of downlink Eb/No values [dB].
%
% NOTES
%   - Conversion uses: Eb/No [dB] = C/No [dB-Hz] – 10*log10(Rb).
%   - Supports multiple passes and time steps through cell array inputs.
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

    % Cell arrays for results
    EbNo_UL_Table = cell(numel(Co_UL_Table), 1);
    EbNo_DL_Table = cell(numel(Co_UL_Table), 1);
    
    % Precompute the bit rate term in dB
    Rb_dB = 10 * log10(Rb);

    for i = 1:numel(Co_UL_Table)

        EbNo_UL_Table{i} = Co_UL_Table{i} - Rb_dB; % [dB]
        EbNo_DL_Table{i} = Co_DL_Table{i} - Rb_dB; % [dB]
    end
end
