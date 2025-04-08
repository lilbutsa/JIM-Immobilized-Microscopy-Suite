%% 3) Extract Traces to Separate Folder
sysVar.fileName = 'D:\.shortcut-targets-by-id\1PQH-WPrVPEdN-xRB_KXxc3ANMH_VSycc\SLO paper 1\good stuff for paper\wash in wash out\round1_single chips_triple_experiments\VLP wash in wash out data PFO\traces\';
sysVar.outputFolder = uigetdir(); 
sysVar.outputFolder = [sysVar.outputFolder,filesep];

sysVar.outputFile = [arrayfun(@(x)[x.folder,filesep,x.name],dir([sysVar.fileName '**' filesep '*_Fluorescent_Intensities.csv']),'UniformOutput',false);
    arrayfun(@(x)[x.folder,filesep,x.name],dir([sysVar.fileName '**' filesep '*_Fluorescent_Backgrounds.csv']),'UniformOutput',false);
    arrayfun(@(x)[x.folder,filesep,x.name],dir([sysVar.fileName '**' filesep '*_StepMeans.csv']),'UniformOutput',false);
    arrayfun(@(x)[x.folder,filesep,x.name],dir([sysVar.fileName '**' filesep '*_StepPoints.csv']),'UniformOutput',false);
    arrayfun(@(x)[x.folder,filesep,x.name],dir([sysVar.fileName '**' filesep '*_Detected_Filtered_Measurements.csv']),'UniformOutput',false);];
disp([num2str(length(sysVar.outputFile)) ' files to copy']);

for i=1:length(sysVar.outputFile)
    sysVar.fileNameIn = sysVar.outputFile{i};
    sysVar.fileNameIn = extractAfter(sysVar.fileNameIn,length(sysVar.fileName));
    sysVar.fileNameIn = [sysVar.outputFolder sysVar.fileNameIn];
    [sysVar.folderNameIn,~,~] = fileparts(sysVar.fileNameIn);

    if ~exist(sysVar.folderNameIn, 'dir')
        mkdir(sysVar.folderNameIn)%make a subfolder with that name
    end
    copyfile(sysVar.outputFile{i},sysVar.fileNameIn,'f');
end
disp('Traces Extracted');