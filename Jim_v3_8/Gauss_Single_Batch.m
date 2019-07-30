clear
%% 1) Select the input folder
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) detect files to analyze
insubfolders = true;

if insubfolders
    allfiles = dir(pathname);
    allfiles(~[allfiles.isdir]) = [];
    allfiles=allfiles(3:end);
    filenum=size(allfiles);
    upperfilenames = allfiles;
    for i=1:filenum(1)
        outnames = dir([pathname,allfiles(i).name,'\*.tif']);
        allfiles(i).name=[allfiles(i).name,'\',outnames.name];
    end
else
    allfiles = dir([pathname,'\*.tif']);
    filenum=size(allfiles);
end
disp(['There are ',num2str(filenum(1)),' files to analyse']);
%% 3)Run Guass single iteratively
cutoff=2;
mincount = 9;
maxcount=101;
maxeccentricity = 1;
mindistfromedge = 10;

for i=1:filenum(1)
    filename = allfiles(i).name;
    disp(['Analysing ',filename]);
    % 3.2) Create folder for results
    completename = [pathname,filename];
    [pathstr,namein,~] = fileparts(completename);
    workingdir = [pathstr,'\',namein,'\'];
    mkdir(workingdir);

    % 3.3) Align Channels and Calculate Drifts
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'"'];
    system(cmd)
    % 3.4) Detect Particles
    refchan = [workingdir,'Aligned_final_mean_1.tiff'];
    cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minCount ',num2str(mincount),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxCount ',num2str(maxcount)];
    system(cmd)
    % 3.5) Fit Gaussians to each particle 
    cmd = [JIM,'Fit_Particles.exe "',refchan,'" "',workingdir,'Positions_Filtered_Measurements.csv" "',workingdir,'Refined_Positions"'];
    system(cmd)
    % 3.6) Calculate amplitude for each frame
    cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Refined_Positions_Measurements.csv" "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Traces_Channel_1"'];
    system(cmd)

end