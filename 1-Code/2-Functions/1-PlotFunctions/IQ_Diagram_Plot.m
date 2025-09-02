function IQ_Diagram_Plot(y, xLabelStr, yLabelStr, plotTitle, outName)
%PAPER_SCATTER Create a publication-ready scatter plot with zero reference lines.
%
%   PAPER_SCATTER(y) plots the values in y versus their index.
%   PAPER_SCATTER(y, xLabelStr, yLabelStr, plotTitle) sets axis labels and title.
%   PAPER_SCATTER(y, xLabelStr, yLabelStr, plotTitle, outName) saves to file.
%
%   All labels can use LaTeX formatting.

    % Handle optional arguments
    if nargin < 2 || isempty(xLabelStr), xLabelStr = '$X$-axis label'; end
    if nargin < 3 || isempty(yLabelStr), yLabelStr = '$Y$-axis label'; end
    if nargin < 4 || isempty(plotTitle), plotTitle = 'Scatter Plot Example'; end
    if nargin < 5 || isempty(outName), outName = ''; end

    % Create scatter plot
    scatterplot(y); 
    h = gca;  % Axis handle

    % ----------------------------
    % Figure appearance
    % ----------------------------
    % set(gcf, 'Units','centimeters', 'Position',[2 2 12 8], 'Color','w'); % ~12x8 cm
    % set(gcf, 'Renderer', 'painters');  % vector output for papers

    % Marker styling
    h.Children.Marker          = 'o';
    h.Children.MarkerEdgeColor = [0 0.2 0.35];   % dark outline
    h.Children.MarkerFaceColor = [0 0.45 0.74];  % colorblind-friendly blue

    % Colors
    h.Title.Color  = 'k';
    h.YColor       = 'k';
    h.XColor       = 'k';
    h.Color        = 'w'; % inside-axis
    h.Parent.Color = 'w'; % figure background

    % Axes formatting
    h.FontName   = 'Times New Roman';
    h.FontSize   = 9;
    h.LineWidth  = 0.75;
    h.TickDir    = 'out';
    h.Box        = 'off';
    h.XMinorGrid = 'on';
    h.YMinorGrid = 'on';
    h.MinorGridLineStyle = '-';
    h.GridAlpha  = 0.15;

    % LaTeX labels
    set(groot, 'defaultTextInterpreter','latex', ...
               'defaultAxesTickLabelInterpreter','latex', ...
               'defaultLegendInterpreter','latex');
    xlabel(xLabelStr, 'FontSize', 14);
    ylabel(yLabelStr, 'FontSize', 14);
    title(plotTitle, 'FontSize', 16);

    % Tight limits with padding
    xlim([min(h.Children.XData) max(h.Children.XData)]);
    yl = ylim; dy = diff(yl);
    ylim([yl(1)-0.05*dy, yl(2)+0.05*dy]);

    % ----------------------------
    % Add horizontal & vertical zero lines behind data
    % ----------------------------
    hold on;
    uistack(plot([0 0], ylim, 'k--', 'LineWidth', 1.2, 'Color', [0.5 0.5 0.5]), 'bottom');
    uistack(plot(xlim, [0 0], 'k--', 'LineWidth', 1.2, 'Color', [0.5 0.5 0.5]), 'bottom');
    hold off;

    % ----------------------------
    % Save if filename given
    % ----------------------------
    if ~isempty(outName)
        exportgraphics(gcf, [outName '.pdf'], 'ContentType','vector');  % journal
        exportgraphics(gcf, [outName '.png'], 'Resolution',600);        % slides
    end
end
