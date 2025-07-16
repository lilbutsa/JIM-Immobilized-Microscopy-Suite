clear
%% select input folder
fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,filesep];
%% Select output folder
outputFolder = uigetdir(); 
outputFolder = [outputFolder,filesep];
%% find all files
files = [arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*_Fluorescent_Intensities.csv']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*_Fluorescent_Backgrounds.csv']),'UniformOutput',false)];
disp([num2str(length(files)) ' files to copy']);
%%
files = [arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*.csv']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*.hdf5']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*.yaml']),'UniformOutput',false)];
disp([num2str(length(files)) ' files to copy']);
%%
files = [arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*_Fluorescent_Intensities.csv']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*_Fluorescent_Backgrounds.csv']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*Picasso_JIM_ROI.hdf5']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([fileName '**\*Picasso_JIM_ROI.yaml']),'UniformOutput',false)];
disp([num2str(length(files)) ' files to copy']);
%% copy file structure
for i=1:length(files)
    fileNameIn = files{i};
    fileNameIn = extractAfter(fileNameIn,length(fileName));
    fileNameIn = [outputFolder fileNameIn];
    [folderNameIn,~,~] = fileparts(fileNameIn);

    if ~exist(folderNameIn, 'dir')
        mkdir(folderNameIn)%make a subfolder with that name
    end

    copyfile(files{i},fileNameIn);
end