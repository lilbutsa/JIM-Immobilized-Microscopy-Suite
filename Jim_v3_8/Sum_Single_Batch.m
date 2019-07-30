%% 0) Clear previous variables to keep things neat
clear
%% 1) Select the input folder
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [jimpath,'\Jim_Programs\'];
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) detect files to analyze
insubfolders = true;

if insubfolders
    allfiles = dir(pathname);
    allfiles(~[allfiles.isdir]) = [];
    allfiles=allfiles(3:end);
    filenum=size(allfiles);
    upperfilenames = allfiles;
    for i=1:filenum(1)
        outnames = [dir([pathname,allfiles(i).name,'\*.tif']) dir([pathname,allfiles(i).name,'\*.tiff'])];
        allfiles(i).name=[allfiles(i).name,'\',outnames.name];
    end
else
    allfiles = [dir([pathname,'\*.tif']) dir([pathname,'\*.tiff'])];
    filenum=size(allfiles);
end
disp(['There are ',num2str(filenum(1)),' files to analyse']);
%% 3)Run Guass single iteratively
startframe = 1;
endframe = 5;

cutoff=0.5;

mindistfromedge = 25;

mincount = 10;
maxcount=1000000;

mineccentricity = -0.1;
maxeccentricity = 0.4;

minlength = 0;
maxlength = 1000000;

maxDistFromLinear = 100000;

innerradius=4.1;
backgroundradius = 20;

for i=1:filenum(1)
    filename = allfiles(i).name;
    disp(['Analysing ',filename]);
    % 3.2) Create folder for results
    completename = [pathname,filename];
    [pathstr,namein,~] = fileparts(completename);
    workingdir = [pathstr,'\',namein,'\'];
    mkdir(workingdir);

    % 3.3) Align Channels and Calculate Drifts
    cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',completename,'"'];
    system(cmd);
    
    cmd = [JIM,'MeanofFrames.exe "',completename,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];
    system(cmd);
    % 3.4) Detect Particles
    refchan = [workingdir,'Aligned_Partial_Mean.tiff'];
    cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)
    % 3.5) Fit areas around each shape
    cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Labelled_Positions.csv" "',workingdir,'Expanded" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
    system(cmd)
    cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements.csv" "',workingdir,'Expanded_ROI_Positions.csv" "',workingdir,'Expanded_Background_Positions.csv" "',workingdir,'Filtered_Expanded" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)
    % 3.6) Calculate Sum of signal and background for each frame
    cmd = [JIM,'AS_Measure_Each_Frame.exe "',completename,'" "',workingdir,'Filtered_Expanded_Positions.csv" "',workingdir,'Filtered_Expanded_BackGround_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
    system(cmd)

end


usedvals = {'startframe' num2str(startframe); 'endframe' num2str(endframe);'cutoff' num2str(cutoff);'mindistfromedge', num2str(mindistfromedge);'mincount', num2str(mincount);'maxcount', num2str(maxcount); 'mineccentricity', num2str(mineccentricity);'maxeccentricity', num2str(maxeccentricity);'minlength', num2str(minlength);'maxlength', num2str(maxlength);'maxDistFromLinear', num2str(maxDistFromLinear);'innerradius', num2str(innerradius);'backgroundradius', num2str(backgroundradius)};
T = cell2table(usedvals);
T.Properties.VariableNames= {'Variable','Value'};
writetable(T, [pathname,'Detection_Variables.csv']);