laserPower = 75;
m = 28.6*laserPower;
s = 17.9*laserPower;
logNormalMu = log(m^2/sqrt(m^2+s^2));
logNormalSig = sqrt(log(1+s^2/m^2));

logNormalMu2 = 0.8772*log(laserPower)+3.6797;
logNormalSig2 = 0.0543*log(laserPower)+0.3179;

%%
X = 1:8000;
Y = 1./X.*normpdf(log(X),logNormalMu,logNormalSig);
Y2 = zeros(length(X),1);

for i=X
    for j = max(-round(20*sqrt(i)),-i+1):min(round(20*sqrt(i)),max(X)-i)
        Y2(i+j) = Y2(i+j)+normpdf(j,0,10*sqrt(i))*Y(i);
    end
end

%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Pre-Step Intensity','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData(allData>0),'Normalization','pdf','HandleVisibility','off')
plot(X,1.08.*Y2./sum(Y2),'LineWidth',2)
xlim([0 7000])
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'PreStep_Intensities_GlobalFit'], '-dpng', '-r600');
print([photobleachFile 'PreStep_Intensities_GlobalFit'], '-dsvg', '-r600'); 

%%


