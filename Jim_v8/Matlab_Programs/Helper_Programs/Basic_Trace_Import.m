%%
clear
%% 1) Select Input Folder
numberOfChannels = 3;

sysVar.fileName = uigetdir('Z:\Upasana\James_3-channel_titration_13032026\'); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep]; 

sysVar.allFiles = dir(fullfile(sysVar.fileName, '**\*.*'));
sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true),1:length(sysVar.allFiles));

sysVar.allFiles = arrayfun(@(z)sysVar.allFiles(z).folder,find(sysVar.toselect),'UniformOutput',false)';

for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    allData(j).stepPoints = cell(numberOfChannels,1);
    allData(j).stepMeans = cell(numberOfChannels,1);
    for i=1:numberOfChannels
        allData(j).intensityFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
        allData(j).backgroundFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
        allData(j).stepPointsFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepPoints.csv'];
        allData(j).stepMeansFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepMeans.csv'];
        allData(j).bleachCorrectedFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Corrected.csv'];
        allData(j).bleachFitFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Fit.csv'];
    end
end

NumberOfFiles=length(sysVar.allFiles);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select the folder to save output images to
sysVar.fileName = uigetdir(sysVar.fileName); % open the dialog box to select the folder for batch files
saveFolder=[sysVar.fileName,filesep];

%% detect experiment settings

concentrationIdentifier = {'_40pM','_60pM','_80pM','_100pM','_150pM', '_200pM', '_250pM'};
concentrations = [40 60 80 100 150 200 250];

secondsPerFrameIdentifier = {'_20spf','_18spf','_3spf','_1spf'};
secondsPerFrame = [20 18 3 1];

reagentIdentifier = {'_Batch3_'};
singleMoleculeIntensities = [1 1 559*10/65];% have one for each channel, each line is for each reagent/rep, set it to one to just keep it as camera intensity


%replicateIdentifier = arrayfun(@(z) ['P' num2str(z) '_'] ,1:40 ,'UniformOutput' ,false);
replicateIdentifier = {'Rep1','Rep3', 'Rep4', 'Rep5', 'Rep6', 'Rep7'};

for i=1:NumberOfFiles
    for j=1:length(concentrationIdentifier)
        if contains(allData(i).intensityFileNames(1),concentrationIdentifier(j),'IgnoreCase',true) 
            allData(i).concentration = concentrations(j);
            allData(i).expNo = j;
            break;
        end
    end
    for j=1:length(secondsPerFrameIdentifier)
        if contains(allData(i).intensityFileNames(1),secondsPerFrameIdentifier(j),'IgnoreCase',true) 
            allData(i).SPF = secondsPerFrame(j);
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*j;
            break;
        end
    end
    for j=1:length(reagentIdentifier)
        if contains(allData(i).intensityFileNames(1),reagentIdentifier(j),'IgnoreCase',true) 
            allData(i).reagent = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(secondsPerFrameIdentifier)*j;
            break;
        end
    end
    for j=1:length(replicateIdentifier)
        if contains(allData(i).intensityFileNames(1),replicateIdentifier(j),'IgnoreCase',true) 
            allData(i).rep = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(secondsPerFrameIdentifier)*length(reagentIdentifier)*j;
            break;
        end
    end
end

