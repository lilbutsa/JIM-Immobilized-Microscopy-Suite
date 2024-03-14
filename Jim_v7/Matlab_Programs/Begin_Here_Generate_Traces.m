clear
%% 0) (Optional) Load parameters into this script

[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Parameter File');
completeName = [sysVar.pathName,sysVar.fileName];
sysVar.paramtab = readtable(completeName,'Format','%s%s');
sysVar.paramtab = sysVar.paramtab(2:end,:);
sysVar.paramtab = table2cell(sysVar.paramtab);
[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
sysVar.line = splitlines(fileread([sysConst.JIM,'\Begin_Here_Generate_Traces.m']));

sysVar.paramIsString = [7 8 9 10 16 19 20 21 22 24 25 26 42 43 44];
%%
for i=1:length(sysVar.paramtab)
    sysVar.toreplace = find(contains(sysVar.line,sysVar.paramtab{i,1},'IgnoreCase',true),1);
    sysVar.linein = sysVar.line{sysVar.toreplace};
    if max(sysVar.paramIsString==i)
        sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ''' sysVar.paramtab{i,2} '''' sysVar.linein(strfind(sysVar.linein,';'):end)];
    else
        sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ' sysVar.paramtab{i,2} sysVar.linein(strfind(sysVar.linein,';'):end)];

    end
end
sysVar.fid = fopen([sysConst.JIM,'\Begin_Here_Generate_Traces.m'],'w');
for i=1:size(sysVar.line,1)
    fprintf(sysVar.fid,'%s\n',sysVar.line{i});
end
fclose(sysVar.fid);
matlab.desktop.editor.openAndGoToLine([sysConst.JIM,'\Begin_Here_Generate_Traces.m'],24);

%% 1) Select the input tiff file and Create a Folder for results
additionalExtensionsToRemove = 0; %remove extra .ome from working folder name if you want to
multipleFilesPerImageStack = false ; % choose this if you're stack is split over multiple tiff files (i.e. >4Gb)

[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%get JIM Folder

%Set JIM folder here if you have moved the generate traces file away from
%its normal location
%sysConst.JIM = 'C:\Users\jameswa\Google Drive\Jim\Jim_Compressed_v2';


% Default directory for input file selector e.g.
%sysVar.defaultFolder = 'G:\My_Jim';
sysVar.defaultFolder = [fileparts(sysConst.JIM) '\Examples_v2_To_Run\']; %by default it will go to the example files

% Change the overlay colours for colourblind as desired. In RGB, values from 0 to 1
sysVar.overlayColour1 = [1, 0, 0];
sysVar.overlayColour2 = [0, 1, 0];
sysVar.overlayColour3 = [0, 0, 1];

%Don't Touch From Here


sysConst.fileEXE = '"';
if ismac
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'/c++_Base_Programs/Mac/'];
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

if multipleFilesPerImageStack
    completeName = arrayfun(@(x)['"',sysVar.pathName,x.name,'" '],dir(sysVar.pathName)','UniformOutput',false);
    completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
    completeName = sort(completeName);
    completeName = horzcat(completeName{:});
else
    completeName = ['"',completeName,'" '];
end

%% 2) Organise Image Stack into channels 
imStackNumberOfChannels = 1; % Input the number of channels in the data

imStackDisableMetadata = true; % Images are usually split using embedded OME metadata but can be disabled if this causes problems

imStackStartFrame = 1; % Part of the image stack can be completely ignored for all downstream analysis, set to 1 to start from the first frame
imStackEndFrame = -1; % Last frame to take. Negative numbers go from the end of the stack, so set to -1 to take the entire stack.

%Transform channels so they roughly overlay each other
imStackChannelsToTransform = '';% If no channels need to be transformed set channelsToTransform = '', otherwise channel numbers spearated by spaces '2 3' for channels 2 and 3;
imStackVerticalFlipChannel = '1';% For each channel to be transformed put 1 to flip that channel or 0 to not. eg. '1 0' to flip channel 2 but not 3.
imStackHorizontalFlipChannel = '0';% Same as vertical
imStackRotateChannel = '0';%rotate should either be 0, 90 180 or 270 for the angle to rotate each selected channel


% Don't touch from here
    
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
alignEndFrame = 1;% 

alignMaxShift = 20; % Limit the mamximum distance that the program will shift images for alignment this can help stop false alignments

%Output the aligned image stacks. Note this is not required by JIM but can
%be helpful for visualization. To save space, aligned stack will not output in batch
%regarless of this value
alignOutputStacks = true;

%Multi Channel Alignment from here
%Parameters for Automatic Alignment
alignMaxIntensities = '1000 1000 1000';% Set a threshold so that during channel to channel alignment agregates are ignored
alignSNRCutoff = 1; % Set a minimum alignment SNR to throw warnings 

%Parameters for Manual Alignment
alignManually = true ; % Manually set the alignment between the multiple channels, If set to false the program will try to automatically find an alignment
alignXoffset = '0';
alignYoffset = '0';
alignRotationAngle = '0';
alignScalingFactor = '1';


%Don't touch from here

sysVar.cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',sysVar.allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),sysConst.outputFiles];

if alignManually
    sysVar.cmd = [sysVar.cmd,' -Alignment ',alignXoffset,' ',alignYoffset,' ',alignRotationAngle,' ',alignScalingFactor];
elseif imStackNumberOfChannels>1
    sysVar.cmd = [sysVar.cmd,' -MaxIntensities ',alignMaxIntensities,' -SNRCutoff ',num2str(alignSNRCutoff)];
end

if alignOutputStacks
    sysVar.cmd = [sysVar.cmd,' -OutputAligned '];
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

%% 4a) Make a SubAverage of Frames for each Channel for Detection 
detectUsingMaxProjection = false ; %Use a max projection rather than mean. This is better for short lived blinking particles

detectionStartFrame = '1'; %first frame of the reference region for detection for each channel
detectionEndFrame = '2'; %last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

%Each channel is multiplied by this value before they're combined. This is handy if one channel is much brigthter than another. 
detectWeights = '1' ;

% Don't Touch From Here

if ischar(detectionStartFrame)==false
    detectionStartFrame = num2str(detectionStartFrame);
end

if ischar(detectionEndFrame)==false
    detectionEndFrame = num2str(detectionEndFrame);
end

sysVar.cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Image_For_Detection"',sysVar.allChannelNames,' -Start ',detectionStartFrame,' -End ',detectionEndFrame,sysConst.maxProjectionString,' -Weights ',detectWeights];
if detectUsingMaxProjection
    sysVar.cmd = [sysVar.cmd,' -MaxProjection'];
end

system(sysVar.cmd);

figure
sysVar.channel1Im = cast(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff']),'double');
sysVar.channel1Im = (sysVar.channel1Im-min(min(sysVar.channel1Im)))./(prctile(reshape(sysVar.channel1Im.',1,[]),99.5)-min(min(sysVar.channel1Im)));
imshow(sysVar.channel1Im);
disp('Average projection completed');

%% 4b) Detect Particles

%Thresholding
detectionCutoff = 0.25; % The cutoff for the initial thresholding. Typically in range 0.25-2

%Filtering
detectLeftEdge =10;% Excluded particles closer to the left edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
detectRightEdge = 10;% Excluded particles closer to the Right edge than this. 
detectTopEdge = 10;% Excluded particles closer to the Top edge than this. 
detectBottomEdge = 10;% Excluded particles closer to the Bottom edge than this. 

detectMinCount = 5; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount= 50; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
detectMaxEccentricity = 0.4;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

detectMinLength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
detectMaxLength = 10000000; % Maximum number of pixels for the major axis of the best fit ellipse

detectMaxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.

detectMinSeparation = 4;% Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

sysVar.displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
sysVar.displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Don't Touch From Here

sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
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

%% 5a) Additional Background Detection - Use this to detect all other particles that are not in the detection image to cut around for background
additionBackgroundDetect = false ;% enable the additional detection. Disable if all particles were detected (before filtering) above.

additionBackgroundUseMaxProjection = false ; %Use a max projection rather than mean. This is better for short lived blinking particles

additionalBackgroundStartFrame = '1 1'; %first frame of the reference region for background detection
additionalBackgroundEndFrame = '-1 -1';%last frame of background reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

additionalBackgroundWeights = '1 1' ;

additionBackgroundCutoff = 0.75; %Threshold for particles to be detected for background

%don't touch from here

if additionBackgroundDetect

    sysVar.cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Channel_1.csv" "',workingDir,'Background"',sysVar.allChannelNames,' -Start ',additionalBackgroundStartFrame,' -End ',additionalBackgroundEndFrame,sysConst.backgroundMaxProjectionString,' -Weights ',additionalBackgroundWeights];
    if additionBackgroundUseMaxProjection
        sysVar.cmd = [sysVar.cmd,' -MaxProjection'];
    end   
    
    system(sysVar.cmd);

    sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(additionBackgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
    system(sysVar.cmd);

    figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
    sysVar.channel1Im = cast(imread([workingDir,'Background_Partial_Mean.tiff']),'double');
    sysVar.flatim = sort(reshape(sysVar.channel1Im,[],1),'descend');
    sysVar.fivepclen = round(0.05*length(sysVar.flatim));
    sysVar.channel1Im = sysVar.displayMax.*(sysVar.channel1Im-sysVar.flatim(end-sysVar.fivepclen))./(sysVar.flatim(sysVar.fivepclen)-sysVar.flatim(end-sysVar.fivepclen))+sysVar.displayMin;
    sysVar.channel1Im= min(max(sysVar.channel1Im,0),1);
    sysVar.channel2Im = im2double(imread([workingDir,'Background_Detected_Regions.tif']));
    sysVar.combinedImage = cat(3, sysVar.overlayColour1(1).*sysVar.channel1Im+sysVar.overlayColour2(1).*sysVar.channel2Im,sysVar.overlayColour1(2).*sysVar.channel1Im+sysVar.overlayColour2(2).*sysVar.channel2Im,sysVar.overlayColour1(3).*sysVar.channel1Im+sysVar.overlayColour2(3).*sysVar.channel2Im);
    imshow(sysVar.combinedImage)
end


%% 6) Expand Regions
expandForegroundDist = 4.1; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
expandBackInnerDist = 4.1; % Minimum distance to dilate beyond the ROI to measure the local background
expandBackOuterDist = 30; % Maximum distance to dilate beyond the ROI to measure the local background

sysVar.displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
sysVar.displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%don't touch from here

sysVar.cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(expandBackOuterDist),' -backInnerRadius ',num2str(expandBackInnerDist)];
if additionBackgroundDetect
    sysVar.cmd = [sysVar.cmd,' -extraBackgroundFile "',workingDir,'Background_Detected_Positions.csv"'];
end
if imStackNumberOfChannels > 1
    sysVar.cmd = [sysVar.cmd,' -channelAlignment "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv"'];
end

system(sysVar.cmd) 


figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')

sysVar.imout{1} = im2double(imread([workingDir,'Image_For_Detection_Partial_Mean.tiff'],i));

sysVar.imout{1} = sysVar.displayMax.*(sysVar.imout{1}-min(min(sysVar.imout{1})))./(prctile(reshape(sysVar.imout{1}.',1,[]),99.5)-min(min(sysVar.imout{1})))+sysVar.displayMin;
sysVar.imout{1} = min(max(sysVar.imout{1},0),1);
sysVar.imout{2} = im2double(imread([workingDir,'Expanded_ROIs.tif']));
sysVar.imout{3} = im2double(imread([workingDir,'Expanded_Background_Regions.tif']));
sysVar.combinedImage = cat(3, sysVar.overlayColour1(1).*sysVar.imout{1}+sysVar.overlayColour2(1).*sysVar.imout{2}+sysVar.overlayColour3(1).*sysVar.imout{3},sysVar.overlayColour1(2).*sysVar.imout{1}+sysVar.overlayColour2(2).*sysVar.imout{2}+sysVar.overlayColour3(2).*sysVar.imout{3},sysVar.overlayColour1(3).*sysVar.imout{1}+sysVar.overlayColour2(3).*sysVar.imout{2}+sysVar.overlayColour3(3).*sysVar.imout{3});
imshow(sysVar.combinedImage);

disp('Finished Expanding ROIs');

%% 7) Calculate Traces
traceVerboseOutput = false ; % Create additional file with additional statistics on each particle in each frame. Warning, this file can get very large. In general you don't want this.

%don't touch from here
for j = 1:imStackNumberOfChannels
    sysVar.cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_ROI_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,'Alignment_Channel_'+num2str(j)+".csv"];
    if traceVerboseOutput
        sysVar.cmd = [sysVar.cmd,' -Verbose'];
    end  
    system(sysVar.cmd);    
end


sysConst.falsetrue = ['false ';'true '];
sysConst.variableString = ['Date, ', datestr(datetime('today'))...
    ,'\nadditionalExtensionsToRemove,',num2str(additionalExtensionsToRemove)...
    ,'\nmultipleFilesPerImageStack,',sysConst.falsetrue(multipleFilesPerImageStack+1,:)...
    ,'\nimStackNumberOfChannels,', num2str(imStackNumberOfChannels) ...
    ,'\nimStackChannelsToTransform,', imStackChannelsToTransform...
    ,'\nimStackVerticalFlipChannel,', imStackVerticalFlipChannel ...
    ,'\nimStackHorizontalFlipChannel,', imStackHorizontalFlipChannel...
    ,'\nimStackRotateChannel,', imStackRotateChannel...
    ,'\nimStackStartFrame,', num2str(imStackStartFrame)...
    ,'\nimStackEndFrame,', num2str(imStackEndFrame)...
    ,'\nimStackDisableMetadata,', sysConst.falsetrue(imStackDisableMetadata+1,:)...
    ,'\nalignIterations,',num2str(alignIterations)...
    ,'\nalignStartFrame,', num2str(alignStartFrame)...
    ,'\nalignEndFrame,', num2str(alignEndFrame)...
    ,'\nalignManually,',sysConst.falsetrue(alignManually+1,:)...
    ,'\nalignRotationAngle,',alignRotationAngle...
    ,'\nalignScalingFactor,', alignScalingFactor...
    ,'\nalignXoffset,',alignXoffset...
    ,'\nalignYoffset,', alignYoffset...
    ,'\nalignMaxShift,', num2str(alignMaxShift)...
    ,'\nalignMaxIntensities,',alignMaxIntensities...
    ,'\nalignSNRCutoff,',num2str(alignSNRCutoff)...
    ,'\ndetectUsingMaxProjection,',sysConst.falsetrue(detectUsingMaxProjection+1,:)...
    ,'\ndetectWeights,',detectWeights...
    ,'\ndetectionStartFrame,', detectionStartFrame...
    ,'\ndetectionEndFrame,', detectionEndFrame...
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
    ,'\nadditionalBackgroundWeights,',additionalBackgroundWeights...
    ,'\nadditionBackgroundUseMaxProjection,',sysConst.falsetrue(additionBackgroundUseMaxProjection+1,:)...
    ,'\nadditionalBackgroundStartFrame,', additionalBackgroundStartFrame...
    ,'\nadditionalBackgroundEndFrame,', additionalBackgroundEndFrame...
    ,'\nadditionBackgroundCutoff,',num2str(additionBackgroundCutoff)...
    ,'\nexpandForegroundDist,',num2str(expandForegroundDist)...
    ,'\nexpandBackInnerDist,', num2str(expandBackInnerDist)...
    ,'\nexpandBackOuterDist,', num2str(expandBackOuterDist)...
    ,'\ntraceVerboseOutput,', sysConst.falsetrue(traceVerboseOutput+1,:)...
    ,'\ntraceIndependentDrifts,', sysConst.falsetrue(traceIndependentDrifts+1,:)];

sysVar.fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
fprintf(sysVar.fileID, sysConst.variableString);
fclose(sysVar.fileID);

disp('Finished Generating Traces');

%% (Optional) Save Parameters
[sysVar.file,sysVar.path] = uiputfile('*.csv','Save Parameter CSV File');
sysVar.fileID = fopen([sysVar.path,sysVar.file],'w');
fprintf(sysVar.fileID, sysVar.variableString);
fclose(sysVar.fileID);
%% 8a) Plot Page of Traces
montage.pageNumber =2; % Select the page number for traces. 28 traces per page. So traces from(n-1)*28+1 to n*28
montage.timePerFrame = 1.25;%Set to zero to just have frames
montage.timeUnits = 'mins'; % Unit to use for x axis 

%don't touch from here
for toCollapse = 1
if ~exist([workingDir 'Examples\'], 'dir')
    mkdir([workingDir 'Examples\'])%make a subfolder with that name
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
sysVar.fact(1) = ceil(log10(max(max(sysVar.traces1))))-3;

if imStackNumberOfChannels>1
    sysVar.traces2=sysVar.allTraces{2};
    sysVar.fact(2) = ceil(log10(max(max(sysVar.traces2))))-3;
end

sysVar.opts.Colors= get(groot,'defaultAxesColorOrder');sysVar.opts.width= 17.78;sysVar.opts.height= 22.86;sysVar.opts.fontType= 'Myriad Pro';sysVar.opts.fontSize= 9;
sysVar.fig = figure; sysVar.fig.Units= 'centimeters';sysVar.fig.Position(3)= sysVar.opts.width;sysVar.fig.Position(4)= sysVar.opts.height;
set(sysVar.fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('LineWidth',1.5, 'FontName','Myriad Pro')
%set(gcf, 'Position', [100, 100, 1500, 800])
yyaxis left

montage.timeaxis = [1:size(sysVar.traces1,2)];
if montage.timePerFrame ~= 0
    montage.timeaxis = montage.timeaxis.*montage.timePerFrame;
end

for i=1:28

    if i+28*(montage.pageNumber-1)<=size(sysVar.traces1,1)
        subplot(7,4,i)
        hold on
        %title(['No. ' num2str(i+28*(pageNumber-1)) ' x ' num2str(round(sysVar.measures(i+28*(pageNumber-1),1))) ' y ' num2str(round(sysVar.measures(i+28*(pageNumber-1),2)))])
        title(['Particle ' num2str(i+28*(montage.pageNumber-1))],'FontName','Myriad Pro','FontSize',9)
        if imStackNumberOfChannels>1
            yyaxis left
        end
        if i==13
             ylabel(['Channel 1 Intensity (10^{',num2str(sysVar.fact(1)),'} a.u.)'])
        end

        plot(montage.timeaxis,sysVar.traces1(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(1)),'LineWidth',2)
        plot([0 max(montage.timeaxis)],[0 0] ,'-black');

        if imStackNumberOfChannels>1
            yyaxis right
            if i==16
                ylabel(['Channel 2 Intensity (10^{',num2str(sysVar.fact(2)),'} a.u.)'])
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
movegui(sysVar.fig);
set(findobj(gcf,'type','axes'),'FontName','Myriad Pro','FontSize',9, 'LineWidth', 1.5);
print([workingDir 'Examples\' 'Example_Page_' num2str(montage.pageNumber)], '-dpng', '-r600');
print([workingDir 'Examples\' 'Example_Page_' num2str(montage.pageNumber)], '-depsc', '-r600');
savefig(sysVar.fig,[workingDir 'Examples\' 'Example_Page_' num2str(montage.pageNumber)],'compact');
end
%% 8b)Extract Individual Trace and montage
montage.traceNo = 267;
montage.start = 1;
montage.end = 240;
montage.delta = 20;
montage.average = 19;

montage.outputParticleImageStack = true;% Create a Tiff stack of the ROI of the particle

% Don't tought from here
for toCollapse = 1
sysConst.ParticleStackStr = '';
if montage.outputParticleImageStack
    sysConst.ParticleStackStr = ' -outputImageStack';
end

sysVar.opts.Colors= get(groot,'defaultAxesColorOrder');sysVar.opts.width= 5.7;sysVar.opts.height= 4.3;sysVar.opts.fontType= 'Myriad Pro';sysVar.opts.fontSize= 9;
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

if imStackNumberOfChannels>1
    yyaxis right

    ylabel(['Channel 2 Intensity (a.u.)'])

    plot(montage.timeaxis,sysVar.traces2(montage.traceNo,:),'LineWidth',2)

    for j=3:imStackNumberOfChannels
        traces=sysVar.allTraces{j};
        montage.c = colororder;
        plot(montage.timeaxis,traces(montage.traceNo,:).*max(sysVar.traces2(montage.traceNo,:))./max(traces(montage.traceNo,:)),'-','LineWidth',2,'Color',montage.c(j,:))
    end
    [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(montage.traceNo,:),'all');
    [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(montage.traceNo,:),'all');
    sysVar.ratio = min([sysVar.yliml(1)/sysVar.yliml(2) sysVar.ylimr(1)/sysVar.ylimr(2) -0.05]);
    set(gca,'Ylim',[sysVar.ylimr(2)*sysVar.ratio sysVar.ylimr(2)])
    yyaxis left
    set(gca,'Ylim',[sysVar.yliml(2)*sysVar.ratio sysVar.yliml(2)])
end
xlim([0 max(montage.timeaxis)])
if montage.timePerFrame ==0
    xlabel('Frame')
else
    xlabel(['Time  (' montage.timeUnits ')'])
end
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
sysVar.fig.PaperPositionMode   = 'auto';

print([workingDir 'Examples\Example_Trace_' num2str(montage.traceNo)], '-dpng', '-r600');
print([workingDir 'Examples\Example_Trace_' num2str(montage.traceNo)], '-depsc', '-r600');
savefig(sysVar.fig,[workingDir 'Examples\Example_Trace_' num2str(montage.traceNo)],'compact');

sysVar.cmd = [sysConst.JIM,'Isolate_Particle',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Combined_Drift.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Examples\Example" ',sysVar.allChannelNames,' -Start ',num2str(montage.start),' -End ',num2str(montage.end),' -Particle ',num2str(montage.traceNo),' -Delta ',num2str(montage.delta),' -Average ',num2str(montage.average),sysConst.ParticleStackStr];
system(sysVar.cmd);

sysVar.channel1Im = imread([workingDir,'Examples\Example_Trace_' num2str(montage.traceNo) '_Range_' num2str(montage.start) '_' num2str(montage.delta) '_' num2str(montage.end) '_montage.tiff']);
figure('Name',['Particle ' num2str(montage.traceNo) ' montage']);
imshow(sysVar.channel1Im,'Border','tight','InitialMagnification',200);
end
%% Continue from here for batch processing
%
%
%
%
%
%% 9) Detect files for batch
filesInSubFolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

for toCollapse = 1
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

if multipleFilesPerImageStack
    sysVar.allFolders = arrayfun(@(x) fileparts(allFiles{x}),1:max(size(allFiles)),'UniformOutput',false);
    [~,folderPos] = unique(sysVar.allFolders);
    allFiles = allFiles(folderPos);
end
sysConst.NumberOfFiles=size(allFiles,1);
disp(['There are ',num2str(sysConst.NumberOfFiles),' files to analyse']);
end
%% 10) Batch Analyse
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
    
    if multipleFilesPerImageStack
        completeName = arrayfun(@(x)['"',pathName,x.name,'" '],dir(pathName)','UniformOutput',false);
        completeName = completeName(contains(completeName,'.tif','IgnoreCase',true));
        completeName = horzcat(completeName{:});
    else
        completeName = ['"',completeName,'" '];
    end


    
   % 3.3) Split File into individual channels 
    
    if (isempty(imStackChannelsToTransform))
        cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame),sysConst.metadatastr]; % Run TIFFChannelSplitter',sysConst.fileEXE,' using the metadata  and write the split channels to the reults folder with the prefix Images
    else
        cmd = [sysConst.JIM,'Tiff_Channel_Splitter',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack" ',completeName,'-NumberOfChannels ',num2str(imStackNumberOfChannels),' -Transform ',imStackChannelsToTransform,' ',imStackVerticalFlipChannel,' ',imStackHorizontalFlipChannel,' ',imStackRotateChannel,' -StartFrame ',num2str(imStackStartFrame),' -EndFrame ',num2str(imStackEndFrame),sysConst.metadatastr];
    end
    system(cmd);
    % 3.4) Align Channels and Calculate Drifts 
    

    allChannelNames = ''; % make a list of all channels that need aligning (everything above channel 1)
    for j = 1:imStackNumberOfChannels
        allChannelNames = [allChannelNames,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif"'];
    end

    if imStackNumberOfChannels==1
        cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift)];
    elseif alignManually
        cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',allChannelNames,' -Alignment ',alignXoffset,' ',alignYoffset,' ',alignRotationAngle,' ',alignScalingFactor,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),sysConst.skipIndDriftsStr];
    else
        cmd = [sysConst.JIM,'Align_Channels',sysConst.fileEXE,' "',workingDir,'Alignment"',allChannelNames,' -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(alignIterations),' -MaxShift ',num2str(alignMaxShift),' -MaxIntensities ',alignMaxIntensities,' -alignSNRCutoff ',num2str(alignSNRCutoff),sysConst.skipIndDriftsStr];
    end
    system(cmd);


    
    % make submean
    cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Combined_Drift.csv" "',workingDir,'Image_For_Detection"',allChannelNames,' -Start ',detectionStartFrame,' -End ',detectionEndFrame,sysConst.maxProjectionString,' -Weights ',detectWeights];
    system(cmd);
    
    % 3.5) Detect Particles

    cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Image_For_Detection_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
    system(cmd)
    
    %background Detect
    backgroundFileStr = ['"',workingDir,'Detected_Positions.csv"'];
    if additionBackgroundDetect
        backgroundFileStr = ['"',workingDir,'Background_Detected_Positions.csv"'];
        
        cmd = [sysConst.JIM,'Mean_of_Frames',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Combined_Drift.csv" "',workingDir,'Background"',allChannelNames,' -Start ',additionalBackgroundStartFrame,' -End ',additionalBackgroundEndFrame,sysConst.backgroundMaxProjectionString,' -Weights ',additionalBackgroundWeights];
        system(cmd)
        
        cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',workingDir,'Background_Partial_Mean.tiff" "',workingDir,'Background_Detected" -BinarizeCutoff ', num2str(additionBackgroundCutoff)]; % Run the program Find_Particles.exe with the users values and write the output to the reults sysVar.file with the prefix Detected_
        system(cmd)
    end
    
    %3.6
    if imStackNumberOfChannels > 1
        cmd = [sysConst.JIM,'Other_Channel_Positions',sysConst.fileEXE,' "',workingDir,'Alignment_Channel_To_Channel_Alignment.csv" "',workingDir,'Alignment_Combined_Drift.csv" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Transformed" -positions "',workingDir,'Detected_Filtered_Positions.csv" -backgroundpositions ',sysConst.backgroundFileStr];
        system(cmd)
    end


    % 3.7) Fit areas around each shape 

    cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" ',sysConst.backgroundFileStr,' "',workingDir,'Expanded_Channel_1" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(expandBackOuterDist),' -backInnerRadius ',num2str(expandBackInnerDist)];
    system(cmd)

    for j = 2:imStackNumberOfChannels

       cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Transformed_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Transformed_Background_Positions_Channel_',num2str(j),'.csv" "',workingDir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(expandBackOuterDist),' -backInnerRadius ',num2str(expandBackInnerDist)];
       system(cmd)
    end

    % 3.8) Calculate amplitude for each frame for each channel
    
    driftStr = 'Alignment_Combined_Drift.csv"';
    if traceIndependentDrifts && imStackNumberOfChannels>1
        driftStr = 'Alignment_Channel_1_Drift.csv"';
    end
    cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack_Channel_1.tif" "',workingDir,'Expanded_Channel_1_ROI_Positions.csv" "',workingDir,'Expanded_Channel_1_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,driftStr,sysConst.verboseString];
    system(cmd)
    for j = 2:imStackNumberOfChannels
        driftStr = ['Transformed_Drifts_Channel_',num2str(j),'.csv"'];
        if traceIndependentDrifts
            driftStr = ['Alignment_Channel_',num2str(j),'_Drift.csv"'];
        end
        cmd = [sysConst.JIM,'Calculate_Traces',sysConst.fileEXE,' "',workingDir,'Raw_Image_Stack_Channel_',num2str(j),'.tif" "',workingDir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingDir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingDir,'Channel_',num2str(j),'" -Drift "',workingDir,driftStr,sysConst.verboseString];
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
%% 11) Extract Traces to Separate Folder
%sysVar.fileName = 'G:\My_Jim\20221412_VLP_Len_5%488_50ms\';
sysVar.outputFolder = uigetdir(); 
sysVar.outputFolder = [sysVar.outputFolder,filesep];
%%
sysVar.outputFile = [arrayfun(@(x)[x.folder,'\',x.name],dir([sysVar.fileName '**\*_Fluorescent_Intensities.csv']),'UniformOutput',false);arrayfun(@(x)[x.folder,'\',x.name],dir([sysVar.fileName '**\*_Fluorescent_Backgrounds.csv']),'UniformOutput',false)];
disp([num2str(length(sysVar.outputFile)) ' files to copy']);
%% 
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
