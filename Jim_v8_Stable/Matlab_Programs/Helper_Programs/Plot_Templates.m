    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 4;opts.height= 3;opts.fontType= 'Myriad Pro';opts.fontSize= 7;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 5);
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro','FontSize', 7)
    hold on
    %title('Bleaching Rate','FontSize', 7)
    xlabel('Frame','FontSize', 7)
    ylabel('Remaining Particles (%)','FontSize', 7)
    %%
    hold off
    set(gca,'Layer','top')
    leg = legend({'Data', 'Exp. Fit'},'Location','northeast','Box','off','FontSize', 7);
    leg.ItemTokenSize = [10,30];
    print([photobleachFile 'Bleaching_Rate'], '-dpng', '-r600');
    print([photobleachFile 'Bleaching_Rate'], '-dsvg', '-r600'); 
   %% line plots
   plot(x,y,'LineWidth',2);
   plot(x,y,'--*','LineWidth',0.5)
%% survival not normalized
    toplot = allBleachingX;
    x = 1:max(round(max(toplot)/100),1):max(toplot);
    y = arrayfun(@(z) nnz(toplot>z),x);
    plot(x,y,'LineWidth',2);
    
    %% survival normalized (%)
    toplot = allBleachingX;
    x = 1:max(round(max(toplot)/100),1):max(toplot);
    y = 100.*arrayfun(@(z) nnz(toplot>z),x)./length(toplot);
    plot(x,y,'--*','LineWidth',0.5)
    
   %%
   