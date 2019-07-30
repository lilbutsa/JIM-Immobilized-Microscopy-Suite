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
numberofchannels = 2;
cutoff=2;
mincount = 9;
maxcount=101;
maxeccentricity = 0.25;
mindistfromedge = 10;
channeltodetect = 1;%0 for all, 1 for channel 1 2 for 2 etc

for i=1:filenum(1)
    filename = allfiles(i).name;
    disp(['Analysing ',filename]);
    % 3.2) Create folder for results
    completename = [pathname,filename];
    [pathstr,namein,~] = fileparts(completename);
    workingdir = [pathstr,'\',namein,'\'];
    mkdir(workingdir);

   % 3.3) Split File into individual channels 
    
    cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" ',num2str(numberofchannels)];
    system(cmd)

    % 3.4) Invert the second channel
    cmd = [JIM,'Invert_Channel.exe "',workingdir,'Images_Channel_2.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff"'];
    system(cmd)
    
    % 3.5) Align Channels and Calculate Drifts 
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff'];
    system(cmd)

    % 3.6) Detect Particles

    if channeltodetect == 0
        refchan = [workingdir,'Aligned_final_Combined_Mean_Image.tiff']; 
    elseif channeltodetect ==1
           refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
    else
           refchan = [workingdir,'Aligned_final_mean_aligned_',num2str(channeltodetect),'.tiff']; 
    end 

    cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minCount ',num2str(mincount),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxCount ',num2str(maxcount)];
    system(cmd)

    % 3.7) Fit Gaussians to each particle 
    cmd = [JIM,'Fit_Particles.exe "',refchan,'" "',workingdir,'Positions_Filtered_Measurements.csv" "',workingdir,'Refined_Positions"'];
    system(cmd)

    % 3.8)Calculate the equivalent positions in the other channels
    cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Refined_Positions_Measurements.csv" "',workingdir,'Positions"'];
    system(cmd)

    % 3.9) Calculate amplitude for each frame for each channel
    cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Refined_Positions_Measurements.csv" "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Traces_Channel_1"'];
    system(cmd)
    cmd = [JIM,'Fit_Each_Timepoint.exe "',workingdir,'Positions_Measurements_Channel_2.csv" "',workingdir,'Images_Channel_2_Inverted.tiff" "',workingdir,'Positions_Drifts_Channel_2.csv" "',workingdir,'Traces_Channel_2"'];
    system(cmd)
end