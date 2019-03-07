%%
clear
%% 1) get the working folder
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [fileparts(jimpath),'\Jim_Programs\'];
pathname = uigetdir();
pathname=[pathname,'\'];

%% 2) Find all traces
insubfolders = true;

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
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);

%% Step Fit all experiments
parfor i=1:numofexps
    disp(['Step Fitting Experiment ' num2str(i)]);
    cmd = [JIM,'Change_Point_Analysis.exe "',channel1{i},'" "',fileparts(channel1{i}),'\Stepfit" -FitSingleSteps'];
    system(cmd);
end

%% Check individual File
    filetocheck = 2;

    traces=csvread(channel1{filetocheck},1);
    stepsdata = csvread([fileparts(channel1{filetocheck}) '\Stepfit_Single_Step_Fits.csv'],1);
    
%% Print example traces
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

%% Show single stepfits
    pagenumber = 3;
    
    stepheight = stepsdata(:,4)-stepsdata(:,5);
    steptime = stepsdata(:,3); 
    
    selection = stepheight>0.8.*stepsdata(:,5)&stepsdata(:,2)>0.6&stepheight>0;
    bleachheights = stepheight(selection);
    bleachtime = steptime(selection);
    %run for each trace
    ftraces = traces(selection,:);
    allmax = stepsdata(selection,4);
    allmin = stepsdata(selection,5);
    
    snr = [];
    for i=1:size(ftraces,1)
        tracein =  ftraces(i,:)';
        snr = [snr;bleachheights(i)./std([(tracein(1:bleachtime(i))-stepsdata(i,4)); tracein(1+bleachtime(i):end)-stepsdata(i,5)])]; 
    end
    
    figure
    set(gcf, 'Position', [100, 100, 1500, 800])

    for i=1:36
        subplot(6,6,i)
        hold on
        plot(ftraces(i+36*(pagenumber-1),:),'-r');
        plot([0 size(ftraces(i+36*(pagenumber-1),:),2)],[0 0] ,'-b');
        plot([0 bleachtime(i+36*(pagenumber-1)) bleachtime(i+36*(pagenumber-1)) size(ftraces(i+36*(pagenumber-1),:),2)],[allmax(i+36*(pagenumber-1)) allmax(i+36*(pagenumber-1)) allmin(i+36*(pagenumber-1)) allmin(i+36*(pagenumber-1))] ,'-black');
        hold off
    end
    
    
