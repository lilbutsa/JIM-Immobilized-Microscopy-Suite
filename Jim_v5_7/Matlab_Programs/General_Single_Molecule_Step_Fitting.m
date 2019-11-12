%%
clear
%% 1) get the working folder
if ismac
    fileSep = '/';
elseif ispc
    fileSep = '\';
end

fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep];
%% Find all traces
filesInSubFolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

if filesInSubFolders
    allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name,fileSep],dir(cell2mat(y))','UniformOutput',false),dir(fileName),'UniformOutput',false);
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
else
    allFolders = arrayfun(@(x)[fileName,x.name,fileSep],dir(fileName),'UniformOutput',false); % find everything in the input folder
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
end
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
channel1 = allFiles(contains(allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));
NumberOfFiles=size(channel1,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select traces and step fit them
threshold = 1.25;
singleMoleculeIntensity = 16000;

minInitial=-0.5;
maxInitial = 0.5;

minFinal=2;
maxFinal = 20;

minMaxVal = 2; % minimum (max value) a trace need to reach
maxMaxVal = 20; % maximum (max value) a trace can reach

minMinVal = 0.5;% minimum of trace must be less than this
maxMinVal = -3; % maximum of trace must be greater than this

allResults = cell(NumberOfFiles,1);% deltat,  start step height,end step height,mean height
allPosStepDeltaT = cell(NumberOfFiles,1);
allNegStepDeltaT = cell(NumberOfFiles,1);

fileToPlot = 1;
pageNumber = 1;

figure
for expCount=1:NumberOfFiles
   
    traces=csvread(channel1{expCount},1)./singleMoleculeIntensity;
    
    tracesToSelect = max(traces')'>minMaxVal & max(traces')'<maxMaxVal & min(traces')' < minMinVal & min(traces')'>maxMinVal...
        & traces(:,1) > minInitial & traces(:,1) < maxInitial & traces(:,end) > minFinal & traces(:,end) < maxFinal;
    
    filteredTraces = traces(tracesToSelect,:);
    
    expResults = [];
    expPosStepDeltaT = [];
    expNegStepDeltaT = [];
    
    for traceCount = 1:size(filteredTraces,1)
        tracein = filteredTraces(traceCount,:)';
        steps = findchangepts(tracein,'MinThreshold', threshold, 'Statistic', 'mean');
        steps2 = cat(2,[1;steps],[steps-1;size(filteredTraces,2)]);
        means1 = arrayfun(@(x) mean(tracein(steps2(x,1):steps2(x,2))),1:size(steps2,1))';
        stepHeights = diff(means1);
        stepDeltaT = steps2(2:end-1,2)-steps2(2:end-1,1)+1;
        
        if traceCount > 36*(pageNumber-1)&& traceCount <= 36*(pageNumber) && expCount==fileToPlot
            subplot(6,6,traceCount-36*(pageNumber-1))
            hold on
            plot(tracein,'-r');
            plot([0 size(tracein,1)],[0 0] ,'-black');
            plot(reshape(steps2',[],1),reshape(cat(1,means1',means1'),[],1),'-b');
            hold off
        end
        if size(steps,1)>1
            prevMax = arrayfun(@(x) max(tracein(1:steps(x))),1:size(steps,1)-1)';
            resultsin = cat(2,stepDeltaT,stepHeights(1:end-1),stepHeights(2:end),means1(2:end-1),prevMax);% deltat,  start step height,end step height,mean height,previousMaxValue
            expResults = [expResults;resultsin];

            posSteps = steps(stepHeights>0);
            %expPosStepDeltaT = [expPosStepDeltaT;diff(posSteps)];
            expPosStepDeltaT = [expPosStepDeltaT;cat(2,diff(posSteps),arrayfun(@(x) min(tracein(posSteps(x):(posSteps(x+1)-1))),1:(size(posSteps,1)-1))')];
            negSteps = steps(stepHeights<0);
            expNegStepDeltaT = [expNegStepDeltaT;diff(negSteps)];
        end
        
    end
    
    allResults{expCount} = expResults;
    allPosStepDeltaT{expCount} = expPosStepDeltaT;
    allNegStepDeltaT{expCount} = expNegStepDeltaT;
      
end
%% select steps to analyse for lifetime
experimentsToPlot = 7:9;
framesPerSecond = 4;

minMean = 2.5;
maxMean = 3.5;

minPrevMean = -100;
maxPrevMean =100;

minNextMean = -100;
maxNextMean = 100;

minInitialStepHeight = 0;
maxInitialStepHeight = 100;

minFinalStepHeight = 0;
maxFinalStepHeight = 100;

prevMax = 3;


combinedResults = cell2mat(allResults(experimentsToPlot));
combinedResults = combinedResults(combinedResults(:,2)>minInitialStepHeight & combinedResults(:,2)<maxInitialStepHeight ...
    & combinedResults(:,3)>minFinalStepHeight & combinedResults(:,3)<maxFinalStepHeight ...
    & combinedResults(:,4)>minMean & combinedResults(:,4)<maxMean...
    & combinedResults(:,4)-combinedResults(:,2)>minPrevMean & combinedResults(:,4)-combinedResults(:,2)<maxPrevMean...
    & combinedResults(:,4)+combinedResults(:,3)>minNextMean & combinedResults(:,4)+combinedResults(:,3)<maxNextMean & combinedResults(:,5)<prevMax,1);

disp([num2str((minMean+maxMean)/2),' ',num2str(mean(combinedResults)),' ',num2str(framesPerSecond/mean(combinedResults))]);

bxin = sort(combinedResults./framesPerSecond);
byin = size(combinedResults,1):-1:1;


byin2 = byin(byin<1.*size(combinedResults,1));
byx = byin2(byin2>0.25.*size(combinedResults,1));

bxin2=bxin(byin<1.*size(combinedResults,1));
bx = bxin2(byin2>0.25.*size(combinedResults,1))';


by = @(b,bx)( b(1)*exp(-b(2)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(combinedResults,1) 3/max(combinedResults)], opts);

bxin = 0:max(combinedResults);
byxin = by(Bb,bxin);


 figure
 hold on
 plot(sort(combinedResults./framesPerSecond),size(combinedResults,1):-1:1);
 plot(bxin,byxin,'-r');
 xlim([0 20])
 hold off
 
disp(['The Step Rate is ' num2str(Bb(2)) ' per second']);

%% select steps to analyse for stepHeight


%% Analyse time between positive or negative steps



%%
experimentsToPlot = 1:9;
combinedResults = cell2mat(allResults(experimentsToPlot));
%%
histBins = 0:0.1*singleMoleculeIntensity:4*singleMoleculeIntensity;
posStepHistCounts = histcounts(singleMoleculeIntensity.*combinedResults(combinedResults(:,2)>0,2),histBins);
posStepHistCounts = posStepHistCounts./sum(posStepHistCounts);
negStepHistCounts = histcounts(-1.*singleMoleculeIntensity.*combinedResults(combinedResults(:,2)<0,2),histBins);
negStepHistCounts = negStepHistCounts./sum(negStepHistCounts);
firstStepHistCounts = histcounts(singleMoleculeIntensity.*combinedResults(combinedResults(:,2)>0 & combinedResults(:,4)>0.5 & combinedResults(:,4)-combinedResults(:,2)<0.5,2),histBins);
firstStepHistCounts = firstStepHistCounts./sum(firstStepHistCounts);
%%
photobleaching = csvread('G:\Group_Jim_Data\jimilly\Final_Single_Molecule\allnumoffluor_Tpm18.csv',0);
pbhistcounts = histcounts(12600.*photobleaching,histBins);
pbhistcounts = pbhistcounts./sum(pbhistcounts);
%%
figure
hold on
plot(histBins(1:end-1)+ 0.5.*diff(histBins) ,posstephistcounts)
plot(histBins(1:end-1)+ 0.5.*diff(histBins) ,negStepHistCounts)
plot(histBins(1:end-1)+ 0.5.*diff(histBins),firstStepHistCounts)
plot(histBins(1:end-1)+ 0.5.*diff(histBins),pbhistcounts)
xline(singleMoleculeIntensity)
hold off
%%
framesPerSecond = 4;
experimentsToPlot = 4:6;

combinedResults = cell2mat(allPosStepDeltaT(experimentsToPlot));
combinedResults = combinedResults(combinedResults(:,2)>0.5,1);


%%
bxin = sort(combinedResults./framesPerSecond);
byin = size(combinedResults,1):-1:1;


byin2 = byin(byin<0.9.*size(combinedResults,1));
byx = byin2(byin2>0.1.*size(combinedResults,1));

bxin2=bxin(byin<0.9.*size(combinedResults,1));
bx = bxin2(byin2>0.1.*size(combinedResults,1))';


by = @(b,bx)( b(1)*exp(-b(2)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(combinedResults,1) 3/max(combinedResults)], opts);

bxin = 0:max(combinedResults);
byxin = by(Bb,bxin);


 figure
 hold on
 %histogram(posdeltatsteps,50,'Normalization', 'pdf');
 plot(sort(combinedResults./framesPerSecond),size(combinedResults,1):-1:1);
 plot(bxin,byxin,'-r');
 xlim([0 20])
 hold off
 
disp(['The Step Rate is ' num2str(Bb(2)) ' per second']);

%%
framesPerSecond = 4;
experimentsToPlot = 4:6;
combinedResults = cell2mat(allResults(experimentsToPlot));
combinedResults = combinedResults(combinedResults(:,2)>0 & combinedResults(:,4)>0.5 & combinedResults(:,4)-combinedResults(:,2)<0.5,1);
%%

bxin = sort(combinedResults./framesPerSecond);
byin = size(combinedResults,1):-1:1;


byin2 = byin(byin<0.9.*size(combinedResults,1));
byx = byin2(byin2>0.001.*size(combinedResults,1));

bxin2=bxin(byin<0.9.*size(combinedResults,1));
bx = bxin2(byin2>0.001.*size(combinedResults,1))';


by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3)*exp(-b(4)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(combinedResults,1)/2 100/max(combinedResults)  size(combinedResults,1)/2 1/max(combinedResults)], opts);


% by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3)*exp(-0.446*bx));             % Objective function
% OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
% opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
% Bb = fminsearch(OLS, [size(combinedResults,1)/2 0.8  size(combinedResults,1)/2], opts);


bxin = 0:max(combinedResults);
byxin = by(Bb,bxin);


 figure
 hold on
 %histogram(posdeltatsteps,50,'Normalization', 'pdf');
 plot(sort(combinedResults./framesPerSecond),size(combinedResults,1):-1:1);
 plot(bxin,byxin,'-r');
 xlim([0 24])
 hold off
 
disp(['The rate of polymerisation is ' num2str(Bb(2)) ' per second']);