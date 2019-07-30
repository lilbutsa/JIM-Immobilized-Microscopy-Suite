%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = false;

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
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']];
                 channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Flourescent_Intensities.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']];
             channel2 = [channel2 [pathname,allfiles(i).name,'\Channel_2_Flourescent_Intensities.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%% 3) Extract Traces
filetocheck = 1;
    traces1=csvread(channel1{filetocheck},1);
    numparticles = size(traces1,1);
    numframes = size(traces1,2);
    traces2=csvread(channel2{filetocheck},1);

    
%% 4) Plot example traces
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:9
    subplot(3,3,i)
    hold on
    plot(traces1(i+36*(pagenumber-1),:),'-r');
    plot(traces2(i+36*(pagenumber-1),:),'-b');
    plot([0 size(traces1(i+36*(pagenumber-1),:),2)],[0 0] ,'-black');
    hold off
end