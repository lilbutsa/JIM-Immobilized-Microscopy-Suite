%%
clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = false;

channel1 = {};

allfiles = dir(pathname);
allfiles(~[allfiles.isdir]) = [];
allfiles=allfiles(3:end);

if insubfolders
    for i=1:size(allfiles,1)
        innerfolder = dir([pathname,allfiles(i).name,'\']);
        innerfolder(~[innerfolder.isdir]) = [];
        innerfolder=innerfolder(3:end);
        for j=1:size(innerfolder,1)
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%% 3) Extract Traces
filetocheck = 1;
    traces=csvread(channel1{filetocheck},1);
    numparticles = size(traces,1);
    numframes = size(traces,2); 
    
%% 4) Plot example traces
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(traces(i+36*(pagenumber-1),:),'-r');
    plot([0 size(traces(i+36*(pagenumber-1),:),2)],[0 0] ,'-b');
    hold off
end

%% 5) Step Fit
bleachtime = [];
stepheight = [];
singlesteptrace = [];
stepmeans=[];
snr = [];
for i=1:size(traces,1)
    tracein = traces(i,:)';
    normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
    steps = findchangepts(normedtrace,'MinThreshold', 1, 'Statistic', 'mean');
    if size(steps,1)==1
        meanhigh = mean(tracein(1:steps));
        meanlow = mean(tracein(1+steps:end));
        if 0.8*meanhigh<(meanhigh-meanlow) 
            bleachtime = [bleachtime steps];
            stepheight = [stepheight meanhigh-meanlow];
            singlesteptrace = [singlesteptrace tracein];
            stepmeans = [stepmeans; [meanhigh meanlow]];
            
            snr = [snr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])]; 
        end
    end
end
%% 6) Plot single step traces
pagenumber = 3;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(singlesteptrace(:,i+36*(pagenumber-1)),'-r');
    plot([0 size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[0 0] ,'-b');
    plot([0 bleachtime(i+36*(pagenumber-1)) bleachtime(i+36*(pagenumber-1)) size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),2) stepmeans(i+36*(pagenumber-1),2)] ,'-black');
    hold off
end
%% 7) Fit Bleaching Time

bxin = sort(bleachtime);
byin = size(bleachtime,2):-1:1;

byin2 = byin(byin<0.9.*size(bleachtime,2));
byx = byin2(byin2>0.01.*size(bleachtime,2));

bxin2=bxin(byin<0.9.*size(bleachtime,2));
bx = bxin2(byin2>0.01.*size(bleachtime,2));


by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [0 size(bleachtime,2) 3/max(bleachtime)], opts);

%% 8) Fit Step Height

sxin = sort(stepheight);
syin = 1:size(stepheight,2);

syin2 = syin(syin<0.9.*size(stepheight,2));
syx = syin2(syin2>0.1.*size(stepheight,2));

sxin2=sxin(syin<0.9.*size(stepheight,2));
sx = sxin2(syin2>0.1.*size(stepheight,2));


sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bs = fminsearch(OLS, [size(stepheight,2) mean(stepheight) std(stepheight) 0], opts); 

phat = gamfit(stepheight);

%% 9) Plot Analysis

figure
byout = by(Bb,bxin);

set(gcf, 'Position', [100, 100, 1700, 300])

subplot(1,4,1)
title('Bleaching Rate')
xlabel('Frame')
ylabel('Remaining Particles')
hold on
plot(bxin,byin);
plot(bxin,byout,'-r');
hold off


sy2 = @(b,sx)(1/sqrt(2*pi*b(3)*b(3))*exp(-(sx-b(2)).^2./(2*b(3)*b(3)))); 
syout = sy2(Bs,sxin);
subplot(1,4,2);
title('Single Molecule Intensity')
xlabel('Step Intensity (a.u.)')
ylabel('Probability Density')
hold on;

histogram(stepheight,round(size(bleachtime,2)/10),'Normalization','pdf');
plot(sxin,syout,'-g');

