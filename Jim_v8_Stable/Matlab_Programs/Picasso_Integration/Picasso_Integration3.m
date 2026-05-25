
%%
threshold = 500;
channelNum = 2;
cmd = ['picasso localize "' workingDir 'Images_Channel_' num2str(channelNum) '.tif" -b 9 -g ' num2str(threshold) ' -bl 100'];
system(cmd);
%%
picData = h5read([workingDir 'Images_Channel_2_locs.hdf5'],'/locs');
jimDrifts = csvread([workingDir,'Detected_Filtered_Drifts_Channel_2.csv'],1,0);
%%
for i=1:length(picData.x)
    picData.x(i) = picData.x(i)+jimDrifts(picData.frame(i)+1,1);
    picData.y(i) = picData.y(i)+jimDrifts(picData.frame(i)+1,2);
end
%%
struct2hdf5(picData,'/locs',workingDir(1:end-1),'Images_Channel_2_locs_undrift.hdf5');
copyfile([workingDir 'Images_Channel_2_locs.yaml'],[workingDir 'Images_Channel_2_locs_undrift.yaml']);
    %%
    picassodist = 1;
    cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(channelNum),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(channelNum),'.csv" "',workingDir,'Picasso_regions" -boundaryDist ', num2str(picassodist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
    system(cmd) 
    %%
jimPos = csvread([workingDir 'Picasso_regions_ROI_Positions.csv'],1,0);
%%
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
%% 12) Batch Analyse
threshold = 500;
channelNum = 2;
driftFrames = 0;%0 to disable

overwritePreviouslyAnalysed = true;
deleteWorkingImageStacks = false;

for fileNo=1:NumberOfFiles
    
    completeName = allFiles{fileNo};
    
    
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
   
    
    cmd = ['picasso localize "' workingDir 'Images_Channel_' num2str(channelNum) '.tif" -b 9 -g ' num2str(threshold) ' -bl 100'];
    system(cmd);

    picData = h5read([workingDir 'Images_Channel_2_locs.hdf5'],'/locs');
    jimDrifts = csvread([workingDir,'Detected_Filtered_Drifts_Channel_2.csv'],1,0);

    for i=1:length(picData.x)
        picData.x(i) = picData.x(i)+jimDrifts(picData.frame(i)+1,1);
        picData.y(i) = picData.y(i)+jimDrifts(picData.frame(i)+1,2);
    end

    struct2hdf5(picData,'/locs',workingDir(1:end-1),'Images_Channel_2_locs_undrift.hdf5');
    copyfile([workingDir 'Images_Channel_2_locs.yaml'],[workingDir 'Images_Channel_2_locs_undrift.yaml']);

        picassodist = 1;
           cmd = [JIM,'Expand_Shapes',fileEXE,' "',workingDir,'Detected_Filtered_Positions_Channel_',num2str(channelNum),'.csv" "',workingDir,'Detected_Filtered_Background_Positions_Channel_',num2str(channelNum),'.csv" "',workingDir,'Picasso_regions" -boundaryDist ', num2str(picassodist),' -backgroundDist ',num2str(backOuterDist),' -backInnerRadius ',num2str(backInnerDist)];
        system(cmd) 

    jimPos = csvread([workingDir 'Picasso_regions_ROI_Positions.csv'],1,0);

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

    picData = h5read([workingDir 'Images_Channel_2_locs_undrift.hdf5'],'/locs');


    picData.group = cast(zeros(length(picData.x),1),'int32');
    for i=1:length(picData.x)
        if ceil(picData.x(i))>imWidth || ceil(picData.y(i))>imHeight || ceil(picData.x(i))<1 || ceil(picData.y(i))<1
            picData.group(i) = 0;
        else
            picData.group(i) = imPos(ceil(picData.x(i)),ceil(picData.y(i)));
        end
    end
    picData = IndexedStructCopy(picData,picData.group>0);

    meanx = arrayfun(@(z) mean(picData.x(picData.group==z)),1:max(picData.group));
    meany = arrayfun(@(z) mean(picData.y(picData.group==z)),1:max(picData.group));

    xin = arrayfun(@(z) picData.x(z) - meanx(picData.group(z)),1:length(picData.x));
    yin = arrayfun(@(z) picData.y(z) - meany(picData.group(z)),1:length(picData.y));

    driftx = arrayfun(@(z) mean(xin(picData.frame==z)),1:(max(picData.frame)+1));
    drifty = arrayfun(@(z) mean(yin(picData.frame==z)),1:(max(picData.frame)+1));

    for i=1:length(picData.x)
        picData.x(i) = picData.x(i) - driftx(picData.frame(i)+1);
        picData.y(i) = picData.y(i) - drifty(picData.frame(i)+1);
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
