clear
%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
JIM = [fileparts(jimpath),'\Jim_Programs\'];%Convert to the file path for the C++ Jim Programs
[filename,pathname] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze

%% 2) Create folder for results
completename = [pathname,filename];
[~,name,~] = fileparts(completename);%get the name of the tiff image excluding the .tiff extension
workingdir = [pathname,name];
[~,name,~] = fileparts(workingdir);%also remove the .ome if it exists or any other full stops
workingdir = [pathname,name,'\'];
mkdir(workingdir);%make a subfolder with that name

%% 3) Split File into individual channels 
usemetadatafile = true; % Set to true to read in a micromanager metadata file to ensure the tiff is split correctly. If this is not used the program assumes the tiff stack is saved in order
numberofchannels = 2; % only used if not using metadata
if usemetadatafile
    metafilename = [pathname,name,'_metadata.txt']; % Finds the metadaata file in the same folder as the tiff imagestack with the suffix _metadata.txt
    cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" -MetadataFile ',metafilename]; % Run TIFFChannelSplitter.exe using the metadata file and write the split channels to the reults folder with the prefix Images
else
    cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" -NumberOfChannels ',num2str(numberofchannels)];% Run TIFFChannelSplitter.exe without the metadata file and write the split channels to the reults folder with the prefix Images
end
system(cmd)

%% (Optional invert second channel) In two camera systems the second image is reflected off the dichroic splitter. If this isn't corrected in the microscope software it can be corrected here
invertchannel2 = false;

if invertchannel2
    cmd = [JIM,'Invert_Channel.exe "',workingdir,'Images_Channel_2.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff"']; %Creates the flipped image as Images_Channel_2_Inverted.tiff
    system(cmd)
    delete([workingdir,'Images_Channel_2.tiff']); % deletes the original image
    movefile([workingdir,'Images_Channel_2_Inverted.tiff'],[workingdir,'Images_Channel_2.tiff']);% put the flipped image in its place
end


%% 4) Align Channels and Calculate Drifts 

manualalignment = false; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
xoffset = 3.8;
yoffset = -1.6;
rotationangle = 0.425;
scalingfactor = 1.00233;


allchannelnames = ''; % make a list of all channels that need aligning (everything above channel 1)
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
figure('Name','Before Drift Correction and Alignment')
imshow(IMG1);

%view alignment after
detectedim = imread([workingdir,'Aligned_final_mean_1.tiff']);
detectedim = imadjust(detectedim);
originalim = imread([workingdir,'Aligned_final_mean_aligned_2.tiff']);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
figure('Name','After Drift Correction and Alignment')
imshow(IMG1);

%% 4) Make a SubAverage of frames where all particles are present 

channeltodetect = 0;% set to -1 to use partial mean of channel 1, 0 for combined mean image, 1 for mean of channel 1, 2 for 2 etc
startframe = 1;
endframe = 10;


if channeltodetect ==-1 
    refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
    cmd = [JIM,'MeanofFrames.exe "',refchan,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];
    system(cmd);
elseif channeltodetect ==-2 
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
% User Defined Parameters 
%Thresholding
cutoff=0.3; % The curoff for the initial thresholding

%Filtering

mindistfromedge = 25; % Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

mincount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxcount=1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

mineccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxeccentricity = 0.4;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minlength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxlength = 1000000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 100000; % Maximum distance that a pixel can diviate from the major axis.

displayminmax = [0 1]; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Detection Program

cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)


%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
figure('Name','Detected Particles - Red Original Image - White Selected ROIs - Green to Yellow->Excluded by filters')
originalim = imread(refchan);
originalim = imadjust(originalim);
originalim = imadjust(originalim, displayminmax);
thresim = imread([workingdir,'Detected_Regions.tif']);
thresim = im2uint16(thresim)/1.5;
detectedim = imread([workingdir,'Detected_Filtered_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
IMG1 = cat(3, originalim,thresim,detectedim);
imshow(IMG1)


%% 6)Calculate the equivalent positions in the other channels
cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Detected_Filtered_Measurements.csv" "',workingdir,'Detected_Filtered" -positions "',workingdir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingdir,'Detected_Positions.csv"'];
system(cmd)

%% 7) Fit areas around each shape 
innerradius=4.1;
backgroundradius = 20;
cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Detected_Filtered_Positions.csv" "',workingdir,'Detected_Positions.csv" "',workingdir,'Expanded_Channel_1" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
system(cmd)

