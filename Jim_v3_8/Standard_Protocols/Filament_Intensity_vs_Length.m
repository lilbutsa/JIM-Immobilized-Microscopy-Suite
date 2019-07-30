%%
clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = false;

channel1 = {};
measurements = {};

allfiles = dir(pathname);
allfiles(~[allfiles.isdir]) = [];
allfiles=allfiles(3:end);

if insubfolders
    for i=1:size(allfiles,1)
        innerfolder = dir([pathname,allfiles(i).name,'\']);
        innerfolder(~[innerfolder.isdir]) = [];
        innerfolder=innerfolder(3:end);
        for j=1:size(innerfolder,1)
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']];
                measurements = [measurements [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Positions_Filtered_Measurements.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_traces.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_traces.csv']];
            measurements = [measurements [pathname,allfiles(i).name,'\Filtered_Expanded_Measurements.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%% 3) Extract Traces
filetocheck = 1;


    channelin = channel1(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces = zeros(numparticles,numframes);
    for j=1:numparticles
        traces(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    channelin = measurements(filetocheck);
    d1 = csvread(channelin{1},1);
    lengths = 2.*d1(:,4);
 %% calculate mean traces and lengths in nm
 scalefactor = 0.0866; % um per pixel
 diffractionlimit = 0.2;
 
 scaledlengths = scalefactor.*lengths-2*diffractionlimit;
 allmeans = mean(traces')';
 
 
 allratios = allmeans./scaledlengths;
%% Fit the mean ratio to a gaussian

sxin = sort(allratios);
syin = 1:size(allratios,1);

syin2 = syin(syin<0.9.*size(allratios,1));
syx = syin2(syin2>0.1.*size(allratios,1));

sxin2=sxin(syin<0.9.*size(allratios,1));
sx = sxin2(syin2>0.1.*size(allratios,1));


sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
OLS = @(b) sum((sy(b,sx) - syx').^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bs = fminsearch(OLS, [size(allratios,1) mean(allratios) std(allratios) 0], opts); 

fitratio = Bs(2);
disp(['Intensity /length ratio fit is ' num2str(fitratio)]);
 %% Sanity check with plot
 figure

set(gcf, 'Position', [100, 100, 1000, 300])

sy2 = @(b,sx)(1/sqrt(2*pi*b(3)*b(3))*exp(-(sx-b(2)).^2./(2*b(3)*b(3)))); 
syout = sy2(Bs,sxin);
subplot(1,2,1);
title('Intensity to Length')
xlabel('Intensity/Length (a.u.)')
ylabel('Probability Density')
hold on;
histogram(allratios,round(size(allratios,1)/5),'Normalization','pdf');
plot(sxin,syout,'-r');
hold off;



subplot(1,2,2);
title('Intensity to Length')
xlabel('Length')
ylabel('Intensity')
hold on;
scatter(scaledlengths,allmeans);
plot([0,max(scaledlengths)],[0,max(scaledlengths).*fitratio],'-r');
hold off;

%% Batch processing for all other images
scalefactor = 0.0866;
monomerintensity = 247;
diffractionlimit = 0.2;


combinedratios = [];
combinedscaledlengths=[];
combinedmeans = [];
indfitratios = [];
indstddev = [];
CombinedMeasurements = zeros(numofexps+2,3);
for filetocheck=1:numofexps
    disp(['Currently Analysing File ',num2str(filetocheck)]);
    channelin = channel1(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces = zeros(numparticles,numframes);
    for j=1:numparticles
        traces(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    channelin = measurements(filetocheck);
    d1 = csvread(channelin{1},1);
    lengths = 2.*d1(:,4);
    
     scaledlengths = scalefactor.*lengths-2*diffractionlimit;
     allmeans = mean(traces')'./monomerintensity;
     allratios = allmeans./scaledlengths;
     
     lograt = log(allratios(allratios>0));
     
     sxin = sort(lograt);
    syin = 1:size(lograt,1);

    syin2 = syin(syin<0.9.*size(lograt,1));
    syx = syin2(syin2>0.1.*size(lograt,1));

    sxin2=sxin(syin<0.9.*size(lograt,1));
    sx = sxin2(syin2>0.1.*size(lograt,1));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx').^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(allratios,1) mean(allratios) std(allratios) 0], opts); 

    fitratio = Bs(2); 
     
     CombinedMeasurements(filetocheck,1) = exp(fitratio);
     CombinedMeasurements(filetocheck,2)  = Bs(3);
     CombinedMeasurements(filetocheck,3)  = numparticles;
     
     combinedscaledlengths = [combinedscaledlengths scaledlengths'];
     combinedratios = [combinedratios allratios'];
     combinedmeans = [combinedmeans allmeans'];
end

    CombinedMeasurements(numofexps+1,:) = mean(CombinedMeasurements(1:numofexps,:));

    lograt = log(combinedratios(combinedratios>0));
    
    sxin = sort(lograt);
    syin = 1:size(lograt,1);

    syin2 = syin(syin<0.9.*size(lograt,1));
    syx = syin2(syin2>0.1.*size(lograt,1));

    sxin2=sxin(syin<0.9.*size(lograt,1));
    sx = sxin2(syin2>0.1.*size(lograt,1));


    sy = @(b,sx)(2*b(1)*(1+erf((sx-b(2))/(b(3)*sqrt(2))))+b(4));            % Objective function
    OLS = @(b) sum((sy(b,sx) - syx').^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bs = fminsearch(OLS, [size(combinedratios,1) mean(lograt) std(lograt) 0], opts); 

    fitratio = Bs(2); 
     
     CombinedMeasurements(numofexps+2,1) = exp(fitratio);
     CombinedMeasurements(numofexps+2,2)  = Bs(3);
     CombinedMeasurements(numofexps+2,3)  = size(combinedscaledlengths,2);
    %% Final plot for everything
figure

set(gcf, 'Position', [100, 100, 1700, 300])

sy2 = @(b,sx)(1/sqrt(2*pi*b(3)*b(3))*exp(-(sx-b(2)).^2./(2*b(3)*b(3)))); 
syout = sy2(Bs,sxin);
subplot(1,4,1);
title('Log Normal Fluorophores to Length')
xlabel('Log(Fluorophores/Length)')
ylabel('Probability Density')
hold on;

%histogram(combinedratios,round(size(combinedratios,2)/100),'Normalization','pdf');
histogram(lograt,round(size(combinedratios,2)/100),'Normalization','pdf');
plot(sxin,syout,'-r');
hold off;

sxin = sort(combinedratios);
sy2 = @(b,sx)(1./(sx.*sqrt(2*pi*b(3)*b(3))).*exp(-(log(sx)-b(2)).^2./(2*b(3)*b(3)))); 
syout = sy2(Bs,sxin);
subplot(1,4,2);
title('Fluorophores to Length')
xlabel('Fluorophores/Length')
ylabel('Probability Density')
hold on;
histogram(combinedratios,round(size(combinedratios,2)/10),'Normalization','pdf');
plot(sxin,syout,'-r');
xlim([0 200000/monomerintensity])
ylim([0,inf])
hold off;

subplot(1,4,3);
hold on
title('Intensity to Length')
xlabel('Length')
ylabel('Fluorophores')
zlabel('Count');
h=histogram2(combinedscaledlengths,combinedmeans)
h.FaceColor = 'flat';
xlim([0 2.5])
ylim([0,250000/monomerintensity])
zlim([0,600])
view(-20, 60);
hold off;

subplot(1,4,4);
title('Linear Fit')
xlabel('Length')
ylabel('Fluorophores')
hold on;
histogram2(combinedscaledlengths,combinedmeans,'DisplayStyle','tile');
plot([0,max(combinedscaledlengths)],[0,max(combinedscaledlengths).*exp(fitratio)],'-r');
xlim([0 2.5])
ylim([0,250000/monomerintensity])
hold off;

f=figure;
set(gcf, 'Position', [100, 100, 1300, 300])
t=uitable(f,'Data',CombinedMeasurements,'Position', [0, 0, 1300, 300]);
t.ColumnName = {'Fluorophore per um', 'Std. Dev.', 'Count'};
t.RowName = num2cell([1:numofexps+1]);
t.RowName(numofexps+1) = {'Mean'};
t.RowName(numofexps+2) = {'Pooled'};

%%
cypalengths = scaledlengths;
%% Plotting histogram of length
figure
%histogram(scaledlengths,round(size(scaledlengths,1)/10),'Normalization','pdf');
boxplot([scaledlengths cypalengths]);
xlabel('Lengths (um)')
ylabel('Probability')
disp(['mean = ' num2str(mean(scaledlengths))]);
disp(['median = ' num2str(median(scaledlengths))]);
disp(['mean = ' num2str(mean(cypalengths))]);
disp(['median = ' num2str(median(cypalengths))]);