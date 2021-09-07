
%Read in Data
myJim = JIM_Commands();
fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,filesep];
myData = arrayfun(@(x) JIM_Data([x.folder,filesep]),dir([fileName,filesep,'**',filesep,'Channel_1_Fluorescent_Intensities.csv']),'UniformOutput',false);
NumberOfFiles=size(myData,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

%% Step Fit Data
poppingChannel = 1;
stepfitIterations = 10000;
for i=1:NumberOfFiles
myData{i} = myData{i}.parseSingleStepData(myJim.singleStepfit(myData{i}.traces{poppingChannel},stepfitIterations));
end
%%
secondStep = myData;
for i=1:NumberOfFiles
    for j=1:max(size(secondStep{i}.traces))
        secondStep{i}.traces{j} = cell(size(secondStep{i}.traces{j},1),1);
        for k=1:size(secondStep{i}.traces{j},1)
            secondStep{i}.traces{j}{k} = myData{i}.traces{j}(k,min(myData{i}.stepData.stepTimes(k)+3,end-3):end);
        end
    end
    secondStep{i} = secondStep{i}.parseSingleStepData(myJim.singleStepfit(secondStep{i}.traces{poppingChannel},stepfitIterations));
end
%%
    fileToCheck = 1;
    pageNumber = 1;
    
    figure('Name','Single Step Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    for i=1:36
        if i+36*(pageNumber-1)<size(myData{fileToCheck}.traces{1},1)
            subplot(6,6,i)
            hold on
            %%title(['No. ' num2str(selectedData.formerPos(i+36*(pageNumber-1),1)) ' P1 ' num2str(round(selectedData.stepData.noStepProb(i+36*(pageNumber-1)),2,'significant')) ' R ' num2str(round(selectedData.stepData.postHeight(i+36*(pageNumber-1))./selectedData.stepData.preHeight(i+36*(pageNumber-1)),2,'significant')) ' P2 ' num2str(round(selectedData.stepData.moreStepProb(i+36*(pageNumber-1)),2,'significant'))])
            plot(myData{fileToCheck}.traces{1}(i+36*(pageNumber-1),:),'-r');
            plot([0 size(myData{fileToCheck}.traces{1}(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+1 myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+3+secondStep{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+4+secondStep{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) size(myData{fileToCheck}.traces{1},2)],...
                [myData{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.postHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.postHeight(i+36*(pageNumber-1))] ,'-blue');
            hold off
        end
    end

%% 3) View Single Step Filters
    fileToCheck = 1;
    pageNumber = 1;
    
    minFirstStepProb = 0.5;
    maxSecondMeanFirstMeanRatio=0.25;
    maxMoreStepProb=0.99;
    
    
    singleStepTraceQ = myData{fileToCheck}.stepData.noStepProb>minFirstStepProb & myData{fileToCheck}.stepData.preHeight>0 & abs(myData{fileToCheck}.stepData.postHeight) < maxSecondMeanFirstMeanRatio .* myData{fileToCheck}.stepData.preHeight & myData{fileToCheck}.stepData.moreStepProb<maxMoreStepProb;
    
    selectedData = JIM_Data(myData{fileToCheck},singleStepTraceQ);
    excludedData = JIM_Data(myData{fileToCheck},~singleStepTraceQ);
    
    figure('Name','Single Step Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    for i=1:36
        if i+36*(pageNumber-1)<size(selectedData.traces{1},1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(selectedData.formerPos(i+36*(pageNumber-1),1)) ' P1 ' num2str(round(selectedData.stepData.noStepProb(i+36*(pageNumber-1)),2,'significant')) ' R ' num2str(round(selectedData.stepData.postHeight(i+36*(pageNumber-1))./selectedData.stepData.preHeight(i+36*(pageNumber-1)),2,'significant')) ' P2 ' num2str(round(selectedData.stepData.moreStepProb(i+36*(pageNumber-1)),2,'significant'))])
            plot(selectedData.traces{1}(i+36*(pageNumber-1),:),'-r');
            plot([0 size(selectedData.traces{1}(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 selectedData.stepData.stepTimes(i+36*(pageNumber-1)) selectedData.stepData.stepTimes(i+36*(pageNumber-1))+1 size(selectedData.traces{1},2)],[selectedData.stepData.preHeight(i+36*(pageNumber-1)) selectedData.stepData.preHeight(i+36*(pageNumber-1)) selectedData.stepData.postHeight(i+36*(pageNumber-1)) selectedData.stepData.postHeight(i+36*(pageNumber-1))] ,'-blue');
            hold off
        end
    end
    
        figure('Name','Excluded Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    for i=1:36
        if i+36*(pageNumber-1)<size(excludedData.traces{1},1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(excludedData.formerPos(i+36*(pageNumber-1),1)) ' P1 ' num2str(round(excludedData.stepData.noStepProb(i+36*(pageNumber-1)),2,'significant')) ' R ' num2str(round(excludedData.stepData.postHeight(i+36*(pageNumber-1))./excludedData.stepData.preHeight(i+36*(pageNumber-1)),2,'significant')) ' P2 ' num2str(round(excludedData.stepData.moreStepProb(i+36*(pageNumber-1)),2,'significant'))])
            plot(excludedData.traces{1}(i+36*(pageNumber-1),:),'-r');
            plot([0 size(excludedData.traces{1}(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 excludedData.stepData.stepTimes(i+36*(pageNumber-1)) excludedData.stepData.stepTimes(i+36*(pageNumber-1))+1 size(excludedData.traces{1},2)],[excludedData.stepData.preHeight(i+36*(pageNumber-1)) excludedData.stepData.preHeight(i+36*(pageNumber-1)) excludedData.stepData.postHeight(i+36*(pageNumber-1)) excludedData.stepData.postHeight(i+36*(pageNumber-1))] ,'-blue');
            hold off
        end
    end
    
%% Filter all Traces
selectedData = cell(NumberOfFiles,1);

for fileToCheck=1:NumberOfFiles
    singleStepTraceQ = myData{fileToCheck}.stepData.noStepProb>minFirstStepProb & myData{fileToCheck}.stepData.preHeight>0 & abs(myData{fileToCheck}.stepData.postHeight) < maxSecondMeanFirstMeanRatio .* myData{fileToCheck}.stepData.preHeight & myData{fileToCheck}.stepData.moreStepProb<maxMoreStepProb;
    selectedData{fileToCheck} = JIM_Data(myData{fileToCheck},singleStepTraceQ);
end

%%

%%
   
    


    