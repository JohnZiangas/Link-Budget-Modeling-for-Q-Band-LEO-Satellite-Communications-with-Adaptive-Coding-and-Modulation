function plot_xx_y_paper(x, y1, y2, x_label, y_label1, y_label2, titleStr, legendLabels, outName)
%PLOT_XX_Y_PAPER  Publication-ready dual-axis plot with AoS/LoS markers.
%
%   plot_xx_y_paper(x, y1, y2, x_label, y_label1, y_label2)
%   plot_xx_y_paper(..., titleStr)
%   plot_xx_y_paper(..., titleStr, legendLabels)
%   plot_xx_y_paper(..., titleStr, legendLabels, outName)
%
%   Inputs:
%     x           : vector (datetime or numeric)
%     y1          : vector, data for left Y-axis
%     y2          : vector, data for right Y-axis
%     x_label     : string (LaTeX OK), label for X-axis
%     y_label1    : string (LaTeX OK), label for left Y-axis
%     y_label2    : string (LaTeX OK), label for right Y-axis
%     titleStr    : optional string (LaTeX OK), plot title
%     legendLabels: optional cell array {label1, label2}
%     outName     : optional base filename to export PDF/PNG (no extension)
%
%   Notes:
%     - Adds vertical dashed lines for AoS (start) and LoS (end).
%     - Automatically handles datetime and numeric X data.
%     - Padding on Y-limits for readability.

    % --- Defaults ---
    if nargin < 7 || isempty(titleStr), titleStr = ''; end
    if nargin < 8 || isempty(legendLabels), legendLabels = {'Series 1', 'Series 2'}; end
    if nargin < 9, outName = ''; end

    % --- Checks ---
    assert(numel(x) == numel(y1) && numel(y1) == numel(y2), ...
        'x, y1, and y2 must have the same length.');

    % --- Figure ---
    figure

    % LaTeX interpreters
    set(groot,'defaultTextInterpreter','latex', ...
              'defaultAxesTickLabelInterpreter','latex', ...
              'defaultLegendInterpreter','latex');

    % --- Left Y-axis ---
    yyaxis left;
    p1 = plot(x, y1, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]); % blue
    ylabel(y_label1, 'FontSize', 14);
    yl1 = ylim; padding1 = 0.05 * range(yl1);
    ylim([min(y1)-padding1, max(y1)+padding1]);

    % --- Right Y-axis ---
    yyaxis right;
    p2 = plot(x, y2, 'LineWidth', 1.5, 'LineStyle', '--', 'Color', [0.85 0.33 0.10]); % orange
    ylabel(y_label2, 'FontSize', 14);
    yl2 = ylim; padding2 = 0.05 * range(yl2);
    ylim([min(y2)-padding2, max(y2)+padding2]);

    % --- Shared axes formatting ---
    ax = gca;
    ax.FontName = 'Times New Roman';
    ax.FontSize = 10;
    ax.LineWidth = 0.8;
    ax.TickDir = 'out';
    ax.Box = 'on';
    ax.GridAlpha = 0.6;
    ax.GridLineWidth = 0.8;
    ax.MinorGridLineStyle = ':';
    ax.XMinorGrid = 'on';
    ax.YMinorGrid = 'on';
    grid(ax, 'on');

    xlabel(x_label, 'FontSize', 14);
    if ~isempty(titleStr)
        title(titleStr, 'FontSize', 16);
    end

    % --- X-axis formatting ---
    if isdatetime(x)
        xlim([x(1) x(end)]);
        ax.XAxis.TickLabelFormat = 'HH:mm';
    elseif isfloat(x) && max(x) > 1e5 % datenum
        xlim([x(1) x(end)]);
        datetick('x','HH:MM','keeplimits','keepticks');
    else
        xlim([min(x) max(x)]);
    end

    % --- AoS & LoS vertical dashed lines ---
    hold on;
    yl = ylim; % current y-limits for active side
    aosLine = xline(x(1), '--k', 'AoS', ...
        'LineWidth', 1, 'Color', [0.3 0.3 0.3], 'LabelOrientation', 'horizontal', 'LabelHorizontalAlignment', 'right', 'LabelVerticalAlignment', 'bottom');
    losLine = xline(x(end), '--k', 'LoS', ...
        'LineWidth', 1, 'Color', [0.3 0.3 0.3], 'LabelOrientation', 'horizontal', 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');

    % --- Legend ---
    % legend([p1 p2 aosLine losLine], ...
    %     [legendLabels, {'AoS', 'LoS'}], ...
    %     'Location','best', 'Box','on');

    % --- Prevent label clipping ---
    set(ax, 'LooseInset', max(get(ax,'TightInset'), 0.02));

    % --- Export (optional) ---
    if ~isempty(outName)
        exportgraphics(fig, [outName '.pdf'], 'ContentType','vector'); % journal quality
        exportgraphics(fig, [outName '.png'], 'Resolution', 600);       % high-DPI PNG
    end
end
