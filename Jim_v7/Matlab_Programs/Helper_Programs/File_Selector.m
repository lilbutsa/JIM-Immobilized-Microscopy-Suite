%%
clear
%% 1) Select Input Folder
numberOfChannels = 2;
stepFitting = true;
stepFitChannel = 1;

filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep]; 

sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
sysVar.allFolders = sysVar.allFolders(3:end);
sysVar.allFolders = arrayfun(@(x)[x{1},filesep],sysVar.allFolders,'UniformOutput',false);

if filesInSubFolders
    sysVar.allSubFolders = sysVar.allFolders;
    sysVar.allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allSubFolders,'UniformOutput',false);
    sysVar.allFolders = arrayfun(@(x)x{:}(3:end),sysVar.allFolders,'UniformOutput',false);
    sysVar.allFolders = horzcat(sysVar.allFolders{:})';
    sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
    sysVar.allFolders = arrayfun(@(x)[x{1},filesep],sysVar.allFolders,'UniformOutput',false);
end

sysVar.allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allFolders','UniformOutput',false);
sysVar.allFiles = horzcat(sysVar.allFiles{:})';

sysVar.allFiles = sysVar.allFiles(contains(sysVar.allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));

allTraceNames = cell(size(sysVar.allFiles,1),2*(numberOfChannels+stepFitting));
for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    for i=1:numberOfChannels
    allData(j).intensityFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
    allData(j).backgroundFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
    end
    if stepFitting
        allData(j).stepPoints = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(stepFitChannel),'_StepPoints.csv'];
        allData(j).stepMeans = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(stepFitChannel),'_StepMeans.csv'];
    end
end

NumberOfFiles=length(allData);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select the folder to save output images to
sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
saveFolder=[sysVar.fileName,filesep];

%% detect experiment settings

concentrationIdentifier = {'_200pM','_500pM'};
concentrations = [200 500];

minutesPerFrameIdentifier = {'120sf'};
minutesPerFrame = [2];

reagentIdentifier = {'FLD_VLP','FLD_Liposome','PFO_VLP','PFO_Liposome'};
singleMoleculeIntensities = [1 1;1 1;1 1;1 1];% have one for each channel each line is for each reagent, set it to one to just keep it as camera intensity


replicateIdentifier = {'_C1','_C2','_C3','_C4','_C5'};

for i=1:NumberOfFiles
    for j=1:length(concentrationIdentifier)
        if contains(allData(i).intensityFileNames(1),concentrationIdentifier(j),'IgnoreCase',true) 
            allData(i).concentration = concentrations(j);
            allData(i).expNo = j;
            break;
        end
    end
    for j=1:length(minutesPerFrameIdentifier)
        if contains(allData(i).intensityFileNames(1),minutesPerFrameIdentifier(j),'IgnoreCase',true) 
            allData(i).MPF = minutesPerFrame(j);
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*j;
            break;
        end
    end
    for j=1:length(reagentIdentifier)
        if contains(allData(i).intensityFileNames(1),reagentIdentifier(j),'IgnoreCase',true) 
            allData(i).reagent = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(minutesPerFrameIdentifier)*j;
            break;
        end
    end
    for j=1:length(replicateIdentifier)
        if contains(allData(i).intensityFileNames(1),replicateIdentifier(j),'IgnoreCase',true) 
            allData(i).rep = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(minutesPerFrameIdentifier)*length(reagentIdentifier)*j;
            break;
        end
    end
end

% Group FOV from the same experiment and read in data
sysVar.detectedExps = sort(unique([allData.expNo]));
numOfExps = length(sysVar.detectedExps);
for i=1:numOfExps
    expData(i).reagent = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).reagent;
    expData(i).allTraces = cell(numberOfChannels,1);
    for j=1:numberOfChannels
        expData(i).allTraces{j} = cell2mat(arrayfun(@(z) csvread(allData(z).intensityFileNames{j},1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,j);
    end
    expData(i).numOfTraces = size(expData(i).allTraces{1},1);
    expData(i).concentration = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).concentration;
    expData(i).MPF = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).MPF;

    
    if stepFitting
        expData(i).stepMeans = arrayfun(@(z) csvread(allData(z).stepMeans,1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false);
        sysVar.maxsize = max(arrayfun(@(z)size(expData(i).stepMeans{z},1),1:length(expData(i).stepMeans)));
        expData(i).stepMeans = cell2mat(arrayfun(@(z)resize(expData(i).stepMeans{z},[sysVar.maxsize size(expData(i).stepMeans{z},2)]),1:length(expData(i).stepMeans),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,stepFitChannel);
        expData(i).stepPoints = arrayfun(@(z) csvread(allData(z).stepPoints,1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false);
        sysVar.maxsize = max(arrayfun(@(z)size(expData(i).stepPoints{z},1),1:length(expData(i).stepPoints)));
        expData(i).stepPoints = cell2mat(arrayfun(@(z)resize(expData(i).stepPoints{z},[sysVar.maxsize size(expData(i).stepPoints{z},2)]),1:length(expData(i).stepPoints),'UniformOutput',false))';
        expData(i).numOfSteps = arrayfun(@(z) length(expData(i).stepMeans(z,expData(i).stepMeans(z,:)~=0))-1,1:expData(i).numOfTraces)';
        expData(i).stepHeights = cell2mat(arrayfun(@(z) resize(diff(expData(i).stepMeans(z,expData(i).stepMeans(z,:)~=0)),[1 size(expData(i).stepMeans,2)-1]),1:expData(i).numOfTraces,'UniformOutput',false)')./singleMoleculeIntensities(expData(i).reagent,stepFitChannel);
    end
    
end

