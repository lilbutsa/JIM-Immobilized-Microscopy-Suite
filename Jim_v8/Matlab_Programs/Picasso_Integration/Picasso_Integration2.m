clear
%% 1) Select the input tiff file Create a Folder for results
additionalExtensionsToRemove = 1;
multipleFilesPerImageStack = false;

[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
%Convert to the file path for the C++ Jim Programs
fileEXE = '"';
fileSep = '';
if ismac
    JIM = ['"',fileparts(JIM),'/Mac_Programs/'];
    fileSep = '/';
elseif ispc
    JIM = ['"',fileparts(JIM),'\Jim_Programs\'];
    fileEXE = '.exe"';
    fileSep = '\';
else
    disp('Platform not supported')
end

[fileName,pathName] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze

overlayColour1 = [1, 0, 0];
overlayColour2 = [0, 1, 0];
overlayColour3 = [0, 0, 1];

completeName = [pathName,fileName];
[fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
for j=1:additionalExtensionsToRemove
    workingDir = [fileNamein,fileSep,name];
    [fileNamein,name,~] = fileparts(workingDir);
end
workingDir = [fileNamein,fileSep,name,fileSep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end

if multipleFilesPerImageStack
    completeName = arrayfun(@(x)['"',pathName,x.name,'" '],dir(pathName)','UniformOutput',false);
    completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
    completeName = sort(completeName);
    completeName = horzcat(completeName{:});
else
    completeName = ['"',completeName,'" '];
end

%% 2) Organise Channels 
numberOfChannels = 2;

%Transform channels so they roughly overlay each other
channelsToTransform = '';%If no channels need to be transformed set channelsToTransform = '';
VerticalFlipChannel = '';
HorizontalFlipChannel = '';
RotateChannel = '';%rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel

startFrame = 1;
endFrame = -1;

disableMetadata = true; 

metadatastr = '';
if(disableMetadata)
    metadatastr = ' -DisableMetadata';
end

if (isempty(channelsToTransform))
    cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),' -StartFrame ',num2str(startFrame),' -EndFrame ',num2str(endFrame),metadatastr]; % Run TIFFChannelSplitter',fileEXE,' using the metadata  and write the split channels to the reults folder with the prefix Images
else
    cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),' -Transform ',channelsToTransform,' ',VerticalFlipChannel,' ',HorizontalFlipChannel,' ',RotateChannel,' -StartFrame ',num2str(startFrame),' -EndFrame ',num2str(endFrame),metadatastr];
end
returnVal = system(cmd);

if length(dir([workingDir,'Images_Channel_*.tif']))~= numberOfChannels
    numberOfChannels = length(dir([workingDir,'Images_Channel_*.tif']));
    f = errordlg(['Metadata detected ' num2str(numberOfChannels) ' Channels. numberOfChannels has been changed to this value'],'Difference in Channels Detected'); 
end
if returnVal==1
    f = errordlg('Check that channelsToTransform, VerticalFlipChannel, HorizontalFlipChannel and RotateChannel all have the same number of parameters.','Error Inputting Parameters. channelsToTransform should be the list of channels that need to be transformed. VerticalFlipChannel and HorizontalFlipChannel should state whether the respective channel should (1) or shouldnt (0) be flipped. rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel'); 
elseif returnVal~=0
    f = errordlg('An unknown error has occured while organising channels. See console for details','Error During Channel Splitting'); 
end

%% 4) Align Channels and Calculate Drifts
iterations = 3;

alignStartFrame = 3;
alignEndFrame = 10;

maxShift = 1000;

manualAlignment = true; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
xoffset = '0';
yoffset = '0';
rotationAngle = '0';
scalingFactor = '1';

%Parmeters for Automatic Alignment
maxIntensities = '64000 64000';
SNRCutoff = 1.005;

%Output the aligned image stacks. Note this is not required by JIM but can
%be helpful for visualization
outputAlignedStacks = false;

%Don't touch from here

allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
for j = 1:numberOfChannels
    allChannelNames = [allChannelNames,' "',workingDir,'Images_Channel_',num2str(j),'.tif"'];
end

outputFiles = '';
if outputAlignedStacks
    outputFiles = ' -OutputAligned ';
end

if numberOfChannels==1
    cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift)];
elseif manualAlignment
    cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Alignment ',xoffset,' ',yoffset,' ',rotationAngle,' ',scalingFactor,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),outputFiles];
