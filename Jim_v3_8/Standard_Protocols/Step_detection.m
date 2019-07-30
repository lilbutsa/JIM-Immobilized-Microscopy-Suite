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
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_traces.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_traces.csv']];
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
    
    
%% 4) Plot example traces
pagenumber = 4;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(traces(i+36*(pagenumber-1),:),'-r');
    plot([0 size(traces(i+36*(pagenumber-1),:),2)],[0 0] ,'-b');
    hold off
end
filtertracesbool = false;
%% run this if you want to select certain traces
tracestoselect = [4 45 54 57 82 98 99];
filtertracesbool = true;
%% run this regardless
if filtertracesbool
    filteredtraces = traces(tracestoselect,:);
else
    filteredtraces = traces;
end
%% 4) Plot selected traces
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(filteredtraces(i+36*(pagenumber-1),:),'-r');
    plot([0 size(filteredtraces(i+36*(pagenumber-1),:),2)],[0 0] ,'-b');
    hold off
end
%% step fit traces
singleintensity = 23685;
threshold = 0.1;

allmeans = [];
diffmeans = [];

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:size(filteredtraces,1)
    tracein = filteredtraces(i,:)'./singleintensity;
    normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
    steps = findchangepts(normedtrace,'MinThreshold', threshold, 'Statistic', 'mean');
    if size(steps,1)>0
        means = zeros(size(steps,1)+1,1);
        steplinex = zeros(2.*size(means,1),1);
        stepliney = zeros(2.*size(means,1),1);
        means(1) = mean(tracein(1:steps(1)));
        means(size(means,1)) = mean(tracein(1+steps(size(steps,1)):end));
        
        steplinex(1) = 0;
        steplinex(2) = steps(1);
        steplinex(2*size(means,1)-1) = steps(size(steps,1));
        steplinex(2*size(means,1)) = size(tracein,1);
        
        for j=2:size(steps,1)
            means(j) = mean(tracein(1+steps(j-1):steps(j)));
            steplinex(2*j-1) = steps(j-1);
            steplinex(2*j) = steps(j);

        end
        
        for j=1:size(means,1)
            stepliney(2*j-1) = means(j);
            stepliney(2*j) = means(j);
        end
        
    else
        means = mean(tracein);
        steplinex = [0 size(tracein,1)];
        stepliney = [mean(tracein) mean(tracein)];
    end
    
    allmeans = [allmeans;means];
    diffmeans = [diffmeans;diff(means)];
    
    if i < 37
        subplot(6,6,i)
        hold on
        plot(tracein,'-r');
        plot([0 size(tracein,1)],[0 0] ,'-b');
        plot(steplinex,stepliney,'-g');
        hold off
    end
end
%%
histogram(allmeans,20)

histogram(diffmeans,20)

















