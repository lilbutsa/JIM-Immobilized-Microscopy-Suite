clear
%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
[filename,pathname] = uigetfile('*','Select the Image file');

%% 2) Create folder for results
completename = [pathname,filename];
[pathstr,name,ext] = fileparts(completename);%get the name of the tiff image
workingdir = [pathname,name,'\'];
mkdir(workingdir);%make a subfolder with that name

%% 3) Split File into individual channels 
numberofchannels = 2;
cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" ',num2str(numberofchannels)];
system(cmd)

%% (Optional invert second channel)
invertchannel2 = false;

if invertchannel2
    cmd = [JIM,'Invert_Channel.exe "',workingdir,'Images_Channel_2.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff"'];
    system(cmd)
    delete([workingdir,'Images_Channel_2.tiff']);
    movefile([workingdir,'Images_Channel_2_Inverted.tiff'],[workingdir,'Images_Channel_2.tiff']);
end


%% 4) Align Channels and Calculate Drifts 

manualalignment = false;
rotationangle = 0.425;
scalingfactor = 1.00233;
xoffset = 3.8;
yoffset = -1.6;


allchannelnames = '';
for j = 2:numberofchannels
    allchannelnames = [allchannelnames,' "',workingdir,'Images_Channel_',num2str(j),'.tiff"'];
end

if manualalignment
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff"',allchannelnames,' -Alignment ',num2str(xoffset),' ',num2str(yoffset),' ',num2str(rotationangle),' ',num2str(scalingfactor)];
else
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff"',allchannelnames];
end
system(cmd)

%view alignment before
detectedim = imread([workingdir,'Aligned_final_mean_1.tiff']);
detectedim = imadjust(detectedim);
originalim = imread([workingdir,'Aligned_final_mean_2.tiff']);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
figure
imshow(IMG1);

%view alignment after
detectedim = imread([workingdir,'Aligned_final_mean_1.tiff']);
detectedim = imadjust(detectedim);
originalim = imread([workingdir,'Aligned_final_mean_aligned_2.tiff']);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
figure
imshow(IMG1);

%% 4) Make a SubAverage of frames where all particles are present 

channeltodetect = 2;% set to -1 to use partial mean of channel 1, 0 for combined mean image, 1 for mean of channel 1, 2 for 2 etc
startframe = 1;
endframe = 10;


if channeltodetect ==-1 
    refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
    cmd = [JIM,'MeanofFrames.exe "',refchan,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];
    system(cmd);
end 

if channeltodetect ==-1
    refchan = [workingdir,'Aligned_Partial_Mean.tiff'];
elseif channeltodetect == 0
    refchan = [workingdir,'Aligned_final_Combined_Mean_Image.tiff']; 
elseif channeltodetect ==1
       refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
else
       refchan = [workingdir,'Aligned_final_mean_aligned_',num2str(channeltodetect),'.tiff']; 
end 

    figure
    originalim = imread(refchan);
    originalim = imadjust(originalim);
    imshow(originalim);

%% 5) Detect Particles

cutoff = 0.6;

%this is a clean up filter further cleaning 
mindistfromedge = 25;
mincount = 30;
maxcount = 1000000;

mineccentricity = 0.6;
maxeccentricity = 1.1;

minlength = 0;
maxlength = 1000000;

maxDistFromLinear = 5;



cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
system(cmd)

%view detection
figure
detectedim = imread([workingdir,'Positions_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
imshow(IMG1);


figure
detectedim = imread([workingdir,'Positions_Filtered_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
imshow(IMG1);


%% 6)Calculate the equivalent positions in the other channels
cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Positions_Measurements.csv" "',workingdir,'Positions" -positions "',workingdir,'Positions_Labelled_Positions.csv"'];
system(cmd)

%% 7) Fit areas around each shape 
innerradius=4.1;
backgroundradius = 20;
cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Labelled_Positions.csv" "',workingdir,'Expanded_Channel_1" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
system(cmd)
cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements.csv" "',workingdir,'Expanded_Channel_1_ROI_Positions.csv" "',workingdir,'Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_1" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
system(cmd)

for j = 2:numberofchannels
    cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
    system(cmd)
    cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)
end

%view detection
figure
detectedim = imread([workingdir,'Filtered_Expanded_Channel_1_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;

backim = imread([workingdir,'Filtered_Expanded_Channel_1_BackGround_Regions.tif']);
backim = im2uint16(backim)/1.5;

IMG1 = cat(3, originalim,detectedim,backim);
imshow(IMG1);

% figure
% detectedim = imread([workingdir,'Filtered_Expanded_Channel_2_Regions.tif']);
% detectedim = im2uint16(detectedim)/1.5;
% 
% backim = imread([workingdir,'Filtered_Expanded_Channel_2_BackGround_Regions.tif']);
% backim = im2uint16(backim)/1.5;
% 
% IMG1 = cat(3, originalim,detectedim,backim);
% imshow(IMG1);



%% 8) Calculate Sum for each frame for each channel
cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_1.tiff" "',workingdir,'Filtered_Expanded_Channel_1_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
system(cmd)
for j = 2:numberofchannels
    cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_',num2str(j),'.tiff" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Channel_',num2str(j),'" -Drifts "',workingdir,'Positions_Drifts_Channel_',num2str(j),'.csv"'];
    system(cmd)
end
