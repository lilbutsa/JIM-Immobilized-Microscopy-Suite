clear
%% 1) Select the input tiff file and Create folder for results
[jimPath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
fileEXE = '';
fileSep = '';
if ismac
    JIM = [fileparts(jimPath),'/Jim_Programs_Mac/'];
    fileSep = '/';
elseif ispc
    JIM = [fileparts(jimPath),'\Jim_Programs\'];
    fileEXE = '.exe';
    fileSep = '\';
else
    disp('Platform not supported')
end


%Convert to the file path for the C++ Jim Programs
[fileName,pathName] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze

overlayColour1 = [1, 0, 0];
overlayColour2 = [0, 1, 0];
overlayColour3 = [0, 0, 1];

completeName = [pathName,fileName];
[fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
workingDir = [fileNamein,filesep,name];
[fileNamein,name,~] = fileparts(workingDir);
workingDir = [fileNamein,filesep,name,filesep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end
%% 2) Calculate Drifts
iterations = 3;

alignStartFrame = 90;
alignEndFrame = 100;

cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned" "',completeName,'" -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];%Run the Align_Channels program with the selected image stack as the input and save the results to the results folder with the Aligned prefix
system(cmd);

figure('Name','Before Drift Correction') %Display the initial mean that has no drift correction. This is equivilent to the z projection if the stack in ImageJ
channel1Im = im2double(imread([workingDir,'Aligned_initial_mean.tiff']));
channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
imshow(channel1Im);
truesize([900 900]);

figure('Name','After Drift Correction')%Display the final mean drift corrected mean.
channel1Im = im2double(imread([workingDir,'Aligned_final_mean.tiff']));
channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
imshow(channel1Im);
truesize([900 900]);

drifts = csvread([workingDir,'Aligned_Drifts.csv'],1);%Read in drifts to see waht the max the image has shifted by
disp(['Maximum drift is ', num2str(max(max(abs(drifts))))]);
%% 3) Make a SubAverage of Frames for Detection 
useMaxProjection = false;

detectionStartFrame = 60;
detectionEndFrame = 100;

maxProjectionString = '';
if useMaxProjection
    maxProjectionString = ' -MaxProjection';
end

cmd = [JIM,'Mean_of_Frames',fileEXE,' NULL "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned" "',completeName,'" -Start ',num2str(detectionStartFrame),' -End ',num2str(detectionEndFrame),maxProjectionString];
system(cmd);

figure('Name','Sub-Average to use for detection')%Display the mean of the substack that will be used for particle detection
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = (channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)));
imshow(channel1Im);
truesize([900 900]);

%% 4) Detect Particles
% User Defined Parameters 
%Thresholding
cutoff=0.5; % The curoff for the initial thresholding

%Filtering
left = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases


minCount = 15; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount=1000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxLength = 100000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.


displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 5; % This just adjusts the contrast in the displayed image. It does NOT effect detection
% Detection Program

cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)

%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
%channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Detected_Regions.tif']));
channel3Im = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage)
truesize([900 900]);
disp('Finish detecting particles');

%% 5) Join Fragments
%Joining
maxAngle =5;
maxJoinDist = 7;
maxLineDist = 7; % maximum joining distance to line of best fit


%Filtering

left2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom2 = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

minCount2 = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount2=1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity2 = 0.0; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity2 = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength2 = 70; %Minimum number of pixels for the major axis of the best fit ellipse
maxLength2 = 80; %Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear2 = 1000000; % Maximum distance that a pixel can diviate from the major axis.

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 5; % This just adjusts the contrast in the displayed image. It does NOT effect detection

%the actual program