for j = 2:numberofchannels
    cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
    system(cmd)
end

%view detection
figure('Name','Channel 1 Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
detectedim = imread([workingdir,'Expanded_Channel_1_ROIs.tif']);
detectedim = im2uint16(detectedim)/1.5;

backim = imread([workingdir,'Expanded_Channel_1_Background_Regions.tif']);
backim = im2uint16(backim)/1.5;

 originalim = imread([workingdir,'Aligned_final_mean_1.tiff']);
 originalim = imadjust(originalim);

IMG1 = cat(3, originalim,detectedim,backim);
imshow(IMG1);

 figure('Name','Channel 2 Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
 detectedim = imread([workingdir,'Expanded_Channel_2_ROIs.tif']);
 detectedim = im2uint16(detectedim)/1.5;
 
 backim = imread([workingdir,'Expanded_Channel_2_Background_Regions.tif']);
 backim = im2uint16(backim)/1.5;
 
 originalim = imread([workingdir,'Aligned_final_mean_2.tiff']);
   originalim = imadjust(originalim);

 IMG1 = cat(3, originalim,detectedim,backim);
 imshow(IMG1);



%% 8) Calculate Sum for each frame for each channel
cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_1.tiff" "',workingdir,'Expanded_Channel_1_ROI_Positions.csv" "',workingdir,'Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
system(cmd)
for j = 2:numberofchannels
    cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_',num2str(j),'.tiff" "',workingdir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Channel_',num2str(j),'" -Drifts "',workingdir,'Detected_Drifts_Channel_',num2str(j),'.csv"'];
    system(cmd)