else
    cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),' -MaxIntensities ',maxIntensities,' -SNRCutoff ',num2str(SNRCutoff),outputFiles];
end
returnVal = system(cmd);

if returnVal == 0
    %view alignment before
    imout = cell(3,1);
    base = 'Aligned_initial_partial_mean_';

    if numberOfChannels>1
        for i=1:3
            if i<= numberOfChannels
            imout{i}=im2double(imread([workingDir,base,num2str(i),'.tiff']));
            imout{i} = (imout{i}-min(min(imout{i})))./(prctile(reshape(imout{i}.',1,[]),99.5)-min(min(imout{i})));
            else
               imout{i} = 0.*imout{1};
            end
        end
        if numberOfChannels>1
            combinedImage = cat(3, overlayColour1(1).*imout{1}+overlayColour2(1).*imout{2}+overlayColour3(1).*imout{3},overlayColour1(2).*imout{1}+overlayColour2(2).*imout{2}+overlayColour3(2).*imout{3},overlayColour1(3).*imout{1}+overlayColour2(3).*imout{2}+overlayColour3(3).*imout{3});
        else
            combinedImage = imout{1};
        end
        figure('Name','Before Drift Correction and Alignment')
        imshow(combinedImage);
    else
        figure('Name','Before Drift Correction') %Display the initial mean that has no drift correction. This is equivilent to the z projection if the stack in ImageJ
        channel1Im = im2double(imread([workingDir,'Aligned_initial_partial_mean_1.tiff']));
        channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
        imshow(channel1Im);
    end

    if numberOfChannels>1
        base = 'Aligned_aligned_full_mean_';
        for i=1:3
            if i<= numberOfChannels
            imout{i}=im2double(imread([workingDir,base,num2str(i),'.tiff']));
            imout{i} = (imout{i}-min(min(imout{i})))./(prctile(reshape(imout{i}.',1,[]),99.5)-min(min(imout{i})));
            else
               imout{i} = 0.*imout{1};
            end
        end
        if numberOfChannels>1
            combinedImage = cat(3, overlayColour1(1).*imout{1}+overlayColour2(1).*imout{2}+overlayColour3(1).*imout{3},overlayColour1(2).*imout{1}+overlayColour2(2).*imout{2}+overlayColour3(2).*imout{3},overlayColour1(3).*imout{1}+overlayColour2(3).*imout{2}+overlayColour3(3).*imout{3});
        else
            combinedImage = imout{1};
        end
        figure('Name','After Drift Correction and Alignment')
        imshow(combinedImage);
        disp('Alignment and drift correction completed');
    else
        figure('Name','After Drift Correction')%Display the final mean drift corrected mean.
        channel1Im = im2double(imread([workingDir,'Aligned_aligned_full_mean_1.tiff']));
        channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
        imshow(channel1Im);
    end

    drifts = csvread([workingDir,'Aligned_Drifts.csv'],1);%Read in drifts to see waht the max the image has shifted by
    disp(['Maximum drift is ', num2str(max(max(abs(drifts))))]);
elseif returnVal == 1
    errormsg = ['Check that you have the same number of Max Intensity values as Channels (' num2str(numberOfChannels) ')'];
    if manualAlignment
        errormsg = ['Check you have ' num2str(numberOfChannels-1) ' values for each of: xoffset, yoffset,rotationAngle and scalingFactor'];
    end
    f = errordlg(errormsg,'Error Importing Parameters');
elseif returnVal == 2
    f = errordlg('Check that data is reasonable','Error during alignment');    
end
%% 5) Make a SubAverage of Frames for each Channel for Detection 
useMaxProjection = false;

detectionStartFrame = '1 0';
detectionEndFrame = '10 0';

maxProjectionString = '';
if useMaxProjection
    maxProjectionString = ' -MaxProjection';
end

cmd = [JIM,'Mean_of_Frames',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(detectionStartFrame),' -End ',num2str(detectionEndFrame),maxProjectionString,' -NoNorm'];
system(cmd);

figure
channel1Im = cast(imread([workingDir,'Aligned_Partial_Mean.tiff']),'double');
channel1Im = (channel1Im-min(min(channel1Im)))./(prctile(reshape(channel1Im.',1,[]),99.5)-min(min(channel1Im)));
imshow(channel1Im);
disp('Average projection completed');

%% 6) Detect Particles
% User Defined Parameters 
%Thresholding
cutoff=0.2; % The cutoff for the initial thresholding

%Filtering
leftEdge = 20;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
rightEdge = 20;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
topEdge = 20;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottomEdge = 20;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases


minCount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount=100; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity = 0.4;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxLength = 10000000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.

minSeparation = 0;% Minimum separation between ROI's. Given by the closest edge between particles

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection
% Detection Program

cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(leftEdge),' -right ',num2str(rightEdge),' -top ',num2str(topEdge),' -bottom ',num2str(bottomEdge),' -maxDistFromLinear ',num2str(maxDistFromLinear),' -minSeparation ',num2str(minSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)

%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
channel1Im = cast(imread([workingDir,'Aligned_Partial_Mean.tiff']),'double');
flatim = sort(reshape(channel1Im,[],1),'descend');
fivepclen = round(0.05*length(flatim));
channel1Im = displayMax.*(channel1Im-flatim(end-fivepclen))./(flatim(fivepclen)-flatim(end-fivepclen))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Detected_Regions.tif']));
channel3Im = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage)
disp('Finish detecting particles');
%% 6.5)Background Detection 

backgroundUseMaxProjection = false;

backgroundDetectionStartFrame = '5 -15';
backgroundDetectionEndFrame = '15 -1';

backgroundMaxProjectionString = '';
if backgroundUseMaxProjection
    backgroundMaxProjectionString = ' -MaxProjection';
end

cmd = [JIM,'Mean_of_Frames',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Background"',allChannelNames,' -Start ',num2str(backgroundDetectionStartFrame),' -End ',num2str(backgroundDetectionEndFrame),backgroundMaxProjectionString,' -NoNorm'];
system(cmd);

figure
channel1Im = cast(imread([workingDir,'Background_Partial_Mean.tiff']),'double');
channel1Im = (channel1Im-min(min(channel1Im)))./(prctile(reshape(channel1Im.',1,[]),99.5)-min(min(channel1Im)));
imshow(channel1Im);
%%
backgroundCutoff = 0.2;

cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(backgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd);

figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
channel1Im = cast(imread([workingDir,'Background_Partial_Mean.tiff']),'double');
flatim = sort(reshape(channel1Im,[],1),'descend');
fivepclen = round(0.05*length(flatim));
channel1Im = displayMax.*(channel1Im-flatim(end-fivepclen))./(flatim(fivepclen)-flatim(end-fivepclen))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Background_Detected_Regions.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im);
imshow(combinedImage)

disp('Average projection completed');
%% 7)Calculate the equivalent positions in the other channels
if numberOfChannels > 1
    cmd = [JIM,'Other_Channel_Positions',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Detected_Filtered" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingDir,'Background_Detected_Positions.csv"'];
    system(cmd)
end
disp('Calculated equivalent position in other channels');

%% 8) Expand Regions 
foregroundDist = 4.1; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backInnerDist = 4.1;
backOuterDist = 20; % Distance to dilate beyond the ROI to measure the local background

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Background_Detected_Positions.csv" "',workingDir,'Expanded_Channel_1" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
system(cmd)

for j = 2:numberOfChannels
    cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd)
end

base = 'Aligned_initial_partial_mean_';

for i=1:numberOfChannels
    figure('Name',['Channel ',num2str(i),' Detected Particles - Red Original Image - Green ROIs - Blue Background Regions'])

    imout{1} = im2double(imread([workingDir,base,num2str(i),'.tiff']));

    imout{1} = displayMax.*(imout{1}-min(min(imout{1})))./(prctile(reshape(imout{1}.',1,[]),99.5)-min(min(imout{1})))+displayMin;
    imout{1} = min(max(imout{1},0),1);
    imout{2} = im2double(imread([workingDir,'Expanded_Channel_',num2str(i),'_ROIs.tif']));
    imout{3} = im2double(imread([workingDir,'Expanded_Channel_',num2str(i),'_Background_Regions.tif']));
    combinedImage = cat(3, overlayColour1(1).*imout{1}+overlayColour2(1).*imout{2}+overlayColour3(1).*imout{3},overlayColour1(2).*imout{1}+overlayColour2(2).*imout{2}+overlayColour3(2).*imout{3},overlayColour1(3).*imout{1}+overlayColour2(3).*imout{2}+overlayColour3(3).*imout{3});
    imshow(combinedImage);
end
disp('Finished Expanding ROIs');

%% 9) Calculate Traces
verboseOutput = false;

verboseString = '';
if verboseOutput
    verboseString = ' -Verbose';
end

cmd = [JIM,'Calculate_Traces',fileEXE,' "',workingDir,'Images_Channel_1.tif" "',workingDir,'Expanded_Channel_1_ROI_Positions.csv" "',workingDir,'Expanded_Channel_1_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',verboseString];
system(cmd)
for j = 2:numberOfChannels
    cmd = [JIM,'Calculate_Traces',fileEXE,' "',workingDir,'Images_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingDir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Detected_Filtered_Drifts_Channel_',num2str(j),'.csv"',verboseString];
    system(cmd)
end

variableString = ['Date, ', datestr(datetime('today')),'\nadditionalExtensionsToRemove,',num2str(additionalExtensionsToRemove)...
    ,'\nmultipleFilesPerImageStack,',num2str(multipleFilesPerImageStack)...
    ,'\nnumberOfChannels,', num2str(numberOfChannels)...
    ,'\niterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame)...
    ,'\nmanualAlignment,',num2str(manualAlignment),'\nrotationAngle,',num2str(rotationAngle),'\nscalingFactor,', num2str(scalingFactor),'\nxoffset,', num2str(xoffset),'\nyoffset,', num2str(yoffset),'\nmaxShift,', num2str(maxShift)...
    ,'\nmaxIntesities,',maxIntensities,'\nSNRCutoff,',num2str(SNRCutoff)...
    ,'\nuseMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', detectionStartFrame,'\ndetectionEndFrame,', detectionEndFrame...
    ,'\ncutoff,',num2str(cutoff),'\nleft,', num2str(leftEdge),'\nright,', num2str(rightEdge),'\ntop,', num2str(topEdge),'\nbottom,', num2str(bottomEdge)...
    ,'\nminCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity)...
    ,'\nminLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\nminSeparation,', num2str(minSeparation)...
    ,'\nforegroundDist,',num2str(foregroundDist),'\nbackInnerDist,', num2str(backInnerDist),'\nbackOuterDist,', num2str(backOuterDist),'\nverboseOutput,', num2str(verboseOutput)];

fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
fprintf(fileID, variableString);
fclose(fileID);

disp('Finished Generating Traces');

%%
threshold = 600;
channelNum = 2;
cmd = ['picasso localize "' workingDir 'Images_Channel_' num2str(channelNum) '.tif" -b 9 -g ' num2str(threshold) ' -bl 100'];
system(cmd);
%%
picData = h5read([workingDir 'Images_Channel_2_locs.hdf5'],'/locs');
jimDrifts = csvread([workingDir,'Detected_Filtered_Drifts_Channel_2.csv'],1,0);
%%
for i=1:length(picData.x)
    picData.x(i) = picData.x(i)+jimDrifts(picData.frame(i)+1,1);
    picData.y(i) = picData.y(i)+jimDrifts(picData.frame(i)+1,2);
end
%%
struct2hdf5(picData,'/locs',workingDir(1:end-1),'Images_Channel_2_locs_undrift.hdf5');
copyfile([workingDir 'Images_Channel_2_locs.yaml'],[workingDir 'Images_Channel_2_locs_undrift.yaml']);
    %%
jimPos = csvread([workingDir 'Expanded_Channel_2_ROI_Positions.csv'],1,0);
%%
imWidth = jimPos(1,1);
imHeight = jimPos(1,2);
imPos = cast(zeros(imWidth,imHeight),'int32');
imPos2 = zeros(imWidth,imHeight);

for i=2:size(jimPos,1)
    toadd = jimPos(i,:);
    toadd = toadd(toadd>0);
    for j=1:length(toadd)
       imPos(mod(toadd(j),imWidth)+1,floor(toadd(j)/imWidth)+1)=i-1; 
       imPos2(mod(toadd(j),imWidth)+1,floor(toadd(j)/imWidth)+1)=(i-1)/size(jimPos,1); 
    end
end
%%
picData = h5read([workingDir 'Images_Channel_2_locs_undrift.hdf5'],'/locs');

%%
picData.group = cast(zeros(length(picData.x),1),'int32');
for i=1:length(picData.x)
    if ceil(picData.x(i))>imWidth || ceil(picData.y(i))>imHeight
        picData.group(i) = 0;
    else
        picData.group(i) = imPos(ceil(picData.x(i)),ceil(picData.y(i)));
    end
end
picData = IndexedStructCopy(picData,picData.group>0);
%%
meanx = arrayfun(@(z) mean(picData.x(picData.group==z)),1:max(picData.group));
meany = arrayfun(@(z) mean(picData.y(picData.group==z)),1:max(picData.group));
%%
xin = arrayfun(@(z) picData.x(z) - meanx(picData.group(z)),1:length(picData.x));
yin = arrayfun(@(z) picData.y(z) - meany(picData.group(z)),1:length(picData.y));
%%
driftx = arrayfun(@(z) mean(xin(picData.frame==z)),1:(max(picData.frame)+1));
drifty = arrayfun(@(z) mean(yin(picData.frame==z)),1:(max(picData.frame)+1));
%%
for i=1:length(picData.x)
    picData.x(i) = picData.x(i) - driftx(picData.frame(i)+1);
    picData.y(i) = picData.y(i) - drifty(picData.frame(i)+1);
end
%%
struct2hdf5(picData,'/locs',workingDir(1:end-1),'Picasso_JIM_ROI.hdf5');
copyfile([workingDir 'Images_Channel_2_locs_undrift.yaml'],[workingDir 'Picasso_JIM_ROI.yaml']);
%%








%% 11) Detect files for batch
filesInSubFolders = true; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep];

if filesInSubFolders
    allFolders = arrayfun(@(x)[fileName,x.name],dir(fileName),'UniformOutput',false); % find everything in the input folder
    allFolders = allFolders(arrayfun(@(x) isdir(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
else
    allFolders = {fileName};
end
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),fileSep,x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
allFiles = allFiles(contains(allFiles,'.tif','IgnoreCase',true));

if multipleFilesPerImageStack
    allFolders = arrayfun(@(x) fileparts(allFiles{x}),1:max(size(allFiles)),'UniformOutput',false);
    [~,folderPos] = unique(allFolders);
    allFiles = allFiles(folderPos);
end
NumberOfFiles=size(allFiles,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

%% 12) Batch Analyse
overwritePreviouslyAnalysed = true;
deleteWorkingImageStacks = false;

for i=11:NumberOfFiles
    
    completeName = allFiles{i};
    
    
    disp(['Analysing ',completeName]);
    % 3.2) Create folder for results
    [fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
    pathName = [fileNamein,fileSep];
    for j=1:additionalExtensionsToRemove
        workingDir = [fileNamein,fileSep,name];
        [fileNamein,name,~] = fileparts(workingDir);
    end
    workingDir = [fileNamein,fileSep,name,fileSep];
    
    if ~exist(workingDir, 'dir')
        mkdir(workingDir)%make a subfolder with that name
    end
    
    if (exist([workingDir,'Channel_1_Fluorescent_Intensities.csv'],'file')==2 && overwritePreviouslyAnalysed==false)
        disp(['Skipping ',completeName,' - Analysis already exists']);
        continue
    end
    
    if multipleFilesPerImageStack
        completeName = arrayfun(@(x)['"',pathName,x.name,'" '],dir(pathName)','UniformOutput',false);
        completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
        completeName = horzcat(completeName{:});
    else
        completeName = ['"',completeName,'" '];
    end


    
   % 3.3) Split File into individual channels 
    startFrame = washoutframes(i,1);
    endFrame = -1;
    if (isempty(channelsToTransform))
        cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),' -StartFrame ',num2str(startFrame),' -EndFrame ',num2str(endFrame),metadatastr]; % Run TIFFChannelSplitter',fileEXE,' using the metadata  and write the split channels to the reults folder with the prefix Images
    else
        cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),' -Transform ',channelsToTransform,' ',VerticalFlipChannel,' ',HorizontalFlipChannel,' ',RotateChannel,' -StartFrame ',num2str(startFrame),' -EndFrame ',num2str(endFrame),metadatastr];
    end
    returnVal = system(cmd);
    
    % 3.4) Align Channels and Calculate Drifts 
    

    allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
    for j = 1:numberOfChannels
        allChannelNames = [allChannelNames,' "',workingDir,'Images_Channel_',num2str(j),'.tif"'];
    end

    if numberOfChannels==1
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift)];
    elseif manualAlignment
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Alignment ',xoffset,' ',yoffset,' ',rotationAngle,' ',scalingFactor,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),outputFiles];
    else
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),' -MaxIntensities ',maxIntensities,' -SNRCutoff ',num2str(SNRCutoff),outputFiles];
    end
    returnVal = system(cmd);



    % make submean
    cmd = [JIM,'Mean_of_Frames',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(detectionStartFrame),' -End ',num2str(detectionEndFrame),maxProjectionString,' -NoNorm'];
    system(cmd);
    
    % 3.5) Detect Particles

    cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(leftEdge),' -right ',num2str(rightEdge),' -top ',num2str(topEdge),' -bottom ',num2str(bottomEdge),' -maxDistFromLinear ',num2str(maxDistFromLinear),' -minSeparation ',num2str(minSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd);
    
    %background Detect
    cmd = [JIM,'Mean_of_Frames',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Background"',allChannelNames,' -Start ',num2str(backgroundDetectionStartFrame),' -End ',num2str(backgroundDetectionEndFrame),backgroundMaxProjectionString,' -NoNorm'];
    system(cmd);
    
    cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(backgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd);
    
    %3.6
    if numberOfChannels > 1
        cmd = [JIM,'Other_Channel_Positions',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Detected_Filtered" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingDir,'Background_Detected_Positions.csv"'];
        system(cmd)
    end


    % 3.7) Fit areas around each shape 

    cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded_Channel_1" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd);

    for j = 2:numberOfChannels
        cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
        system(cmd);
    end

    % 3.8) Calculate amplitude for each frame for each channel
    cmd = [JIM,'Calculate_Traces',fileEXE,' "',workingDir,'Images_Channel_1.tif" "',workingDir,'Expanded_Channel_1_ROI_Positions.csv" "',workingDir,'Expanded_Channel_1_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',verboseString];
    system(cmd);
    for j = 2:numberOfChannels
        cmd = [JIM,'Calculate_Traces',fileEXE,' "',workingDir,'Images_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingDir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Detected_Filtered_Drifts_Channel_',num2str(j),'.csv"',verboseString];
        system(cmd);
    end
    
    fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
    fprintf(fileID, variableString);
    fclose(fileID);
    
    
    cmd = ['picasso localize "' workingDir 'Images_Channel_' num2str(channelNum) '.tif" -b 9 -g ' num2str(threshold) ' -bl 100 -d 5'];
    system(cmd);

    cmd = ['picasso render "' workingDir 'Images_Channel_' num2str(channelNum) '_locs_undrift.hdf5" -o 1 -b none --scaling yes -c gray -s'];
    returnVal = system(cmd);
    Imin = imread([workingDir 'Images_Channel_' num2str(channelNum) '_locs_undrift.png']);
    Imin = cast(Imin(:, :, 1),'uint16').*255;
    imwrite(Imin,[workingDir 'Picasso_out.tif'],'Compression','none')

    cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Picasso_Aligned" "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Picasso_out.tif" -Start ',num2str(1),' -End ',num2str(1),' -Iterations ',num2str(1),' -MaxShift ',num2str(30)];
    returnVal = system(cmd);

    cmd = [JIM,'Other_Channel_Positions',fileEXE,' "',workingDir,'Picasso_Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Picasso" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions "',workingDir,'Background_Detected_Positions.csv"'];
    system(cmd)

    cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Picasso_Positions_Channel_2.csv" "',workingDir,'Picasso_Background_Positions_Channel_2.csv" "',workingDir,'Picasso_Expanded" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd)

    jimPos = csvread([workingDir 'Picasso_Expanded_ROI_Positions.csv'],1,0);

    imWidth = jimPos(1,1);
    imHeight = jimPos(1,2);
    imPos = cast(zeros(imWidth,imHeight),'int32');

    for i=2:size(jimPos,1)
        toadd = jimPos(i,:);
        toadd = toadd(toadd>0);
        for j=1:length(toadd)
           imPos(mod(toadd(j),imWidth)+1,floor(toadd(j)/imWidth)+1)=i-1; 
        end
    end

    picData = h5read([workingDir 'Images_Channel_2_locs_undrift.hdf5'],'/locs');

    picData.group = cast(zeros(length(picData.x),1),'int32');
    for j=1:length(picData.x)
        picData.group(j) = imPos(ceil(picData.x(j)),ceil(picData.y(j)));
    end

    struct2hdf5(picData,'/locs',workingDir(1:end-1),'Picasso_JIM_ROI.hdf5');
    copyfile([workingDir 'Images_Channel_2_locs_undrift.yaml'],[workingDir 'Picasso_JIM_ROI.yaml']);
    
    
    %Delete working files
    if deleteWorkingImageStacks
        for j=1:numberOfChannels
            delete([workingDir,'Images_Channel_',num2str(j),'.tif']);
        end
    end
end

disp('Batch Process Completed');