%% Fit single file 
    
    tofit = bleachtime';
    bxin = sort(tofit);
    byin = size(tofit,2):-1:1;
    byin2 = byin(byin<0.9.*size(tofit,2));
    byx = byin2(byin2>0.01.*size(tofit,2));
    bxin2=bxin(byin<0.9.*size(tofit,2));
    bx = bxin2(byin2>0.01.*size(tofit,2));


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [0 size(tofit,2) 3/max(tofit)], opts);

    tofit = bleachheights';
    sxin = sort(tofit);
    syin = 1:size(tofit,2);

    syin2 = syin(syin<0.9.*size(tofit,2));
    syx = syin2(syin2>0.001.*size(tofit,2));

    sxin2=sxin(syin<0.9.*size(tofit,2));
    sx = sxin2(syin2>0.001.*size(tofit,2));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(tofit,2) mean(tofit) std(tofit) 0], opts); 
    
    phat = gamfit(tofit);
    
    numofflour = mean(traces(:,1:5)')./(phat(1)*phat(2)-phat(2));    
    
    
%% Plot Single file
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
histogram(bleachheights,0:max(sxin2)/30:2*max(sxin2),'Normalization','pdf');
plot(sxin,syout,'-g');
syout = gampdf(sxin,phat(1),phat(2));
plot(sxin,syout,'-r');
xlim([0 2*max(sxin2)])
hold off;


subplot(1,4,3);
title('Initial Particle Intensity')
xlabel('Number of fluorophores')
ylabel('count')
hold on;
histogram(numofflour,'BinLimits',[0,5],'BinWidth',0.1);
hold off;


subplot(1,4,4);
title('Signal To Noise')
xlabel('Step Height/Std.Dev.(residiual)')
ylabel('count')
hold on;
histogram(snr,min([round(size(bleachtime,1)/20) 50]));
hold off;


%% Analyse all files
SingleMoleculeBleachingResults = zeros(numofexps+2,15);
allbleachtimes = [];
allbleachheights = [];
allsnr = [];
allinitvals = [];
for filetocheck = 1:numofexps

    traces=csvread(channel1{filetocheck},1);
    stepsdata = csvread([fileparts(channel1{filetocheck}) '\Stepfit_Single_Step_Fits.csv'],1);

    stepheight = stepsdata(:,4)-stepsdata(:,5);
    steptime = stepsdata(:,3); 
    onestepprob = (1-stepsdata(:,6)).*(1-stepsdata(:,7));
    
    selection = stepheight>0.8.*stepsdata(:,5)&stepsdata(:,2)>0.6&stepheight>0;
    bleachheights = stepheight(selection);
    bleachtime = steptime(selection);
    allbleachheights = [allbleachheights;bleachheights];
    allbleachtimes = [allbleachtimes;bleachtime];
    
    allinitvals = [allinitvals;mean(traces(:,1:5),2)];
    
    %run for each trace
    ftraces = traces(selection,:);
    stepsdata = stepsdata(selection,:);
    snr = [];
    for i=1:size(ftraces,1)
        tracein =  ftraces(i,:)';
        snr = [snr;bleachheights(i)./std([(tracein(1:bleachtime(i))-stepsdata(i,4)); tracein(1+bleachtime(i):end)-stepsdata(i,5)])]; 
    end
    allsnr = [allsnr;snr];
    
    
    tofit = bleachtime';
    bxin = sort(tofit);
    byin = size(tofit,2):-1:1;
    byin2 = byin(byin<0.9.*size(tofit,2));
    byx = byin2(byin2>0.01.*size(tofit,2));
    bxin2=bxin(byin<0.9.*size(tofit,2));
    bx = bxin2(byin2>0.01.*size(tofit,2));


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [0 size(tofit,2) 3/max(tofit)], opts);

    sxin = sort(bleachheights);
    syin = 1:size(bleachheights,2);

    syin2 = syin(syin<0.9.*size(bleachheights,2));
    syx = syin2(syin2>0.001.*size(bleachheights,2));

    sxin2=sxin(syin<0.9.*size(bleachheights,2));
    sx = sxin2(syin2>0.001.*size(bleachheights,2));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(bleachheights,2) mean(bleachheights) std(bleachheights) 0], opts); 
    
    phat = gamfit(bleachheights);
    
    numofflour = mean(traces(:,1:5)')./(phat(1)*phat(2)-phat(2));
    
    SingleMoleculeBleachingResults(filetocheck,1) = size(numofflour,2);
    SingleMoleculeBleachingResults(filetocheck,2) = size(bleachheights,1);
    
    SingleMoleculeBleachingResults(filetocheck,3) = Bb(3);
    SingleMoleculeBleachingResults(filetocheck,4) = log(2)/Bb(3);
    SingleMoleculeBleachingResults(filetocheck,5) = log(10/9)/Bb(3);
    
    SingleMoleculeBleachingResults(filetocheck,6) = mean(bleachheights);
    SingleMoleculeBleachingResults(filetocheck,7) = median(bleachheights);
    SingleMoleculeBleachingResults(filetocheck,8) = std(bleachheights);
    
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
    
    tofit = allbleachtimes';
    bxin = sort(tofit);
    byin = size(tofit,2):-1:1;
    byin2 = byin(byin<0.9.*size(tofit,2));
    byx = byin2(byin2>0.01.*size(tofit,2));
    bxin2=bxin(byin<0.9.*size(tofit,2));
    bx = bxin2(byin2>0.01.*size(tofit,2));

    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [0 size(tofit,2) 3/max(tofit)], opts);

    
    
    tofit = allbleachheights';
    sxin = sort(tofit);
    syin = 1:size(tofit,2);
    syin2 = syin(syin<0.9.*size(tofit,2));
    syx = syin2(syin2>0.001.*size(tofit,2));
    sxin2=sxin(syin<0.9.*size(tofit,2));
    sx = sxin2(syin2>0.001.*size(tofit,2));

    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(tofit,2) mean(tofit) std(tofit) 0], opts); 
    
    phat = gamfit(tofit);
    
    allnumoffluor = allinitvals./(phat(1)*phat(2)-phat(2));
    
    
    SingleMoleculeBleachingResults(numofexps+2,1) = size(allnumoffluor,1);
    SingleMoleculeBleachingResults(numofexps+2,2) = size(allbleachheights,1);
    
    SingleMoleculeBleachingResults(numofexps+2,3) = Bb(3);
    SingleMoleculeBleachingResults(numofexps+2,4) = log(2)/Bb(3);
    SingleMoleculeBleachingResults(numofexps+2,5) = log(10/9)/Bb(3);
    
    SingleMoleculeBleachingResults(numofexps+2,6) = mean(allbleachheights);
    SingleMoleculeBleachingResults(numofexps+2,7) = median(allbleachheights);
    SingleMoleculeBleachingResults(numofexps+2,8) = std(allbleachheights);
    
    
    SingleMoleculeBleachingResults(numofexps+2,9) = phat(1)*phat(2)-phat(2);
    SingleMoleculeBleachingResults(numofexps+2,10) = phat(1)*phat(2);
    SingleMoleculeBleachingResults(numofexps+2,11) = sqrt(phat(1)*phat(2)*phat(2));
    
    
    SingleMoleculeBleachingResults(numofexps+2,12) = Bs(2);
    SingleMoleculeBleachingResults(numofexps+2,13) = Bs(3);
    
    SingleMoleculeBleachingResults(numofexps+2,14) = median(allsnr);
    
    SingleMoleculeBleachingResults(numofexps+2,15) = size(allnumoffluor(allnumoffluor<=0.5),1)/size(allnumoffluor,1);
    SingleMoleculeBleachingResults(numofexps+2,16) = size(allnumoffluor(allnumoffluor>0.5 & allnumoffluor<=1.5),1)/size(allnumoffluor,1);
    SingleMoleculeBleachingResults(numofexps+2,17) = size(allnumoffluor(allnumoffluor>1.5 & allnumoffluor<=2.5),1)/size(allnumoffluor,1);
    SingleMoleculeBleachingResults(numofexps+2,18) = size(allnumoffluor(allnumoffluor>2.5),1)/size(allnumoffluor,1);
   

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
histogram(allbleachheights,[0:max(sxin2)/30:2*max(sxin2)],'Normalization','pdf');
plot(sxin,syout,'-g');
syout = gampdf(sxin,phat(1),phat(2));
plot(sxin,syout,'-r');
xlim([0 2*max(sxin2)])
hold off;


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
histogram(allsnr,min([round(size(allbleachtimes,1)/20) 50]));
hold off;
saveas(gcf,[pathname,'Pooled_Fits.tif']);




    