%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
[filename,pathname] = uigetfile('*','Select the Image file');

%% 2) Create folder for results
completename = [pathname,filename];
[pathstr,name,ext] = fileparts(completename);
workingdir = [pathname,name,'\'];
mkdir(workingdir);

%% 3) Split File into individual channels 
numberofchannels = 2;
cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" ',num2str(numberofchannels)];
system(cmd)

%% 4) Align Channels and Calculate Drifts 
allchannelnames = '';
for i = 2:numberofchannels
    allchannelnames = [allchannelnames,' "',workingdir,'Images_Channel_',num2str(i),'.tiff"'];
end
cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff"',allchannelnames];
system(cmd)

%% 5) Detect Particles
cutoff=0.5;
mincount = 9;
maxcount=101;
maxeccentricity = 0.25;
mindistfromedge = 10;
channeltodetect = 1;%0 for all, 1 for channel 1 2 for 2 etc

if channeltodetect == 0
    refchan = [workingdir,'Aligned_final_Combined_Mean_Image.tiff']; 
elseif channeltodetect ==1
       refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
else
       refchan = [workingdir,'Aligned_final_mean_aligned_',num2str(channeltodetect),'.tiff']; 
end 

cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minCount ',num2str(mincount),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxCount ',num2str(maxcount)];
system(cmd)

%view detection
detectedim = imread([workingdir,'Positions_Filtered_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, detectedim, originalim,zeros(size(detectedim)));
imshow(IMG1);

%% 6) Fit Gaussians to each particle 
cmd = [JIM,'Fit_Particles.exe "',refchan,'" "',workingdir,'Positions_Filtered_Measurements.csv" "',workingdir,'Refined_Positions"'];
system(cmd)

%% 7)Calculate the equivalent positions in the other channels
cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Refined_Positions_Measurements.csv" "',workingdir,'Positions"'];
system(cmd)

%% 8) Calculate amplitude for each frame for each channel
cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Refined_Positions_Measurements.csv" "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Traces_Channel_1"'];
system(cmd)
for i = 2:numberofchannels
    cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Positions_Measurements_Channel_',num2str(i),'.csv" "',workingdir,'Images_Channel_',num2str(i),'.tiff" "',workingdir,'Positions_Drifts_Channel_',num2str(i),'.csv" "',workingdir,'Traces_Channel_',num2str(i),'"'];
    system(cmd)
end

