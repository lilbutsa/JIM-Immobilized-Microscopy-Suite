clear
%% 0) (Optional) Load parameters into this script

[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Parameter File');
completeName = [sysVar.pathName,sysVar.fileName];
sysVar.paramtab = readtable(completeName,'Format','%s%s');
sysVar.paramtab = sysVar.paramtab(2:end,:);
sysVar.paramtab = table2cell(sysVar.paramtab);
[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
sysVar.line = splitlines(fileread([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m']));

sysVar.paramIsString = [7 8 9 10 16 19 20 21 22 25 26 27 43 44 45];

for i=1:length(sysVar.paramtab)
    sysVar.toreplace = find(contains(sysVar.line,sysVar.paramtab{i,1},'IgnoreCase',true),1);
    sysVar.linein = sysVar.line{sysVar.toreplace};
    if max(sysVar.paramIsString==i)
        sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ''' sysVar.paramtab{i,2} '''' sysVar.linein(strfind(sysVar.linein,';'):end)];
    else
        sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ' sysVar.paramtab{i,2} sysVar.linein(strfind(sysVar.linein,';'):end)];

    end
end
sysVar.fid = fopen([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m'],'w');
for i=1:size(sysVar.line,1)
    fprintf(sysVar.fid,'%s\n',sysVar.line{i});
end
fclose(sysVar.fid);
matlab.desktop.editor.openAndGoToLine([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m'],24);

%% 1) Select the input tiff file and Create a Folder for results
additionalExtensionsToRemove = 0; %remove extra .ome from working folder name if you want to

[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%get JIM Folder

%Set JIM folder here if you have moved the generate traces file away from
%its normal location
%sysConst.JIM = 'C:\Users\jameswa\Google Drive\Jim\Jim_Compressed_v2';


% Default directory for input file selector e.g.
%sysVar.defaultFolder = 'G:\My_Jim';
sysVar.defaultFolder = [fileparts(sysConst.JIM) filesep 'Examples_To_Run' filesep]; %by default it will go to the example files

% Change the overlay colours for colourblind as desired. In RGB, values from 0 to 1
sysVar.overlayColour = [[1, 0, 0];[0, 1, 0];[0, 0, 1]];

%Don't Touch From Here


sysConst.fileEXE = '"';
if ismac
    sysConst.JIM = [fileparts(sysConst.JIM),'/c++_Base_Programs/Mac/'];
    source = dir([sysConst.JIM,'/*']);
    for j=1:length(source)
        cmd = ['chmod +x "',sysConst.JIM,source(j).name,'"'];
        system(cmd);
    end
    sysConst.JIM = ['"',sysConst.JIM];
    
elseif ispc
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'\c++_Base_Programs\Windows\'];
    sysConst.fileEXE = '.exe"';
else
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'/c++_Base_Programs/Linux/'];
end

[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Image sysVar.file',sysVar.defaultFolder);%Open the Dialog box to select the initial sysVar.file to analyze

completeName = [sysVar.pathName,sysVar.fileName];
[sysVar.fileNamein,sysVar.name,~] = fileparts(completeName);%get the name of the tiff image
for j=1:additionalExtensionsToRemove
    sysVar.workingDir = [sysVar.fileNamein,filesep,sysVar.name];
    [sysVar.fileNamein,sysVar.name,~] = fileparts(sysVar.workingDir);
end
workingDir = [sysVar.fileNamein,filesep,sysVar.name,filesep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end


completeName = ['"',completeName,'" '];


%% 2) Organise Image Stack into channels 
imStackMultipleFiles = false ; % choose this if you're stack is split over multiple tiff files (i.e. >4Gb)

imStackNumberOfChannels = 2; % Input the number of channels in the data

imStackDisableMetadata = true ; % Images are usually split using embedded OME metadata but can be disabled if this causes problems

imStackStartFrame = 1; % Part of the image stack can be completely ignored for all downstream analysis, set to 1 to start from the first frame
imStackEndFrame = -1; % Last frame to take. Negative numbers go from the end of the stack, so set to -1 to take the entire stack.

%Transform channels so they roughly overlay each other
imStackChannelsToTransform = '';% If no channels need to be transformed set channelsToTransform = '', otherwise channel numbers spearated by spaces '2 3' for channels 2 and 3;
imStackVerticalFlipChannel = '0 0';% For each channel to be transformed put 1 to flip that channel or 0 to not. eg. '1 0' to flip channel 2 but not 3.
imStackHorizontalFlipChannel = '1 0';% Same as vertical
imStackRotateChannel = '0 180';%rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel


% Don't touch from here
 
if (length(sscanf(imStackChannelsToTransform,"%f"))>=length(sscanf(imStackVerticalFlipChannel,"%f")) || length(sscanf(imStackChannelsToTransform,"%f"))>=length(sscanf(imStackHorizontalFlipChannel,"%f")) || length(sscanf(imStackChannelsToTransform,"%f"))>=length(sscanf(imStackRotateChannel,"%f")) )
        errordlg('Check that channelsToTransform, VerticalFlipChannel, HorizontalFlipChannel and RotateChannel all have the same number of parameters.','Error Inputting Parameters. channelsToTransform should be the list of channels that need to be transformed. VerticalFlipChannel and HorizontalFlipChannel should state whether the respective channel should (1) or shouldnt (0) be flipped. rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel'); 
end


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

sysVar.cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame)];

if imStackMultipleFiles
    sysVar.cmd = [ sysVar.cmd ,' -DetectMultipleFiles'];
end

if ~isempty(imStackChannelsToTransform)    
     sysVar.cmd = [ sysVar.cmd ,' -Transform ',imStackChannelsToTransform,' ',imStackVerticalFlipChannel,' ',imStackHorizontalFlipChannel,' ',imStackRotateChannel];
end

if(imStackDisableMetadata)
     sysVar.cmd = [ sysVar.cmd ,' -DisableMetadata'];
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



disp('Organization completed');

%% 3) Align Channels and Calculate Drifts
alignIterations = 3; % Number of times to iterate drift correction calculations - 1 is fine if there minimal drift in the reference frames

alignStartFrame = 1;% Select reference frames where there is signal in all channels at the same time start frame from 1
alignEndFrame = 20;% 

alignMaxShift = 50.00; % Limit the mamximum distance that the program will shift images for alignment this can help stop false alignments

%Output the aligned image stacks. Note this is not required by JIM but can
%be helpful for visualization. To save space, aligned stack will not output in batch
%regarless of this value
alignOutputStacks = true ;

%Multi Channel Alignment from here
%Parameters for Automatic Alignment
alignMaxIntensities = '65000 65000';% Set a threshold so that during channel to channel alignment agregates are ignored
alignSNRCutoff = 0.1; % Set a minimum alignment SNR to throw warnings 

%Parameters for Manual Alignment
alignManually = false ; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
alignXOffset = '0 0';
alignYOffset = '0 0';
alignRotationAngle = '0 0';
alignScalingFactor = '1 1';

% Visualisation saturationg percentages
displayMin = 0.05;
displayMax = 0.99;

%Don't touch from here

if (alignManually && (length(split(alignXOffset))<imStackNumberOfChannels-1 || length(split(alignYOffset))<imStackNumberOfChannels-1 || length(split(alignRotationAngle))<imStackNumberOfChannels-1 || length(split(alignScalingFactor))<imStackNumberOfChannels-1))
        errordlg('alignXOffset,alignYOffset,alignRotationAngle and alignScalingFactor each require one value for each channel that needs to be aligned to channel 1, separated by a space. e.g. ''5 -5'' for 3 channel data'); 
elseif (~alignManually && length(split(alignMaxIntensities))<imStackNumberOfChannels)
        errordlg('alignMaxIntensities requires one value for each channel separated by a space. e.g. ''65000 65000'' for 2 channel data'); 
end


sysVar.cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',sysVar.allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift)];

if alignManually
    sysVar.cmd = [sysVar.cmd,' -Alignment ',alignXOffset,' ',alignYOffset,' ',alignRotationAngle,' ',alignScalingFactor];
elseif imStackNumberOfChannels>1
    sysVar.cmd = [sysVar.cmd,' -MaxIntensities ',alignMaxIntensities,' -SNRCutoff ',num2str(alignSNRCutoff)];
end

if alignOutputStacks
    sysVar.cmd = [sysVar.cmd,' -OutputAligned '];
end

sysVar.returnVal = system(sysVar.cmd);

if sysVar.returnVal == 0
    %view partial projection after
    
    sysVar.imout = im2double(imread([workingDir,'Alignment_Full_Projection_Before.tiff'],1));
    if imStackNumberOfChannels>1
        sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
        for i=1:imStackNumberOfChannels
            sysVar.imout = im2double(imread([workingDir,'Alignment_Full_Projection_Before.tiff'],i));
            sysVar.tosort = sort(sysVar.imout(:));
            sysVar.imout = (sysVar.imout-sysVar.tosort(round(displayMin*length(sysVar.tosort))))./(sysVar.tosort(round(displayMax*length(sysVar.tosort)))-sysVar.tosort(round(displayMin*length(sysVar.tosort))));

            for j=1:3
                sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(i,j);
            end
        end 
    else
        sysVar.tosort = sort(sysVar.imout(:));
        sysVar.imout = (sysVar.imout-sysVar.tosort(round(displayMin*length(sysVar.tosort))))./(sysVar.tosort(round(displayMax*length(sysVar.tosort)))-sysVar.tosort(round(displayMin*length(sysVar.tosort))));
        sysVar.combinedImage = sysVar.imout;
    end
    
    figure('Name','Alignment Full Projection Before')
    imshow(sysVar.combinedImage);           

   
    sysVar.imout = im2double(imread([workingDir,'Alignment_Full_Projection_After.tiff'],1));
    if imStackNumberOfChannels>1
        sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
        for i=1:imStackNumberOfChannels
            sysVar.imout = im2double(imread([workingDir,'Alignment_Full_Projection_After.tiff'],i));
            sysVar.tosort = sort(sysVar.imout(:));
            sysVar.imout = (sysVar.imout-sysVar.tosort(round(displayMin*length(sysVar.tosort))))./(sysVar.tosort(round(displayMax*length(sysVar.tosort)))-sysVar.tosort(round(displayMin*length(sysVar.tosort))));

            for j=1:3
                sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(i,j);
            end
        end 
    else
        sysVar.tosort = sort(sysVar.imout(:));
        sysVar.imout = (sysVar.imout-sysVar.tosort(round(displayMin*length(sysVar.tosort))))./(sysVar.tosort(round(displayMax*length(sysVar.tosort)))-sysVar.tosort(round(displayMin*length(sysVar.tosort))));
        sysVar.combinedImage = sysVar.imout;
    end
    
    figure('Name','Alignment Full Projection After')
    imshow(sysVar.combinedImage);
    
end
disp('Alignment completed');

%% 4) Make a SubAverage of Frames for each Channel for Detection 
detectUsingMaxProjection = false ; %Use a max projection rather than mean. This is better for short lived blinking particles

detectPercent = false; % Set to false if specifying start and end frames in frame number or true to specify as a percent of stack length between 0 and 100.  
detectionStartFrame = '1 0'; %first frame of the reference region for detection for each channel
detectionEndFrame = '2 0'; %last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

%Each channel is multiplied by this value before they're combined. This is handy if one channel is much brigthter than another. 
detectWeights = '1 0';

% Visualisation saturationg percentages
displayMin = 0.05;
displayMax = 0.99;


% Don't Touch From Here
if length(split(detectionStartFrame))<imStackNumberOfChannels
    errordlg('detectionStartFrame requires one value for each channel separated by a space. e.g. ''1 1'' for 2 channel data'); 
elseif length(split(detectionEndFrame))<imStackNumberOfChannels
    errordlg('detectionEndFrame requires one value for each channel separated by a space. e.g. ''-1 -1'' for 2 channel data'); 
elseif length(split(detectWeights))<imStackNumberOfChannels
    errordlg('detectWeights requires one value for each channel separated by a space. e.g. ''1 1'' for 2 channel data'); 
else  
    if ischar(detectionStartFrame)==false
        detectionStartFrame = num2str(detectionStartFrame);
    end

    if ischar(detectionEndFrame)==false
        detectionEndFrame = num2str(detectionEndFrame);
    end

    sysVar.cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Image_For_Detection"',sysVar.allChannelNames,' -Start ',detectionStartFrame,' -End ',detectionEndFrame,' -Weights ',detectWeights];
    if detectUsingMaxProjection
        sysVar.cmd = [sysVar.cmd,' -MaxProjection'];
    end

    if detectPercent
        sysVar.cmd = [sysVar.cmd,' -Percent'];
    end

    system(sysVar.cmd);

    figure
    sysVar.imout = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
    tosort = sort(sysVar.imout(:));
    sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
    imshow(sysVar.imout);
end
disp('Average projection completed');

%% 5) Detect Particles

%Thresholding
detectionCutoff = 0.4; % The cutoff for the initial thresholding. Typically in range 0.25-2

%Filtering
detectLeftEdge = 25;% Excluded particles closer to the left edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
detectRightEdge = 25;% Excluded particles closer to the Right edge than this. 
detectTopEdge = 25;% Excluded particles closer to the Top edge than this. 
detectBottomEdge = 25;% Excluded particles closer to the Bottom edge than this. 

detectMinCount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount= 100; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = -0.10; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
detectMaxEccentricity = 0.5;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

detectMinLength = 0.00; % Minimum number of pixels for the major axis of the best fit ellipse
detectMaxLength = 10000.00; % Maximum number of pixels for the major axis of the best fit ellipse

detectMaxDistFromLinear = 10000.00; % Maximum distance that a pixel can diviate from the major axis.

detectMinSeparation = 10.00;% Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

% Visualisation saturationg percentages

displayMin = 0.05; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.95; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Don't Touch From Here

sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
system(sysVar.cmd)

%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
sysVar.imout = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
end
sysVar.imout = im2double(imread([workingDir,'Detected_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
end
sysVar.imout = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(3,j);
end

figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
imshow(sysVar.combinedImage)
disp('Finish detecting particles');

%% 6) Additional Background Detection - Use this to detect all other particles that are not in the detection image to cut around for background
additionBackgroundDetect = true ;% enable the additional detection. Disable if all particles were detected (before filtering) above.

additionBackgroundUseMaxProjection = true ; %Use a max projection rather than mean. This is better for short lived blinking particles

additionBackgroundPercent = false;

additionalBackgroundStartFrame = '0 1'; %first frame of the reference region for background detection
additionalBackgroundEndFrame = '0 -1';%last frame of background reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

additionalBackgroundWeights = '0 1';

additionBackgroundCutoff = 2; %Threshold for particles to be detected for background

% Visualisation saturationg percentages

displayMin = 0.05; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.99; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%don't touch from here

if additionBackgroundDetect
    
    if length(split(additionalBackgroundStartFrame))<imStackNumberOfChannels
        errordlg('additionalBackgroundStartFrame requires one value for each channel separated by a space. e.g. ''1 1'' for 2 channel data'); 
    elseif length(split(additionalBackgroundEndFrame))<imStackNumberOfChannels
        errordlg('additionalBackgroundEndFrame requires one value for each channel separated by a space. e.g. ''-1 -1'' for 2 channel data'); 
    elseif length(split(additionalBackgroundWeights))<imStackNumberOfChannels
        errordlg('additionalBackgroundWeights requires one value for each channel separated by a space. e.g. ''1 1'' for 2 channel data'); 
    end

    sysVar.cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Background"',sysVar.allChannelNames,' -Start ',additionalBackgroundStartFrame,' -End ',additionalBackgroundEndFrame,' -Weights ',additionalBackgroundWeights];
    if additionBackgroundUseMaxProjection
        sysVar.cmd = [sysVar.cmd,' -MaxProjection'];
    end   
    
    if additionBackgroundPercent
        sysVar.cmd = [sysVar.cmd,' -Percent'];
    end
    
    system(sysVar.cmd);

    sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(additionBackgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
    system(sysVar.cmd);

    sysVar.imout = cast(imread([workingDir,'Background_Partial_Mean.tiff']),'double');
    tosort = sort(sysVar.imout(:));
    sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
    sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
    for j=1:3
        sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
    end
    sysVar.imout = im2double(imread([workingDir,'Background_Detected_Regions.tif']));
    for j=1:3
        sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
    end

    figure('Name','Detected Particles - Red Original Image - Green to Yellow Selected Extra Backgrounds')
    imshow(sysVar.combinedImage)
    disp('Finish detecting particles');
    
end


%% 7) Expand Regions
expandForegroundDist = 4.10; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
expandBackInnerDist = 4.10; % Minimum distance to dilate beyond the ROI to measure the local background
expandBackOuterDist = 30.00; % Maximum distance to dilate beyond the ROI to measure the local background

sysVar.displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
sysVar.displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%don't touch from here

sysVar.cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(expandBackOuterDist),' -backInnerRadius ',num2str(expandBackInnerDist)];
if additionBackgroundDetect
    sysVar.cmd = [sysVar.cmd,' -extraBackgroundFile "',workingDir,'Background_Detected_Positions.csv"'];
end
if imStackNumberOfChannels > 1
    sysVar.cmd = [sysVar.cmd,' -channelAlignment "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv"'];
end

system(sysVar.cmd) 

sysVar.imout = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
end
sysVar.imout = im2double(imread([workingDir,'Expanded_ROIs.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
end
sysVar.imout = im2double(imread([workingDir,'Expanded_Background_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(3,j);
end

figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
imshow(sysVar.combinedImage);

disp('Finished Expanding ROIs');

%% 8) Calculate Traces
traceVerboseOutput = false ; % Create additional file with additional statistics on each particle in each frame. Warning, this file can get very large. In general you don't want this.

%don't touch from here
for j = 1:imStackNumberOfChannels
    sysVar.cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_ROI_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Alignment_Channel_',num2str(j),'.csv"'];
    if traceVerboseOutput
        sysVar.cmd = [sysVar.cmd,' -Verbose'];
    end  
    system(sysVar.cmd);    
end

%% Step-fit
stepfitEnable = true;
stepfitChannel = 1;
stepfitThreshold = 10;
if stepfitEnable
    sysVar.cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
    system(sysVar.cmd);
end

disp('Step fitting completed');
%% Save Parameters

sysConst.falsetrue = ['false';'true '];
sysConst.variableString = ['Date, ', datestr(datetime('today'))...
    ,'\nadditionalExtensionsToRemove,',num2str(additionalExtensionsToRemove)...
    ,'\nimStackMultipleFiles,',sysConst.falsetrue(imStackMultipleFiles+1,:)...
    ,'\nimStackNumberOfChannels,', num2str(imStackNumberOfChannels) ...
    ,'\nimStackDisableMetadata,', sysConst.falsetrue(imStackDisableMetadata+1,:)...
    ,'\nimStackStartFrame,', num2str(imStackStartFrame)...
    ,'\nimStackEndFrame,', num2str(imStackEndFrame)...    
    ,'\nimStackChannelsToTransform,', imStackChannelsToTransform...
    ,'\nimStackVerticalFlipChannel,', imStackVerticalFlipChannel ...
    ,'\nimStackHorizontalFlipChannel,', imStackHorizontalFlipChannel...
    ,'\nimStackRotateChannel,', imStackRotateChannel...
    ,'\nalignIterations,',num2str(alignIterations)...
    ,'\nalignStartFrame,', num2str(alignStartFrame)...
    ,'\nalignEndFrame,', num2str(alignEndFrame)...
    ,'\nalignMaxShift,', num2str(alignMaxShift)...
    ,'\nalignOutputStacks,',sysConst.falsetrue(alignOutputStacks+1,:)...
    ,'\nalignMaxIntensities,',alignMaxIntensities...
    ,'\nalignSNRCutoff,',num2str(alignSNRCutoff)...
    ,'\nalignManually,',sysConst.falsetrue(alignManually+1,:)...
    ,'\nalignXOffset,',alignXOffset...
    ,'\nalignYOffset,', alignYOffset...
    ,'\nalignRotationAngle,',alignRotationAngle...
    ,'\nalignScalingFactor,', alignScalingFactor...
    ,'\ndetectUsingMaxProjection,',sysConst.falsetrue(detectUsingMaxProjection+1,:)...
    ,'\ndetectPercent,',sysConst.falsetrue(detectPercent+1,:)...
    ,'\ndetectionStartFrame,', detectionStartFrame...
    ,'\ndetectionEndFrame,', detectionEndFrame...
    ,'\ndetectWeights,',detectWeights...
    ,'\ndetectionCutoff,',num2str(detectionCutoff)...
    ,'\ndetectLeftEdge,', num2str(detectLeftEdge)...
    ,'\ndetectRightEdge,', num2str(detectRightEdge)...
    ,'\ndetectTopEdge,', num2str(detectTopEdge)...
    ,'\ndetectBottomEdge,', num2str(detectBottomEdge)...
    ,'\ndetectMinCount,',num2str(detectMinCount)...
    ,'\ndetectMaxCount,', num2str(detectMaxCount)...
    ,'\ndetectMinEccentricity,', num2str(detectMinEccentricity)...
    ,'\ndetectMaxEccentricity,', num2str(detectMaxEccentricity)...
    ,'\ndetectMinLength,',num2str(detectMinLength)...
    ,'\ndetectMaxLength,', num2str(detectMaxLength)...
    ,'\ndetectMaxDistFromLinear,', num2str(detectMaxDistFromLinear)...
    ,'\ndetectMinSeparation,', num2str(detectMinSeparation)...
    ,'\nadditionBackgroundDetect,',sysConst.falsetrue(additionBackgroundDetect+1,:)...
    ,'\nadditionBackgroundUseMaxProjection,',sysConst.falsetrue(additionBackgroundUseMaxProjection+1,:)...
    ,'\nadditionBackgroundPercent,',sysConst.falsetrue(additionBackgroundPercent+1,:)...
    ,'\nadditionalBackgroundStartFrame,', additionalBackgroundStartFrame...
    ,'\nadditionalBackgroundEndFrame,', additionalBackgroundEndFrame...
    ,'\nadditionalBackgroundWeights,',additionalBackgroundWeights...
    ,'\nadditionBackgroundCutoff,',num2str(additionBackgroundCutoff)...
    ,'\nexpandForegroundDist,',num2str(expandForegroundDist)...
    ,'\nexpandBackInnerDist,', num2str(expandBackInnerDist)...
    ,'\nexpandBackOuterDist,', num2str(expandBackOuterDist)...
    ,'\ntraceVerboseOutput,', sysConst.falsetrue(traceVerboseOutput+1,:)...
    ,'\nstepfitEnable,', sysConst.falsetrue(stepfitEnable+1,:)...
    ,'\nstepfitChannel,', num2str(stepfitChannel)...
    ,'\nstepfitThreshold,', num2str(stepfitThreshold)...
    ];

sysVar.fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
fprintf(sysVar.fileID, sysConst.variableString);
fclose(sysVar.fileID);

disp('Finished Generating Traces');
%% (Optional) Save Copy of Parameters
[sysVar.file,sysVar.path] = uiputfile('*.csv','Save Parameter CSV File');
sysVar.fileID = fopen([sysVar.path,sysVar.file],'w');
fprintf(sysVar.fileID, sysVar.variableString);
fclose(sysVar.fileID);
%% 10) View Traces
montage.pageNumber =3; % Select the page number for traces. 28 traces per page. So traces from(n-1)*28+1 to n*28
montage.timePerFrame = 6;%Set to zero to just have frames
montage.timeUnits = 's'; % Unit to use for x axis 
montage.showStepfit = true;

%don't touch from here
for toCollapse = 1
if ~exist([workingDir 'Examples' filesep], 'dir')
    mkdir([workingDir 'Examples' filesep])%make a subfolder with that name
end

sysVar.measures = csvread([workingDir,'Detected_Filtered_Measurements.csv'],1);
sysVar.channel1Im = imread([workingDir,'Detected_Filtered_Region_Numbers.tif']);
figure('Name','Particle Numbers');
imshow(sysVar.channel1Im);


sysVar.allTraces = cell(imStackNumberOfChannels,1);
for j=1:imStackNumberOfChannels
    sysVar.allTraces{j} = csvread([workingDir,'Channel_',num2str(j),'_Fluorescent_Intensities.csv'],1);
end

sysVar.traces1=sysVar.allTraces{1};
sysVar.fact(1) = ceil(log10(max(max(sysVar.traces1))))-2;

if imStackNumberOfChannels>1
    sysVar.traces2=sysVar.allTraces{2};
    sysVar.fact(2) = ceil(log10(max(max(sysVar.traces2))))-2;
end

if montage.showStepfit && stepfitEnable
    sysVar.stepPoints = csvread([workingDir,'Channel_',num2str(stepfitChannel),'_StepPoints.csv'],1);
    sysVar.stepMeans = csvread([workingDir,'Channel_',num2str(stepfitChannel),'_StepMeans.csv'],1);
end


sysVar.opts.Colors= get(groot,'defaultAxesColorOrder');sysVar.opts.width= 17.78;sysVar.opts.height= 22.86;sysVar.opts.fontType= 'Myriad Pro';sysVar.opts.fontSize= 9;
sysVar.fig = figure; sysVar.fig.Units= 'centimeters';sysVar.fig.Position(3)= sysVar.opts.width;sysVar.fig.Position(4)= sysVar.opts.height;
set(sysVar.fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('LineWidth',1.5, 'FontName','Myriad Pro')
%set(gcf, 'Position', [100, 100, 1500, 800])
yyaxis left

montage.timeaxis = [1:size(sysVar.traces1,2)];
if montage.timePerFrame ~= 0
    montage.timeaxis = (montage.timeaxis-1).*montage.timePerFrame;
end

for i=1:28

    if i+28*(montage.pageNumber-1)<=size(sysVar.traces1,1)
        subplot(7,4,i)
        hold on
        title(['No. ' num2str(i+28*(montage.pageNumber-1)) ' x ' num2str(round(sysVar.measures(i+28*(montage.pageNumber-1),1))) ' y ' num2str(round(sysVar.measures(i+28*(montage.pageNumber-1),2)))])
        %title(['Particle ' num2str(i+28*(montage.pageNumber-1))],'FontName','Myriad Pro','FontSize',9)
        if imStackNumberOfChannels>1
            yyaxis left
        end
        if i==13
             ylabel(['Channel 1 Intensity (x10^{',num2str(sysVar.fact(1)),'} a.u.)'],'FontWeight','bold','FontSize',14)
        end

        plot(montage.timeaxis,sysVar.traces1(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(1)),'LineWidth',2)
        
        plot([0 max(montage.timeaxis)],[0 0] ,'-black');
        
        if montage.showStepfit && stepfitEnable
            sysVar.count = 0;
            sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
            for j=1:size(sysVar.traces1,2)
                if ismember(j-1,sysVar.stepPoints(i+28*(montage.pageNumber-1),:))
                    sysVar.count = sysVar.count +1;
                end
                sysVar.stepPlot(j) = sysVar.stepMeans(i+28*(montage.pageNumber-1),sysVar.count);
            end
            if stepfitChannel == 1
                plot(montage.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(1)),'-black','LineWidth',2)
            elseif stepfitChannel == 2
                plot(montage.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(2)),'-black','LineWidth',2)
            end
        end

        if imStackNumberOfChannels>1
            yyaxis right
            if i==16
                ylabel(['Channel 2 Intensity (x10^{',num2str(sysVar.fact(2)),'} a.u.)'],'FontWeight','bold','FontSize',14)
            end
            plot(montage.timeaxis,sysVar.traces2(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(2)),'LineWidth',2)

            for j=3:imStackNumberOfChannels
                traces=sysVar.allTraces{j};
                montage.c = colororder;
                plot(montage.timeaxis,traces(i+28*(montage.pageNumber-1),:).*max(sysVar.traces2(i+28*(montage.pageNumber-1),:))./(10.^sysVar.fact(2))./max(traces(i+28*(montage.pageNumber-1),:)),'-','LineWidth',2,'Color',montage.c(j,:))
            end

            [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(1)),'all');
            [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(2)),'all');
            sysVar.ratio = min([sysVar.yliml(1)/sysVar.yliml(2) sysVar.ylimr(1)/sysVar.ylimr(2) -0.05]);
            set(gca,'Ylim',sort([sysVar.ylimr(2)*sysVar.ratio sysVar.ylimr(2)]))
            yyaxis left
            set(gca,'Ylim',sort([sysVar.yliml(2)*sysVar.ratio sysVar.yliml(2)]))
        end
        xlim([0 max(montage.timeaxis)])
        hold off
    end
end
h = annotation('textbox',[0.5,0.08,0,0],'string',['Time (',montage.timeUnits,')'],'FontSize',14,'EdgeColor',"none",'FitBoxToText',true,'HorizontalAlignment','center','FontWeight','bold');
movegui(sysVar.fig);
%set(findobj(gcf,'type','axes'),'FontName','Myriad Pro','FontSize',9,'LineWidth', 1.5);
print([workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-dpng', '-r600');
print([workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-depsc', '-r600');
savefig(sysVar.fig,[workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)],'compact');
end
%% 11)Extract Individual Trace and montage
montage.traceNo = 285;
montage.start = 3;
montage.end = 48;
montage.delta = 5;
montage.average = 5;

montage.outputParticleImageStack = true;% Create a Tiff stack of the ROI of the particle

% Don't touch from here

sysVar.cmd = [sysConst.JIM,'Isolate_Particle',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Examples',filesep,'Example" ',sysVar.allChannelNames,' -Start ',num2str(montage.start),' -End ',num2str(montage.end),' -Particle ',num2str(montage.traceNo),' -Delta ',num2str(montage.delta),' -Average ',num2str(montage.average)];
if montage.outputParticleImageStack
    sysVar.cmd = [sysVar.cmd ' -outputImageStack'];
end

system(sysVar.cmd);   
    
sysVar.channel1Im = imread([workingDir,'Examples' filesep 'Example_Trace_' num2str(montage.traceNo) '_Range_' num2str(montage.start) '_' num2str(montage.delta) '_' num2str(montage.end) '_montage.tiff']);
figure('Name',['Particle ' num2str(montage.traceNo) ' montage']);
imshow(sysVar.channel1Im,'Border','tight','InitialMagnification',200);    

sysVar.opts.Colors= get(groot,'defaultAxesColorOrder');sysVar.opts.width=10;sysVar.opts.height= 6;sysVar.opts.fontType= 'Myriad Pro';sysVar.opts.fontSize= 9;
    sysVar.fig = figure; sysVar.fig.Units= 'centimeters';sysVar.fig.Position(3)= sysVar.opts.width;sysVar.fig.Position(4)= sysVar.opts.height;
    set(sysVar.fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
sysVar.ax = gca;

if imStackNumberOfChannels>1
    yyaxis left
end

ylabel(['Channel 1 Intensity ( a.u.)'])

plot(montage.timeaxis,sysVar.traces1(montage.traceNo,:),'LineWidth',2)
plot([0 max(montage.timeaxis)],[0 0] ,'-black');

if montage.showStepfit && stepfitEnable
    sysVar.count = 0;
    sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
    for j=1:size(sysVar.traces1,2)
        if ismember(j-1,sysVar.stepPoints(montage.traceNo,:))
            sysVar.count = sysVar.count +1;
        end
        sysVar.stepPlot(j) = sysVar.stepMeans(montage.traceNo,sysVar.count);
    end
    plot(montage.timeaxis,sysVar.stepPlot,'-black','LineWidth',2)

end

if imStackNumberOfChannels>1
    yyaxis right

    ylabel(['Channel 2 Intensity (a.u.)'])

    plot(montage.timeaxis,sysVar.traces2(montage.traceNo,:),'LineWidth',2)

    for j=3:imStackNumberOfChannels
        traces=sysVar.allTraces{j};
        montage.c = colororder;
        plot(montage.timeaxis,traces(montage.traceNo,:).*max(sysVar.traces2(montage.traceNo,max(montage.start-(montage.average-1)/2,1):min(montage.end+(montage.average-1)/2,length(montage.timeaxis))))./max(traces(montage.traceNo,max(montage.start-(montage.average-1)/2,1):min(montage.end+(montage.average-1)/2,length(montage.timeaxis)))),'-','LineWidth',2,'Color',montage.c(j,:))
    end
    [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(montage.traceNo,max(montage.start-(montage.average-1)/2,1):min(montage.end+(montage.average-1)/2,length(montage.timeaxis))),'all');
    [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(montage.traceNo,max(montage.start-(montage.average-1)/2,1):min(montage.end+(montage.average-1)/2,length(montage.timeaxis))),'all');
    sysVar.ratio = min([sysVar.yliml(1)/sysVar.yliml(2) sysVar.ylimr(1)/sysVar.ylimr(2) -0.05]);
    set(gca,'Ylim',[sysVar.ylimr(2)*sysVar.ratio sysVar.ylimr(2)])
    yyaxis left
    set(gca,'Ylim',[sysVar.yliml(2)*sysVar.ratio sysVar.yliml(2)])
end
xlim([0 montage.timeaxis(min(montage.end+(montage.average-1)/2,length(montage.timeaxis)))])
if montage.timePerFrame ==0
    xlabel('Frame')
else
    xlabel(['Time  (' montage.timeUnits ')'])
end
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
sysVar.fig.PaperPositionMode   = 'auto';

print([workingDir 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)], '-dpng', '-r600');
print([workingDir 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)], '-depsc', '-r600');
savefig(sysVar.fig,[workingDir 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)],'compact');


%% Continue from here for batch processing
%
%
%
%
%
%% 1) Detect files for batch
filesInSubFolders = true; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder


sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep];

if filesInSubFolders
    sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
    sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isdir(cell2mat(x)),sysVar.allFolders));
    sysVar.allFolders = sysVar.allFolders(3:end);
else
    sysVar.allFolders = {sysVar.fileName};
end
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),filesep,x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
allFiles = allFiles(contains(allFiles,'.tif','IgnoreCase',true));

if imStackMultipleFiles
    sysVar.allFolders = arrayfun(@(x) fileparts(allFiles{x}),1:max(size(allFiles)),'UniformOutput',false);
    [~,folderPos] = unique(sysVar.allFolders);
    allFiles = allFiles(folderPos);
end
sysConst.NumberOfFiles=size(allFiles,1);
disp(['There are ',num2str(sysConst.NumberOfFiles),' files to analyse']);

%% 2) Batch Analyse
overwritePreviouslyAnalysed = true;
deleteWorkingImageStacks = true;

parfor i=1:sysConst.NumberOfFiles
    
    completeName = allFiles{i};
    
    
    disp(['Analysing ',completeName]);
    % 3.2) Create folder for results
    [fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
    pathName = [fileNamein,filesep];
    
    for j=1:additionalExtensionsToRemove
        workingDir = [fileNamein,filesep,name];
        [fileNamein,name,~] = fileparts(workingDir);
    end
    workingDir = [fileNamein,filesep,name,filesep];
    
    if ~exist(workingDir, 'dir')
        mkdir(workingDir)%make a subfolder with that name
    end
    
    if (exist([workingDir,'Channel_1_Fluorescent_Intensities.csv'],'file')==2 && overwritePreviouslyAnalysed==false)
        disp(['Skipping ',completeName,' - Analysis already exists']);
        continue
    end
    
    if imStackMultipleFiles
        completeName = arrayfun(@(x)['"',pathName,x.name,'" '],dir(pathName)','UniformOutput',false);
        completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
        completeName = horzcat(completeName{:});
    else
        completeName = ['"',completeName,'" '];
    end


    
   % 3.3) Split File into individual channels 
    
    cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame)];

    if ~isempty(imStackChannelsToTransform)    
         cmd = [ cmd ,' -Transform ',imStackChannelsToTransform,' ',imStackVerticalFlipChannel,' ',imStackHorizontalFlipChannel,' ',imStackRotateChannel];
    end

    if(imStackDisableMetadata)
         cmd = [ cmd ,' -DisableMetadata'];
    end

    system(cmd);
    
    % 3.4) Align Channels and Calculate Drifts 

    allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
    for j = 1:imStackNumberOfChannels
        allChannelNames = [allChannelNames,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif"'];
    end

    cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift)];

    if alignManually
        cmd = [cmd,' -Alignment ',alignXOffset,' ',alignYOffset,' ',alignRotationAngle,' ',alignScalingFactor];
    elseif imStackNumberOfChannels>1
        cmd = [cmd,' -MaxIntensities ',alignMaxIntensities,' -SNRCutoff ',num2str(alignSNRCutoff)];
    end

