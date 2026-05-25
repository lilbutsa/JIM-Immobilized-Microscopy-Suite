clear
%% 1) Select the input tiff file and Create a Folder for results
additionalExtensionsToRemove = 0; %remove extra .ome from working folder name if you want to
multipleFilesPerImageStack = false ; % choose this if you're stack is split over multiple tiff files (i.e. >4Gb)

% Default directory for input file selector e.g.
% sysVar.defaultFolder = 'C:\Users\jameswa\Google Drive\Jim\Jim_Compressed\Examples_v2_To_Run\';
[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
sysVar.defaultFolder = [fileparts(sysConst.JIM) '\Examples_v2_To_Run\']; %by default it will go to the example files

% Change the overlay colours for colourblind as desired. In RGB, values from 0 to 1
sysVar.overlayColour1 = [1, 0, 0];
sysVar.overlayColour2 = [0, 1, 0];
sysVar.overlayColour3 = [0, 0, 1];

%Don't Touch From Here
for toCollapse = 1
[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
sysConst.fileEXE = '"';

if ismac
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'/Mac_Programs/'];
elseif ispc
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'\Jim_Programs\'];
    sysConst.fileEXE = '.exe"';
else
    disp('Platform not supported')
end

[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Image sysVar.file',sysVar.defaultFolder);%Open the Dialog box to select the initial sysVar.file to analyze

completeName = [sysVar.pathName,sysVar.fileName];
[sysVar.fileNamein,sysVar.name,~] = fileparts(completeName);%get the name of the tiff image
for j=1:additionalExtensionsToRemove
    workingDir = [sysVar.fileNamein,filesep,sysVar.name];
    [sysVar.fileNamein,sysVar.name,~] = fileparts(sysVar.workingDir);
end
workingDir = [sysVar.fileNamein,filesep,sysVar.name,filesep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end

if multipleFilesPerImageStack
    completeName = arrayfun(@(x)['"',sysVar.pathName,x.name,'" '],dir(sysVar.pathName)','UniformOutput',false);
    completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
    completeName = sort(completeName);
    completeName = horzcat(completeName{:});
else
    completeName = ['"',completeName,'" '];
end
end

%% 2) Organise Channels 
imStackNumberOfChannels = 1; % Input the number of channels in the data

%Transform channels so they roughly overlay each other
imStackChannelsToTransform = '';% If no channels need to be transformed set channelsToTransform = '', otherwise channel numbers spearated by spaces '2 3' for channels 2 and 3;
imStackVerticalFlipChannel = '1';% For each channel to be transformed put 1 to flip that channel or 0 to not. eg. '1 0' to flip channel 2 but not 3.
imStackHorizontalFlipChannel = '0';% Same as vertical
imStackRotateChannel = '0';%rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel

imStackDisableMetadata = true ; % Images are usually split using embedded OME metadata but can be disabled if this causes problems

imStackStartFrame = 1; % Part of the image stack can be completely ignored for all downstream analysis, set to 1 to start from the first frame
imStackEndFrame = -1; % Last frame to take. Negative numbers go from the end of the stack, so set to -1 to take the entire stack.

imStackPreSplitChannels = false ; % Some scopes output channels as individual files. These files can be organised in another script, in which case set this to true.

% Don't touch from here
for toCollapse = 1
    
sysVar.allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
for j = 1:imStackNumberOfChannels
sysVar.allChannelNames = [sysVar.allChannelNames,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif"'];
end
if ischar(imStackChannelsToTransform)==false
    imStackChannelsToTransform = num2str(imStackChannelsToTransform);
end

if ischar(imStackVerticalFlipChannel)==false
    imStackVerticalFlipChannel = num2str(imStackVerticalFlipChannel);
end

if ischar(imStackHorizontalFlipChannel)==false
    imStackHorizontalFlipChannel = num2str(imStackHorizontalFlipChannel);
end

if ischar(imStackRotateChannel)==false
    imStackRotateChannel = num2str(imStackRotateChannel);
end

if(imStackPreSplitChannels==false)
    sysConst.metadatastr = '';
    if(imStackDisableMetadata)
        sysConst.metadatastr = ' -DisableMetadata';
    end

    if (isempty(imStackChannelsToTransform)||all(isstrprop(mystr,'digit')|isstrprop(mystr,'wspace'))==false || contains(mystr,'0'))
        sysVar.cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame),sysConst.metadatastr]; % Run TIFFChannelSplitter',sysConst.fileEXE,' using the metadata  and write the split channels to the reults folder with the prefix Images
    else
        sysVar.cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -Transform ',imStackChannelsToTransform,' ',imStackVerticalFlipChannel,' ',imStackHorizontalFlipChannel,' ',imStackRotateChannel,' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame),sysConst.metadatastr];
    end
    sysVar.returnVal = system(sysVar.cmd);

    if length(dir([workingDir,'Raw_Image_Stack_*.tif']))~= imStackNumberOfChannels
        imStackNumberOfChannels = length(dir([workingDir,'Raw_Image_Stack_*.tif']));
        errordlg(['Metadata detected ' num2str(imStackNumberOfChannels) ' Channels. imStackNumberOfChannels has been changed to this value'],'Difference in Channels Detected'); 
    end
    if sysVar.returnVal==1
        errordlg('Check that channelsToTransform, VerticalFlipChannel, HorizontalFlipChannel and RotateChannel all have the same number of parameters.','Error Inputting Parameters. channelsToTransform should be the list of channels that need to be transformed. VerticalFlipChannel and HorizontalFlipChannel should state whether the respective channel should (1) or shouldnt (0) be flipped. rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel'); 
    elseif sysVar.returnVal~=0
        errordlg('An unknown error has occured while organising channels. See console for details','Error During Channel Splitting'); 
    end
end
disp('Organization completed');
end

%% 3) Align Channels and Calculate Drifts
alignIterations = 1; % Number of times to iterate drift correction calculations - 1 is fine if there minimal drift in the reference frames

