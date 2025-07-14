%% Basic Plot

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
for fileNo = 1:3
    ax.ColorOrderIndex = fileNo;
    plot(1:100,exp(-fileNo.*[1:100]./30),'LineWidth',2)
end
for fileNo = 1:3
    ax.ColorOrderIndex = fileNo;
    scatter(1:10:100,(0.9+0.2.*rand(1,10)).*exp(-fileNo.*[1:10:100]./30))
end
xlim([0 50])
ylim([0 1])
xlabel('Time (mins)')
ylabel('Intensity')
leg = legend({'1 pM','2 pM','3 pM'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [15,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
%print([saveFolder 'Mean_PFO_Intensity_vs_Time'], '-dpng', '-r600');
%print([saveFolder 'Mean_PFO_Intensity_vs_Time'], '-depsc', '-r600');