% Group FOV from the same experiment and read in data
sysVar.detectedExps = sort(unique([allData.expNo]));
numOfExps = length(sysVar.detectedExps);
for i=1:numOfExps
    expData(i).reagent = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).reagent;
    expData(i).concentration = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).concentration;
    expData(i).SPF = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).SPF;
    expData(i).replicate = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).rep;

    expData(i).allTraces = cell(numberOfChannels,1);
    expData(i).allBleachCorrectedTraces = cell(numberOfChannels,1);
    expData(i).allBackgrounds = cell(numberOfChannels,1);
    expData(i).allStepMeans = cell(numberOfChannels,1);
    expData(i).allStepPoints = cell(numberOfChannels,1);
    expData(i).allNumOfSteps = cell(numberOfChannels,1);
    expData(i).allStepHeights = cell(numberOfChannels,1);
    expData(i).allStepTraces = cell(numberOfChannels,1);


    for j=1:numberOfChannels
        
        sysVar.allNumberOfFrames = arrayfun(@(z) size(csvread(allData(z).intensityFileNames{j},1),2),find([allData.expNo]==sysVar.detectedExps(i)));
        sysVar.maxFrames = max(sysVar.allNumberOfFrames);

        expData(i).allTraces{j} = cell2mat(arrayfun(@(z) padarray(csvread(allData(z).intensityFileNames{j},1),[0 max(sysVar.maxFrames-size(csvread(allData(z).intensityFileNames{j},1),2),0)],NaN,'post')',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,j);
        expData(i).numOfTraces = size(expData(i).allTraces{1},1);
        expData(i).numOfFrames = size(expData(i).allTraces{1},2);

        if exist(allData(1).bleachCorrectedFileNames{j}, 'file')
            expData(i).allBleachCorrectedTraces{j} = cell2mat(arrayfun(@(z) padarray(csvread(allData(z).bleachCorrectedFileNames{j},1),[0 max(sysVar.maxFrames-size(csvread(allData(z).bleachCorrectedFileNames{j},1),2),0)],NaN,'post')',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,j);

        end

        if exist(allData(1).bleachFitFileNames{j}, 'file')
            expData(i).bleachFitTraces{j} = cell2mat(arrayfun(@(z) padarray(csvread(allData(z).bleachFitFileNames{j},1),[0 max(sysVar.maxFrames-size(csvread(allData(z).bleachFitFileNames{j},1),2),0)],NaN,'post')',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,j);
        end


        if exist(allData(1).stepPointsFileNames{j}, 'file')
            sysVar.temp = arrayfun(@(z) csvread(allData(z).stepMeansFileNames{j},1),find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false)';
            sysVar.maxsize = max(arrayfun(@(z)size(sysVar.temp{z},2),1:length(sysVar.temp)));
            expData(i).allStepMeans{j} = cell2mat(arrayfun(@(z)resize(sysVar.temp{z},[size(sysVar.temp{z},1) sysVar.maxsize]),1:length(sysVar.temp),'UniformOutput',false)')./singleMoleculeIntensities(expData(i).reagent,j);

            sysVar.temp = arrayfun(@(z) csvread(allData(z).stepPointsFileNames{j},1),find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false)';
            sysVar.maxsize = max(arrayfun(@(z)size(sysVar.temp{z},2),1:length(sysVar.temp)));
            expData(i).allStepPoints{j} = cell2mat(arrayfun(@(z)resize(sysVar.temp{z},[size(sysVar.temp{z},1) sysVar.maxsize]),1:length(sysVar.temp),'UniformOutput',false)');

            sysVar.temp = expData(i).allStepMeans{j};
            expData(i).allStepHeights{j} = cell2mat(arrayfun(@(z) resize(diff(sysVar.temp(z,sysVar.temp(z,:)~=0)),[1 size(sysVar.temp,2)-1]),1:expData(i).numOfTraces,'UniformOutput',false)');
            expData(i).allNumOfSteps{j} = arrayfun(@(z) nnz(sysVar.temp(z,:))-1,1:length(sysVar.temp));

            traces = expData(i).allTraces{j};
            stepPoints = expData(i).allStepPoints{j};
            stepMeans = expData(i).allStepMeans{j};
            for traceNo = 1:size(traces,1)
                count = 0;
                for k=1:size(traces,2)
                    if ismember(k-1,stepPoints(traceNo,:))
                        count = count +1;
                    end
                    traces(traceNo,k) = stepMeans(traceNo,count);
                end
            end
            expData(i).allStepTraces{j} = traces;
        end
    end
    
end