clear
%% 1) Select the input tiff file Create a Folder for results
[jimPath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
JIM = [fileparts(jimPath),'\Jim_Programs\'];%Convert to the file path for the C++ Jim Programs
[fileName,pathName] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze

completeName = [pathName,fileName];
[~,name,~] = fileparts(completeName);%get the name of the tiff image excluding the .tiff extension
workingDir = [pathName,name];
[~,name,~] = fileparts(workingDir);%also remove the .ome if it exists or any other full stops
workingDir = [pathName,name,'\'];
mkdir(workingDir);%make a subfolder with that name

%% 2) Split File into individual channels 
useMetadataFile = false; % Set to true to read in a micromanager metadata file to ensure the tiff is split correctly. If this is not used the program assumes the tiff stack is saved in order
numberOfChannels = 2;
if useMetadataFile
    metaFileName = [pathName,name,'_metadata.txt']; % Finds the metadaata file in the same folder as the tiff imagestack with the suffix _metadata.txt
    cmd = [JIM,'TIFF_Channel_Splitter.exe "',completeName,'" "',workingDir,'Images" -MetadataFile "',metaFileName,'"']; % Run TIFFChannelSplitter.exe using the metadata file and write the split channels to the reults folder with the prefix Images
else
    cmd = [JIM,'TIFF_Channel_Splitter.exe "',completeName,'" "',workingDir,'Images" -NumberOfChannels ',num2str(numberOfChannels)];% Run TIFFChannelSplitter.exe without the metadata file and write the split channels to the reults folder with the prefix Images
end
system(cmd)

%% 3) invert second channel 
% In two camera systems the second image is reflected off the dichroic splitter. If this isn't corrected in the microscope software it can be corrected here
invertChannel2 = false;

if invertChannel2
    cmd = [JIM,'Invert_Channel.exe "',workingDir,'Images_Channel_2.tiff" "',workingDir,'Images_Channel_2_Inverted.tiff"']; %Creates the flipped image as Images_Channel_2_Inverted.tiff
    system(cmd)
    delete([workingDir,'Images_Channel_2.tiff']); % deletes the original image
    movefile([workingDir,'Images_Channel_2_Inverted.tiff'],[workingDir,'Images_Channel_2.tiff']);% put the flipped image in its place
end


%% 4) Align Channels and Calculate Drifts
iterations = 1;

alignStartFrame = 15;
alignEndFrame = 15;

manualAlignment = false; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
rotationAngle = -2.86;
scalingFactor = 1;
xoffset = -5;
yoffset = -5;

allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
for j = 1:numberOfChannels
    allChannelNames = [allChannelNames,' "',workingDir,'Images_Channel_',num2str(j),'.tiff"'];
end

