%%
clear
%% 1) Select Input Folder
numberOfChannels = 3;

sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep]; 

sysVar.allFiles = dir(fullfile(sysVar.fileName, '**\*.*'));
sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true),1:length(sysVar.allFiles));

sysVar.allFiles = arrayfun(@(z)sysVar.allFiles(z).folder,find(sysVar.toselect),'UniformOutput',false)';

clear("allData");
for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    for i=1:numberOfChannels
        allData(j).intensityFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
        allData(j).backgroundFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
        allData(j).bleachCorrectedFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Corrected.csv'];
        allData(j).bleachFitFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Fit.csv'];
        allData(j).stepPointsFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepPoints.csv'];
        allData(j).stepMeansFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepMeans.csv'];
    end
end

NumberOfFiles=length(sysVar.allFiles);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

%%
bleachCorrectChannel = 1;
meanBleachFrame = 21.06*65/10;%362*2;%
parfor fileNo=1:length(allData)
    

    traces = csvread(allData(fileNo).intensityFileNames{bleachCorrectChannel},1);

    disp([fileNo,size(traces,1) ,size(traces,2)]);

    Amat = zeros(length(traces(1,:)),length(traces(1,:)));
    for i=1:length(traces(1,:))
        for j=1:i
            Amat(i,j) = exp((j-i)./meanBleachFrame);
        end
    end

    correctedSteps = cell2mat(arrayfun(@(z) lsqnonneg(Amat,traces(z,:)') ,1:size(traces,1),'UniformOutput' ,false))';

    bleachCorrected = cumsum(correctedSteps')';

    bleachFit = cell2mat(arrayfun(@(z) Amat*(correctedSteps(z,:)') ,1:size(traces,1),'UniformOutput' ,false))';

    outputString = ['Each row is a particle. Each column is a Frame,Bleach Corrected With Mean Bleach Frame =,' num2str(meanBleachFrame) '\n ' strjoin(arrayfun(@(z) strjoin(arrayfun(@num2str,bleachCorrected(z,:),'UniformOutput',false),','),1:size(bleachCorrected,1),'UniformOutput',false),'\n')];

    fileID = fopen(allData(fileNo).bleachCorrectedFileNames{bleachCorrectChannel},'w');
    fprintf(fileID, outputString);
    fclose(fileID);


    outputString = ['Each row is a particle. Each column is a Frame,Bleach Corrected With Mean Bleach Frame =,' num2str(meanBleachFrame) '\n ' strjoin(arrayfun(@(z) strjoin(arrayfun(@num2str,bleachFit(z,:),'UniformOutput',false),','),1:size(bleachFit,1),'UniformOutput',false),'\n')];


    fileID = fopen(allData(fileNo).bleachFitFileNames{bleachCorrectChannel},'w');
    fprintf(fileID, outputString);
    fclose(fileID);

end

%%
fileNo=1;
traces = csvread(allData(fileNo).intensityFileNames{bleachCorrectChannel},1);
bleachFit = csvread(allData(fileNo).bleachFitFileNames{bleachCorrectChannel},1);
bleachCorrected = csvread(allData(fileNo).bleachCorrectedFileNames{bleachCorrectChannel},1);

traceNo = 11;
figure
hold on
plot(traces(traceNo,:))
plot(bleachFit(traceNo,:))
plot(bleachCorrected(traceNo,:))
hold off
%%
allSteps = correctedSteps(:);
allSteps = allSteps(allSteps>0.0001);
figure
histogram(allSteps)
disp(mean(allSteps))
