function [a_t, b_t, c_t, d_t] = Tmr_approximation(fc)
% Tmr_approximation returns the empirical coefficients a_t, b_t, c_t, d_t
% corresponding to a given frequency 'fc' based on precomputed simulation data.
%
% INPUT:
%   fc  - Chosen frequency in GHz
%
% OUTPUT:
%   a_t, b_t, c_t, d_t - Empirical coefficients for the given frequency
%
% DESCRIPTION:
%   The coefficients a_t(f), b_t(f), c_t(f), and d_t(f) are obtained from
%   radiative transfer simulations based on the “U.S. Standard Atmosphere,”
%   incorporating the contribution of water vapour above the tropopause.
%   The reference values for these coefficients are provided in
%   ITU-R Recommendation P.372-17.
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

    % -------------------------------------------------------------------------
    % Step 1: Load the precomputed data file
    % -------------------------------------------------------------------------
    % The MAT-file contains a matrix 'Tmr_approx' with:
    %   Column 1: Frequency in GHz
    %   Column 2: Coefficient a_t(f)
    %   Column 3: Coefficient b_t(f)
    %   Column 4: Coefficient c_t(f)
    %   Column 5: Coefficient d_t(f)
    % -------------------------------------------------------------------------
    load("Tmr_approx.mat", "Tmr_approx");
    
    % -------------------------------------------------------------------------
    % Step 2: Assign each column to a separate variable
    % -------------------------------------------------------------------------
    frequency = Tmr_approx(:, 1); % Frequency values in GHz
    a = Tmr_approx(:, 2);         % Coefficient a_t(f)
    b = Tmr_approx(:, 3);         % Coefficient b_t(f)
    c = Tmr_approx(:, 4);         % Coefficient c_t(f)
    d = Tmr_approx(:, 5);         % Coefficient d_t(f)
    
    % -------------------------------------------------------------------------
    % Step 3: Find the row corresponding to the chosen frequency
    % -------------------------------------------------------------------------
    chosenFreq = fc; % Frequency of interest in GHz
    
    % Since floating point numbers may not match exactly, use a tolerance
    tol = 1e-6;
    rowIdx = find(abs(frequency - chosenFreq) < tol, 1); % Finds the first match
    
    % -------------------------------------------------------------------------
    % Step 4: Extract the corresponding coefficients
    % -------------------------------------------------------------------------
    a_t = a(rowIdx);
    b_t = b(rowIdx);
    c_t = c(rowIdx);
    d_t = d(rowIdx);
    
    % -------------------------------------------------------------------------
    % Step 5: Display results or throw an error if frequency is not found
    % -------------------------------------------------------------------------
%     if ~isempty(rowIdx)
%         fprintf('\t\tFor frequency %.2f [GHz]:\n', chosenFreq);
%         fprintf('\t\t\ta_t(f) = %.6e\n\t\t\tb_t(f) = %.6e\n\t\t\tc_t(f) = %.6e\n\t\t\td_t(f) = %.6e\n', ...
%             a(rowIdx), b(rowIdx), c(rowIdx), d(rowIdx));
%     else
%         error('\t\tFrequency %.2f not found.', chosenFreq);
%     end
% end
