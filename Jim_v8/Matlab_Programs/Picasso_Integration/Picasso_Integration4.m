%% Run Generate Traces before this. If using batch set deleteWorkingImageStacks = false;
%%
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
[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Image file',sysVar.defaultFolder);%Open the Dialog box to select the initial sysVar.file to analyze

completeName = [sysVar.pathName,sysVar.fileName];
[sysVar.fileNamein,sysVar.name,~] = fileparts(completeName);%get the name of the tiff image
for j=1:additionalExtensionsToRemove
    sysVar.workingDir = [sysVar.fileNamein,filesep,sysVar.name];
    [sysVar.fileNamein,sysVar.name,~] = fileparts(sysVar.workingDir);
end
workingDir = [sysVar.fileNamein,filesep,sysVar.name,filesep];


completeName = ['"',completeName,'" '];


%% if less than 4gb
threshold = 600;
channelNum = 2;
cmd = ['picasso localize "' workingDir 'Images_Channel_' num2str(channelNum) '.tif" -b 9 -g ' num2str(threshold) ' -bl 100'];
system(cmd);
%% else convert to raw first
cmd = [JIM,'Picasso_Raw_Converter',fileEXE,' "',completeName,'" "',workingDir,'"'];
returnVal = system(cmd);
%%
picData = h5read([workingDir 'Images_Channel_2_locs.hdf5'],'/locs');
jimDrifts = csvread([workingDir,'Detected_Filtered_Drifts_Channel_2.csv'],1,0);

for i=1:length(picData.x)
    picData.x(i) = picData.x(i)+jimDrifts(picData.frame(i)+1,1);
    picData.y(i) = picData.y(i)+jimDrifts(picData.frame(i)+1,2);
end

struct2hdf5(picData,'/locs',workingDir(1:end-1),'Images_Channel_2_locs_undrift.hdf5');
copyfile([workingDir 'Images_Channel_2_locs.yaml'],[workingDir 'Images_Channel_2_locs_undrift.yaml']);
%%
jimPos = csvread([workingDir 'Expanded_Channel_2_ROI_Positions.csv'],1,0);

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
