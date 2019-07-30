%%
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
        outnames = dir([pathname,allfiles(i).name,'\*.tif']);
        allfiles(i).name=[allfiles(i).name,'\',outnames.name];
    end
else
    allfiles = dir([pathname,'\*.tif']);
    filenum=size(allfiles);
end
disp(['There are ',num2str(filenum(1)),' files to analyse']);
%% 3)Run Guass single iteratively'
numberofchannels = 2;

invertchannel2 = false;

manualalignment = false;
rotationangle = 0.43375;
scalingfactor = 1.00;
xoffset = 3.7;
yoffset = -1.7;

channeltodetect = 2; %%change this depending on which channel to detect

startframe = 1;
endframe = 10;

%paste from Sum_multi
%this is Figure 1 cutoff/mask that will pick up all particles
cutoff = 0.6;

%this is a clean up filter further cleaning 
mindistfromedge = 25;
mincount = 30;
maxcount = 1000000;

mineccentricity = 0.6;
maxeccentricity = 1.1;

minlength = 0;
maxlength = 1000000;

maxDistFromLinear = 5;

%do not touch below here
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

   % 3.3) Split File into individual channels 
    
    cmd = [JIM,'TIFFChannelSplitter.exe "',completename,'" "',workingdir,'Images" ',num2str(numberofchannels)];
    system(cmd)

    %invert if needed
    if invertchannel2
        cmd = [JIM,'Invert_Channel.exe "',workingdir,'Images_Channel_2.tiff" "',workingdir,'Images_Channel_2_Inverted.tiff"'];
        system(cmd)
        delete([workingdir,'Images_Channel_2.tiff']);
        movefile([workingdir,'Images_Channel_2_Inverted.tiff'],[workingdir,'Images_Channel_2.tiff']);
    end
    
    % 3.4) Align Channels and Calculate Drifts 
    allchannelnames = '';
    for j = 2:numberofchannels
        allchannelnames = [allchannelnames,' "',workingdir,'Images_Channel_',num2str(j),'.tiff"'];
    end
    
    if manualalignment
        cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff"',allchannelnames,' -Alignment ',num2str(xoffset),' ',num2str(yoffset),' ',num2str(rotationangle),' ',num2str(scalingfactor)];
    else
        cmd = [JIM,'Align_Channels.exe "',workingdir,'Aligned" "',workingdir,'Images_Channel_1.tiff"',allchannelnames];
    end
    system(cmd)

    % make submean
    if channeltodetect ==-1 
        refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
        cmd = [JIM,'MeanofFrames.exe "',refchan,'" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Aligned" -End ',num2str(endframe),' -Start ',num2str(startframe)];
        system(cmd);
    end 

    if channeltodetect ==-1
        refchan = [workingdir,'Aligned_Partial_Mean.tiff'];
    elseif channeltodetect == 0
        refchan = [workingdir,'Aligned_final_Combined_Mean_Image.tiff']; 
    elseif channeltodetect ==1
           refchan = [workingdir,'Aligned_final_mean_1.tiff']; 
    else
           refchan = [workingdir,'Aligned_final_mean_aligned_',num2str(channeltodetect),'.tiff']; 
    end 
    
    
 
    
    % 3.5) Detect Particles

    cmd = [JIM,'Find_Particles.exe "',refchan,'" "',workingdir,'Positions" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)

    % 3.6)Calculate the equivalent positions in the other channels
    cmd = [JIM,'Calculate_Positions_For_Other_Channels.exe "',workingdir,'Aligned_channel_alignment.csv" "',workingdir,'Aligned_Drifts.csv" "',workingdir,'Positions_Measurements.csv" "',workingdir,'Positions" -positions "',workingdir,'Positions_Labelled_Positions.csv"'];
    system(cmd)

    % 3.7) Fit areas around each shape 
    cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Labelled_Positions.csv" "',workingdir,'Expanded_Channel_1" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
    system(cmd)
    cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements.csv" "',workingdir,'Expanded_Channel_1_ROI_Positions.csv" "',workingdir,'Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_1" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
    system(cmd)
    
    for j = 2:numberofchannels
        cmd = [JIM,'Fit_Arbitrary_Shapes.exe "',workingdir,'Positions_Positions_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'" -boundaryDist ', num2str(innerradius),' -backgroundDist ',num2str(backgroundradius)];
        system(cmd)
        cmd = [JIM,'Filter_ROIs "',workingdir,'Positions_Measurements_Channel_',num2str(j),'.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_ROI_Positions.csv" "',workingdir,'Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'" -BinarizeCutoff ', num2str(cutoff),' -minLength ',num2str(minlength),' -maxLength ',num2str(maxlength),' -minCount ',num2str(mincount),' -maxCount ',num2str(maxcount),' -minEccentricity ',num2str(mineccentricity),' -maxEccentricity ',num2str(maxeccentricity),' -minDistFromEdge ',num2str(mindistfromedge),' -maxDistFromLinear ',num2str(maxDistFromLinear)];
        system(cmd)
    end

    % 3.8) Calculate amplitude for each frame for each channel
    cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_1.tiff" "',workingdir,'Filtered_Expanded_Channel_1_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_1_Background_Positions.csv" "',workingdir,'Channel_1" -Drifts "',workingdir,'Aligned_Drifts.csv"'];
    system(cmd)

    for j = 2:numberofchannels
        cmd = [JIM,'AS_Measure_Each_Frame.exe "',workingdir,'Images_Channel_',num2str(j),'.tiff" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'_Positions.csv" "',workingdir,'Filtered_Expanded_Channel_',num2str(j),'_Background_Positions.csv" "',workingdir,'Channel_',num2str(j),'" -Drifts "',workingdir,'Positions_Drifts_Channel_',num2str(j),'.csv"'];
        system(cmd)
    end
end

disp('Batch Process Compeleted');


if manualalignment
    manstr = 'true';
else
    manstr = 'false';
    rotationangle = 0;
    scalingfactor = 1.00;
    xoffset = 0;
    yoffset = 0;

end
    


T = cell2table({'manual alignment' manstr; 'rotation angle' num2str(rotationangle); 'scaling factor' num2str(scalingfactor);'x offset' num2str(xoffset);'y offset' num2str(yoffset);'Detection Channel' num2str(channeltodetect); 'startframe' num2str(startframe); 'endframe' num2str(endframe);'cutoff' num2str(cutoff);'mindistfromedge', num2str(mindistfromedge);'mincount', num2str(mincount);'maxcount', num2str(maxcount); 'mineccentricity', num2str(mineccentricity);'maxeccentricity', num2str(maxeccentricity);'minlength', num2str(minlength);'maxlength', num2str(maxlength);'maxDistFromLinear', num2str(maxDistFromLinear);'innerradius', num2str(innerradius);'backgroundradius', num2str(backgroundradius)});
T.Properties.VariableNames= {'Variable','Value'};
writetable(T, [pathname,'Detection_Variables.csv']);