syout = gampdf(sxin,phat(1),phat(2));
plot(sxin,syout,'-r');
hold off;


initialintensities = mean(traces(:,1:5)')./Bs(2);
subplot(1,4,3);
title('Initial Particle Intensity')
xlabel('Number of fluorophores')
ylabel('count')
hold on;
histogram(initialintensities,'BinLimits',[0,5],'BinWidth',0.1);
hold off;

subplot(1,4,4);
title('Signal To Noise')
xlabel('Step Height/Std.Dev.(residiual)')
ylabel('count')
hold on;
histogram(snr,round(size(bleachtime,2)/5));
hold off;

%% 10) Analyze all experiments
allbleachtimes = [];
allstepheights = [];
allsnr = [];
allinitvals = [];
SingleMoleculeBleachingResults = zeros(numofexps+2,15);
for filetocheck=1:numofexps
    disp(['Currently Analysing File ',num2str(filetocheck)]);
    traces=csvread(channel1{filetocheck},1);
    numparticles = size(traces,1);
    numframes = size(traces,2); 

     %Step Fit
    bleachtime = [];
    stepheight = [];
    snr = [];
    for i=1:size(traces,1)
        tracein = traces(i,:)';
        normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
        steps = findchangepts(normedtrace,'MinThreshold', 1, 'Statistic', 'mean');
        allinitvals = [allinitvals mean(tracein(1:5))];
        if size(steps,1)==1
            meanhigh = mean(tracein(1:steps));
            meanlow = mean(tracein(1+steps:end));
            if 0.8*meanhigh<(meanhigh-meanlow) 
                allbleachtimes = [allbleachtimes steps];
                allstepheights = [allstepheights meanhigh-meanlow];
                allsnr = [allsnr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])];
                bleachtime = [bleachtime steps];
                stepheight = [stepheight meanhigh-meanlow];
                snr = [snr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])]; 
            end
        end
    end



    bxin = sort(bleachtime);
    byin = size(bleachtime,2):-1:1;

    byin2 = byin(byin<0.9.*size(bleachtime,2));
    byx = byin2(byin2>0.01.*size(bleachtime,2));

    bxin2=bxin(byin<0.9.*size(bleachtime,2));
    bx = bxin2(byin2>0.01.*size(bleachtime,2));


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [0 size(bleachtime,2) 3/max(bleachtime)], opts);

    sxin = sort(stepheight);
    syin = 1:size(stepheight,2);

    syin2 = syin(syin<0.9.*size(stepheight,2));
    syx = syin2(syin2>0.001.*size(stepheight,2));

    sxin2=sxin(syin<0.9.*size(stepheight,2));
    sx = sxin2(syin2>0.001.*size(stepheight,2));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(stepheight,2) mean(stepheight) std(stepheight) 0], opts); 
    
    phat = gamfit(stepheight);
    
    numofflour = mean(traces(:,1:5)')./(phat(1)*phat(2)-phat(2));
  
    
    
    SingleMoleculeBleachingResults(filetocheck,1) = size(numofflour,2);
    SingleMoleculeBleachingResults(filetocheck,2) = size(stepheight,2);
    
    SingleMoleculeBleachingResults(filetocheck,3) = Bb(3);
    SingleMoleculeBleachingResults(filetocheck,4) = log(2)/Bb(3);
    SingleMoleculeBleachingResults(filetocheck,5) = log(10/9)/Bb(3);
    
    SingleMoleculeBleachingResults(filetocheck,6) = mean(stepheight);
    SingleMoleculeBleachingResults(filetocheck,7) = median(stepheight);
    SingleMoleculeBleachingResults(filetocheck,8) = std(stepheight);
    
    SingleMoleculeBleachingResults(filetocheck,9) = phat(1)*phat(2)-phat(2);
    SingleMoleculeBleachingResults(filetocheck,10) = phat(1)*phat(2);
    SingleMoleculeBleachingResults(filetocheck,11) = sqrt(phat(1)*phat(2)*phat(2));
    
    SingleMoleculeBleachingResults(filetocheck,12) = Bs(2);
    SingleMoleculeBleachingResults(filetocheck,13) = Bs(3);
    
    SingleMoleculeBleachingResults(filetocheck,14) = median(snr);
    
    SingleMoleculeBleachingResults(filetocheck,15) = size(numofflour(numofflour<=0.5),2)/size(numofflour,2);
    SingleMoleculeBleachingResults(filetocheck,16) = size(numofflour(numofflour>0.5 & numofflour<=1.5),2)/size(numofflour,2);
    SingleMoleculeBleachingResults(filetocheck,17) = size(numofflour(numofflour>1.5 & numofflour<=2.5),2)/size(numofflour,2);
    SingleMoleculeBleachingResults(filetocheck,18) = size(numofflour(numofflour>2.5),2)/size(numofflour,2);
end

    SingleMoleculeBleachingResults(numofexps+1,:) = mean(SingleMoleculeBleachingResults(1:numofexps,:));
    
    
    bxin = sort(allbleachtimes);
    byin = size(allbleachtimes,2):-1:1;

    byin2 = byin(byin<0.9.*size(allbleachtimes,2));
    byx = byin2(byin2>0.01.*size(allbleachtimes,2));

    bxin2=bxin(byin<0.9.*size(allbleachtimes,2));
    bx = bxin2(byin2>0.01.*size(allbleachtimes,2));


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [0 size(allbleachtimes,2) 3/max(allbleachtimes)], opts);

    sxin = sort(allstepheights);
    syin = 1:size(allstepheights,2);

    syin2 = syin(syin<0.9.*size(allstepheights,2));
    syx = syin2(syin2>0.001.*size(allstepheights,2));

    sxin2=sxin(syin<0.9.*size(allstepheights,2));
    sx = sxin2(syin2>0.001.*size(allstepheights,2));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(allstepheights,2) mean(allstepheights) std(allstepheights) 0], opts); 
    
    phat = gamfit(allstepheights);
    
    allnumoffluor = allinitvals./(phat(1)*phat(2)-phat(2));
    
    
    
    
    SingleMoleculeBleachingResults(numofexps+2,1) = size(allnumoffluor,2);
    SingleMoleculeBleachingResults(numofexps+2,2) = size(allstepheights,2);
    
    SingleMoleculeBleachingResults(numofexps+2,3) = Bb(3);
    SingleMoleculeBleachingResults(numofexps+2,4) = log(2)/Bb(3);
    SingleMoleculeBleachingResults(numofexps+2,5) = log(10/9)/Bb(3);
    
    SingleMoleculeBleachingResults(numofexps+2,6) = mean(allstepheights);
    SingleMoleculeBleachingResults(numofexps+2,7) = median(allstepheights);
    SingleMoleculeBleachingResults(numofexps+2,8) = std(allstepheights);
    
    
    SingleMoleculeBleachingResults(numofexps+2,9) = phat(1)*phat(2)-phat(2);
    SingleMoleculeBleachingResults(numofexps+2,10) = phat(1)*phat(2);
    SingleMoleculeBleachingResults(numofexps+2,11) = sqrt(phat(1)*phat(2)*phat(2));
    
    
    SingleMoleculeBleachingResults(numofexps+2,12) = Bs(2);
    SingleMoleculeBleachingResults(numofexps+2,13) = Bs(3);
    
    SingleMoleculeBleachingResults(numofexps+2,14) = median(allsnr);
    
    SingleMoleculeBleachingResults(numofexps+2,15) = size(allnumoffluor(allnumoffluor<=0.5),2)/size(allnumoffluor,2);
    SingleMoleculeBleachingResults(numofexps+2,16) = size(allnumoffluor(allnumoffluor>0.5 & allnumoffluor<=1.5),2)/size(allnumoffluor,2);
    SingleMoleculeBleachingResults(numofexps+2,17) = size(allnumoffluor(allnumoffluor>1.5 & allnumoffluor<=2.5),2)/size(allnumoffluor,2);
    SingleMoleculeBleachingResults(numofexps+2,18) = size(allnumoffluor(allnumoffluor>2.5),2)/size(allnumoffluor,2);
    
    

