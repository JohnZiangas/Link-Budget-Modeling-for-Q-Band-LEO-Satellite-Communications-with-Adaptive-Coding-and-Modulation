function [Ts_seg, Ps_seg, RH_seg, Td_seg, t_seg] = interpMetLinear(time10, Ts, Ps, RH, Td, i, dt_sec, varargin)
%INTERPMETLINEARINTERVAL  Linear 1-second interpolation for ONE 10-min interval [t_i, t_{i+1}).
%
% Behavior:
%   - Starts at 00:00:00 and interpolates forward within the same day.
%   - DOES NOT wrap from the previous day's 23:50:00 into today's 00:00:00.
%   - For the last index i==N, returns an EMPTY segment (no interpolation toward next day).
%
% Inputs
%   time10 : 144x1 vector (string table, string array, char/cellstr, datetime)
%   Ts,Ps,RH,Td : 144x1 vectors or single-column tables (same length as time10)
%   i      : interval index (1..N). For i==N, returns empty vectors.
%   dt_sec : target sampling period in seconds (use 1 for 1 Hz)
% Optional Name-Value:
%   'InputFormat' : datetime format for string times (e.g., 'HH:mm' or 'dd/MM/yyyy HH:mm')
%
% Outputs (for interval i)
%   Ts_seg, Ps_seg, RH_seg, Td_seg : 1-Hz vectors on [time10(i), time10(i+1))  (right endpoint EXCLUDED)
%   t_seg : datetime vector of the returned 1-Hz timestamps
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

    % ----- parse inputs & optional format -----
    ip = inputParser;
    addParameter(ip, 'InputFormat', '', @(s) isstring(s) || ischar(s));
    parse(ip, varargin{:});
    inFmt = ip.Results.InputFormat;

    % Tables -> arrays
    Ts = toCol(Ts); Ps = toCol(Ps); RH = toCol(RH); Td = toCol(Td);

    % time10 (string table or other) -> datetime
    t_c = coerceToDatetime(time10, inFmt);

    N = numel(t_c);
    if i < 1 || i > N
        error('Index i out of range (1..%d).', N);
    end
    if nargin < 7 || isempty(dt_sec), dt_sec = 1; end
    if ~isscalar(dt_sec) || dt_sec <= 0
        error('dt_sec must be a positive scalar.');
    end

    % ----- determine interval [t0, t1) & duration -----
    t0 = t_c(i);

    if i < N
        t1 = t_c(i+1);
        durSec = seconds(t1 - t0);
        if durSec <= 0
            error('Non-increasing time at i=%d.', i);
        end

        % 1-Hz grid on [t0, t1) -> exclude right endpoint to avoid duplicates
        n = floor(durSec / dt_sec);
        if n <= 0
            % Degenerate case: no interior 1s slots in this tiny interval
            Ts_seg = []; Ps_seg = []; RH_seg = []; Td_seg = []; t_seg = datetime.empty(0,1);
            return;
        end

        t_seg = t0 + seconds(0:dt_sec:(n-1)*dt_sec);
        frac = (0:n-1) / n;  % normalized position in [0, 1)

        % Linear between endpoints of the current interval
        Ts_seg = Ts(i) + (Ts(i+1) - Ts(i)) * frac.';
        Ps_seg = Ps(i) + (Ps(i+1) - Ps(i)) * frac.';
        RH_seg = RH(i) + (RH(i+1) - RH(i)) * frac.';
        Td_seg = Td(i) + (Td(i+1) - Td(i)) * frac.';

    else
        % i == N: DO NOT produce interpolation toward next day (no wrap).
        % Return empty outputs.
        Ts_seg = []; Ps_seg = []; RH_seg = []; Td_seg = []; 
        t_seg  = datetime.empty(0,1);
        return;
    end

    % ----- physical constraints -----
    RH_seg = max(min(RH_seg, 100), 0);   % clamp RH
    Td_seg = min(Td_seg, Ts_seg);        % ensure Td <= Ts
end

% ===== helpers =====
function v = toCol(x)
    if istable(x), v = table2array(x);
    else,          v = x;
    end
    v = v(:);
end

function dt = coerceToDatetime(x, inFmt)
    if istable(x), x = table2array(x); end
    if isdatetime(x)
        dt = x(:);
    elseif isnumeric(x)
        % assume datenums
        dt = datetime(x(:), 'ConvertFrom', 'datenum');
    else
        % string / char / cellstr
        s = string(x(:));
        if ~isempty(inFmt)
            dt = datetime(s, 'InputFormat', inFmt);
        else
            % try to infer (works for 'HH:mm' or full timestamps)
            dt = datetime(s);
        end
    end
end