alignStartFrame = 5;% Select reference frames where there is signal in all channels at the same time start frame from 1
alignEndFrame = 20;% 

alignMaxShift = 20; % Limit the mamximum distance that the program will shift images for alignment this can help stop false alignments

%Output the aligned image stacks. Note this is not required by JIM but can
%be helpful for visualization. To save space, aligned stack will not output in batch
%regarless of this value
outputAlignedStacks = false;

%Multi Channel Alignment from here

alignManually = false ; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
alignXoffset = '28.3 29.5';
alignYoffset = '1.7 0.2';
alignRotationAngle = '-0.35 -0.35';
alignScalingFactor = '0.997 1';

%Parmeters for Automatic Alignment
alignMaxIntensities = '1000 1000 1000';% Set a threshold so that during channel to channel alignment agregates are ignored
alignSNRCutoff = 1; % Set a minimum alignment SNR to throw warnings 

%If there is strong signal in both channels, or using manual alignment, this can speed up alignment. Don't use if you want independent drifts
skipIndependentDrifts = false;

%Don't touch from here
for toCollapse = 1

sysConst.skipIndDriftsStr = '';
if skipIndependentDrifts
    sysConst.skipIndDriftsStr = ' -SkipIndependentDrifts ';
end

sysConst.outputFiles = '';
if outputAlignedStacks
    sysConst.outputFiles = ' -OutputAligned ';
end

if imStackNumberOfChannels==1
    sysVar.cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',sysVar.allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),sysConst.outputFiles];
elseif alignManually
    sysVar.cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',sysVar.allChannelNames,' -Alignment ',alignXoffset,' ',alignYoffset,' ',alignRotationAngle,' ',alignScalingFactor,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),sysConst.outputFiles,sysConst.skipIndDriftsStr];
else
    sysVar.cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',sysVar.allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),' -MaxIntensities ',alignMaxIntensities,' -SNRCutoff ',num2str(alignSNRCutoff),sysConst.outputFiles,sysConst.skipIndDriftsStr];
end
sysVar.returnVal = system(sysVar.cmd);

