
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
%% Make initial iGFP Results table
%Conditions: First Pop intensity ratio<0.5, Std dev Mid post residual / 2nd step <0.8,Std dev(level 2)/mean(level2) < 1
     
maxstepratio = 0.5;
maxsecondstepresidual = 0.8;
maxlvl2relativestd = 1;

backgroundThreshold = 0.03;
residualSignalThreshold = 0.08;

iGFPResults = cell(NumberOfFiles,1);
resultsHeadings = {'Class ', 'First step time', 'second step time', 'pre height', 'mid height', 'post height',  '1st step prob', '2nd step prob','mid/post residual std dev/ second step height','std(level2)/mean(level2)'};
%classes 1 = leaky, 2 = closed 3 = opening
for i=1:NumberOfFiles
     fileResults= zeros(size(myData{i}.traces{1},1),10);
    
     fileResults(:,2) = myData{i}.stepData.stepTimes;
     fileResults(:,3) = myData{i}.stepData.stepTimes+3+secondStep{i}.stepData.stepTimes;
     fileResults(:,4) = myData{i}.stepData.preHeight;
     fileResults(:,5) = secondStep{i}.stepData.preHeight;
     fileResults(:,6) = secondStep{i}.stepData.postHeight;
     fileResults(:,7) = myData{i}.stepData.noStepProb;
     fileResults(:,8) = secondStep{i}.stepData.noStepProb;
     fileResults(:,9) = secondStep{i}.stepData.residualStdDev./(fileResults(:,5)-fileResults(:,6));
     traces = myData{i}.traces{1};
     fileResults(:,10) = arrayfun(@(x) std(traces(x,fileResults(x,2):fileResults(x,3)))/mean(traces(x,fileResults(x,2):fileResults(x,3))),1:size(traces,1));

     
     fileResults(fileResults(:,5)<maxstepratio.*fileResults(:,4) & fileResults(:,6)<maxstepratio.*fileResults(:,5) & fileResults(:,5)<maxstepratio.*fileResults(:,4) & fileResults(:,9)<maxsecondstepresidual & fileResults(:,10)<maxlvl2relativestd,1) = 3;     
     
     fileResults(fileResults(:,5)<maxstepratio.*fileResults(:,4) & fileResults(:,5)<backgroundThreshold.*fileResults(:,4),1) = 1;
     
     fileResults(fileResults(:,5)<maxstepratio.*fileResults(:,4) & fileResults(:,6)>residualSignalThreshold.*fileResults(:,4),1) = 2;
     
     
     iGFPResults{i} = fileResults;
end


%% view all traces
    fileToCheck = 1;
    pageNumber = 1;
    
    figure('Name','Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    for i=1:36
        if i+36*(pageNumber-1)<size(myData{fileToCheck}.traces{1},1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(i+36*(pageNumber-1))])
            plot(myData{fileToCheck}.traces{1}(i+36*(pageNumber-1),:),'-r');
            plot([0 size(myData{fileToCheck}.traces{1}(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+1 myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+3+secondStep{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1))+4+secondStep{fileToCheck}.stepData.stepTimes(i+36*(pageNumber-1)) size(myData{fileToCheck}.traces{1},2)],...
                [myData{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) myData{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.preHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.postHeight(i+36*(pageNumber-1)) secondStep{fileToCheck}.stepData.postHeight(i+36*(pageNumber-1))] ,'-blue');
            hold off
        end
    end

%% Class 1 = leaky
    fileToCheck = 1;
    pageNumber = 1;
    
    figure('Name','Leaky Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    fileResults = iGFPResults{fileToCheck};
    traces = myData{fileToCheck}.traces{1};
    traces = traces(fileResults(:,1)==1,:);
    numbers = find(fileResults(:,1)==1);
    fileResults = fileResults(fileResults(:,1)==1,:);

    
    for i=1:36
        if i+36*(pageNumber-1)<size(traces,1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(numbers(i+36*(pageNumber-1)))])
            plot(traces(i+36*(pageNumber-1),:),'-r');
            plot([0 size(traces(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 fileResults(i+36*(pageNumber-1),2) fileResults(i+36*(pageNumber-1),2)+1 fileResults(i+36*(pageNumber-1),3) fileResults(i+36*(pageNumber-1),3)+1 size(traces,2)],...
                [fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),6) fileResults(i+36*(pageNumber-1),6)] ,'-blue');
            hold off
        end
    end
%% Class 2 = closed
    fileToCheck = 1;
    pageNumber = 1;
    
    figure('Name','Closed Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    fileResults = iGFPResults{fileToCheck};
    traces = myData{fileToCheck}.traces{1};
    traces = traces(fileResults(:,1)==2,:);
    numbers = find(fileResults(:,1)==2);
    fileResults = fileResults(fileResults(:,1)==2,:);
    
    
    for i=1:36
        if i+36*(pageNumber-1)<size(traces,1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(numbers(i+36*(pageNumber-1)))])
            plot(traces(i+36*(pageNumber-1),:),'-r');
            plot([0 size(traces(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 fileResults(i+36*(pageNumber-1),2) fileResults(i+36*(pageNumber-1),2)+1 fileResults(i+36*(pageNumber-1),3) fileResults(i+36*(pageNumber-1),3)+1 size(traces,2)],...
                [fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),6) fileResults(i+36*(pageNumber-1),6)] ,'-blue');
            hold off
        end
    end
    %% Class 3 = opening
    fileToCheck = 1;
    pageNumber = 1;
    
    figure('Name','Opening Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])
    fileResults = iGFPResults{fileToCheck};
    traces = myData{fileToCheck}.traces{1};
    traces = traces(fileResults(:,1)==3,:);
    numbers = find(fileResults(:,1)==3);
    fileResults = fileResults(fileResults(:,1)==3,:);
    
    
    for i=1:36
        if i+36*(pageNumber-1)<size(traces,1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(numbers(i+36*(pageNumber-1)))])
            plot(traces(i+36*(pageNumber-1),:),'-r');
            plot([0 size(traces(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 fileResults(i+36*(pageNumber-1),2) fileResults(i+36*(pageNumber-1),2)+1 fileResults(i+36*(pageNumber-1),3) fileResults(i+36*(pageNumber-1),3)+1 size(traces,2)],...
                [fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),4) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),5) fileResults(i+36*(pageNumber-1),6) fileResults(i+36*(pageNumber-1),6)] ,'-blue');
            hold off
        end
    end

    

   
    


    