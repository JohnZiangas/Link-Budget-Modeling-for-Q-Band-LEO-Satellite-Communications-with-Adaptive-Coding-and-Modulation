function [M_sel_cells, Rc_sel_cells, Rb_info_cells, margin_cells, forced_cells] = ...
    ACMCalc(CNoTable, B, alpha, M_list, Rc_list, Delta_impl_dB, H_up_dB, H_down_dB, min_dwell)
% ACMCALC  Adaptive MODCOD selection with hysteresis + summary plots.
%
% Inputs:
%   CNoTable      : {N_pass x 1}, each cell [T_k x 1] of C/N0 in dB-Hz over time
%   B             : occupied RF bandwidth [Hz]
%   alpha         : roll-off factor (e.g., 0.9). Symbol rate Rs = B/(1+alpha)
%   M_list        : vector of square-QAM constellation sizes, e.g., [4 16 64 256]
%   Rc_list       : vector of code rates, e.g., [0.50 0.75 0.90]
%   Delta_impl_dB : implementation gap to Shannon capacity for target BER [dB]
%   H_up_dB       : extra margin required to upgrade MODCOD [dB]
%   H_down_dB     : margin deficit to trigger downgrade [dB]
%   min_dwell     : minimum dwell time before upgrade [s]
%
% Outputs (parallel to CNoTable):
%   M_sel_cells   : selected modulation order M(t) for each pass
%   Rc_sel_cells  : selected coding rate Rc(t) for each pass
%   Rb_info_cells : instantaneous information bit rate [bps]
%   margin_cells  : decoder margin (Eb/N0_inst − Eb/N0_req) [dB]
%   forced_cells  : true where fallback (lowest MODCOD) was enforced
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

    % --- STEP 1: Candidate MODCOD grid
    Rs         = B/(1+alpha);               % symbol rate [symbols/s]
    [Mg, Rcg]  = ndgrid(M_list, Rc_list);   % all (M,Rc) combinations
    kg         = log2(Mg);                  % bits/symbol per constellation
    Rb_g       = Rs .* kg .* Rcg;           % info bit rate per candidate [bps]
    eta_g      = (kg .* Rcg) / (1+alpha);   % spectral efficiency [b/s/Hz]

    % Shannon threshold + implementation gap: required Eb/N0 for each candidate
    EbN0_req_dB_g = 10.*log10((2.^eta_g - 1)./eta_g) + Delta_impl_dB;

    % Flatten to vectors for easier indexing
    M_cand      = Mg(:)';               % 1 x Nc
    Rc_cand     = Rcg(:)';              % 1 x Nc
    Rb_cand     = Rb_g(:)';             % 1 x Nc
    EbN0_req_dB = EbN0_req_dB_g(:)';    % 1 x Nc
    k_cand      = log2(M_cand);         % bits per symbol

    % Preference rule: slightly favor lower-M for same bit rate
    Rb_pref = Rb_cand - 1e-6 * k_cand;

    % Find most-robust MODCOD (lowest throughput) for forced fallback
    [~, ord_tmp] = sortrows([Rb_cand(:), k_cand(:)], [1 1]);
    lowest_idx = ord_tmp(1);

    % Allocate outputs
    numPass = numel(CNoTable);
    M_sel_cells   = cell(numPass,1);
    Rc_sel_cells  = cell(numPass,1);
    Rb_info_cells = cell(numPass,1);
    margin_cells  = cell(numPass,1);
    forced_cells  = cell(numPass,1);

    % --- STEP 2: Process each pass
    for p = 1:numPass
        CNo_dBHz = CNoTable{p}(:); % C/N0 trace [T x 1]
        T = numel(CNo_dBHz);

        % Compute instantaneous Eb/N0 for all candidates:
        % Eb/N0_dB = C/N0_dBHz − 10log10(Rb)
        EbN0_inst_dB = CNo_dBHz - 10*log10(Rb_cand); 

        % Allocate per-pass vectors
        M_sel   = nan(T,1);
        Rc_sel  = nan(T,1);
        Rb_info = zeros(T,1);
        margin  = -inf(T,1);
        forced  = false(T,1);

        cur_idx = NaN;   % current active MODCOD index
        last_change = 0; % last time we switched MODCOD

        % Time evolution loop
        for t = 1:T
            row = EbN0_inst_dB(t,:); % Eb/N0 across all candidates at time t

            if isnan(CNo_dBHz(t))
                % Missing measurement -> force smallest/most robust
                cur_idx     = lowest_idx;
                forced(t)   = true;
                last_change = t;

            else
                % Candidates meeting basic requirement and upgrade margin
                meets    = row >= EbN0_req_dB;                 % feasible at base threshold
                meets_up = row >= (EbN0_req_dB + H_up_dB);     % feasible for upgrade

                if isnan(cur_idx)
                    % Initialize to best feasible, else fallback to smallest
                    Rb_tmp = Rb_pref; Rb_tmp(~meets) = -Inf;
                    [~, j] = max(Rb_tmp);
                    if ~isfinite(Rb_tmp(j)), j = lowest_idx; forced(t) = true; end
                    cur_idx = j; last_change = t;

                else
                    % Compute current link margin for active MODCOD
                    margin_cur = row(cur_idx) - EbN0_req_dB(cur_idx);

                    % Immediate downgrade if margin deficit exceeds H_down_dB
                    if margin_cur < -H_down_dB
                        Rb_tmp = Rb_pref; Rb_tmp(~meets) = -Inf;
                        [~, j] = max(Rb_tmp);
                        if ~isfinite(Rb_tmp(j)), j = lowest_idx; forced(t) = true; end
                        if j ~= cur_idx, cur_idx = j; last_change = t; end

                    % Consider upgrade after dwell time if higher modes feasible
                    elseif (t - last_change) >= min_dwell
                        higher = (Rb_cand > Rb_cand(cur_idx) + 1e-6) & meets_up;
                        if any(higher)
                            Rb_tmp = Rb_pref; Rb_tmp(~higher) = -Inf;
                            [~, j] = max(Rb_tmp);
                            if j ~= cur_idx, cur_idx = j; last_change = t; end
                        end
                    end
                end
            end

            % Record selection at time t
            M_sel(t)   = M_cand(cur_idx);
            Rc_sel(t)  = Rc_cand(cur_idx);
            Rb_info(t) = Rb_cand(cur_idx);
            margin(t)  = row(cur_idx) - EbN0_req_dB(cur_idx);   % may be negative if forced
        end

        % Save results for this pass
        M_sel_cells{p}   = M_sel;
        Rc_sel_cells{p}  = Rc_sel;
        Rb_info_cells{p} = Rb_info;
        margin_cells{p}  = margin;
        forced_cells{p}  = forced;

        % --- STEP 3: Generate summary plots
        % [1] Rb vs time
        % [2] Decoder margin vs time
        % [3] Selected MODCOD timeline
        % [4] CDF of spectral efficiency
        % [5] Efficiency vs Shannon limit (eta/Cshannon)
        % [6] Time share (occupancy) per MODCOD

        tsec = (1:T).';
        eta  = Rb_info / B;                   % spectral efficiency [b/s/Hz]
        SNR_Hz_dB  = CNo_dBHz - 10*log10(B);   % [dB]
        SNR_Hz = 10.^(SNR_Hz_dB/10);
        Csh_perHz      = log2(1 + SNR_Hz);        % Shannon capacity [b/s/Hz]

        eff_frac = eta ./ Csh_perHz; 
        eff_frac(~isfinite(eff_frac)) = NaN;

        % Figure and layout
        titleStr = sprintf('ACM Summary — Pass %d', p);
        fig = figure('Name', titleStr, 'Color','w', 'Units','centimeters', 'Position', [1 1 18 20]);
        tl = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
        title(tl, titleStr, 'FontSize', 12);

        % [1] Information bit rate Rb vs time
        ax1 = nexttile;
        plot(ax1, tsec, Rb_info/1e6, '-', 'LineWidth',1.4);
        xlabel(ax1, 'Time [s]');
        ylabel(ax1, 'Rb [Mbit/s]');
        styleAxes(ax1);

        % [2] Margin vs time (single reference line at 0 dB)
        ax2 = nexttile;
        plot(ax2, tsec, margin, '-', 'LineWidth',1.4); 
        hold(ax2,'on'); yline(ax2, 0, '-', '0 dB');
        if any(forced)
            plot(ax2, tsec(forced), margin(forced), 'o', 'MarkerSize',3, 'LineWidth',1.0);
        end
        xlabel(ax2, 'Time [s]');
        ylabel(ax2, 'Margin [dB]');
        styleAxes(ax2);

        % [3] Selected MODCOD vs time — ordered from lowest to highest info rate
        ax3 = nexttile;
        modes_used = [M_sel, Rc_sel];                 % [T x 2]
        [uPairs, ~, ~] = unique(modes_used, 'rows');  % unique modes present [K x 2]
        Rb_u = Rs .* log2(uPairs(:,1)) .* uPairs(:,2);
        [~, ord] = sortrows(uPairs, [1 2]);  % M ascending, then Rc ascending
        uPairs_ord = uPairs(ord, :);
        [~, idxMode] = ismember(modes_used, uPairs_ord, 'rows');
        stairs(ax3, tsec, idxMode, '-x', 'LineWidth', 1.4);
        yticks(ax3, 1:size(uPairs_ord,1));
        yticklabels(ax3, arrayfun(@(i) sprintf('M=%d, Rc=%.2f', ...
                                   uPairs_ord(i,1), uPairs_ord(i,2)), ...
                                   (1:size(uPairs_ord,1))', 'UniformOutput', false));
        xlabel(ax3, 'Time [s]');
        ylabel(ax3, 'Selected MODCOD (low to high)');
        title(ax3, 'Mode timeline', 'FontSize', 10);
        styleAxes(ax3);

        % [4] Spectral efficiency CDF (single line)
        ax4 = nexttile;
        eta_valid = eta(isfinite(eta)); 
        if isempty(eta_valid), eta_valid = 0; end
        eta_sorted = sort(eta_valid);
        F = (1:numel(eta_sorted)).'/numel(eta_sorted);
        plot(ax4, eta_sorted, F, 'LineWidth',1.4);
        xlabel(ax4, 'Spectral efficiency [b/s/Hz]');
        ylabel(ax4, 'CDF');
        styleAxes(ax4);

        % [5] Efficiency vs capacity (eta/Cshannon) over time — with overshoot squash + red X markers
        ax5 = nexttile;  % or: ax5 = gca; if you're using a standalone figure
        hold(ax5,'on');

        eff = eff_frac;                                 % your eta/Cshannon series
        maxEff = max(eff(~isnan(eff)), [], 'omitnan');  % highest overshoot (if any)

        if isempty(maxEff) || maxEff <= 1 + 1e-9
            % No overshoot: plot normally 0..1
            hCurve = plot(ax5, tsec, eff, 'LineWidth',1.4, 'DisplayName','Efficiency');
            yline(ax5, 1, '--', '1.0');
            ylim(ax5, [0 1]);
            yticks(ax5, 0:0.2:1);
            yticklabels(ax5, compose('%.1f', 0:0.2:1));
        else
            % Overshoot present: squash y>1 into the top 20% of the panel
            den = max(maxEff - 1, eps);                 % avoid /0
            ydisp = nan(size(eff));
            mask_lo = eff <= 1 | isnan(eff);
            mask_hi = eff > 1;

            % Map [0,1] -> [0,0.8]; map [1,maxEff] -> [0.8,1]
            ydisp(mask_lo) = 0.8 * eff(mask_lo);
            ydisp(mask_hi) = 0.8 + 0.2 * (eff(mask_hi) - 1) / den;

            % Lightly shade the squashed region (0.8..1)
            patch(ax5, [tsec(1) tsec(end) tsec(end) tsec(1)], [0.8 0.8 1 1], ...
                        [0.94 0.94 0.94], 'EdgeColor','none');

            % Plot the transformed curve
            hCurve = plot(ax5, tsec, ydisp, 'LineWidth',1.4, 'DisplayName','Efficiency (scaled)');

            % Add red "X" markers at overshoot samples (>1.0), at their scaled positions
            plot(ax5, tsec(mask_hi), ydisp(mask_hi), 'x', ...
                 'Color', [0.85 0 0], 'LineWidth', 1.2, 'MarkerSize', 6, ...
                 'DisplayName','Overshoot (>1.0)');

            % Reference line showing where 1.0 sits (80% height)
            yline(ax5, 0.8, '--', '1.0');

            ylim(ax5, [0 1]);

            % Build readable ticks that show REAL values
            low_real  = 0:0.25:1;                  % 0..1 region
            low_disp  = 0.8 * low_real;

            frac      = [0.25 0.5 0.75 1.0];       % ticks in the overshoot region
            high_real = 1 + (maxEff - 1) * frac;   % real values >1
            high_disp = 0.8 + 0.2 * frac;          % positions after squash

            yt = [low_disp, high_disp];
            yl = [low_real, high_real];

            % Deduplicate if 1.0 appears twice
            [yt, ord] = unique(yt, 'stable'); 
            yl = yl(ord);

            yticks(ax5, yt);
            yticklabels(ax5, arrayfun(@(v) sprintf('%.2f', v), yl, 'UniformOutput', false));

            % Optional legend only when overshoots exist
            legend(ax5, 'Location','best');
        end

        xlabel(ax5, 'Time [s]');
        ylabel(ax5, 'eta / Cshannon (scaled above 1)');
        styleAxes(ax5);


        % [6] Time-share per MODCOD (same ordering as panel [3])
        ax6 = nexttile;
        share = accumarray(idxMode, 1, [size(uPairs_ord,1) 1]) / numel(idxMode) * 100;
        bar(ax6, share, 'LineWidth', 0.9);
        xticks(ax6, 1:size(uPairs_ord,1));
        xticklabels(ax6, arrayfun(@(i) sprintf('M=%d, Rc=%.2f', ...
                                   uPairs_ord(i,1), uPairs_ord(i,2)), ...
                                   (1:size(uPairs_ord,1))', 'UniformOutput', false));
        xtickangle(ax6, 10);
        ylabel(ax6, 'Time share [%]');
        title(ax6, 'Mode occupancy', 'FontSize', 10);
        styleAxes(ax6);
    end % for each pass
end

%% --------- Local helper: consistent journal-style axes ---------
function styleAxes(ax)
    % Apply consistent journal-style formatting to plots
    set(ax, 'FontName','Times New Roman', 'FontSize',10, 'LineWidth',0.8, ...
        'TickLabelInterpreter','none', 'Box','on');
    grid(ax,'on'); 
    ax.XMinorGrid = 'on'; 
    ax.YMinorGrid = 'on';
end