%% Save folder       
sysVar.saveFolder = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.saveFolder=[sysVar.saveFolder,filesep];
%% Source File
sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep];
sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
sysVar.allFolders = sysVar.allFolders(~startsWith(sysVar.allFolders, {[sysVar.fileName '.']}) & ~startsWith(sysVar.allFolders, {[sysVar.fileName 'Header']}));
%% Compile JIM into mex files
for i=1:length(sysVar.allFolders)
    sysVar.folderIn = sysVar.allFolders{i};
    
    allFiles = arrayfun(@(x)[sysVar.folderIn,filesep,x.name],dir(sysVar.folderIn)','UniformOutput',false);
    allFiles = allFiles(endsWith(allFiles, {'.cpp'}) | endsWith(allFiles, {'.c'}));
    sysVar.allFiles2 = arrayfun(@(x)[sysVar.folderIn,filesep, 'Matlab',filesep,x.name],dir([sysVar.folderIn, filesep, 'Matlab'])','UniformOutput',false);
    sysVar.allFiles2 = sysVar.allFiles2(endsWith(sysVar.allFiles2, {'.cpp'}));
    allFiles = horzcat(sysVar.allFiles2,allFiles);
    
    mexStr = ['mex COMPFLAGS="$COMPFLAGS /std:c++17 /O2 /Ob2 /Oi /Ot /GL" "' strjoin(allFiles,'" "') '" -outdir "' sysVar.saveFolder '" -I' sysVar.fileName filesep '\\Header_Libraries'];
    eval(mexStr);
end
%% Add save folder to matlab path
addpath(sysVar.saveFolder);