%     if alignOutputStacks
%         cmd = [cmd,' -OutputAligned '];
%     end

    system(cmd);


    % make submean
    cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Image_For_Detection"',allChannelNames,' -Start ',detectionStartFrame,' -End ',detectionEndFrame,' -Weights ',detectWeights];
    if detectUsingMaxProjection
        cmd = [cmd,' -MaxProjection'];
    end
    if detectPercent
    	cmd = [cmd,' -Percent'];
    end

    system(cmd);
    
    % 3.5) Detect Particles

    cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
    system(cmd)
    
    %background Detect
    if additionBackgroundDetect

        cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Background"',allChannelNames,' -Start ',additionalBackgroundStartFrame,' -End ',additionalBackgroundEndFrame,' -Weights ',additionalBackgroundWeights];
        if additionBackgroundUseMaxProjection
            cmd = [cmd,' -MaxProjection'];
        end 
        if additionBackgroundPercent
            cmd = [cmd,' -Percent'];
        end

        system(cmd);

        cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(additionBackgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
        system(cmd);
    end


    % 3.7) Fit areas around each shape 

    cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(expandBackOuterDist),' -backInnerRadius ',num2str(expandBackInnerDist)];
    if additionBackgroundDetect
        cmd = [cmd,' -extraBackgroundFile "',workingDir,'Background_Detected_Positions.csv"'];
    end
    if imStackNumberOfChannels > 1
        cmd = [cmd,' -channelAlignment "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv"'];
    end
    
    system(cmd);

    % 3.8) Calculate amplitude for each frame for each channel
    
    for j = 1:imStackNumberOfChannels
        cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_ROI_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Alignment_Channel_',num2str(j),'.csv"'];
        if traceVerboseOutput
            cmd = [cmd,' -Verbose'];
        end  
        system(cmd);    
    end
    
    if stepfitEnable
        cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
        system(cmd);
    end
    
    fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
    fprintf(fileID, sysConst.variableString);
    fclose(fileID);
    
    %Delete working files
    if deleteWorkingImageStacks
        for j=1:imStackNumberOfChannels
            delete([workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif']);
        end
    end
end

disp('Batch Process Completed');
%% 3) Extract Traces to Separate Folder
%sysVar.fileName = 'G:\My_Jim\20221412_VLP_Len_5%488_50ms\';
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