%% 11) Output results
f=figure;
set(gcf, 'Position', [100, 100, 1300, 300])
t=uitable(f,'Data',SingleMoleculeBleachingResults,'Position', [0, 0, 1300, 300]);
t.ColumnName = {'Num of Particles','Num of Single Steps','Bleach Rate (1/frames)','Half Life (frames)','10% Bleached (frames)','Mean Step Height','Median Step Height', 'Std. Dev. Step Height','Gamma Fit Max Single Molecule Intesity (a.u.)','Gamma Fit Mean', 'Gamma Fit Std. Dev.(a.u.)','Gauss Fit Mean', 'Gauss Fit Std. Dev.(a.u.)','Signal to Noise','Submonomer Fraction','Monomer Fraction','Dimer Fraction', 'Higher Order Fraction'};
t.RowName = num2cell([1:numofexps+1]);
t.RowName(numofexps+1) = {'Mean'};
t.RowName(numofexps+2) = {'Pooled'};

%saveas(gcf,[pathname,'Bleaching_Summary.tif']);


T = array2table(SingleMoleculeBleachingResults);
T.Properties.VariableNames= matlab.lang.makeValidName({'Num_of_Particles','Num_of_Single_Steps','Bleach_Rate_per_frames','Half_Life','Ten_Percent_Bleached','Mean_Step_Height','Median_Step_Height', 'Std_Dev_Step_Height','Gamma_Fit_Max_Single_Molecule_Intesity','Gamma_Fit_Mean', 'Gamma_Fit_Std_Dev','Gauss_Fit_Mean', 'Gauss_Fit_Std_Dev','Signal_to_Noise','Submonomer_Fraction','Monomer_Fraction','Dimer_Fraction', 'Higher_Order_Fraction'});
T.Properties.RowNames = t.RowName;
writetable(T, [pathname,'Bleaching_Summary.csv'],'WriteRowNames',true);