if sysVar.returnVal == 0
    %view partial projection after
    sysVar.imout = cell(3,1);
    if imStackNumberOfChannels>1
        for i=1:3
            if i<= imStackNumberOfChannels
            sysVar.imout{i} = im2double(imread([workingDir,'Alignment_Reference_Frames_After.tiff'],i));
            sysVar.imout{i} = (sysVar.imout{i}-min(min(sysVar.imout{i})))./(prctile(reshape(sysVar.imout{i}.',1,[]),99.5)-min(min(sysVar.imout{i})));
            else
               sysVar.imout{i} = 0.*sysVar.imout{1};
            end
        end 
        
        sysVar.combinedImage = cat(3, sysVar.overlayColour1(1).*sysVar.imout{1}+sysVar.overlayColour2(1).*sysVar.imout{2}+sysVar.overlayColour3(1).*sysVar.imout{3},sysVar.overlayColour1(2).*sysVar.imout{1}+sysVar.overlayColour2(2).*sysVar.imout{2}+sysVar.overlayColour3(2).*sysVar.imout{3},sysVar.overlayColour1(3).*sysVar.imout{1}+sysVar.overlayColour2(3).*sysVar.imout{2}+sysVar.overlayColour3(3).*sysVar.imout{3});
        
        figure('Name','Reference Frames Projection After')
        imshow(sysVar.combinedImage);           
    end
   
    for i=1:3
        if i<= imStackNumberOfChannels
        sysVar.imout{i}=im2double(imread([workingDir,'Alignment_Full_Projection_After.tiff'],i));
        sysVar.imout{i} = (sysVar.imout{i}-min(min(sysVar.imout{i})))./(prctile(reshape(sysVar.imout{i}.',1,[]),99.5)-min(min(sysVar.imout{i})));
        else
           sysVar.imout{i} = 0.*sysVar.imout{1};
        end
    end
    
    if imStackNumberOfChannels>1
        sysVar.combinedImage = cat(3, sysVar.overlayColour1(1).*sysVar.imout{1}+sysVar.overlayColour2(1).*sysVar.imout{2}+sysVar.overlayColour3(1).*sysVar.imout{3},sysVar.overlayColour1(2).*sysVar.imout{1}+sysVar.overlayColour2(2).*sysVar.imout{2}+sysVar.overlayColour3(2).*sysVar.imout{3},sysVar.overlayColour1(3).*sysVar.imout{1}+sysVar.overlayColour2(3).*sysVar.imout{2}+sysVar.overlayColour3(3).*sysVar.imout{3});
    else
        sysVar.combinedImage = sysVar.imout{1};
    end
    figure('Name','Complete Stack Projection After')
    imshow(sysVar.combinedImage); 
    
end
disp('Alignment completed');
end
%% 4a) Make a SubAverage of Frames for each Channel for Detection 
detectUsingMaxProjection = false ; %Use a max projection rather than mean. This is better for short lived blinking particles

detectionStartFrame = '10'; %first frame of the reference region for detection for each channel
detectionEndFrame = '30'; %last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

%Each channel is multiplied by this value before they're combined. This is handy if one channel is much brigthter than another. 
detectWeights = '1' ;

% Don't Touch From Here
for toCollapse = 1
sysConst.maxProjectionString = '';
if detectUsingMaxProjection
    sysConst.maxProjectionString = ' -MaxProjection';
end

if ischar(detectionStartFrame)==false
    detectionStartFrame = num2str(detectionStartFrame);
end

if ischar(detectionEndFrame)==false
    detectionEndFrame = num2str(detectionEndFrame);
end

sysVar.cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Combined_Drift.csv" "',workingDir,'Image_For_Detection"',sysVar.allChannelNames,' -Start ',detectionStartFrame,' -End ',detectionEndFrame,sysConst.maxProjectionString,' -Weights ',detectWeights];
system(sysVar.cmd);

figure
sysVar.channel1Im = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
sysVar.channel1Im = (sysVar.channel1Im-min(min(sysVar.channel1Im)))./(prctile(reshape(sysVar.channel1Im.',1,[]),99.5)-min(min(sysVar.channel1Im)));
imshow(sysVar.channel1Im);
disp('Average projection completed');
end
%% 4b) Detect Particles

%Thresholding
detectionCutoff = 0.75; % The cutoff for the initial thresholding. Typically in range 0.25-2

%Filtering
detectLeftEdge = 0;% Excluded particles closer to the left edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
detectRightEdge = 0;% Excluded particles closer to the Right edge than this. 
detectTopEdge = 0;% Excluded particles closer to the Top edge than this. 
detectBottomEdge = 0;% Excluded particles closer to the Bottom edge than this. 

detectMinCount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount= 100000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = 0.4; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
detectMaxEccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

detectMinLength = 1; % Minimum number of pixels for the major axis of the best fit ellipse
detectMaxLength = 10000000; % Maximum number of pixels for the major axis of the best fit ellipse

detectMaxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.

detectMinSeparation = 0;% Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

sysVar.displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
sysVar.displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Don't Touch From Here
for toCollapse = 1
sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
system(sysVar.cmd)

%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
sysVar.channel1Im = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
sysVar.flatim = sort(reshape(sysVar.channel1Im,[],1),'descend');
sysVar.fivepclen = round(0.05*length(sysVar.flatim));
sysVar.channel1Im = sysVar.displayMax.*(sysVar.channel1Im-sysVar.flatim(end-sysVar.fivepclen))./(sysVar.flatim(sysVar.fivepclen)-sysVar.flatim(end-sysVar.fivepclen))+sysVar.displayMin;
sysVar.channel1Im= min(max(sysVar.channel1Im,0),1);
sysVar.channel2Im = im2double(imread([workingDir,'Detected_Regions.tif']));
sysVar.channel3Im = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
sysVar.combinedImage = cat(3, sysVar.overlayColour1(1).*sysVar.channel1Im+sysVar.overlayColour2(1).*sysVar.channel2Im+sysVar.overlayColour3(1).*sysVar.channel3Im,sysVar.overlayColour1(2).*sysVar.channel1Im+sysVar.overlayColour2(2).*sysVar.channel2Im+sysVar.overlayColour3(2).*sysVar.channel3Im,sysVar.overlayColour1(3).*sysVar.channel1Im+sysVar.overlayColour2(3).*sysVar.channel2Im+sysVar.overlayColour3(3).*sysVar.channel3Im);
imshow(sysVar.combinedImage)
disp('Finish detecting particles');
end
%% 5) Join Fragments
%Joining
maxAngle = 15;
maxJoinDist = 7;
maxLineDist = 7; % maximum joining distance to line of best fit

%Filtering

left2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

minCount2 = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount2=1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity2 = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity2 = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength2 = 15; %Minimum number of pixels for the major axis of the best fit ellipse
maxLength2 = 1000; %Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear2 = 1000000; % Maximum distance that a pixel can diviate from the major axis.

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%the actual program

cmd = [sysConst.JIM,'Join_Filaments',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Joined"  -minLength ',num2str(minLength2),' -maxLength ',num2str(maxLength2),' -minCount ',num2str(minCount2),' -maxCount ',num2str(maxCount2),' -minEccentricity ',num2str(minEccentricity2),' -maxEccentricity ',num2str(maxEccentricity2),' -left ',num2str(left2),' -right ',num2str(right2),' -top ',num2str(top2),' -bottom ',num2str(bottom2),' -maxDistFromLinear ',num2str(maxDistFromLinear2),' -maxAngle ',num2str(maxAngle),' -maxJoinDist ',num2str(maxJoinDist),' -maxLine ',num2str(maxLineDist)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)





% figure('Name','Input Regions - Red Original Image,  Green to Yellow->Original Regions, Blue-> Initial Lines')
% %channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
% channel1Im = im2double(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']));
% channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
% channel1Im= min(max(channel1Im,0),1);
% channel2Im = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
% channel3Im = im2double(imread([workingDir,'Joined_Initial_Lines.tif']));
% combinedImage = cat(3, sysVar.overlayColour1(1).*channel1Im+sysVar.overlayColour2(1).*channel2Im+sysVar.overlayColour3(1).*channel3Im,sysVar.overlayColour1(2).*channel1Im+sysVar.overlayColour2(2).*channel2Im+sysVar.overlayColour3(2).*channel3Im,sysVar.overlayColour1(3).*channel1Im+sysVar.overlayColour2(3).*channel2Im+sysVar.overlayColour3(3).*channel3Im);
% imshow(combinedImage)
% %truesize([900 900]);

% figure('Name','Joined Regions - Red Original Image,  Green to Yellow->Final Filtered Regions, Blue-> Final Joined Lines')
% %channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
% channel1Im = im2double(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']));
% channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
% channel1Im= min(max(channel1Im,0),1);
% channel2Im = im2double(imread([workingDir,'Joined_Filtered_Regions.tif']));
% channel3Im = im2double(imread([workingDir,'Joined_Joined_Lines.tif']));
% combinedImage = cat(3, sysVar.overlayColour1(1).*channel1Im+sysVar.overlayColour2(1).*channel2Im+sysVar.overlayColour3(1).*channel3Im,sysVar.overlayColour1(2).*channel1Im+sysVar.overlayColour2(2).*channel2Im+sysVar.overlayColour3(2).*channel3Im,sysVar.overlayColour1(3).*channel1Im+sysVar.overlayColour2(3).*channel2Im+sysVar.overlayColour3(3).*channel3Im);
% imshow(combinedImage)
% %truesize([900 900]);

figure('Name','Input Regions - Red Original Image,  Green to Yellow->Original Regions, Blue-> Initial Lines')
channel1Im= im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
channel2Im = im2double(imread([workingDir,'Joined_Filtered_Regions.tif']));
channel3Im = im2double(imread([workingDir,'Joined_Joined_Lines.tif']));
combinedImage = cat(3, sysVar.overlayColour1(1).*channel1Im+sysVar.overlayColour2(1).*channel2Im+sysVar.overlayColour3(1).*channel3Im,sysVar.overlayColour1(2).*channel1Im+sysVar.overlayColour2(2).*channel2Im+sysVar.overlayColour3(2).*channel3Im,sysVar.overlayColour1(3).*channel1Im+sysVar.overlayColour2(3).*channel2Im+sysVar.overlayColour3(3).*channel3Im);
imshow(combinedImage)
%truesize([900 900]);

measurefile = [workingDir,'Joined_Measurements.csv'];
allmeasures = csvread(measurefile,1,0);

figure('Name','Filament Length Distribution')
histogram(allmeasures(:,4),round(length(allmeasures(:,4))/3))



%% 6) Expand Regions and find kymograph lines

kymExtensionDist = 30;
kymWidth=5; % Perpendicular distance of foreground kymograph
kymBackWidth = 30; % Background Kymograph Width
backDist = 3; % Background Particles Expansion

cmd = [sysConst.JIM,'Kymograph_Positions',sysConst.fileEXE,' "',workingDir,'Joined_Measurements.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(kymWidth),' -backgroundDist ',num2str(kymBackWidth),' -backInnerRadius ',num2str(backDist),' -ExtendKymographs ',num2str(kymExtensionDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
system(cmd)


figure('Name','Kymograph Regions - Red Original Image - Green ROIs - Blue Background Regions')
%channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
channel1Im = im2double(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Expanded_ROIs.tif']));
channel3Im = im2double(imread([workingDir,'Expanded_Background_Regions.tif']));
combinedImage = cat(3, sysVar.overlayColour1(1).*channel1Im+sysVar.overlayColour2(1).*channel2Im+sysVar.overlayColour3(1).*channel3Im,sysVar.overlayColour1(2).*channel1Im+sysVar.overlayColour2(2).*channel2Im+sysVar.overlayColour3(2).*channel3Im,sysVar.overlayColour1(3).*channel1Im+sysVar.overlayColour2(3).*channel2Im+sysVar.overlayColour3(3).*channel3Im);
imshow(combinedImage)
%truesize([900 900]);

%% 7) Calculate Traces and Make kymographs
cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' ',completeName,' "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Alignment_Combined_Drift.csv"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)

%%
% variableString = ['Date, ', datestr(datetime('today')),'\n'...
%     ,'iterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame),'\n'...
%     ,'useMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', num2str(detectionStartFrame),'\ndetectionEndFrame,', num2str(detectionEndFrame),'\n'...
%     ,'cutoff,',num2str(cutoff),'\nleft,', num2str(left),'\nright,', num2str(right),'\ntop,', num2str(top),'\nbottom,', num2str(bottom),'\n'...
%     ,'minCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity),'\n'...
%     ,'minLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\n'...
%     ,'maxAngle,', num2str(maxAngle),'\nmaxJoinDist,', num2str(maxJoinDist),'\nmaxLineDist,', num2str(maxLineDist),'\n'...
%     ,'left2,', num2str(left2),'\nright2,', num2str(right2),'\ntop2,', num2str(top2),'\nbottom2,', num2str(bottom2),'\n'...
%     ,'minCount2,',num2str(minCount),'\nmaxCount2,', num2str(maxCount),'\nminEccentricity2,', num2str(minEccentricity2),'\nmaxEccentricity2,', num2str(maxEccentricity2),'\n'...
%     ,'minLength2,',num2str(minLength2),'\nmaxLength2,', num2str(maxLength2),'\nmaxDistFromLinear2,', num2str(maxDistFromLinear2),'\n'...
%     ,'kymExtensionDist,',num2str(kymExtensionDist),'\nkymWidth,',num2str(kymWidth),'\nbackDist,', num2str(backDist),'\nkymBackWidth,', num2str(kymBackWidth)];
% 
% fileID = fopen([workingDir,'Kymograph_Generation_Variables.csv'],'w');
% fprintf(fileID, variableString);
% fclose(fileID);
kymoAverage = 6;

kymdir = [workingDir,'Kymographs',filesep];
mkdir(kymdir);
cmd = [sysConst.JIM,'Make_Kymographs',sysConst.fileEXE,' "',workingDir,'Channel_1_Fluorescent_Intensities.csv" "',workingDir,'Channel_1_Fluorescent_Backgrounds.csv" "',workingDir,'Expanded_ROI_Positions.csv" "',kymdir,'Kymograph" -Average ' num2str(kymoAverage)]; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)

%% 8) Display kymographs

pageNumber = 1;

numberOfRows = 3;
numberOfColumns = 4;


measures = csvread([workingDir,'Joined_Measurements.csv'],1);
channel1Im = imread([workingDir,'Joined_Region_Numbers.tif']);
figure('Name','Particle Numbers');
imshow(channel1Im);
%truesize([900 900]);


figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:numberOfRows*numberOfColumns
    if i+numberOfRows*numberOfColumns*(pageNumber-1)<size(measures,1)
    subplot(numberOfRows,numberOfColumns,i)
    hold on
    channel1Im = im2double(imread([kymdir,'Kymograph_',num2str(i+numberOfRows*numberOfColumns*(pageNumber-1)),'.tif']));
    channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
    channel1Im= min(max(channel1Im,0),1);
    title(['Particle ' num2str(i+numberOfRows*numberOfColumns*(pageNumber-1)) ' x ' num2str(round(measures(i+numberOfRows*numberOfColumns*(pageNumber-1),1))) ' y ' num2str(round(measures(i+numberOfRows*numberOfColumns*(pageNumber-1),2)))])
    imshow(channel1Im);
    hold off
    end
end




%% Continue from here for batch processing
%
%
%
%
%
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

parfor i=1:NumberOfFiles
    
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
    
    if (isempty(channelsToTransform))
        cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),strDisableMetadata]; % Run TIFFChannelSplitter',fileEXE,' using the metadata  and write the split channels to the reults folder with the prefix Images
    else
        cmd = [JIM,'Tiff_Channel_Splitter',fileEXE,' "',workingDir,'Images" ',completeName,'-NumberOfChannels ',num2str(numberOfChannels),strDisableMetadata,' -Transform ',channelsToTransform,' ',VerticalFlipChannel,' ',HorizontalFlipChannel,' ',RotateChannel];
    end
    returnVal = system(cmd);
    numberOfFrames = length(imfinfo([workingDir,'Images_Channel_1.tiff']));
    
    % 3.4) Align Channels and Calculate Drifts 
    

    allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
    for j = 1:numberOfChannels
        allChannelNames = [allChannelNames,' "',workingDir,'Images_Channel_',num2str(j),'.tiff"'];
    end
    
    alignStartFrame = numberOfFrames-30;
    alignEndFrame = numberOfFrames;

    if numberOfChannels==1
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift)];
    elseif manualAlignment
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Alignment ',xoffset,' ',yoffset,' ',rotationAngle,' ',scalingFactor,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),outputFiles];
    else
        cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations),' -MaxShift ',num2str(maxShift),' -MaxIntensities ',maxIntensities,' -SNRCutoff ',num2str(SNRCutoff),outputFiles];
    end
    returnVal = system(cmd);


    % 3.5) Detect Particles
    detectionStartFrame = numberOfFrames-30;
    detectionEndFrame = numberOfFrames;
    % make submean
    cmd = [JIM,'Mean_of_Frames',fileEXE,' "',workingDir,'Aligned_channel_alignment.csv" "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned"',allChannelNames,' -Start ',num2str(detectionStartFrame),' -End ',num2str(detectionEndFrame),maxProjectionString];
    system(cmd);
    

    cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(leftEdge),' -right ',num2str(rightEdge),' -top ',num2str(topEdge),' -bottom ',num2str(bottomEdge),' -maxDistFromLinear ',num2str(maxDistFromLinear),' -minSeparation ',num2str(minSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)

    
    cmd = [JIM,'Join_Filaments',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Joined"  -minLength ',num2str(minLength2),' -maxLength ',num2str(maxLength2),' -minCount ',num2str(minCount2),' -maxCount ',num2str(maxCount2),' -minEccentricity ',num2str(minEccentricity2),' -maxEccentricity ',num2str(maxEccentricity2),' -left ',num2str(left2),' -right ',num2str(right2),' -top ',num2str(top2),' -bottom ',num2str(bottom2),' -maxDistFromLinear ',num2str(maxDistFromLinear2),' -maxAngle ',num2str(maxAngle),' -maxJoinDist ',num2str(maxJoinDist),' -maxLine ',num2str(maxLineDist)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)

    % 3.5) Fit areas around each shape
    cmd = [JIM,'Kymograph_Positions',fileEXE,' "',workingDir,'Joined_Measurements.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(kymWidth),' -backgroundDist ',num2str(kymBackWidth),' -backInnerRadius ',num2str(backDist),' -ExtendKymographs ',num2str(kymExtensionDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
    system(cmd)
    
    % 3.6) Calculate Sum of signal and background for each frame
    cmd = [JIM,'Calculate_Traces',fileEXE,' ',completeName,' "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)
    
%     variableString = ['Date, ', datestr(datetime('today')),'\n'...
%     ,'iterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame),'\n'...
%     ,'useMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', num2str(detectionStartFrame),'\ndetectionEndFrame,', num2str(detectionEndFrame),'\n'...
%     ,'cutoff,',num2str(cutoff),'\nleft,', num2str(left),'\nright,', num2str(right),'\ntop,', num2str(top),'\nbottom,', num2str(bottom),'\n'...
%     ,'minCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity),'\n'...
%     ,'minLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\n'...
%     ,'maxAngle,', num2str(maxAngle),'\nmaxJoinDist,', num2str(maxJoinDist),'\nmaxLine,', num2str(maxLineDist),'\n'...
%     ,'left2,', num2str(left2),'\nright2,', num2str(right2),'\ntop2,', num2str(top2),'\nbottom2,', num2str(bottom2),'\n'...
%     ,'minCount2,',num2str(minCount),'\nmaxCount2,', num2str(maxCount),'\nminEccentricity2,', num2str(minEccentricity2),'\nmaxEccentricity2,', num2str(maxEccentricity2),'\n'...
%     ,'minLength2,',num2str(minLength2),'\nmaxLength2,', num2str(maxLength2),'\nmaxDistFromLinear2,', num2str(maxDistFromLinear2),'\n'...
%     ,'KymExtensionDist,',num2str(kymExtensionDist),'\nkymWidth,',num2str(kymWidth),'\nbackDist,', num2str(backDist),'\nkymBackWidth,', num2str(kymBackWidth)];
% 
%     fileID = fopen([workingDir,'Kymograph_Generation_Variables.csv'],'w');
%     fprintf(fileID, variableString);
%     fclose(fileID);
    
    
    kymdir = [workingDir,'\Kymographs\'];
    mkdir(kymdir);
    cmd = [JIM,'Make_Kymographs',fileEXE,' "',workingDir,'Channel_1_Fluorescent_Intensities.csv" "',workingDir,'Channel_1_Fluorescent_Backgrounds.csv" "',workingDir,'Expanded_ROI_Positions.csv" "',kymdir,'Kymograph" -Average ' num2str(kymoAverage)];% Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)
end