end
%% Continue from here for batch processing
%
%
%
%
%
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename); % Find the location of this script again in case the user is just running batch (should be in Jim\Matlab_Programs)
JIM = [fileparts(jimpath),'\Jim_Programs\'];
pathname = uigetdir(); % open the dialog box to select the folder for batch files
pathname=[pathname,'\'];

%% 2) detect files to analyze
insubfolders = true; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

if insubfolders
    allfiles = dir(pathname); % find everything in the input folder
    allfiles(~[allfiles.isdir]) = []; % filter for folders
    allfiles=allfiles(3:end);
    allfilescells = arrayfun(@(y) arrayfun(@(x) [pathname,y.name,'\',x.name],[dir([pathname,y.name,'\*.tif']); dir([pathname,y.name,'\*.tiff'])]','UniformOutput',false),allfiles','UniformOutput',false); % look in each folder and pull out all files that end in tif or tiff
    allfilescells = horzcat(allfilescells{:})'; % combine the files from all folders into one list
    filenum=size(allfilescells,1);
else
    allfiles = [dir([pathname,'\*.tif']); dir([pathname,'\*.tiff'])];% find everything in the main folder ending in tiff or tif
    allfilescells = arrayfun(@(y) [pathname,y.name],allfiles,'UniformOutput',false); % generate a full path name for each file
    filenum=size(allfilescells,1);
end
disp(['There are ',num2str(filenum),' files to analyse']);
%% Run this if you haven't run single file
% usemetadatafile = true;
% numberofchannels = 2;%only used if not using metadata
% 
% invertchannel2 = false;
% 
% manualalignment = false;
% rotationangle = 0.43375;
% scalingfactor = 1.00;
% xoffset = 3.7;
% yoffset = -1.7;
% 
% channeltodetect = 2; %%change this depending on which channel to detect
% 
% startframe = 1;
% endframe = 10;
% 
% %paste from Sum_multi
% %this is Figure 1 cutoff/mask that will pick up all particles
% cutoff = 0.6;
% 
% %this is a clean up filter further cleaning 
% mindistfromedge = 25;
% mincount = 30;
% maxcount = 1000000;
% 
% mineccentricity = 0.6;
% maxeccentricity = 1.1;
% 
% minlength = 0;
% maxlength = 1000000;
% 
% maxDistFromLinear = 5;
% 
% %do not touch below here
% innerradius=4.1;
% backgroundradius = 20;
%% Batch Sum Multi
overwrite = false;

parfor i=1:filenum(1)
    completename = allfilescells(i);
    disp(['Analysing ',completename]);
    % 3.2) Create folder for results
    [pathnamein,name,~] = fileparts(completename);%get the name of the tiff image
    workingdir = [pathnamein,'\',name];
    [pathnamein,name,~] = fileparts(workingdir);
    workingdir = [pathnamein,'\',name,'\'];
    mkdir(workingdir);%make a subfolder with that name
    
    if (exist([workingdir,'Channel_1_Flourescent_Intensities.csv'],'file')==2 && exist([workingdir,'Channel_2_Flourescent_Intensities.csv'],'file')==2 && overwrite==false)
        disp(['Skipping ',completename,' - Analysis already exists']);
        continue
    end
    
    
   % 3.3) Split File into individual channels 
    
    if usemetadatafile
        metafilename = [pathnamein,'\',name,'_metadata.txt'];
        cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" -MetadataFile "',metafilename,'"'];
    else
        cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" -NumberOfChannels ',num2str(numberofchannels)];
    end
    system(cmd)

    %invert if needed
    if invertchannel2
        cmd = [JIM,'Invert_Channel.exe "',workingdir,'Images_Channel_2.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff"'];
        system(cmd)
        delete([workingdir,'Images_Channel_2.tiff']);
        movefile([workingdir,'Images_Channel_2_Inverted.tiff'],[workingdir,'Images_Channel_2.tiff']);
    end
    
    % 3.4) Align Channels and Calculate Drifts 
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

    % make submean
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
    
    
 
    
    % 3.5) Detect Particles

    cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)

    % 3.6)Calculate the equivalent positions in the other channels
    cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Detected_Filtered_Measurements.csv" "',workingdir,'Detected_Filtered" -positions "',workingdir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingdir,'Detected_Positions.csv"'];
    system(cmd)

    % 3.7) Fit areas around each shape 
    cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Detected_Filtered_Positions.csv" "',workingdir,'Detected_Positions.csv" "',workingdir,'Expanded_Channel_1" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
    system(cmd)

    for j = 2:numberofchannels
        cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
        system(cmd)
    end

    % 3.8) Calculate amplitude for each frame for each channel
    cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_1.tiff" "',workingdir,'Expanded_Channel_1_ROI_Positions.csv" "',workingdir,'Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
    system(cmd)
    for j = 2:numberofchannels
        cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_',num2str(j),'.tiff" "',workingdir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Channel_',num2str(j),'" -Drifts "',workingdir,'Detected_Drifts_Channel_',num2str(j),'.csv"'];
        system(cmd)
    end
end

disp('Batch Process Compeleted');

% write out the detection parameters used
if usemetadatafile
    metadatastr = 'true';
else
    metadatastr = 'false';
end

if manualalignment
    manstr = 'true';
else
    manstr = 'false';
    rotationangle = 0;
    scalingfactor = 1.00;
    xoffset = 0;
    yoffset = 0;

end
    


T = cell2table({'manual alignment' manstr; 'rotation angle' num2str(rotationangle); 'scaling factor' num2str(scalingfactor);'x offset' num2str(xoffset);'y offset' num2str(yoffset);'Using Metadata File' metadatastr;'Detection Channel' num2str(channeltodetect); 'startframe' num2str(startframe); 'endframe' num2str(endframe);'cutoff' num2str(cutoff);'mindistfromedge', num2str(mindistfromedge);'mincount', num2str(mincount);'maxcount', num2str(maxcount); 'mineccentricity', num2str(mineccentricity);'maxeccentricity', num2str(maxeccentricity);'minlength', num2str(minlength);'maxlength', num2str(maxlength);'maxDistFromLinear', num2str(maxDistFromLinear);'innerradius', num2str(innerradius);'backgroundradius', num2str(backgroundradius)});
T.Properties.VariableNames= {'Variable','Value'};
writetable(T, [pathname,'Detection_Variables.csv']);