if manualAlignment
    cmd = [JIM,'Align_Channels.exe "',workingDir,'Aligned"',allChannelNames,' -Alignment ',num2str(xoffset),' ',num2str(yoffset),' ',num2str(rotationAngle),' ',num2str(scalingFactor),' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];
else
    cmd = [JIM,'Align_Channels.exe "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];
end
system(cmd)

%view alignment before
if manualAlignment
    detectedIm = imread([workingDir,'Aligned_aligned_partial_mean_1.tiff']);
    originalIm = imread([workingDir,'Aligned_aligned_partial_mean_2.tiff']);
else
    detectedIm = imread([workingDir,'Aligned_initial_partial_mean_1.tiff']);
    originalIm = imread([workingDir,'Aligned_initial_partial_mean_2.tiff']);
end
detectedIm = imadjust(detectedIm);
originalIm = imadjust(originalIm);
IMG1 = cat(3, originalIm,detectedIm,zeros(size(detectedIm)));
figure('Name','Before Drift Correction and Alignment')
imshow(IMG1);

%view alignment after
detectedIm = imread([workingDir,'Aligned_aligned_full_mean_1.tiff']);
detectedIm = imadjust(detectedIm);
originalIm = imread([workingDir,'Aligned_aligned_full_mean_2.tiff']);
originalIm = imadjust(originalIm);
IMG1 = cat(3, originalIm,detectedIm,zeros(size(detectedIm)));
figure('Name','After Drift Correction and Alignment')
imshow(IMG1);
disp('Alignment and drift correction completed');

%% 5) Make a SubAverage of Frames for each Channel for Detection 
useMaxProjection = false;

frameRangeStarts = [1,20];
frameRangeEnds = [10,30];

maxProjectionString = '';
if useMaxProjection
    maxProjectionString = ' -MaxProjection';
end

cmd = [JIM,'Mean_of_Frames.exe "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(frameRangeStarts),' -End ',num2str(frameRangeEnds),maxProjectionString];
system(cmd);

figure
originalIm = imread([workingDir,'Aligned_Partial_Mean.tiff']);
originalIm = imadjust(originalIm);
imshow(originalIm);
disp('Average projection completed');

%% 6) Detect Particles
% User Defined Parameters 
%Thresholding
cutoff=0.4; % The curoff for the initial thresholding

%Filtering
left = 0;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right = 30;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top = 20;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom = 12;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

minCount = 15; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount= 1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxLength = 1000000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 100000; % Maximum distance that a pixel can diviate from the major axis.

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.5; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Detection Program

cmd = [JIM,'Detect_Particles.exe "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)


%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
originalIm = imread(refchan);
originalIm = imadjust(originalIm);
originalIm = imadjust(originalIm, [displayMin displayMax]);
thresholdedIm = imread([workingDir,'Detected_Regions.tif']);
thresholdedIm = im2uint16(thresholdedIm)/1.5;
detectedIm = imread([workingDir,'Detected_Filtered_Regions.tif']);
detectedIm = im2uint16(detectedIm)/1.5;
IMG1 = cat(3, originalIm,thresholdedIm,detectedIm);
imshow(IMG1)

disp('Finish detecting particles');
%% 7)Calculate the equivalent positions in the other channels
cmd = [JIM,'Other_Channel_Positions.exe "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Detected_Filtered" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingDir,'Detected_Positions.csv"'];
system(cmd)

disp('Calculated equivalent position in other channels');

%% 8) Expand Regions 
foregroundDist = 4.1; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backInnerDist = 4.1;
backOuterDist = 20; % Distance to dilate beyond the ROI to measure the local background

cmd = [JIM,'Expand_Shapes.exe "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded_Channel_1" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
system(cmd)

for j = 2:numberOfChannels
    cmd = [JIM,'Expand_Shapes.exe "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd)
end

%view detection
figure('Name','Channel 1 Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
detectedIm = imread([workingDir,'Expanded_Channel_1_ROIs.tif']);
detectedIm = im2uint16(detectedIm)/1.5;

backgroundIm = imread([workingDir,'Expanded_Channel_1_Background_Regions.tif']);
backgroundIm = im2uint16(backgroundIm)/1.5;

originalIm = imread([workingDir,'Aligned_aligned_full_mean_1.tiff']);
originalIm = imadjust(originalIm);

IMG1 = cat(3, originalIm,detectedIm,backgroundIm);
imshow(IMG1);

figure('Name','Channel 2 Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
detectedIm = imread([workingDir,'Expanded_Channel_2_ROIs.tif']);
detectedIm = im2uint16(detectedIm)/1.5;

backgroundIm = imread([workingDir,'Expanded_Channel_2_Background_Regions.tif']);
backgroundIm = im2uint16(backgroundIm)/1.5;

originalIm = imread([workingDir,'Aligned_initial_full_mean_2.tiff']);
originalIm = imadjust(originalIm);

IMG1 = cat(3, originalIm,detectedIm,backgroundIm);
imshow(IMG1);

disp('Finished Expanding ROIs');

%% 9) Calculate Traces
verboseOutput = false;

verboseString = '';
if verboseOutput
    verboseString = ' -Verbose';
end

cmd = [JIM,'Calculate_Traces.exe "',workingDir,'Images_Channel_1.tiff" "',workingDir,'Expanded_Channel_1_ROI_Positions.csv" "',workingDir,'Expanded_Channel_1_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',verboseString];
system(cmd)
for j = 2:numberOfChannels
    cmd = [JIM,'Calculate_Traces.exe "',workingDir,'Images_Channel_',num2str(j),'.tiff" "',workingDir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingDir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Detected_Filtered_Drifts_Channel_',num2str(j),'.csv"',verboseString];
    system(cmd)
end

disp('Finished Generating Traces');
%% 10) Plot Traces
    pageNumber = 1;

    traces=csvread([workingDir,'\Channel_1_Fluorescent_Intensities.csv'],1);
    traces2=csvread([workingDir,'\Channel_2_Fluorescent_Intensities.csv'],1);
    measures = csvread([workingDir,'\Detected_Filtered_Measurements.csv'],1);
    numberIm = imread([workingDir,'Detected_Filtered_Region_Numbers.tif']);
    figure('Name','Particle Numbers');
    imshow(numberIm);

    figure
    set(gcf, 'Position', [100, 100, 1500, 800])

    for i=1:36
        if i+36*(pageNumber-1)<size(traces,1)
        subplot(6,6,i)
        hold on
        title(['Particle ' num2str(i+36*(pageNumber-1)) ' x ' num2str(round(measures(i+36*(pageNumber-1),1))) ' y ' num2str(round(measures(i+36*(pageNumber-1),2)))])
        plot(traces(i+36*(pageNumber-1),:),'-r');
        plot(traces2(i+36*(pageNumber-1),:),'-b');
        plot([0 size(traces(i+36*(pageNumber-1),:),2)],[0 0] ,'-b');
        xlim([0 size(traces(i+36*(pageNumber-1),:),2)])
        hold off
        end
    end



%% Continue from here for batch processing
%
%
%
%
%
[jimPath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename); % Find the location of this script again in case the user is just running batch (should be in Jim\Matlab_Programs)
JIM = [fileparts(jimPath),'\Jim_Programs\'];
pathName = uigetdir(); % open the dialog box to select the folder for batch files
pathName=[pathName,'\'];

%% 2) detect files to analyze
filesInSubFolders = true; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

if filesInSubFolders
    allfiles = dir(pathName); % find everything in the input folder
    allfiles(~[allfiles.isdir]) = []; % filter for folders
    allfiles=allfiles(3:end);
    allfilescells = arrayfun(@(y) arrayfun(@(x) [pathName,y.name,'\',x.name],[dir([pathName,y.name,'\*.tif']); dir([pathName,y.name,'\*.tiff'])]','UniformOutput',false),allfiles','UniformOutput',false); % look in each folder and pull out all files that end in tif or tiff
    allfilescells = horzcat(allfilescells{:})'; % combine the files from all folders into one list
    allfilescells = allfilescells(~startsWith(allfilescells,[pathName,'.']));
    filenum=size(allfilescells,1);
else
    allfiles = [dir([pathName,'\*.tif']); dir([pathName,'\*.tiff'])];% find everything in the main folder ending in tiff or tif
    allfilescells = arrayfun(@(y) [pathName,y.name],allfiles,'UniformOutput',false); % generate a full path name for each file
    allfilescells = allfilescells(~startsWith(allfilescells,[pathName,'.']));
    filenum=size(allfilescells,1);
end
disp(['There are ',num2str(filenum),' files to analyse']);

%% Batch Sum Multi
overwritePreviouslyAnalysed = true;

parfor i=1:filenum(1)
    completeName = allfilescells{i};
    disp(['Analysing ',completeName]);
    % 3.2) Create folder for results
    [pathNamein,name,~] = fileparts(completeName);%get the name of the tiff image
    workingDir = [pathNamein,'\',name];
    [pathNamein,name,~] = fileparts(workingDir);
    workingDir = [pathNamein,'\',name,'\'];
    mkdir(workingDir);%make a subfolder with that name
    
    if (exist([workingDir,'Channel_1_Fluorescent_Intensities.csv'],'file')==2 && exist([workingDir,'Channel_2_Fluorescent_Intensities.csv'],'file')==2 && overwritePreviouslyAnalysed==false)
        disp(['Skipping ',completeName,' - Analysis already exists']);
        continue
    end
    
    
   % 3.3) Split File into individual channels 
    
    if useMetadataFile
        metaFileName = [pathNamein,'\',name,'_metadata.txt'];
        cmd = [JIM,'TIFF_Channel_Splitter.exe "',completeName,'" "',workingDir,'Images" -MetadataFile "',metaFileName,'"'];
    else
        cmd = [JIM,'TIFF_Channel_Splitter.exe "',completeName,'" "',workingDir,'Images" -NumberOfChannels ',num2str(numberOfChannels)];
    end
    system(cmd)

    %invert if needed
    if invertChannel2
        cmd = [JIM,'Invert_Channel.exe "',workingDir,'Images_Channel_2.tiff" "',workingDir,'Images_Channel_2_Inverted.tiff"'];
        system(cmd)
        delete([workingDir,'Images_Channel_2.tiff']);
        movefile([workingDir,'Images_Channel_2_Inverted.tiff'],[workingDir,'Images_Channel_2.tiff']);
    end
    
    % 3.4) Align Channels and Calculate Drifts 
    
    allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
    for j = 1:numberOfChannels
        allChannelNames = [allChannelNames,' "',workingDir,'Images_Channel_',num2str(j),'.tiff"'];
    end

    if manualAlignment
        cmd = [JIM,'Align_Channels.exe "',workingDir,'Aligned"',allChannelNames,' -Alignment ',num2str(xoffset),' ',num2str(yoffset),' ',num2str(rotationAngle),' ',num2str(scalingFactor),' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];
    else
        cmd = [JIM,'Align_Channels.exe "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];
    end
    system(cmd)


    % make submean
    cmd = [JIM,'Mean_of_Frames.exe "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(frameRangeStarts),' -End ',num2str(frameRangeEnds),maxProjectionString];
    system(cmd);
    
    % 3.5) Detect Particles

    cmd = [JIM,'Detect_Particles.exe "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)

    % 3.6)Calculate the equivalent positions in the other channels
    cmd = [JIM,'Other_Channel_Positions.exe "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Detected_Filtered" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingDir,'Detected_Positions.csv"'];
    system(cmd)

    % 3.7) Fit areas around each shape 
    cmd = [JIM,'Expand_Shapes.exe "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded_Channel_1" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd)

    for j = 2:numberOfChannels
        cmd = [JIM,'Expand_Shapes.exe "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
        system(cmd)
    end

    % 3.8) Calculate amplitude for each frame for each channel
    cmd = [JIM,'Calculate_Traces.exe "',workingDir,'Images_Channel_1.tiff" "',workingDir,'Expanded_Channel_1_ROI_Positions.csv" "',workingDir,'Expanded_Channel_1_Background_Positions.csv" "',workingDir,'Channel_1" -Drifts "',workingDir,'Aligned_Drifts.csv"',verboseString];
    system(cmd)
    for j = 2:numberOfChannels
        cmd = [JIM,'Calculate_Traces.exe "',workingDir,'Images_Channel_',num2str(j),'.tiff" "',workingDir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingDir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingDir,'Channel_',num2str(j),'" -Drifts "',workingDir,'Detected_Drifts_Channel_',num2str(j),'.csv"',verboseString];
        system(cmd)
    end
end

disp('Batch Process Completed');
