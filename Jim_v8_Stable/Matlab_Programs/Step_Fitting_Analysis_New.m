clear
%% 1) Select Input Folder
filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
fileEXE = '"';
fileSep = '';
if ismac
    JIM = ['"',fileparts(JIM),'/Jim_Programs_Mac/'];
    fileSep = '/';
elseif ispc
    JIM = ['"',fileparts(JIM),'\Jim_Programs\'];
    fileEXE = '.exe"';
    fileSep = '\';
else
    disp('Platform not supported')
end

fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep]; 

allFolders = arrayfun(@(x)[fileName,x.name],dir(fileName),'UniformOutput',false); % find everything in the input folder
allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
allFolders = allFolders(3:end);
allFolders = arrayfun(@(x)[x{1},fileSep],allFolders,'UniformOutput',false);

if filesInSubFolders
    allSubFolders = allFolders;
    allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allSubFolders,'UniformOutput',false);
    allFolders = arrayfun(@(x)x{:}(3:end),allFolders,'UniformOutput',false);
    allFolders = horzcat(allFolders{:})';
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = arrayfun(@(x)[x{1},fileSep],allFolders,'UniformOutput',false);
end

allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
channel1 = allFiles(contains(allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));
channel2 = allFiles(contains(allFiles,'Channel_2_Fluorescent_Intensities.csv','IgnoreCase',true));
channel1b = allFiles(contains(allFiles,'Channel_1_Fluorescent_Backgrounds.csv','IgnoreCase',true));
channel2b = allFiles(contains(allFiles,'Channel_2_Fluorescent_Backgrounds.csv','IgnoreCase',true));

NumberOfFiles=size(channel1,1);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

Analysis_File = [fileName 'Compiled_Step_Fitting_Analysis' fileSep];
if ~exist(Analysis_File, 'dir')
    mkdir(Analysis_File)%make a subfolder with that name
end

%% View and Filter Trace 
fileToPlot = 1;
pageNumber = 1;
viewSubstrateTrace = false;
viewBinderTrace = true;


singleChannelData = false;
channelOneSubstrate = true;

substrate_photobleaching = 6000;%342;
binder_photobleaching = 6000;

substrateMedianRange = [0.5 1.5];
substrateInitialRange = [-10000 1000000];
substrateFinalRange = [-10000 1000000];
substrateMaxRange = [-10000 1000000];
substrateMinRange = [-10000 1000000];

binderMedianRange = [-10000 1000000];
binderInitialRange = [-10000 1000000];
binderFinalRange = [-10000 1000000];
binderMaxRange = [0.5 2.5];
binderMinRange = [-10000 1000000];


%Don't touch from here

if singleChannelData
    binderTrace = csvread(channel1{fileToPlot},1)./binder_photobleaching;
elseif channelOneSubstrate
    substrateTrace = csvread(channel1{fileToPlot},1)./substrate_photobleaching;
    binderTrace = csvread(channel2{fileToPlot},1)./binder_photobleaching;
else
    substrateTrace = csvread(channel2{fileToPlot},1)./substrate_photobleaching;
    binderTrace = csvread(channel1{fileToPlot},1)./binder_photobleaching;  
end


