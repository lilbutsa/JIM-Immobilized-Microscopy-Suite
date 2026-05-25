%%
clear
%% 1) Select Input Folder
numberOfChannels = 2;

[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%get JIM Folder
sysConst.fileEXE = '"';
if ismac
    sysConst.JIM = [fileparts(sysConst.JIM),'/c++_Base_Programs/Mac/'];
    source = dir([sysConst.JIM,'/*']);
    for j=1:length(source)
        cmd = ['chmod +x "',sysConst.JIM,source(j).name,'"'];
        system(cmd);
    end
    sysConst.JIM = ['"',sysConst.JIM];
    
elseif ispc
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'\c++_Base_Programs\Windows\'];
    sysConst.fileEXE = '.exe"';
else
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'/c++_Base_Programs/Linux/'];
end

sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
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
    end
end

NumberOfFiles=length(sysVar.allFiles);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%%
stepfitChannel = 1;
stepfitIterations = 10000;
parfor j=1:length(allData)
    disp(j);
    cmd = [sysConst.JIM,'Change_Point_Analysis',sysConst.fileEXE,' "',allData(j).intensityFileNames{stepfitChannel},'" "',fileparts(allData(j).intensityFileNames{stepfitChannel}),filesep,'Stepfit" -FitSingleSteps -Iterations ',num2str(stepfitIterations)];
    system(cmd);
end