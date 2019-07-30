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
%% 3) Calculate Drifts
iterations = 1;

alignstartframe = 1;
alignendframe = 4;

cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'" -Start ',num2str(alignstartframe),' -End ',num2str(alignendframe),' -Iterations ',num2str(iterations)];%Run the Align_Channels program with the selected image stack as the input and save the results to the results folder with the Aligned prefix
system(cmd);

figure('Name','Before Drift Correction') %Display the initial mean that has no drift correction. This is equivilent to the z projection if the stack in ImageJ
originalim = imread([workingdir,'Aligned_initial_mean.tiff']);
originalim = imadjust(originalim);
imshow(originalim);


figure('Name','After Drift Correction')%Display the final mean drift corrected mean. 
originalim = imread([workingdir,'Aligned_final_mean.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

drifts = csvread([workingdir,'Aligned_Drifts.csv'],1);%Read in drifts to see waht the max the image has shifted by
disp(['Maximum drift is ', num2str(max(max(abs(drifts))))]);
%% 4) Make a SubAverage of the image stack for detection
usemaxprojection = false;

partialstartframe = 1;
partialendframe = 20;

maxprojectstr = '';
if usemaxprojection
    maxprojectstr = ' -MaxProjection';
end

cmd = [JIM,'MeanofFrames.exe NULL "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" "',completename,'" -Start ',num2str(partialstartframe),' -End ',num2str(partialendframe),maxprojectstr];
system(cmd);

figure('Name','Sub-Average to use for detection')%Display the mean of the substack that will be used for particle detection
originalim = imread([workingdir,'Aligned_Partial_Mean.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

%% 5) Detect Particles
% User Defined Parameters 
%Thresholding
cutoff=0.45; % The curoff for the initial thresholding

%Filtering
left = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
right = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
top = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
bottom = 10;% Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases


mincount = -1; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxcount=1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

mineccentricity = -0.1; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxeccentricity = 0.4;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minlength = 0; % Minimum number of pixels for the major axis of the best fit ellipse
maxlength = 10; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 10000000; % Maximum distance that a pixel can diviate from the major axis.

displayminmax = [0 1]; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Detection Program

refchan = [workingdir,'Aligned_Partial_Mean.tiff']; % Change this to change what file is used for detection(If you don't want to use a partial mean make it Aligned_final_mean_1.tiff).
cmd = [JIM,'Detect_Particles.exe "',refchan,'" "',workingdir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
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

%% 6) Fit areas around each shape
expandinnerradius=4.1; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backgroundradius = 20; % Distance to dilate beyond the ROI to measure the local background
backgroundinnerradius = 0;

cmd = [JIM,'Expand_Shapes.exe "',workingdir,'Detected_Filtered_Positions.csv" "',workingdir,'Detected_Positions.csv" "',workingdir,'Expanded" -boundaryDist ', num2str(expandinnerradius),' -backgroundDist ',num2str(backgroundradius),' -backInnerRadius ',num2str(backgroundinnerradius)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
system(cmd)


%view detection overlay RGB
figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
detectedim = imread([workingdir,'Expanded_ROIs.tif']);
detectedim = im2uint16(detectedim)/1.5;

backim = imread([workingdir,'Expanded_Background_Regions.tif']);
backim = im2uint16(backim)/1.5;

IMG1 = cat(3, originalim,detectedim,backim);
imshow(IMG1);

%% 7) Calculate Sum of signal and background for each frame
cmd = [JIM,'Calculate_Traces.exe "',completename,'" "',workingdir,'Expanded_ROI_Positions.csv" "',workingdir,'Expanded_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
system(cmd)
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
insubfolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

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
    allfilescells = allfilescells(~startsWith(allfilescells,[pathname,'.']));
    filenum=size(allfilescells,1);
end
disp(['There are ',num2str(filenum),' files to analyse']);

%% Run sum single iteratively
overwrite = true;
parfor i=1:filenum(1)
    completename = allfilescells{i};
    disp(['Analysing ',completename]);
    % 3.2) Create folder for results
    [pathnamein,name,~] = fileparts(completename);%get the name of the tiff image
    workingdir = [pathnamein,'\',name];
    [pathnamein,name,~] = fileparts(workingdir);
    workingdir = [pathnamein,'\',name,'\'];
    mkdir(workingdir);%make a subfolder with that name

    if (exist([workingdir,'Channel_1_Flourescent_Intensities.csv'],'file')==2 && overwrite==false)
        disp(['Skipping ',completename,' - Analysis already exists']);
        continue
    end
    
    % 3.3)  Calculate Drifts
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'" -Start ',num2str(alignstartframe),' -End ',num2str(alignendframe),' -Iterations ',num2str(iterations)];%Run the Align_Channels program with the selected image stack as the input and save the results to the results folder with the Aligned prefix
    system(cmd);

    
    cmd = [JIM,'MeanofFrames.exe NULL "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" "',completename,'" -Start ',num2str(partialstartframe),' -End ',num2str(partialendframe),maxprojectstr];
    system(cmd);
    % 3.4) Detect Particles
    refchan = [workingdir,'Aligned_Partial_Mean.tiff'];
    cmd = [JIM,'Detect_Particles.exe "',refchan,'" "',workingdir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -left ',num2str(left),' -right ',num2str(right),' -top ',num2str(top),' -bottom ',num2str(bottom),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
    system(cmd)
    % 3.5) Fit areas around each shape
    cmd = [JIM,'Expand_Shapes.exe "',workingdir,'Detected_Filtered_Positions.csv" "',workingdir,'Detected_Positions.csv" "',workingdir,'Expanded" -boundaryDist ', num2str(expandinnerradius),' -backgroundDist ',num2str(backgroundradius),' -backInnerRadius ',num2str(backgroundinnerradius)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
    system(cmd)
    % 3.6) Calculate Sum of signal and background for each frame
    cmd = [JIM,'Calculate_Traces.exe "',completename,'" "',workingdir,'Expanded_ROI_Positions.csv" "',workingdir,'Expanded_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"']; % Generate traces using AS_Measure_Each_Frame.exe and write out with the prefix Channel_1
    system(cmd)

end

