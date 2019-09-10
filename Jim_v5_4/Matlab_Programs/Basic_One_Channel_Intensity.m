
%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
JIM = [fileparts(jimpath),'\Jim_Programs\'];%Convert to the file path for the C++ Jim Programs
[filename,pathname] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze
completename = [pathname,filename];
[~,name,~] = fileparts(completename);%get the name of the tiff image excluding the .tiff extension
workingdir = [pathname,name];
[~,name,~] = fileparts(workingdir);%also remove the .ome if it exists or any other full stops
workingdir = [pathname,name,'\'];

tracefile = [workingdir ,'\Channel_1_Flourescent_Intensities.csv'];

%% 3) Extract Traces

    traces1=csvread(tracefile,1);
    numparticles = size(traces1,1);
    numframes = size(traces1,2);
%% 4) Plot example traces
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(traces1(i+36*(pagenumber-1),:),'-r');
    plot([0 size(traces1(i+36*(pagenumber-1),:),2)],[0 0] ,'-black');
    hold off
end
%%
figure
histogram(traces1(:,1),100)
%%
initthreshold = 2500;
threstraces = traces1(traces1(:,1)>initthreshold,:);
%% 4) Plot example that are above zero at start
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    subplot(6,6,i)
    hold on
    plot(threstraces(i+36*(pagenumber-1),:),'-r');
    plot([0 size(threstraces(i+36*(pagenumber-1),:),2)],[0 0] ,'-black');
    hold off
end
%%
figure
hold on
plot(mean(threstraces))
ylim([0 1.1*max(mean(threstraces))]);
hold off
%%
figure
hold on;
histogram(mean(threstraces,2),50);
hold off;