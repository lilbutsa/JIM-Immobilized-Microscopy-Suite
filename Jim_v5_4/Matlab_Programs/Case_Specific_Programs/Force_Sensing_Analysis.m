clear
%% Batch analyse all files

pathname = uigetdir(); % open the dialog box to select the folder for batch files
pathname=[pathname,'\'];
%%

insubfolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder
workingpathlist = [];
if insubfolders
    allfiles = dir(pathname); % find everything in the input folder
    allfiles(~[allfiles.isdir]) = []; % filter for folders
    allfiles=allfiles(3:end);
    allfilescells = arrayfun(@(y) arrayfun(@(x) [pathname,y.name,'\',x.name],[dir([pathname,y.name,'\*.tif']); dir([pathname,y.name,'\*.tiff'])]','UniformOutput',false),allfiles','UniformOutput',false); % look in each folder and pull out all files that end in tif or tiff
    allfilescells = horzcat(allfilescells{:})'; % combine the files from all folders into one list
    filenum=size(allfilescells,1);
else
    allfiles = [dir([pathname,'\*.tif']); dir([pathname,'\*.tiff'])];% find everything in the main folder ending in tiff or tif
    allfilescells = arrayfun(@(y) [pathname,y.name],allfiles,'UniformOutput',false); % generate a full path name for each file
    filenum=size(allfilescells,1);
end

for i=1:length(allfilescells)
    completename = allfilescells{i};
    [pathnamein,name,~] = fileparts(completename);%get the name of the tiff image
    workingdir = [pathnamein,'\',name];
    [pathnamein,name,~] = fileparts(workingdir);
    workingdir = [pathnamein,'\',name,'\Kymographs\Kymograph_Analysis\AllOutlines.csv'];
        workingpathlist = [workingpathlist;convertCharsToStrings(workingdir)];

end

%%


pixelsize = 110;
framerate = 10;
flowrate = 10;%ul/min
%%
difftab = [];
nucpos = [];

for filenum = 1:length(workingpathlist)

    datain = csvread(workingpathlist(filenum),0,0);


    for i=1:size(datain,1)
        datacut = datain(i,datain(i,:)>1);
        diffsin = [pixelsize./1000.*flowrate.*9.07.*0.00061.*(length(datacut)-2:-1:0);1./diff(datacut).*pixelsize./framerate]';
        diffsin = diffsin(round(0.1*size(diffsin,1)):round(0.9*size(diffsin,1)),:);
        difftab = [difftab;diffsin];
        [~,firstnuc]=min(datacut);
        firstnuc = firstnuc/length(datacut);
        nucpos = [nucpos firstnuc];
    end
end
%%
figure
plot(datacut)
%%
tnuc = nucpos';
%%
figure
histogram(nucpos,[0.1:0.1:0.9])
%%
regdifftab = difftab(abs(difftab(:,2))<35,:);
figure 
histogram(regdifftab(:,2),50)
%%
posdifftab = difftab(difftab(:,2)>0,:);
negdifftab = difftab(difftab(:,2)<0,:);
figure
hold on
scatter(posdifftab(:,1),posdifftab(:,2))
scatter(negdifftab(:,1),negdifftab(:,2))
ylim([-15 15]);
hold off


%%
deltabin = 0.25;
binwidths = 0.25:deltabin:2;
medians = zeros(length(binwidths),2);
counts = zeros(length(binwidths),2);
for i=1:length(binwidths)
    regdifftab = difftab(difftab(:,1)>binwidths(i)&difftab(:,1)<binwidths(i)+deltabin&abs(difftab(:,2))<35,:);
    medians(i,1) = median(regdifftab(regdifftab(:,2)>0,2));
    medians(i,2) = median(regdifftab(regdifftab(:,2)<0,2));
    counts(i,1) = size(regdifftab(regdifftab(:,2)>0,2),1);
    counts(i,2) = size(regdifftab(regdifftab(:,2)<0,2),1);
end
%%
figure('Name', 'Force vs Growth rate')
hold on
plot((binwidths+deltabin/2),medians(:,1))
plot((binwidths+deltabin/2),-medians(:,2))
ylim([0 12])
hold off
%%
figure('Name', 'Count for Force Bins')
hold on
plot((binwidths+deltabin/2),counts(:,1))
plot((binwidths+deltabin/2),counts(:,2))
hold off