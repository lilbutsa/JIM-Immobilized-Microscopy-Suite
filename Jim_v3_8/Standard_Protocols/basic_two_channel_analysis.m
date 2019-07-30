clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = true;

channel1 = {};
channel2 = {};

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
                channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_traces.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_traces.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_traces.csv']];
            channel2 = [channel2 [pathname,allfiles(i).name,'\Channel_2_traces.csv']];
        end 
    end
end

numofexps = size(channel1,2);
disp(['There are ',num2str(numofexps),' files to analyze']);
%% 3) Extract Concentrations
Concentrationunits = 'nM';

concentration = [];

for i=1:numofexps
    channelin = channel1(i);
    found = regexp(channelin{1},['\d+\.?\d+',Concentrationunits,'*'],'match');
    if size(found,2)==0
        found=regexp(channelin{1},['\d',Concentrationunits,'*'],'match');
    end
    found = found(1);
    found = found{1};
    conout = regexp(found,['\d+\.?\d*'],'match');
    concentration = [concentration str2double(conout{1})];
end

disp(concentration);

%% 4) Manual Input
concentration = [100,75,50,100,50,25,10,25,10,7.5,5,2.5,7.5,5,2.5];

%% Example traces
filetocheck = 1;

    channelin = channel1(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces1 = zeros(numparticles,numframes);
    for j=1:numparticles
        traces1(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    channelin = channel2(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces2 = zeros(numparticles,numframes);
    for j=1:numparticles
        traces2(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    %% 4) Plot example traces
pagenumber = 3;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(traces1(i+36*(pagenumber-1),:),'-r');
    plot(traces2(i+36*(pagenumber-1),:),'-b');
    plot([0 size(traces1(i+36*(pagenumber-1),:),2)],[0 0] ,'-black');
    hold off
end

%% mean trace
figure
hold on
plot(mean(traces1),'-r');
plot(mean(traces2),'-b');
hold off


%% 5) Step Fit
poptime = [];
initmean = [];
stepheight = [];
singlesteptrace = [];
singlesteptrace2 = [];
stepmeans=[];
snr = [];
for i=1:size(traces1,1)
    tracein = traces1(i,:)';
    normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
    steps = findchangepts(normedtrace,'MinThreshold', 0.3, 'Statistic', 'mean');
    if size(steps,1)==1
        meanhigh = mean(tracein(1:steps));
        meanlow = mean(tracein(1+steps:end));
        if 0.8*meanhigh<(meanhigh-meanlow) 
            poptime = [poptime steps];
            stepheight = [stepheight meanhigh-meanlow];
            singlesteptrace = [singlesteptrace tracein];
            stepmeans = [stepmeans; [meanhigh meanlow]];
            singlesteptrace2 = [singlesteptrace2 traces2(i,:)'];
            snr = [snr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])]; 
        end
    end
end
%% 6) Plot single step traces
pagenumber = 6;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(singlesteptrace(:,i+36*(pagenumber-1)),'-r');
    plot([0 size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[0 0] ,'-b');
    plot([0 poptime(i+36*(pagenumber-1)) poptime(i+36*(pagenumber-1)) size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),2) stepmeans(i+36*(pagenumber-1),2)] ,'-black');
    plot(singlesteptrace2(:,i+36*(pagenumber-1)),'-g');
    hold off
end

%%
singlemolintensity = 158.*30./200;

popintensity = zeros(size(poptime,2),1);
for i = 1:size(poptime,2)
    popintensity(i,1) = 100./concentration(filetocheck).*singlesteptrace2(poptime(1,i),i)/singlemolintensity;
end

histogram(popintensity,30)

%% check all
filetocheck = 6;

    channelin = channel1(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces1 = zeros(numparticles,numframes);
    for j=1:numparticles
        traces1(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    channelin = channel2(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    traces2 = zeros(numparticles,numframes);
    for j=1:numparticles
        traces2(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    poptime = [];
    initmean = [];
    stepheight = [];
    singlesteptrace = [];
    singlesteptrace2 = [];
    stepmeans=[];
    snr = [];
    for i=1:size(traces1,1)
        tracein = traces1(i,:)';
        normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
        steps = findchangepts(normedtrace,'MinThreshold', 0.3, 'Statistic', 'mean');
        if size(steps,1)==1
            meanhigh = mean(tracein(1:steps));
            meanlow = mean(tracein(1+steps:end));
            if 0.8*meanhigh<(meanhigh-meanlow) 
                poptime = [poptime steps];
                stepheight = [stepheight meanhigh-meanlow];
                singlesteptrace = [singlesteptrace tracein];
                stepmeans = [stepmeans; [meanhigh meanlow]];
                singlesteptrace2 = [singlesteptrace2 traces2(i,:)'];
                snr = [snr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])]; 
            end
        end
    end
    singlemolintensity = 160.*30./200;

    popintensity = zeros(size(poptime,2),1);
    for i = 1:size(poptime,2)
        popintensity(i,1) = 100./concentration(filetocheck).*singlesteptrace2(poptime(1,i),i)/singlemolintensity;
    end

    histogram(popintensity,30)
%%
meanvals = [];
figure
hold on
toplot = [];
for filetocheck=1:numofexps
    channelin = channel2(filetocheck);
    d1=csvread(channelin{1},1);
    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;
    
        traces2 = zeros(numparticles,numframes);
    for j=1:numparticles
        traces2(j,:) = d1(d1(:,1)==j-1,19);
    end
    
    meanvals = [meanvals median(mean(traces1)).*100./concentration(filetocheck)./singlemolintensity];
    meantrace = mean(traces1).*100./concentration(filetocheck)./singlemolintensity;
    meantrace = meantrace(1:60);
    toplot = [toplot;meantrace];
    plot(meantrace);
end
hold off
figure
scatter(concentration,toplot(:,60));
%%
scatter(concentration,toplot(:,60));