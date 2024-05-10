
sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch shift up a level
sysVar.fileName=[sysVar.fileName,filesep];


sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
sysVar.allFolders = sysVar.allFolders(3:end);
    
    
filesIn = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),filesep,x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allFolders','UniformOutput',false);
filesOut = arrayfun(@(y)arrayfun(@(x)[sysVar.fileName,x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allFolders','UniformOutput',false);
filesIn = horzcat(filesIn{:})';
filesOut = horzcat(filesOut{:})';
filesOut = filesOut(arrayfun(@(x) ~isfolder(cell2mat(x)),filesIn));
filesIn = filesIn(arrayfun(@(x) ~isfolder(cell2mat(x)),filesIn));

sysConst.NumberOfFiles=size(filesIn,1);
disp(['There are ',num2str(sysConst.NumberOfFiles),' files to move']);

for i=1:length(filesIn)
    movefile(filesIn{i},filesOut{i});
end
