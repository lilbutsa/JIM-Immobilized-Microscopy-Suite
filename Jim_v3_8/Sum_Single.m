%% 1) Select the input tiff file
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
[filename,pathname] = uigetfile('*','Select the Image file');

%% 2) Create folder for results
completename = [pathname,filename];
[pathstr,name,ext] = fileparts(completename);
workingdir = [pathname,name,'\'];
mkdir(workingdir);
%% 3) Calculate Drifts
cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'"'];
system(cmd);

figure
originalim = imread([workingdir,'Aligned_initial_mean_1.tiff']);
originalim = imadjust(originalim);
imshow(originalim);


%view drift correction before and after
figure
originalim = imread([workingdir,'Aligned_final_mean_1.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

drifts = csvread([workingdir,'Aligned_Drifts.csv'],1);
disp(['Maximum drift is ', num2str(max(max(abs(drifts))))]);
%% 4) Make a SubAverage of frames where all particles are present 
startframe = 1;
endframe = 5;

cmd = [JIM,'MeanofFrames.exe "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];
system(cmd);

figure
originalim = imread([workingdir,'Aligned_Partial_Mean.tiff']);
originalim = imadjust(originalim);
imshow(originalim);

%% 5) Detect Particles
% 5a) User Defined Parameters 
cutoff=1;

mindistfromedge = 25;

mincount = 10;
maxcount=1000000;

mineccentricity = -0.1;
maxeccentricity = 0.5;

minlength = 10;
maxlength = 1000000;

maxDistFromLinear = 100000;

% 5b) Detection Program

refchan = [workingdir,'Aligned_Partial_Mean.tiff'];
cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
system(cmd)

%view detection
figure
detectedim = imread([workingdir,'Positions_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
imshow(IMG1);


figure
detectedim = imread([workingdir,'Positions_Filtered_Detected_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;
originalim = imread(refchan);
originalim = imadjust(originalim);
IMG1 = cat(3, originalim,detectedim,zeros(size(detectedim)));
imshow(IMG1);

%% 6) Fit areas around each shape
innerradius=4.1;
backgroundradius = 20;
cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Labelled_Positions.csv" "',workingdir,'Expanded" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
system(cmd)
cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements.csv" "',workingdir,'Expanded_ROI_Positions.csv" "',workingdir,'Expanded_Background_Positions.csv" "',workingdir,'Filtered_Expanded" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
system(cmd)

%view detection overlay RGB
figure
detectedim = imread([workingdir,'Filtered_Expanded_Regions.tif']);
detectedim = im2uint16(detectedim)/1.5;

backim = imread([workingdir,'Filtered_Expanded_BackGround_Regions.tif']);
backim = im2uint16(backim)/1.5;

IMG1 = cat(3, originalim,detectedim,backim);
imshow(IMG1);

%% 7) Calculate Sum of signal and background for each frame
cmd = [JIM,'AS_Measure_Each_Frame.exe "',completename,'" "',workingdir,'Filtered_Expanded_Positions.csv" "',workingdir,'Filtered_Expanded_BackGround_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
system(cmd)