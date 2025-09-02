function [TA_GS_Table, TA_SAT_Table] = skyNoiseCalc(finalSatTable, syncWeatherData, fc)
% skyNoiseCalc.m
%
% DESCRIPTION:
%   This function estimates the effective antenna noise temperatures for both 
%   the ground station (TA_GS) and the satellite (TA_SAT) during LEO satellite 
%   passes in the Q/V-band (~42 GHz). The calculation incorporates atmospheric 
%   attenuation, rain rate, surface meteorological data, and antenna parameters 
%   to model the impact of sky noise on the communication link.
%
% INPUTS:
%   finalSatTable   : A table containing satellite pass data:
%                       - Time       : Time series for each pass [datetime].
%                       - Elevation  : Satellite elevation angles [deg].
%                       - Rp         : Rain rate per second [mm/s].
%                       - EPL        : Excess path loss (rain + gaseous) [dB].
%
%   syncWeatherData : A table containing synchronized ground weather measurements:
%                       - Surface Temperature [°C].
%                       - Surface Pressure [hPa].
%                       - Dew Point [°C].
%
% OUTPUTS:
%   TA_GS_Table     : Cell array containing the effective ground station antenna
%                     noise temperature [K] for each pass.
%
%   TA_SAT_Table    : Cell array containing the effective satellite antenna noise
%                     temperature [K] for each pass.
%
% PROCESSING STEPS:
%   1. Extracts satellite geometry (time, elevation) and weather data (surface T, P, dew point).
%   2. Calculates the mean radiating temperature (Tmr) using rain/no-rain conditions 
%      and ITU-based approximation models.
%   3. Computes the atmospheric brightness temperature (TB) considering rain, gaseous absorption, 
%      and cosmic background radiation.
%   4. Estimates satellite-view brightness temperature including surface emissivity, 
%      reflection, and time-of-day adjustments.
%   5. Applies hemispheric integration to account for antenna side-lobe spillover.
%   6. Combines main-beam efficiency with spillover contributions to derive the 
%      effective noise temperatures for both the ground station and the satellite.
%
% NOTES:
%   - Emissivity is bounded between [0.85–0.995] to ensure realistic physical limits.
%   - Sunrise/sunset times are set for Athens, Greece (local timezone), with simple 
%     ±2 K adjustments for daytime heating effects.
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

    disp('          --- Running skyNoiseCalc.m ---')
    
    % Importing the data.
    disp('             [1/2] Loading the data...');
    
    % --- STEP 1: Extract Relevant Satellite Pass Information.
    time    = finalSatTable.Time;       % Time series for each satellite pass [HH:MM:SS].
    theta   = finalSatTable.Elevation;  % Satellite Elevation angle [deg].
    R       = finalSatTable.Rp;         % Rain Rate per second [mm/sec].
    EPL     = finalSatTable.EPL;        % Total atmospheric attenuation [dB] (Rain + Gases).
    
    % --- STEP 2: Extract Relevant Weather Station Measurments
    Ts  = syncWeatherData.("Surface Tempature");  % Surface Temperature [C].
    Ps  = syncWeatherData.("Surface Pressure");   % Surface pressure [hPa].
    Td  = syncWeatherData.("Dew Point");          % Dew point [C].
    % Hum = syncWeatherData.Humidity;               % Relative Humidity [%].
    
    % --- STEP 4: Constants
    fc      = fc/1e9;   % Carrier frequency [GHz]
    e_min   = 0.85;     % Minimum emissivity (conservative lower bound for land)
    e_max   = 0.995;    % Maximum emissivity (avoid 1.0 to prevent numerical issues)
    e_base  = 0.97;     % Baseline emissivity by surface & polarization (Q/V band ~42 GHz)
    
    disp('                 ✓ Data successfully loaded.');
    disp('             [2/2] Caclulating the Ground station/Satellite Brightness Temperature (TB)...');
    % --- STEP 5: Calculate Satellite and Ground Station Brightness Temperature (TB)
    % Approximation model coefficients
    [a_t, b_t, c_t, d_t] = Tmr_approximation(fc); 
    
    % Preallocate output cell arrays for Brightness Temperature (TB) results
    TB_Table         = cell(numel(theta), 1);
    TB_satview_Table = cell(numel(theta), 1);
    TA_GS_Table      = cell(numel(theta), 1);
    TA_SAT_Table     = cell(numel(theta), 1);
    
    T_cmd   = 2.73; % cosmic background noise [K]
    eta_GS  = 0.9;  % Main Beam efficiencies of the ground station antenna (0-1)
    eta_SAT = 0.88; % Main beam efficiencies of the satellites antenna (0-1)
    
    % Number of satellite passes
    nPasses = numel(theta);
    
    % Extract the date for the first measurement of the current pass
    day     = str2double(string(datetime(time{1}(1), 'Format', 'dd'))); % Convert datetime to double.
    month   = str2double(string(datetime(time{1}(1), 'Format', 'MM')));
    year    = str2double(string(datetime(time{1}(1), 'Format', 'uuuu')));
    
    % Define sunrise/sunset times (Athens time zone)
    t_sunrise   = datetime(year, month, day, 06, 15, 00, 'Format', 'dd-MM-uuuu HH:mm:ss', 'TimeZone', 'Europe/Athens');
    t_sunset    = datetime(year, month, day, 18, 45, 00, 'Format', 'dd-MM-uuuu HH:mm:ss', 'TimeZone','Europe/Athens');
    
    % Main loop over Satellite Passes
    for i = 1:nPasses
    
        % Loop through all time points in the current satellite pass (i)
        for j = 1:numel(theta{i})
            
            % Current rain rate
            Rp = R{i, 1}(j);
    
            % Convert surface temperature from C to Kelvin
            Ts_K= Ts{i, 1}(j) + 273.15;
    
            % Current dew point temperature [C].
            Td_temp = Td{i, 1}(j); 
    
            % Calculate Water Vapor Density (rho_ws) 
            e = 6.112 * exp((17.62 * Td_temp)/(243.12 + Td_temp)); % actual vapor pressuere [hPa].
            rho_ws = (216.7 * e)/Ts_K;  % Water vapor density [g/m^3]
            
            % Calculate Brightness Temperature (TB)
            if Rp > 0.0
    
                % Rain present → assume ground temp ~ 275 K for emission
                Tmr = 275; % Valid up to 55 GHz.
            else
    
                % Clear sky → use Tmr approximation
                Tmr = a_t + (b_t * Ts_K) + (c_t * Ps{i, 1}(j)) + (d_t * rho_ws); % [K]
            end
    
            TB = 2.73 * (10^(-(EPL{i, 1}(j)/10))) + Tmr * (1 - (10^(-(EPL{i, 1}(j)/10)))); % [K] Eq. 10
    
            % Calculate Surface Temperature from Satellite's View
            % Current time of day
            tod = time{i, 1}(j); 
    
            if (tod >= t_sunrise) && (tod < t_sunset)
                Tsurf_K = Ts_K + 2; % Daytime → +2 K surface heating
            else
                Tsurf_K = Ts_K; % Nighttime → no offset
            end
    
            % Effective Emissivity (e_eff) Adjustment for Rain
            if Rp > 0
                if Rp < 2
                    e_eff = e_base + 0.02;
                elseif Rp < 10
                    e_eff = e_base + 0.03;
                else
                    e_eff = e_base + 0.04;
                end
            
            else
                e_eff = e_base;
            end
    
            % Clamp emissivity within physical bounds
            e_eff = min(max(e_eff, e_min), e_max);
    
            % Reflectivity (rho) from emissivity
            rho = 1 - e_eff;
    
            % Brightness Temperature from Satellite View
            TB_satview_K = e_eff * Tsurf_K + rho * TB;
    
            % Spillover temperatures
    
            theta_main_deg = theta{i}(j);
            theta_main_rad = deg2rad(max(theta_main_deg, 1));        % avoid sin(0)
            A0_dB = EPL{i,1}(j) * sin(theta_main_rad);               % zenith gaseous+rain approx
    
            % Generating diffirent angles to cover the 0 - 90 (deg) in order to
            % calculate the spilling of the side lopes when facing the earth.
            th_deg = linspace(1, 90, 13); % 12-16 Points is plenty
            th_rad = deg2rad(th_deg);
    
            % Map zenith attenuation to other elevations: A(θ) ≈ A0 / sin(θ)
            A_theta_dB = A0_dB ./ sin(th_rad);
            
            % Eq. (10): T_B^down(θ) = 2.73*10^(-A/10) + Tmr*(1 - 10^(-A/10))
            att_lin_vec = 10.^(-A_theta_dB/10);
            TB_down_vec = 2.73.*att_lin_vec + Tmr.*(1 - att_lin_vec);    % [K]
            
            % Hemispheric average with projected-solid-angle weight w = cosθ·sinθ
            w = cos(th_rad).*sin(th_rad);
            w = w ./ trapz(th_rad, w);
            T_atm_hemi_K = trapz(th_rad, TB_down_vec .* w);              % [K]
    
            % Ground station
            TA_GS = (eta_GS * TB) + (1 - eta_GS) * T_atm_hemi_K;
    
            % Satellite
            TA_SAT = (eta_SAT * TB_satview_K) + (1 - eta_SAT) * T_cmd;
    
            % Append results for current time step
            TB_Table{i, 1}          = [TB_Table{i}; TB];
            TA_GS_Table{i,1}        = [TA_GS_Table{i}; TA_GS];
            TA_SAT_Table{i,1}       = [TA_SAT_Table{i}; TA_SAT];
            TB_satview_Table{i, 1}  = [TB_satview_Table{i}; TB_satview_K];
        end
    end
    disp('                 ✓ Calculation Complete.');
    disp('          --- Finished skyNoiseCalc.m ---');

end