toselect = median(binderTrace')'>binderMedianRange(1)& median(binderTrace')'<binderMedianRange(2) &...
    binderTrace(:,1)>binderInitialRange(1) & binderTrace(:,1)<binderInitialRange(2) &...
     binderTrace(:,end)> binderFinalRange(1) & binderTrace(:,end)< binderFinalRange(2) &...
     max(binderTrace')' > binderMaxRange(1) & max(binderTrace')' < binderMaxRange(2) &...
     min(binderTrace')' > binderMinRange(1) & min(binderTrace')' < binderMinRange(2);

if ~singleChannelData  
    toselect = toselect & median(substrateTrace')'>substrateMedianRange(1)& median(substrateTrace')'<substrateMedianRange(2) &...
    substrateTrace(:,1)>substrateInitialRange(1) & substrateTrace(:,1)<substrateInitialRange(2) &...
     substrateTrace(:,end)> substrateFinalRange(1) & substrateTrace(:,end)< substrateFinalRange(2) &...
     max(substrateTrace')' > substrateMaxRange(1) & max(substrateTrace')' < substrateMaxRange(2) &...
     min(substrateTrace')' > substrateMinRange(1) & min(substrateTrace')' < substrateMinRange(2);
   
    selectedSubstrateTraces = substrateTrace(toselect,:);
end

selectedBinderTraces = binderTrace(toselect,:);


figure
for i=36*(pageNumber-1)+1:36*(pageNumber)
    if i>size(selectedBinderTraces,1)
        break;
    end
    h = subplot(6,6,i-36*(pageNumber-1));
    hold on
    if viewBinderTrace
        h.ColorOrderIndex=1;
        if viewSubstrateTrace
            plot(selectedBinderTraces(i,:)./max(selectedBinderTraces(i,:)),'linewidth',2);
        else
            plot(selectedBinderTraces(i,:),'linewidth',2);
        end
    end  
    
    if viewSubstrateTrace
        h.ColorOrderIndex=2;
        if viewBinderTrace
            plot(selectedSubstrateTraces(i,:)./max(selectedSubstrateTraces(i,:)),'linewidth',2);
        else
            plot(selectedSubstrateTraces(i,:),'linewidth',2);
        end
    end     
        

    plot([0 size(selectedBinderTraces(i,:),1)],[0 0] ,'-black','linewidth',1);
    hold off
end


%% Filter All Traces and Step Fit Traces

stepfitThreshold = 0.025;
stepfitIterations = 10000;
minAbsStepHeight = 0.5;

stepfitfilenames = cell(NumberOfFiles,1);
for i=1:NumberOfFiles
    fileout = [fileparts(channel1{i}),fileSep,'Selected_Binder_Traces.csv'];
    stepfitfilenames{i} = [fileparts(channel1{i}),fileSep,'Stepfit_Step_Fits.csv'];
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame. Traces remaining after Single Molecule normalization and Filtering for step fitting');
    fclose(fid);
    
    
    if singleChannelData
        binderTrace = csvread(channel1{i},1)./binder_photobleaching;
    elseif channelOneSubstrate
        substrateTrace = csvread(channel1{i},1)./substrate_photobleaching;
        binderTrace = csvread(channel2{i},1)./binder_photobleaching;
    else
        substrateTrace = csvread(channel2{i},1)./substrate_photobleaching;
        binderTrace = csvread(channel1{i},1)./binder_photobleaching;  
    end


    toselect = median(binderTrace')'>binderMedianRange(1)& median(binderTrace')'<binderMedianRange(2) &...
        binderTrace(:,1)>binderInitialRange(1) & binderTrace(:,1)<binderInitialRange(2) &...
         binderTrace(:,end)> binderFinalRange(1) & binderTrace(:,end)< binderFinalRange(2) &...
         max(binderTrace')' > binderMaxRange(1) & max(binderTrace')' < binderMaxRange(2) &...
         min(binderTrace')' > binderMinRange(1) & min(binderTrace')' < binderMinRange(2);

    if ~singleChannelData  
        toselect = toselect & median(substrateTrace')'>substrateMedianRange(1)& median(substrateTrace')'<substrateMedianRange(2) &...
        substrateTrace(:,1)>substrateInitialRange(1) & substrateTrace(:,1)<substrateInitialRange(2) &...
         substrateTrace(:,end)> substrateFinalRange(1) & substrateTrace(:,end)< substrateFinalRange(2) &...
         max(substrateTrace')' > substrateMaxRange(1) & max(substrateTrace')' < substrateMaxRange(2) &...
         min(substrateTrace')' > substrateMinRange(1) & min(substrateTrace')' < substrateMinRange(2);

        selectedSubstrateTraces = substrateTrace(toselect,:);
    end

    selectedBinderTraces = binderTrace(toselect,:);
    
    dlmwrite(fileout,selectedBinderTraces,'-append');
    cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',fileout,'" "',fileparts(channel1{i}),fileSep,'Stepfit" -Threshold ',num2str(stepfitThreshold),' -Iterations ',num2str(stepfitIterations),' -minStepHeight ',num2str(minAbsStepHeight)];
    system(cmd);
end
disp('Step fitting Complete');

%% Read in and View Step Fits
fileToPlot = 4;
pageNumber = 1;

inputSteps = csvread(stepfitfilenames{fileToPlot},1);

if singleChannelData
    binderTrace = csvread(channel1{fileToPlot},1)./binder_photobleaching;
elseif channelOneSubstrate
    substrateTrace = csvread(channel1{fileToPlot},1)./substrate_photobleaching;
    binderTrace = csvread(channel2{fileToPlot},1)./binder_photobleaching;
else
    substrateTrace = csvread(channel2{fileToPlot},1)./substrate_photobleaching;
    binderTrace = csvread(channel1{fileToPlot},1)./binder_photobleaching;  
end


toselect = median(binderTrace')'>binderMedianRange(1)& median(binderTrace')'<binderMedianRange(2) &...
    binderTrace(:,1)>binderInitialRange(1) & binderTrace(:,1)<binderInitialRange(2) &...
     binderTrace(:,end)> binderFinalRange(1) & binderTrace(:,end)< binderFinalRange(2) &...
     max(binderTrace')' > binderMaxRange(1) & max(binderTrace')' < binderMaxRange(2) &...
     min(binderTrace')' > binderMinRange(1) & min(binderTrace')' < binderMinRange(2);

if ~singleChannelData  
    toselect = toselect & median(substrateTrace')'>substrateMedianRange(1)& median(substrateTrace')'<substrateMedianRange(2) &...
    substrateTrace(:,1)>substrateInitialRange(1) & substrateTrace(:,1)<substrateInitialRange(2) &...
     substrateTrace(:,end)> substrateFinalRange(1) & substrateTrace(:,end)< substrateFinalRange(2) &...
     max(substrateTrace')' > substrateMaxRange(1) & max(substrateTrace')' < substrateMaxRange(2) &...
     min(substrateTrace')' > substrateMinRange(1) & min(substrateTrace')' < substrateMinRange(2);
   
    selectedSubstrateTraces = substrateTrace(toselect,:);
end

selectedBinderTraces = binderTrace(toselect,:);

figure
for i=36*(pageNumber-1)+1:36*(pageNumber)
    if i>size(selectedBinderTraces,1)
        break;
    end
    h = subplot(6,6,i-36*(pageNumber-1));
    hold on
    h.ColorOrderIndex=1;
    plot(selectedBinderTraces(i,:),'linewidth',2);
    plot(inputSteps(i,:),'linewidth',2);
    plot([0 size(selectedBinderTraces(i,:),1)],[0 0] ,'-black');
    hold off
end
%% Select Relevant steps
pageNumber = 2;

ignoreLessThan = -1000;
ignoreGreaterThan = 1000;

% stepIntensityRange = [-0.5 0.5];
% prevStepIntensityRange = [0.5 1.5];
% nextStepIntensityRange = [0.5 1.5];
% initialStepHeightRange = [-1.5 -0.5];
% finalStepHeightRange = [0.5 1.5];
% allPrevIntensityRange = [-5 5];
% allFutureIntensityRange = [-5 5];

stepIntensityRange = [0.5 1.5];
prevStepIntensityRange = [-0.5 0.5];
nextStepIntensityRange = [-0.5 0.5];
initialStepHeightRange = [0.5 1.5];
finalStepHeightRange = [-1.5 -0.5];
allPrevIntensityRange = [-5 5];
allFutureIntensityRange = [-5 5];




allSteptimeDistribution = cell(NumberOfFiles,1);
allStepHeightDistribution = cell(NumberOfFiles,1);
for fileNo = 1:NumberOfFiles

    inputSteps = csvread(stepfitfilenames{fileNo},1);

    stepDetect = diff(inputSteps')';
    stepTimes = arrayfun(@(x)find(stepDetect(x,:)~=0)+1,1:size(stepDetect,1),'UniformOutput',false)';
    stepHeights = arrayfun(@(x)stepDetect(x,stepDetect(x,:)~=0),1:size(stepDetect,1),'UniformOutput',false)';
    stepTimes = arrayfun(@(x)stepTimes{x}(stepHeights{x} > ignoreLessThan & stepHeights{x} < ignoreGreaterThan),1:size(stepDetect,1),'UniformOutput',false)';
    stepHeights = arrayfun(@(x)stepHeights{x}(stepHeights{x} > ignoreLessThan & stepHeights{x} < ignoreGreaterThan),1:size(stepDetect,1),'UniformOutput',false)';
    stepIntensity = arrayfun(@(x)inputSteps(x,[1 stepTimes{x}]),1:size(stepDetect,1),'UniformOutput',false)';
    stepDeltaTimes = arrayfun(@(x)diff(find(stepDetect(x,:)~=0)),1:size(stepDetect,1),'UniformOutput',false)';

    selectedSteps = arrayfun(@(x)intersect(intersect(intersect(intersect(intersect(intersect(...
        find(stepIntensity{x}>stepIntensityRange(1) & stepIntensity{x}<stepIntensityRange(2)),...
        find(stepIntensity{x}>prevStepIntensityRange(1) & stepIntensity{x}<prevStepIntensityRange(2))+1),...
        find(stepIntensity{x}>nextStepIntensityRange(1) & stepIntensity{x}<nextStepIntensityRange(2))-1),...
        find(cummax(stepIntensity{x})>allPrevIntensityRange(1) & cummax(stepIntensity{x})<allPrevIntensityRange(2))+1),...
        find(fliplr(cummax(fliplr(stepIntensity{x})))>allFutureIntensityRange(1) & fliplr(cummax(fliplr(stepIntensity{x})))<allFutureIntensityRange(2))-1),...
        find(stepHeights{x}>initialStepHeightRange(1) & stepHeights{x}<initialStepHeightRange(2))+1),...
        find(stepHeights{x}>finalStepHeightRange(1) & stepHeights{x}<finalStepHeightRange(2))),1:size(stepDetect,1),'UniformOutput',false)';
    steptimeDistribution = arrayfun(@(x)stepDeltaTimes{x}(selectedSteps{x}-1),1:size(stepDetect,1),'UniformOutput',false);
    steptimeDistribution =cell2mat(steptimeDistribution(arrayfun(@(x)min(size(steptimeDistribution{x})),1:size(stepDetect,1))>0))';
    selectedStepHeights = arrayfun(@(x)stepHeights{x}(selectedSteps{x}-1),1:size(stepDetect,1),'UniformOutput',false);
    selectedStepHeights =cell2mat(selectedStepHeights(arrayfun(@(x)min(size(selectedStepHeights{x})),1:size(stepDetect,1))>0))';

    selectedSteps2 =[];
    for i=1:size(selectedSteps,1)
        stepTimes{i} = [1 stepTimes{i} size(selectedBinderTraces,2)];
        stepsin = selectedSteps{i};
        if size(stepsin,1)==0
            continue;
        end
        for j = 1:size(stepsin,2)
            selectedSteps2 = [selectedSteps2;[i stepsin(j)]];
        end
    end
    
    allSteptimeDistribution{fileNo} = steptimeDistribution; 
    allStepHeightDistribution{fileNo} = selectedStepHeights;
    
    if fileNo == fileToPlot
        figure
        for i=36*(pageNumber-1)+1:36*(pageNumber)
            if i>size(selectedSteps2,1)
                break
            end
            h = subplot(6,6,i-36*(pageNumber-1));
            hold on
            h.ColorOrderIndex=1;
            plot(selectedBinderTraces(selectedSteps2(i,1),stepTimes{selectedSteps2(i,1)}(selectedSteps2(i,2)-1):stepTimes{selectedSteps2(i,1)}(selectedSteps2(i,2)+2)-1),'linewidth',2);
            plot(inputSteps(selectedSteps2(i,1),stepTimes{selectedSteps2(i,1)}(selectedSteps2(i,2)-1):stepTimes{selectedSteps2(i,1)}(selectedSteps2(i,2)+2)-1),'linewidth',2);
            %plot(inputSteps(i,:),'linewidth',2);
            %plot([0 size(selectedBinderTraces(i,:),1)],[0 0] ,'-black');
            hold off
        end
    end
end
%% Combine results
resultsFileNamePrefix = 'SeparateOffRate';
groupNames = {'1 nM','2.5 nM','5 nM','10 nM','17.5 nM','25 nM'};

groupNumber= [1 2 3 4 5 6];
secondsPerFrame = [0.5 0.5 0.5 0.5 0.5 0.5];

combinedSteptimeDistribution = cell(max(groupNumber),1);
combinedStepHeightDistribution = cell(max(groupNumber),1);
for fileNo = 1:NumberOfFiles
    combinedStepHeightDistribution{groupNumber(fileNo)} = [combinedStepHeightDistribution{groupNumber(fileNo)}; allStepHeightDistribution{fileNo}];
    combinedSteptimeDistribution{groupNumber(fileNo)} = [combinedSteptimeDistribution{groupNumber(fileNo)}; allSteptimeDistribution{fileNo}.*secondsPerFrame(fileNo)];
end
%% Fit Step times
expYMaxPercent = 0.9;
expYMinPercent = 0;

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Intesity"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
xlabel('Time (s)');
ylabel('Remaining Steps (%)')

fileout = [fileName resultsFileNamePrefix '_Survival_Curves.csv'];
filein = [fileName resultsFileNamePrefix];    
fid = fopen(fileout,'w'); 
fprintf(fid,'%s\n','Each First Line is the concentration, Each Second Line is Binding Intensity');
fclose(fid);
    
maxX = max(arrayfun(@(x)prctile(combinedSteptimeDistribution{x},95),1:size(combinedSteptimeDistribution,1)));
 
for fileNo = 1:size(groupNames,2)
    x = sort(combinedSteptimeDistribution{fileNo}');
    y = (size(x,2):-1:1);
    
    dlmwrite(fileout,x,'-append');   
    dlmwrite(fileout,y,'-append');
    
    plot(x,y.*100./size(x,2),'Linewidth',2)
end
xlim([0 maxX]);
ylim([0 100]);

cmd = [JIM,'Exponential_Fit',fileEXE,' "',fileout,'" "',filein,'" -ymaxPercent ',num2str(expYMaxPercent),' -yminPercent ',num2str(expYMinPercent)];
system(cmd);
expFits = csvread([filein,'_ExpFit.csv'],1,0);

ax = gca;
ax.ColorOrderIndex = 1;

for fileNo = 1:size(groupNames,2)
    x = 0:maxX;
    y = (expFits(fileNo,1)+expFits(fileNo,2).*exp(-expFits(fileNo,3).*x)).*100./size(combinedSteptimeDistribution{fileNo},1);
    plot(x,y,'--','Linewidth',2)
    
end

set(gca,'Layer','top')
leg = legend(groupNames,'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([fileName resultsFileNamePrefix 'Step_Time_Fits'], '-dpng', '-r600');
print([fileName resultsFileNamePrefix 'Step_Time_Fits'], '-depsc', '-r600');


%% Plot step rate versus concentration 
concentrations = [1 2.5 5 10 17.5 25];
withConstantOffset = true;
xaxisLabel = 'Concentration (nM)';

x = concentrations;
y = expFits(:,3);
if withConstantOffset
    a = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(size(x,2).*dot(x,x)-sum(x).*sum(x));
    b = (dot(x,y).*size(x,2)-sum(x).*sum(y))/(size(x,2).*dot(x,x)-sum(x).*sum(x));
else
    a = 0;
    b = dot(x,y)./dot(x,x);
end  
    
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Intesity"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
xlabel(xaxisLabel);
ylabel('Step Rate (1/s)')
scatter(x,y,'filled')
plot(0:max(x), a+b.*[0:max(x)],'Linewidth',2);
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([fileName resultsFileNamePrefix 'Step_Rate_Linear_Fit'], '-dpng', '-r600');
print([fileName resultsFileNamePrefix 'Step_Rate_Linear_Fit'], '-depsc', '-r600');
%% Plot Step Height Distribution
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Intesity"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
xlabel('Step Height (molecules)');
ylabel('Probability (PDF)')

fileout = [fileName resultsFileNamePrefix '_Step_Heights.csv'];
filein = [fileName resultsFileNamePrefix];
fid = fopen(fileout,'w'); 
fprintf(fid,'%s\n','Each Line is the step heights from a combined result');
fclose(fid);
for fileNo = 1:size(groupNames,2)
    dlmwrite(fileout,combinedStepHeightDistribution{fileNo}','-append');
end
cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
system(cmd);    
hists = csvread([filein,'_Histograms.csv'],1,0);
for fileNo = 1:size(groupNames,2)
    plot(hists(1+2*(fileNo-1),:),hists(2+2*(fileNo-1),:),'LineWidth',2)
end

set(gca,'Layer','top')
leg = legend(groupNames,'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([fileName resultsFileNamePrefix 'Step_Height_Distribution'], '-dpng', '-r600');
print([fileName resultsFileNamePrefix 'Step_Height_Distribution'], '-depsc', '-r600');
%% writeout results table
