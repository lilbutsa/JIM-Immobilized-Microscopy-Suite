%% 1) Select Input Folder
numberOfChannels = 2;

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
end

NumberOfFiles=length(allData);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

%%
sysConst.JIM = '"E:\Github\JIM-Immobilized-Microscopy-Suite\Jim_v7\c++_Base_Programs\Windows\';
sysConst.fileEXE = '.exe"';

stepfitChannel = 1;
stepfitThreshold = 20;
for i=1:length(allData)
    workingDir = [fileparts(allData(i).intensityFileNames{stepFitChannel}),filesep];
    sysVar.cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
    system(sysVar.cmd);
end

disp('Step fitting completed');