cmd = [JIM,'Join_Filaments',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Joined"  -minLength ',num2str(minLength2),' -maxLength ',num2str(maxLength2),' -minCount ',num2str(minCount2),' -maxCount ',num2str(maxCount2),' -minEccentricity ',num2str(minEccentricity2),' -maxEccentricity ',num2str(maxEccentricity2),' -left ',num2str(left2),' -right ',num2str(right2),' -top ',num2str(top2),' -bottom ',num2str(bottom2),' -maxDistFromLinear ',num2str(maxDistFromLinear2),' -maxAngle ',num2str(maxAngle),' -maxJoinDist ',num2str(maxJoinDist),' -maxLine ',num2str(maxLineDist)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
system(cmd)

figure('Name','Input Regions - Red Original Image,  Green to Yellow->Original Regions, Blue-> Initial Lines')
%channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
channel3Im = im2double(imread([workingDir,'Joined_Initial_Lines.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage)
truesize([900 900]);

figure('Name','Joined Regions - Red Original Image,  Green to Yellow->Final Filtered Regions, Blue-> Final Joined Lines')
%channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Joined_Filtered_Regions.tif']));
channel3Im = im2double(imread([workingDir,'Joined_Joined_Lines.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage)
truesize([900 900]);

measurefile = [workingDir,'Joined_Measurements.csv'];
allmeasures = csvread(measurefile,1,0);

figure('Name','Filament Length Distribution')
histogram(allmeasures(:,4),round(length(allmeasures(:,4))/3))



%% 6) Expand Regions and find kymograph lines

kymExtensionDist = 10;
kymWidth=6; % Perpendicular distance of foreground kymograph
kymBackWidth = 30; % Background Kymograph Width
backDist = 3; % Background Particles Expansion

cmd = [JIM,'Kymograph_Positions',fileEXE,' "',workingDir,'Joined_Measurements.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(kymWidth),' -backgroundDist ',num2str(kymBackWidth),' -backInnerRadius ',num2str(backDist),' -ExtendKymographs ',num2str(kymExtensionDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
system(cmd)


figure('Name','Kymograph Regions - Red Original Image - Green ROIs - Blue Background Regions')
%channel1Im = rescale(imread([workingDir,'Aligned_Partial_Mean.tiff']),displayMin,displayMax);
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Expanded_ROIs.tif']));
channel3Im = im2double(imread([workingDir,'Expanded_Background_Regions.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage)
truesize([900 900]);

%% 7) Calculate Traces and Make kymographs
cmd = [JIM,'Calculate_Traces',fileEXE,' "',completeName,'" "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',' -Verbose']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)


variableString = ['Date, ', datestr(datetime('today')),'\n'...
    ,'iterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame),'\n'...
    ,'useMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', num2str(detectionStartFrame),'\ndetectionEndFrame,', num2str(detectionEndFrame),'\n'...
    ,'cutoff,',num2str(cutoff),'\nleft,', num2str(left),'\nright,', num2str(right),'\ntop,', num2str(top),'\nbottom,', num2str(bottom),'\n'...
    ,'minCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity),'\n'...
    ,'minLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\n'...
    ,'maxAngle,', num2str(maxAngle),'\nmaxJoinDist,', num2str(maxJoinDist),'\nmaxLineDist,', num2str(maxLineDist),'\n'...
    ,'left2,', num2str(left2),'\nright2,', num2str(right2),'\ntop2,', num2str(top2),'\nbottom2,', num2str(bottom2),'\n'...
    ,'minCount2,',num2str(minCount),'\nmaxCount2,', num2str(maxCount),'\nminEccentricity2,', num2str(minEccentricity2),'\nmaxEccentricity2,', num2str(maxEccentricity2),'\n'...
    ,'minLength2,',num2str(minLength2),'\nmaxLength2,', num2str(maxLength2),'\nmaxDistFromLinear2,', num2str(maxDistFromLinear2),'\n'...
    ,'KymExtensionDist,',num2str(kymExtensionDist),'\nkymWidth,',num2str(kymWidth),'\nbackDist,', num2str(backDist),'\nkymBackWidth,', num2str(kymBackWidth)];

fileID = fopen([workingDir,'Kymograph_Generation_Variables.csv'],'w');
fprintf(fileID, variableString);
fclose(fileID);

kymdir = [workingDir,'Kymographs',fileSep];
mkdir(kymdir);
cmd = [JIM,'Make_Kymographs',fileEXE,' "',workingDir,'Channel_1_Fluorescent_Intensities.csv" "',workingDir,'Channel_1_Fluorescent_Backgrounds.csv" "',workingDir,'Expanded_ROI_Positions.csv" "',kymdir,'Kymograph"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)

%% 8) Display kymographs

pageNumber = 1;

numberOfRows = 3;
numberOfColumns = 4;


measures = csvread([workingDir,'Joined_Measurements.csv'],1);
channel1Im = imread([workingDir,'Joined_Region_Numbers.tif']);
figure('Name','Particle Numbers');
imshow(channel1Im);
truesize([900 900]);


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
%% 10) Detect files for batch
filesInSubFolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder




fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep];

if filesInSubFolders
    allFolders = arrayfun(@(x)[fileName,x.name],dir(fileName),'UniformOutput',false); % find everything in the input folder
    allFolders = allFolders(arrayfun(@(x) isdir(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
else
    allFolders = {fileName};
end
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
allFiles = allFiles(contains(allFiles,'.tif','IgnoreCase',true));
NumberOfFiles=size(allFiles,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
    

%% 11) Batch Analyse
overwritePreviouslyAnalysed = true;
parfor i=1:NumberOfFiles
    completeName = allFiles{i};
    disp(['Analysing ',completeName]);
    % 3.2) Create folder for results
    [fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
    workingDir = [fileNamein,filesep,name];
    [fileNamein,name,~] = fileparts(workingDir);
    workingDir = [fileNamein,filesep,name,filesep];
    if ~exist(workingDir, 'dir')
        mkdir(workingDir)%make a subfolder with that name
    end

    if (exist([workingDir,'Channel_1_Fluorescent_Intensities.csv'],'file')==2 && overwritePreviouslyAnalysed==false)
        disp(['Skipping ',completeName,' - Analysis already exists']);
        continue
    end
    
    % 3.3)  Calculate Drifts
    cmd = [JIM,'Align_Channels',fileEXE,' "',workingDir,'Aligned" "',completeName,'" -Start ',num2str(alignStartFrame),' -End ',num2str(alignEndFrame),' -Iterations ',num2str(iterations)];%Run the Align_Channels program with the selected image stack as the input and save the results to the results folder with the Aligned prefix
    system(cmd);

    
    cmd = [JIM,'Mean_of_Frames',fileEXE,' NULL "',workingDir,'Aligned_Drifts.csv" "',workingDir,'Aligned" "',completeName,'" -Start ',num2str(detectionStartFrame),' -End ',num2str(detectionEndFrame),maxProjectionString];
    system(cmd);
    
    % 3.4) Detect Particles
    cmd = [JIM,'Detect_Particles',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minLength),' -maxLength ',num2str(maxLength),' -minCount ',num2str(minCount),' -maxCount ',num2str(maxCount),' -minEccentricity ',num2str(minEccentricity),' -maxEccentricity ',num2str(maxEccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)
    
    cmd = [JIM,'Join_Filaments',fileEXE,' "',workingDir,'Aligned_Partial_Mean.tiff" "',workingDir,'Detected_Filtered_Measurements.csv" "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Joined"  -minLength ',num2str(minLength2),' -maxLength ',num2str(maxLength2),' -minCount ',num2str(minCount2),' -maxCount ',num2str(maxCount2),' -minEccentricity ',num2str(minEccentricity2),' -maxEccentricity ',num2str(maxEccentricity2),' -left ',num2str(left2),' -right ',num2str(right2),' -top ',num2str(top2),' -bottom ',num2str(bottom2),' -maxDistFromLinear ',num2str(maxDistFromLinear2),' -maxAngle ',num2str(maxAngle),' -maxJoinDist ',num2str(maxJoinDist),' -maxLine ',num2str(maxLineDist)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)

    % 3.5) Fit areas around each shape
    cmd = [JIM,'Kymograph_Positions',fileEXE,' "',workingDir,'Joined_Measurements.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(kymWidth),' -backgroundDist ',num2str(kymBackWidth),' -backInnerRadius ',num2str(backDist),' -ExtendKymographs ',num2str(kymExtensionDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
    system(cmd)
    % 3.6) Calculate Sum of signal and background for each frame
    cmd = [JIM,'Calculate_Traces',fileEXE,' "',completeName,'" "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',' -Verbose']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)
    
    variableString = ['Date, ', datestr(datetime('today')),'\n'...
    ,'iterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame),'\n'...
    ,'useMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', num2str(detectionStartFrame),'\ndetectionEndFrame,', num2str(detectionEndFrame),'\n'...
    ,'cutoff,',num2str(cutoff),'\nleft,', num2str(left),'\nright,', num2str(right),'\ntop,', num2str(top),'\nbottom,', num2str(bottom),'\n'...
    ,'minCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity),'\n'...
    ,'minLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\n'...
    ,'maxAngle,', num2str(maxAngle),'\nmaxJoinDist,', num2str(maxJoinDist),'\nmaxLine,', num2str(maxLineDist),'\n'...
    ,'left2,', num2str(left2),'\nright2,', num2str(right2),'\ntop2,', num2str(top2),'\nbottom2,', num2str(bottom2),'\n'...
    ,'minCount2,',num2str(minCount),'\nmaxCount2,', num2str(maxCount),'\nminEccentricity2,', num2str(minEccentricity2),'\nmaxEccentricity2,', num2str(maxEccentricity2),'\n'...
    ,'minLength2,',num2str(minLength2),'\nmaxLength2,', num2str(maxLength2),'\nmaxDistFromLinear2,', num2str(maxDistFromLinear2),'\n'...
    ,'KymExtensionDist,',num2str(kymExtensionDist),'\nkymWidth,',num2str(kymWidth),'\nbackDist,', num2str(backDist),'\nkymBackWidth,', num2str(kymBackWidth)];

    fileID = fopen([workingDir,'Kymograph_Generation_Variables.csv'],'w');
    fprintf(fileID, variableString);
    fclose(fileID);
    
    
    kymdir = [workingDir,'\Kymographs\'];
    mkdir(kymdir);
    cmd = [JIM,'Make_Kymographs',fileEXE,' "',workingDir,'Channel_1_Fluorescent_Intensities.csv" "',workingDir,'Channel_1_Fluorescent_Backgrounds.csv" "',workingDir,'Expanded_ROI_Positions.csv" "',kymdir,'Kymograph"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)
end


