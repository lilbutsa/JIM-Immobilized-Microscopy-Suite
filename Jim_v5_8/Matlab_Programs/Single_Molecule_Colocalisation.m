clear
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
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']];
                 channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Fluorescent_Intensities.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']];
             channel2 = [channel2 [pathname,allfiles(i).name,'\Channel_2_Fluorescent_Intensities.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);

%% for channel 1
channel1min = -500;
channel1lowercutoff = 5000;
channel1uppercutoff = 15000;
channel1max = 20000;
figure
hold on

channel1deltastep = (channel1max-channel1min)/50;
for i=1:numofexps
    d1=csvread(channel1{i},1);
    numparticles = size(d1,1);

    xintensityin = zeros(numparticles,1);
    xintensityin(:,1) = mean(d1,2);  
    counts = histcounts(xintensityin,channel1min:channel1deltastep:channel1max, 'Normalization', 'probability');
    plot(channel1min+channel1deltastep/2:channel1deltastep:channel1max-channel1deltastep/2,counts)
    
end
plot([channel1lowercutoff channel1lowercutoff],ylim,'-r')
plot([channel1uppercutoff channel1uppercutoff],ylim,'-r')
xlim([channel1min channel1max])
hold off

%% for channel 2
channel2min = -3000;
channel2lowercutoff = 1000;
channel2uppercutoff = 1500;
channel2max = 2000;
figure
hold on

channel2deltastep = (channel2max-channel2min)/50;
for i=1:numofexps
    
    d2=csvread(channel2{i},1);

    numparticles = size(d2,1);

    yintensityin = zeros(numparticles,1);
    yintensityin(:,1) = mean(d2,2);
    
    counts = histcounts(yintensityin,channel2min:channel2deltastep:channel2max, 'Normalization', 'probability');
    plot(channel2min+channel2deltastep/2:channel2deltastep:channel2max-channel2deltastep/2,counts)
    
end
plot([channel2lowercutoff channel2lowercutoff],ylim,'-r')
plot([channel2uppercutoff channel2uppercutoff],ylim,'-r')
xlim([channel2min channel2max])
hold off
%% check scatterplot
xintensityin=[];
yintensityin = [];

for i=1:numofexps
    d1=csvread(channel1{i},1);  
    d2=csvread(channel2{i},1);

    numparticles = size(d2,1);

    xintensityin = [xintensityin;mean(d1,2)];
    
    yintensityin =[yintensityin; mean(d2,2)];
       
end

figure
hold on
histogram2(xintensityin,yintensityin,channel1min:channel1deltastep:channel1max,channel2min:channel2deltastep:channel2max,'DisplayStyle','tile');
xlim([channel1min channel1max])
ylim([channel2min channel2max])
plot([channel1lowercutoff channel1lowercutoff],ylim,'-r')
plot([channel1uppercutoff channel1uppercutoff],ylim,'-r')
plot(xlim,[channel2lowercutoff channel2lowercutoff],'-r')
plot(xlim,[channel2uppercutoff channel2uppercutoff],'-r')
hold off




%% calculate colocalisation
% Areas are numbered as
%   7|8|9
%   - - -
%   4|5|6
%   - - - 
%   1|2|3

colocal =  zeros(numofexps,9);

for i=1:numofexps
    d1=csvread(channel1{i},1);  
    d2=csvread(channel2{i},1);

    numparticles = size(d2,1);
    
    xintensityin = zeros(numparticles,1);
    xintensityin(:,1) = mean(d1,2);
    
    yintensityin = zeros(numparticles,1);
    yintensityin(:,1) = mean(d2,2);
    
    colocal(i,1) = size(xintensityin(xintensityin<channel1lowercutoff & yintensityin<channel2lowercutoff),1);
    colocal(i,2) = size(xintensityin(xintensityin>channel1lowercutoff & xintensityin<channel1uppercutoff & yintensityin<channel2lowercutoff),1);
    colocal(i,3) = size(xintensityin( xintensityin>channel1uppercutoff & yintensityin<channel2lowercutoff),1);
    colocal(i,4) = size(xintensityin(xintensityin<channel1lowercutoff & yintensityin>channel2lowercutoff & yintensityin<channel2uppercutoff),1);
    colocal(i,5) = size(xintensityin(xintensityin>channel1lowercutoff & xintensityin<channel1uppercutoff & yintensityin>channel2lowercutoff & yintensityin<channel2uppercutoff),1);
    colocal(i,6) = size(xintensityin(xintensityin>channel1uppercutoff & yintensityin>channel2lowercutoff & yintensityin<channel2uppercutoff),1);
    colocal(i,7) = size(xintensityin(xintensityin<channel1lowercutoff & yintensityin>channel2uppercutoff),1);
    colocal(i,8) = size(xintensityin(xintensityin>channel1lowercutoff & xintensityin<channel1uppercutoff & yintensityin>channel2uppercutoff),1);
    colocal(i,9) = size(xintensityin( xintensityin>channel1uppercutoff & yintensityin>channel2uppercutoff),1);
end
%% 3) Extract Concentrations/timepoints
timepointunit = 'tp';

timepoints = [];

for i=1:numofexps
    found = regexp(channel1{i},[timepointunit,'\d+\.?\d+','*'],'match');
    if size(found,2)==0
        found=regexp(channel1{i},[timepointunit,'\d','*'],'match');
    end
    found = found(1);
    found = found{1};
    conout = regexp(found,['\d+\.?\d*'],'match');
    timepoints = [timepoints str2double(conout{1})];
end

disp(timepoints);

%% OR manually input timepoints
timepoints =[1 2 3 4];

%%
percentcolocal = colocal(:,5)./(colocal(:,2)+colocal(:,5));
percentcolocalt = [timepoints;percentcolocal']';
percentcolocalt = sortrows(percentcolocalt);
figure
%scatter(timepoints,percentcolocal)
scatter(percentcolocalt(:,1)-1,percentcolocalt(:,2))
ylim([0,1])

%%
csvwrite([pathname,'Colocalisation.csv'],colocal);
csvwrite([pathname,'PercentColocalisation.csv'],percentcolocalt);