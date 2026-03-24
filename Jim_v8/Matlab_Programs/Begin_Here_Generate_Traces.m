clear
%% 0) (Optional) Load parameters into this script
% 
% [sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Parameter File');
% completeName = [sysVar.pathName,sysVar.fileName];
% sysVar.paramtab = readtable(completeName,'Format','%s%s');
% sysVar.paramtab = sysVar.paramtab(2:end,:);
% sysVar.paramtab = table2cell(sysVar.paramtab);
% [sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
% sysVar.line = splitlines(fileread([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m']));
% 
% sysVar.paramIsString = [7 8 9 10 17 18 19 20 22 23 24 41 42 43];
% 
% for i=1:length(sysVar.paramtab)
%     sysVar.toreplace = find(contains(sysVar.line,sysVar.paramtab{i,1},'IgnoreCase',true),1);
%     sysVar.linein = sysVar.line{sysVar.toreplace};
%     if ismember(i, sysVar.paramIsString)
%         sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ''' sysVar.paramtab{i,2} '''' sysVar.linein(strfind(sysVar.linein,';'):end)];
%     else
%         sysVar.line{sysVar.toreplace} = [sysVar.linein(1:strfind(sysVar.linein,'=')) ' ' sysVar.paramtab{i,2} sysVar.linein(strfind(sysVar.linein,';'):end)];
% 
%     end
% end
% sysVar.fid = fopen([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m'],'w');
% for i=1:size(sysVar.line,1)
%     fprintf(sysVar.fid,'%s\n',sysVar.line{i});
% end
% fclose(sysVar.fid);
% matlab.desktop.editor.openAndGoToLine([sysConst.JIM,filesep,'Begin_Here_Generate_Traces.m'],24);

%% 1) Select the input tiff file and Create a Folder for results
%Default directory for input file selector e.g.
sysVar.defaultFolder = 'F:\';

% Change the overlay colours for colourblind as desired. In RGB, values from 0 to 1
sysVar.overlayColour = [[1, 0, 0];[0, 1, 0];[0, 0, 1]];

%Don't Touch From Here
if exist('Tiff_Channel_Splitter')~=3
    [sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%get JIM Folder
    sysConst.JIM = [fileparts(sysConst.JIM),'/c++_Base_Programs/Matlab/'];
    if(exist(sysConst.JIM)==7)
        addpath(sysConst.JIM);
    else
        errordlg('JIMs Matlab mex files could not be found. Please select the \\c++_Base_Programs\\Matlab\\ folder in the JIM directory'); 
        sysConst.JIM = uigetdir('*','Select the c++_Base_Programs\\Matlab folder'); % open the dialog box to select the folder for JIM programs
        addpath(sysConst.JIM);
    end
end

inputFolder = uigetdir(sysVar.defaultFolder,'Select the Folder containing your data'); % open the dialog box to select the folder for batch files
inputFolder=[inputFolder,filesep];



%% 3) Align Channels and Calculate Drifts
positionToAnalyse = 1;

alignStartFrame = 2;% Select reference frames where there is signal in all channels at the same time start frame from 1
alignEndFrame = 2;% 

alignMaxShift = 30; % Limit the mamximum distance that the program will shift images for alignment this can help stop false alignments

%Output the aligned image stacks. Note this is not required by JIM but can
%be helpful for visualization. To save space, aligned stack will not output in batch
%regarless of this value
alignOutputStacks = true ;

%Multi Channel Alignment from here
%Parameters for Manual Alignment [x y rotation scale]
alignment = [0 0 0 1];

% Visualisation saturationg percentages
displayMin = 0.05;
displayMax = 0.99;

%Don't touch from here
%Standard input : ([Output File Base],[Input Image Stack file 1] ,..., NumberOfChannels, startframe, endframe, Transform, bBigTiff, bMetadata,bDetectMultipleFiles)
Align_Channels(inputFolder,alignStartFrame,alignEndFrame,positionToAnalyse,alignment,false,alignMaxShift,alignOutputStacks)

allPositionFolders = strip(strsplit(fileread([inputFolder 'PositionNameList.csv']),'\n'));
if exist([allPositionFolders{positionToAnalyse},filesep, 'Aligned_Channel_To_Channel_Alignment.csv'],'file')>0
    sysVar.channelAlignment = csvread([allPositionFolders{positionToAnalyse},filesep, 'Aligned_Channel_To_Channel_Alignment.csv'],1,0);
    imStackNumberOfChannels = size(sysVar.channelAlignment,1)+1;
else
    imStackNumberOfChannels = 1;
end

sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Aligned_Reference_Frames_Before.tiff'],1));
    if imStackNumberOfChannels>1
        sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
        for i=1:imStackNumberOfChannels
            sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Aligned_Reference_Frames_Before.tiff'],i));
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
    
    figure('Name','Alignment Reference Projection Before')
    imshow(sysVar.combinedImage);           

   
    sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Aligned_Full_Projection_After.tiff'],1));
    if imStackNumberOfChannels>1
        sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
        for i=1:imStackNumberOfChannels
            sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Aligned_Full_Projection_After.tiff'],i));
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

disp('Alignment completed');

%% 4) Make a SubAverage of Frames for each Channel for Detection 
detectUsingMaxProjection = [false false false]; %Use a max projection rather than mean. This is better for short lived blinking particles

detectionStartFrame = [2 2 0]; %first frame of the reference region for detection for each channel
detectionEndFrame = [2 -1 0]; %last frame of reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

%Each channel is multiplied by this value before they're combined. This is handy if one channel is much brigthter than another. 
detectWeights = [1 1 0];

% Visualisation saturationg percentages
displayMin = 0.05;
displayMax = 0.999;

Mean_of_Frames(inputFolder,positionToAnalyse,detectionStartFrame,detectionEndFrame,detectUsingMaxProjection,detectWeights);

figure
sysVar.imout = cast(imread([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff']),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
imshow(sysVar.imout);

disp('Average projection completed');

%% 5) Detect Particles

%Thresholding
detectionCutoff = 0.4; % The cutoff for the initial thresholding. Typically in range 0.25-2

%Filtering
detectMinEdgeDist = 25;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases. 

detectMinCount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount= 100; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = -0.10; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
detectMaxEccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

detectMinSeparation = 5.00;% Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

% Visualisation saturationg percentages

displayMin = 0.05; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.95; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%All options:
% MinDistFromEdge LeftMinDistFromEdge RightMinDistFromEdge TopMinDistFromEdge BottomMinDistFromEdge 
% MinEccentricity MaxEccentricity MinLength MaxLength 
% MinCount MaxCount MaxDistFromLinear 
% IncludeSmall OutputFile GaussStdDev MinSeparation 

% Don't Touch From Here

Detect_Particles([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff'],detectionCutoff, 'MinDistFromEdge',detectMinEdgeDist,'MinCount',detectMinCount,'MaxCount',detectMaxCount,'MinEccentricity',detectMinEccentricity,'MaxEccentricity',detectMaxEccentricity,'MinSeparation',detectMinSeparation); % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_


%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
sysVar.imout = cast(imread([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff']),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
end
sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Detected_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
end
sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(3,j);
end

figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
imshow(sysVar.combinedImage)
disp('Finish detecting particles');

%% 6) Additional Background Detection - Use this to detect all other particles that are not in the detection image to cut around for background
additionBackgroundDetect = false ;% enable the additional detection. Disable if all particles were detected (before filtering) above.

additionBackgroundUseMaxProjection = [false false false] ; %Use a max projection rather than mean. This is better for short lived blinking particles

additionalBackgroundStartFrame = [0 50 50]; %first frame of the reference region for background detection
additionalBackgroundEndFrame = [0 1 -1];%last frame of background reference region. Negative numbers go from end of stack. i.e. -1 is last image in stack

additionalBackgroundWeights = [0 3 1];

additionBackgroundCutoff = 1.5; %Threshold for particles to be detected for background

% Visualisation saturationg percentages

displayMin = 0.05; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.99; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%don't touch from here

if additionBackgroundDetect
    Mean_of_Frames(inputFolder,positionToAnalyse,additionalBackgroundStartFrame,additionalBackgroundEndFrame,additionBackgroundUseMaxProjection,additionalBackgroundWeights);
    Detect_Particles([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff'],additionBackgroundCutoff,'OutputFile',[allPositionFolders{positionToAnalyse},filesep,'Background']);


    sysVar.imout = cast(imread([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff']),'double');
    tosort = sort(sysVar.imout(:));
    sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
    sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
    for j=1:3
        sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
    end
    sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Background_Regions.tif']));
    for j=1:3
        sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
    end

    figure('Name','Detected Particles - Red Original Image - Green to Yellow Selected Extra Backgrounds')
    imshow(sysVar.combinedImage)
    disp('Finish detecting particles');
    
end


%% 7) Expand Regions

sysVar.displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
sysVar.displayMax = 1; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%don't touch from here
if additionBackgroundDetect
    Expand_Shape([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Positions.csv'],[allPositionFolders{positionToAnalyse},filesep,'Detected_Positions.csv'],'ExtraBackgroundFile',[allPositionFolders{positionToAnalyse},filesep,'Background_Positions.csv']);
else
    Expand_Shape([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Positions.csv'],[allPositionFolders{positionToAnalyse},filesep,'Detected_Positions.csv']);
end


sysVar.imout = cast(imread([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff']),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
end
sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Expanded_ROIs.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
end
sysVar.imout = im2double(imread([allPositionFolders{positionToAnalyse},filesep,'Expanded_Background_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(3,j);
end

figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
imshow(sysVar.combinedImage);

disp('Finished Expanding ROIs');

%% 8) Calculate Traces

%Don't touch from here
whileLoopCounter = 1;%Don't change this value from 1!!! It's used for the while loop below
while exist([allPositionFolders{positionToAnalyse},filesep,'Expanded_ROI_Positions_Channel_',num2str(whileLoopCounter),'.csv'])>0
    Calculate_Traces(inputFolder,positionToAnalyse, whileLoopCounter, [allPositionFolders{positionToAnalyse},filesep,'Expanded_ROI_Positions_Channel_',num2str(whileLoopCounter),'.csv'], [allPositionFolders{positionToAnalyse},filesep,'Expanded_Background_Positions_Channel_',num2str(whileLoopCounter),'.csv'])
    whileLoopCounter = whileLoopCounter+1;
end


% Save Parameters
% sysConst.falsetrue = ['false';'true '];
% sysConst.variableString = ['Date, ', datestr(datetime('today'))...
%     ,'\nadditionalExtensionsToRemove,',num2str(additionalExtensionsToRemove)...
%     ,'\nimStackMultipleFiles,',sysConst.falsetrue(imStackMultipleFiles+1,:)...
%     ,'\nimStackNumberOfChannels,', num2str(imStackNumberOfChannels) ...
%     ,'\nimStackDisableMetadata,', sysConst.falsetrue(imStackDisableMetadata+1,:)...
%     ,'\nimStackStartFrame,', num2str(imStackStartFrame)...
%     ,'\nimStackEndFrame,', num2str(imStackEndFrame)...    
%     ,'\nimStackChannelsToTransform,', imStackChannelsToTransform...
%     ,'\nimStackVerticalFlipChannel,', imStackVerticalFlipChannel ...
%     ,'\nimStackHorizontalFlipChannel,', imStackHorizontalFlipChannel...
%     ,'\nimStackRotateChannel,', imStackRotateChannel...
%     ,'\nalignStartFrame,', num2str(alignStartFrame)...
%     ,'\nalignEndFrame,', num2str(alignEndFrame)...
%     ,'\nalignMaxShift,', num2str(alignMaxShift)...
%     ,'\nalignOutputStacks,',sysConst.falsetrue(alignOutputStacks+1,:)...
%     ,'\nalignManually,',sysConst.falsetrue(alignManually+1,:)...
%     ,'\nalignXOffset,',alignXOffset...
%     ,'\nalignYOffset,', alignYOffset...
%     ,'\nalignRotationAngle,',alignRotationAngle...
%     ,'\nalignScalingFactor,', alignScalingFactor...
%     ,'\ndetectUsingMaxProjection,',sysConst.falsetrue(detectUsingMaxProjection+1,:)...
%     ,'\ndetectPercent,',sysConst.falsetrue(detectPercent+1,:)...
%     ,'\ndetectionStartFrame,', detectionStartFrame...
%     ,'\ndetectionEndFrame,', detectionEndFrame...
%     ,'\ndetectWeights,',detectWeights...
%     ,'\ndetectionCutoff,',num2str(detectionCutoff)...
%     ,'\ndetectLeftEdge,', num2str(detectLeftEdge)...
%     ,'\ndetectRightEdge,', num2str(detectRightEdge)...
%     ,'\ndetectTopEdge,', num2str(detectTopEdge)...
%     ,'\ndetectBottomEdge,', num2str(detectBottomEdge)...
%     ,'\ndetectMinCount,',num2str(detectMinCount)...
%     ,'\ndetectMaxCount,', num2str(detectMaxCount)...
%     ,'\ndetectMinEccentricity,', num2str(detectMinEccentricity)...
%     ,'\ndetectMaxEccentricity,', num2str(detectMaxEccentricity)...
%     ,'\ndetectMinLength,',num2str(detectMinLength)...
%     ,'\ndetectMaxLength,', num2str(detectMaxLength)...
%     ,'\ndetectMaxDistFromLinear,', num2str(detectMaxDistFromLinear)...
%     ,'\ndetectMinSeparation,', num2str(detectMinSeparation)...
%     ,'\nadditionBackgroundDetect,',sysConst.falsetrue(additionBackgroundDetect+1,:)...
%     ,'\nadditionBackgroundUseMaxProjection,',sysConst.falsetrue(additionBackgroundUseMaxProjection+1,:)...
%     ,'\nadditionBackgroundPercent,',sysConst.falsetrue(additionBackgroundPercent+1,:)...
%     ,'\nadditionalBackgroundStartFrame,', additionalBackgroundStartFrame...
%     ,'\nadditionalBackgroundEndFrame,', additionalBackgroundEndFrame...
%     ,'\nadditionalBackgroundWeights,',additionalBackgroundWeights...
%     ,'\nadditionBackgroundCutoff,',num2str(additionBackgroundCutoff)...
%     ,'\nexpandForegroundDist,',num2str(expandForegroundDist)...
%     ,'\nexpandBackInnerDist,', num2str(expandBackInnerDist)...
%     ,'\nexpandBackOuterDist,', num2str(expandBackOuterDist)...
%     ,'\nstepfitEnable,', sysConst.falsetrue(stepfitEnable+1,:)...
%     ,'\nstepfitChannel,', num2str(stepfitChannel)...
%     ,'\nstepfitThreshold,', num2str(stepfitThreshold)...
%     ];
% 
% sysVar.fileID = fopen([allPositionFolders{positionToAnalyse},'Trace_Generation_Variables.csv'],'w');
% fprintf(sysVar.fileID, sysConst.variableString);
% fclose(sysVar.fileID);

disp('Finished Generating Traces');
% (Optional) Save Copy of Parameters
% [sysVar.file,sysVar.path] = uiputfile('*.csv','Save Parameter CSV File');
% sysVar.fileID = fopen([sysVar.path,sysVar.file],'w');
% fprintf(sysVar.fileID, sysVar.variableString);
% fclose(sysVar.fileID);
%% 10) View Traces
montage.pageNumber =4; % Select the page number for traces. 28 traces per page. So traces from(n-1)*28+1 to n*28
montage.timePerFrame = 1;%Set to zero to just have frames
montage.timeUnits = 's'; % Unit to use for x axis 

%don't touch from here

if ~exist([allPositionFolders{positionToAnalyse} filesep 'Examples' filesep], 'dir')
    mkdir([allPositionFolders{positionToAnalyse} filesep 'Examples' filesep])%make a subfolder with that name
end

sysVar.measures = csvread([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Measurements.csv'],1);
sysVar.channel1Im = imread([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Region_Numbers.tif']);
figure('Name','Particle Numbers');
imshow(sysVar.channel1Im);


sysVar.allTraces = cell(imStackNumberOfChannels,1);
for j=1:imStackNumberOfChannels
    sysVar.allTraces{j} = csvread([allPositionFolders{positionToAnalyse},filesep,'Channel_',num2str(j),'_Fluorescent_Intensities.csv'],1);
end

sysVar.traces1=sysVar.allTraces{1};
sysVar.fact(1) = ceil(log10(max(max(sysVar.traces1))))-2;

if imStackNumberOfChannels>1
    sysVar.traces2=sysVar.allTraces{2};
    sysVar.fact(2) = ceil(log10(max(max(sysVar.traces2))))-2;
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
    traceIdx = i + 28 * (montage.pageNumber - 1);

    if traceIdx<=size(sysVar.traces1,1)
        subplot(7,4,i)
        hold on
        title(['No. ' num2str(traceIdx) ' x ' num2str(round(sysVar.measures(traceIdx,1))) ' y ' num2str(round(sysVar.measures(traceIdx,2)))])
        %title(['Particle ' num2str(i+28*(montage.pageNumber-1))],'FontName','Myriad Pro','FontSize',9)
        if imStackNumberOfChannels>1
            yyaxis left
        end
        if i==13
             ylabel(['Channel 1 Intensity (x10^{',num2str(sysVar.fact(1)),'} a.u.)'],'FontWeight','bold','FontSize',14)
        end

        plot(montage.timeaxis,sysVar.traces1(traceIdx,:)./(10.^sysVar.fact(1)),'LineWidth',2)
        
        plot([0 max(montage.timeaxis)],[0 0] ,'-black');
        

        if imStackNumberOfChannels>1
            yyaxis right
            if i==16
                ylabel(['Channel 2 Intensity (x10^{',num2str(sysVar.fact(2)),'} a.u.)'],'FontWeight','bold','FontSize',14)
            end
            plot(montage.timeaxis,sysVar.traces2(traceIdx,:)./(10.^sysVar.fact(2)),'LineWidth',2)

            for j=3:imStackNumberOfChannels
                traces=sysVar.allTraces{j};
                montage.c = colororder;
                plot(montage.timeaxis,traces(traceIdx,:).*max(sysVar.traces2(traceIdx,:))./(10.^sysVar.fact(2))./max(traces(traceIdx,:)),'-','LineWidth',2,'Color',montage.c(j,:))
            end

            [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(traceIdx,:)./(10.^sysVar.fact(1)),'all');
            [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(traceIdx,:)./(10.^sysVar.fact(2)),'all');
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
print([allPositionFolders{positionToAnalyse} filesep 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-dpng', '-r600');
print([allPositionFolders{positionToAnalyse} filesep 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-depsc', '-r600');
savefig(sysVar.fig,[allPositionFolders{positionToAnalyse} filesep 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)],'compact');

%% 11)Extract Individual Trace and montage
montage.traceNo = 112;
montage.start = 3;
montage.end = 48;
montage.delta = 5;
montage.average = 5;

montage.outputParticleImageStack = true;% Create a Tiff stack of the ROI of the particle

% Don't touch from here

sysVar.cmd = [sysConst.JIM,'Isolate_Particle',sysConst.fileEXE,' "',allPositionFolders{positionToAnalyse},'Alignment_Channel_To_Channel_Alignment.csv" "',allPositionFolders{positionToAnalyse},'Alignment_Channel_1.csv" "',allPositionFolders{positionToAnalyse},'Detected_Filtered_Measurements.csv" "',allPositionFolders{positionToAnalyse},'Examples',filesep,'Example" ',sysVar.allChannelNames,' -Start ',num2str(montage.start),' -End ',num2str(montage.end),' -Particle ',num2str(montage.traceNo),' -Delta ',num2str(montage.delta),' -Average ',num2str(montage.average)];
if montage.outputParticleImageStack
    sysVar.cmd = [sysVar.cmd ' -outputImageStack'];
end

system(sysVar.cmd);   
    
sysVar.channel1Im = imread([allPositionFolders{positionToAnalyse},'Examples' filesep 'Example_Trace_' num2str(montage.traceNo) '_Range_' num2str(montage.start) '_' num2str(montage.delta) '_' num2str(montage.end) '_montage.tiff']);
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

print([allPositionFolders{positionToAnalyse} 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)], '-dpng', '-r600');
print([allPositionFolders{positionToAnalyse} 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)], '-depsc', '-r600');
savefig(sysVar.fig,[allPositionFolders{positionToAnalyse} 'Examples' filesep 'Example_Trace_' num2str(montage.traceNo)],'compact');


%% Continue from here for batch processing
%
%
%
%
%
%% 1) Detect files for batch
filesInSubFolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder


sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep];

if filesInSubFolders
    sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
    sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isdir(cell2mat(x)),sysVar.allFolders));
    sysVar.allFolders = sysVar.allFolders(~startsWith(sysVar.allFolders, {[sysVar.fileName '.']}));
else
    sysVar.allFolders = {sysVar.fileName};
end

sysConst.NumberOfFiles=size(sysVar.allFolders,1);
disp(['There are ',num2str(sysConst.NumberOfFiles),' folders to analyse']);

%% 2) Batch Analyse

for i=1:sysConst.NumberOfFiles
    
    inputFolder =  sysVar.allFolders{i};
    
    disp(['Analysing ',inputFolder]);

    Align_Channels(inputFolder,alignStartFrame,alignEndFrame,0,alignment,false,alignMaxShift,alignOutputStacks);
    Mean_of_Frames(inputFolder,0,detectionStartFrame,detectionEndFrame,detectUsingMaxProjection,detectWeights);
    allPositionFolders = strip(strsplit(fileread([inputFolder filesep 'PositionNameList.csv']),'\n'));
    allPositionFolders = allPositionFolders(:,1:end-1);

    for positionToAnalyse = 1:length(allPositionFolders);
        Detect_Particles([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff'],detectionCutoff, 'MinDistFromEdge',detectMinEdgeDist,'MinCount',detectMinCount,'MaxCount',detectMaxCount,'MinEccentricity',detectMinEccentricity,'MaxEccentricity',detectMaxEccentricity,'MinSeparation',detectMinSeparation); % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
        if additionBackgroundDetect
            Mean_of_Frames(inputFolder,positionToAnalyse,additionalBackgroundStartFrame,additionalBackgroundEndFrame,additionBackgroundUseMaxProjection,additionalBackgroundWeights);
            Detect_Particles([allPositionFolders{positionToAnalyse},filesep,'Image_For_Detection_Partial_Mean.tiff'],detectionCutoff,'OutputFile',[allPositionFolders{positionToAnalyse},filesep,'Background']);
            Expand_Shape([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Positions.csv'],[allPositionFolders{positionToAnalyse},filesep,'Detected_Positions.csv'],'ExtraBackgroundFile',[allPositionFolders{positionToAnalyse},filesep,'Background_Positions.csv']);
        else
            Expand_Shape([allPositionFolders{positionToAnalyse},filesep,'Detected_Filtered_Positions.csv'],[allPositionFolders{positionToAnalyse},filesep,'Detected_Positions.csv']);
        end
    
        whileLoopCounter = 1;
        while exist([allPositionFolders{positionToAnalyse},filesep,'Expanded_ROI_Positions_Channel_',num2str(whileLoopCounter),'.csv'])>0
            Calculate_Traces(inputFolder,positionToAnalyse, whileLoopCounter, [allPositionFolders{positionToAnalyse},filesep,'Expanded_ROI_Positions_Channel_',num2str(whileLoopCounter),'.csv'], [allPositionFolders{positionToAnalyse},filesep,'Expanded_Background_Positions_Channel_',num2str(whileLoopCounter),'.csv'])
            whileLoopCounter = whileLoopCounter+1;
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

