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
cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'"'];%Run the Align_Channels program with the selected image stack as the input and save the results to the results folder with the Aligned prefix
system(cmd);

figure('Name','Before Drift Correction') %Display the initial mean that has no drift correction. This is equivilent to the z projection if the stack in ImageJ
originalim = imread([workingdir,'Aligned_initial_mean_1.tiff']);
originalim = imadjust(originalim);
imshow(originalim);


figure('Name','After Drift Correction')%Display the final mean drift corrected mean. 
originalim = imread([workingdir,'Aligned_final_mean_1.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

drifts = csvread([workingdir,'Aligned_Drifts.csv'],1);%Read in drifts to see waht the max the image has shifted by
disp(['Maximum drift is ', num2str(max(max(abs(drifts))))]);
%% 4) Make a SubAverage of frames where all particles are present 
startframe = 35; % First frame in statck to take average from (First frame is 1) 
endframe = 45;  % Last frame in stack to take average up to (Make sure this value is not more then the total number of frames)

cmd = [JIM,'MeanofFrames.exe "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];%Run the MeanofFrames.exe program writing the result out to Aligned_Partial_Mean.tiff
system(cmd);

figure('Name','Sub-Average to use for detection')%Display the mean of the substack that will be used for particle detection
originalim = imread([workingdir,'Aligned_Partial_Mean.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

%% 5) Detect Particles
% User Defined Parameters 
%Thresholding
cutoff=0.2; % The curoff for the initial thresholding

%Filtering

mindistfromedge = 25; % Excluded particles closer to the edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases

mincount = 10; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
maxcount=1000000; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

mineccentricity = 0.5; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
maxeccentricity = 1.1;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

minlength = 10; % Minimum number of pixels for the major axis of the best fit ellipse
maxlength = 1000000; % Maximum number of pixels for the major axis of the best fit ellipse

maxDistFromLinear = 100000; % Maximum distance that a pixel can diviate from the major axis.

displayminmax = [0 1]; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Detection Program

refchan = [workingdir,'Aligned_Partial_Mean.tiff']; % Change this to change what file is used for detection(If you don't want to use a partial mean make it Aligned_final_mean_1.tiff).
cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Detected" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)]; % Run the program Find_Particles.exe with the users values and write the output to the reults file with the prefix Detected_
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
innerradius=4; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured
backgroundradius = 50; % Distance to dilate beyond the ROI to measure the local background
cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Detected_Filtered_Positions.csv" "',workingdir,'Detected_Positions.csv" "',workingdir,'Expanded" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)]; % Run Fit_Arbitrary_Shapes.exe on the Detected_Filtered_Positions and output the result with the prefix Expanded
system(cmd)


%view detection overlay RGB
figure('Name','Detected Particles - Red Original Image - Green ROIs - Blue Background Regions')
detectedim = imread([workingdir,'Expanded_ROIs.tif']);
detectedim = im2uint16(detectedim)/1.5;

backim = imread([workingdir,'Expanded_Background_Regions.tif']);
backim = im2uint16(backim)/1.5;

IMG1 = cat(3, originalim,detectedim,backim);
imshow(IMG1);
%%
