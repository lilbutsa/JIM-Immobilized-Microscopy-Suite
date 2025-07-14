%%
clear
%%
fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,filesep];
%%
allfolders = dir(fileName);
allfolders = allfolders(arrayfun(@(x)x.isdir,allfolders));
allfolders = allfolders(3:end);
allfolders = arrayfun(@(x)[x.folder,filesep,x.name,filesep],allfolders,'UniformOutput',false);
%%
allImages = arrayfun(@(x)[x.folder,filesep,x.name],dir([fileName '**\Images_Channel_*.tiff']),'UniformOutput',false);
%%
for i=1:length(allImages)
    delete(allImages{i});
end