%% 9) Plot Pooled Analysis

figure
byout = by(Bb,bxin);

set(gcf, 'Position', [100, 100, 1700, 300])

subplot(1,4,1)
title('Bleaching Rate')
xlabel('Frame')
ylabel('Remaining Particles')
hold on
plot(bxin,byin);
plot(bxin,byout,'-r');
hold off


sy2 = @(b,sx)(1/sqrt(2*pi*b(3)*b(3))*exp(-(sx-b(2)).^2./(2*b(3)*b(3)))); 
syout = sy2(Bs,sxin);
subplot(1,4,2);
title('Single Molecule Intensity (Gamma Red, Gauss Green)')
xlabel('Step Intensity (a.u.)')
ylabel('Probability Density')
hold on;

histogram(allstepheights,min([round(size(allbleachtimes,2)/20) 50]),'Normalization','pdf');
plot(sxin,syout,'-g');

syout = gampdf(sxin,phat(1),phat(2));
plot(sxin,syout,'-r');
hold off;
xlim([0 5*SingleMoleculeBleachingResults(numofexps+2,9)]);


subplot(1,4,3);
title('Initial Particle Intensity')
xlabel('Number of fluorophores')
ylabel('count')
hold on;
histogram(allnumoffluor,'BinLimits',[0,5],'BinWidth',0.1);
hold off;


subplot(1,4,4);
title('Signal To Noise')
xlabel('Step Height/Std.Dev.(residiual)')
ylabel('count')
hold on;
histogram(snr,min([round(size(allbleachtimes,2)/20) 50]));
hold off;
saveas(gcf,[pathname,'Pooled_Fits.tif']);
