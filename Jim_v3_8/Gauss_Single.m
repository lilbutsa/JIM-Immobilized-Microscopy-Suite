
%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
[filename,pathname] = uigetfile('*','Select the Image file');

%% 2) Create folder for results
completename = [pathname,filename];
[pathstr,name,ext] = fileparts(completename);
workingdir = [pathname,name,'\'];
mkdir(workingdir);
%% 3) Calculate Drifts
cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'"'];
system(cmd)

%% 4) Detect Particles
cutoff=2;
mincount = 9;
maxcount=101;
maxeccentricity = 1;
mindistfromedge = 10;

refchan = [workingdir,'Aligned_final_mean_1.tiff'];
cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minCount ',num2str(mincount),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxCount ',num2str(maxcount)];
system(cmd)

%view detection
detectedim = imread([workingdir,'Positions_Filtered_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, detectedim, originalim,zeros(size(detectedim)));
imshow(IMG1);
%% 5) Fit Gaussians to each particle 
cmd = [JIM,'Fit_Particles.exe "',refchan,'" "',workingdir,'Positions_Filtered_Measurements.csv" "',workingdir,'Refined_Positions"'];
system(cmd)
%% 6) Calculate amplitude for each frame
cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Refined_Positions_Measurements.csv" "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Traces_Channel_1"'];
system(cmd)