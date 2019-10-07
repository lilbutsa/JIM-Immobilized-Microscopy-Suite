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

alignStartFrame = 1;
alignEndFrame = 5;

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

detectionStartFrame = 1;
detectionEndFrame = 25;

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
cutoff=0.85; % The curoff for the initial thresholding

%Filtering
left = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases


minCount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxCount=100; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

minEccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxEccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minLength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxLength = 100000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.


displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 2; % This just adjusts the contrast in the displayed image. It does NOT effect detection
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

%% 5) Expand Regions
foregroundDist = 4.1; 
backInnerDist = 4.1;
backOuterDist = 20; 

displayMin = 0; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 2; % This just adjusts the contrast in the displayed image. It does NOT effect detection

cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
system(cmd)

%show expansion reult
figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
channel1Im = im2double(imread([workingDir,'Aligned_Partial_Mean.tiff']));
channel1Im = displayMax.*(channel1Im-min(min(channel1Im)))./(max(max(channel1Im))-min(min(channel1Im)))+displayMin;
channel1Im= min(max(channel1Im,0),1);
channel2Im = im2double(imread([workingDir,'Expanded_ROIs.tif']));
channel3Im = im2double(imread([workingDir,'Expanded_Background_Regions.tif']));
combinedImage = cat(3, overlayColour1(1).*channel1Im+overlayColour2(1).*channel2Im+overlayColour3(1).*channel3Im,overlayColour1(2).*channel1Im+overlayColour2(2).*channel2Im+overlayColour3(2).*channel3Im,overlayColour1(3).*channel1Im+overlayColour2(3).*channel2Im+overlayColour3(3).*channel3Im);
imshow(combinedImage);
truesize([900 900]);

%% 6) Calculate Traces
verboseOutput = false;

verboseString = '';
if verboseOutput
    verboseString = ' -Verbose';
end

cmd = [JIM,'Calculate_Traces',fileEXE,' "',completeName,'" "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drift "',workingDir,'Aligned_Drifts.csv"',verboseString]; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)

variableString = ['Date, ', datestr(datetime('today')),'\n'...
    ,'iterations,',num2str(iterations),'\nalignStartFrame,', num2str(alignStartFrame),'\nalignEndFrame,', num2str(alignEndFrame),'\n'...
    ,'useMaxProjection,',num2str(useMaxProjection),'\ndetectionStartFrame,', num2str(detectionStartFrame),'\ndetectionEndFrame,', num2str(detectionEndFrame),'\n'...
    ,'cutoff,',num2str(cutoff),'\nleft,', num2str(left),'\nright,', num2str(right),'\ntop,', num2str(top),'\nbottom,', num2str(bottom),'\n'...
    ,'minCount,',num2str(minCount),'\nmaxCount,', num2str(maxCount),'\nminEccentricity,', num2str(minEccentricity),'\nmaxEccentricity,', num2str(maxEccentricity),'\n'...
    ,'minLength,',num2str(minLength),'\nmaxLength,', num2str(maxLength),'\nmaxDistFromLinear,', num2str(maxDistFromLinear),'\n'...
    ,'foregroundDist,',num2str(foregroundDist),'\nbackInnerDist,', num2str(backInnerDist),'\nbackOuterDist,', num2str(backOuterDist),'\nverboseOutput,', num2str(verboseOutput)];

fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
fprintf(fileID, variableString);
fclose(fileID);

%% 7) View Traces
pageNumber = 1;

traces=csvread([workingDir,'Channel_1_Fluorescent_Intensities.csv'],1);
measures = csvread([workingDir,'Detected_Filtered_Measurements.csv'],1);
channel1Im = imread([workingDir,'Detected_Filtered_Region_Numbers.tif']);
figure('Name','Particle Numbers');
imshow(channel1Im);
truesize([900 900]);

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for i=1:36
    if i+36*(pageNumber-1)<size(traces,1)
    subplot(6,6,i)
    hold on
    title(['Particle ' num2str(i+36*(pageNumber-1)) ' x ' num2str(round(measures(i+36*(pageNumber-1),1))) ' y ' num2str(round(measures(i+36*(pageNumber-1),2)))])
    plot(traces(i+36*(pageNumber-1),:),'-r');
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
%% 8) Detect files for batch
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
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
allFiles = allFiles(contains(allFiles,'.tif','IgnoreCase',true));
NumberOfFiles=size(allFiles,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
    

%% 9) Batch Analyse
overwritePreviouslyAnalysed = true;
parfor i=1:NumberOfFiles
    completeName = allFiles{i};
    disp(['Analysing ',completeName]);
    % 3.2) Create folder for results
    [fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
    workingDir = [fileNamein,filesep,name];
    [fileNamein,name,~] = fileparts(workingDir);
    workingDir = [fileNamein,filesep,name,filesep];
    if ~exist(workingdir, 'dir')
        mkdir(workingdir)%make a subfolder with that name
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
    % 3.5) Fit areas around each shape
    cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(foregroundDist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
    system(cmd)
    % 3.6) Calculate Sum of signal and background for each frame
    cmd = [JIM,'Calculate_Traces',fileEXE,' "',completeName,'" "',workingDir,'Expanded_ROI_Positions.csv" "',workingDir,'Expanded_Background_Positions.csv" "',workingDir,'Channel_1" -Drifts "',workingDir,'Aligned_Drifts.csv"',verboseString]; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)
    
    fileID = fopen([workingDir,'Trace_Generation_Variables.csv'],'w');
    fprintf(fileID, variableString);
    fclose(fileID);

end

