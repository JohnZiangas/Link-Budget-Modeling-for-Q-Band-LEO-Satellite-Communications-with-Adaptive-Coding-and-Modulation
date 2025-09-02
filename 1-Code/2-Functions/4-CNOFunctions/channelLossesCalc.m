function [Ltotal, d_km] = channelLossesCalc(finalSatTable, fc)
% channelLossesCalc.m
%
% Computes the total channel losses for LEO SATCOM links by combining 
% free-space path loss (FSPL) with excess path loss (EPL) over multiple 
% satellite passes. Also converts slant range values from meters to 
% kilometers and generates diagnostic plots of elevation, distance, 
% and FSPL over time.
%
% INPUTS
%   finalSatTable : Structure or table with per-pass satellite data. 
%                   Must contain the following fields:
%                     - Range     : {N_pass x 1} cell array with slant 
%                                   distances [m] over time.
%                     - EPL       : {N_pass x 1} cell array with excess 
%                                   path loss values [dB].
%                     - Elevation : {N_pass x 1} cell array with elevation 
%                                   angles [deg].
%                     - Time      : {N_pass x 1} cell array with time stamps.
%
%   fc            : Carrier frequency [Hz].
%
% OUTPUTS
%   Ltotal        : {N_pass x 1} cell array 
%                   Each cell contains the total channel losses [dB] 
%                   per timestep (FSPL + EPL).
%
%   d_km        : {N_pass x 1} cell array 
%                   Each cell contains slant distances [km] per timestep.
%
% NOTES
%   - FSPL is computed as:
%       FSPL [dB] = 20*log10(d) + 20*log10(fc) – 147.55,
%     where d is slant distance in meters and fc is the carrier frequency in Hz.
%   - Ltotal is computed as:
%       Ltotal = FSPL + EPL.
%   - Includes plotting routines to visualize elevation vs. distance and 
%     FSPL vs. distance for selected passes.
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

    disp(' ');
    disp('       --- Running channelLossesCalc.m ---');
    disp('           [1/2] Loading the data...');

    % Initialize cell array which will compute the FSPL for each satellite
    % pass.
    FSPL    = cell(numel(finalSatTable.Range), 1);
    Ltotal  = cell(numel(finalSatTable.EPL), 1);
    
    d  = finalSatTable.Range; % Distance between the satellite and ground station in meters.
    
    d_km = cell(numel(d), 1);

    disp('                 ✓ Data successfully loaded.');
    disp('           [2/2] Calculating total channel losses (FSPL + EPL)...');

    % Computing the FSPL and total attenuation in dB.
    for i = 1:numel(finalSatTable.Range)
    
         % fprintf("\t\tPass %d\t →  ", i);
         % reverseStr = '';
    
        for j = 1:numel(d{i})
    
            % Delete last message so the command window won't get
            % clattered.
            % msg = sprintf('\t\tProcessed FSPL %d/%d', j, numel(d{i}));
            % fprintf([reverseStr, msg]);
            % reverseStr = repmat(sprintf('\b'), 1, length(msg));
            % 
            % dividing by 1000 to make meters to kms.
            d_km{i}(j) = d{i}(j)/1000;
    
            % Calculating Free Space Path Loss
            FSPL{i}(j) = 20*log10(d{i}(j)) + 20*log10(fc) - 147.55;
    
            % Calculating the total attenuation in the path.
            Ltotal{i}(j) = FSPL{i}(j) + finalSatTable.EPL{i}(j);
    
        end
    
        % fprintf("\n");
    end

    disp('                 ✓ Total channel losses successfully calculated.');
    %%
    
    % el = finalSatTable.Elevation;
    % y = finalSatTable.Time;
    % 
    % x_label = 'Time [HH:MM]';
    % y_label1 = 'Elevation Angle $(\theta)$ [deg]';
    % y_label2 = 'Slant Distance $d$ [km]';
    % title = 'Elevation vs. Distance over time';
    % 
    % for i = 1:19
    %     plot_xx_y_paper(y{i}, el{i}, d_km{i}, x_label, y_label1, y_label2, title);
    % end
    % 
    % x_label = 'Time [HH:MM]';
    % y_label1 = 'FSPL $(l)$ [dB]';
    % y_label2 = 'Slant Distance $d$ [km]';
    % title = 'FSPL vs. Distance over time';
    % 
    % for i = 1:19
    %     plot_xx_y_paper(y{i}, FSPL{i}, d_km{i}, x_label, y_label1, y_label2, title);
    % end
    disp('       --- Finished channelLossesCalc.m ---');

end


