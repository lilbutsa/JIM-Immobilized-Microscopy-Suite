clear
%% Select the files
driftCorrect = true;

sysConst.JIM = 'E:\Github\JIM-Immobilized-Microscopy-Suite\Jim_v7.1';


% don't touch from here
sysConst.JIM = ['"',sysConst.JIM,'\c++_Base_Programs\Windows\'];
sysConst.fileEXE = '.exe"';


[sysVar.fileName,sysVar.pathName] = uigetfile('*.hdf5','Select the filtered HDF5');

sysVar.allFiles = dir(fullfile(sysVar.pathName, '**\*.ti*'));
sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'before','IgnoreCase',true),1:length(sysVar.allFiles));
beforeImage = arrayfun(@(z)[sysVar.allFiles(z).folder filesep sysVar.allFiles(z).name],find(sysVar.toselect),'UniformOutput',false);
beforeImage = beforeImage{1};
%beforeImage = uigetfile('*.tif','Select the Before Image');

sysVar.overlayColour = [[1, 0, 0];[0, 1, 0];[0, 0, 1]];

workingDir=[sysVar.pathName 'Jim_Picasso_Workings' filesep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end

%% 5) Detect Particles

%Thresholding
detectionCutoff =1.5; % The cutoff for the initial thresholding. Typically in range 0.25-2

%Filtering
detectLeftEdge = 10;% Excluded particles closer to the left edge than this. Make sure this value is larger than the maximum drift. 25 works well in most cases
detectRightEdge = 10;% Excluded particles closer to the Right edge than this. 
detectTopEdge = 10;% Excluded particles closer to the Top edge than this. 
detectBottomEdge =10;% Excluded particles closer to the Bottom edge than this. 

detectMinCount = 7; % Minimum number of pixels in a ROI to be counted as a particle. Use this to exclude speckles of background
detectMaxCount= 100; % Maximum number of pixels in a ROI to be counted as a particle. Use this to exclude aggregates

detectMinEccentricity = -0.10; % Eccentricity of best fit ellipse goes from 0 to 1 - 0=Perfect Circle, 1 = Line. Use the Minimum to exclude round objects. Set it to any negative number to allow all round objects
detectMaxEccentricity = 0.5;  % Use the maximum to exclude long, thin objects. Set it to a value above 1 to include long, thin objects  

detectMinLength = 0.00; % Minimum number of pixels for the major axis of the best fit ellipse
detectMaxLength = 10000.00; % Maximum number of pixels for the major axis of the best fit ellipse

detectMaxDistFromLinear = 10000.00; % Maximum distance that a pixel can diviate from the major axis.

detectMinSeparation = 2.00;% Minimum separation between ROI's. Given by the closest edge between particles Set to 0 to accept all particles

% Visualisation saturationg percentages

displayMin = 0.05; % This just adjusts the contrast in the displayed image. It does NOT effect detection
displayMax = 0.95; % This just adjusts the contrast in the displayed image. It does NOT effect detection

% Don't Touch From Here

sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',beforeImage,'" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
system(sysVar.cmd)

%Show detection results - Red Original Image -ROIs->White -
% Green/Yellow->Excluded by filters
sysVar.imout = cast(imread(beforeImage),'double');
tosort = sort(sysVar.imout(:));
sysVar.imout = (sysVar.imout-tosort(round(displayMin*length(tosort))))./(tosort(round(displayMax*length(tosort)))-tosort(round(displayMin*length(tosort))));
sysVar.combinedImage = zeros(size(sysVar.imout,1),size(sysVar.imout,2),3);
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(1,j);
end
sysVar.imout = im2double(imread([workingDir,'Detected_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(2,j);
end
sysVar.imout = im2double(imread([workingDir,'Detected_Filtered_Regions.tif']));
for j=1:3
    sysVar.combinedImage(:,:,j) = sysVar.combinedImage(:,:,j)+sysVar.imout.*sysVar.overlayColour(3,j);
end

figure('Name','Detected Particles - Red Original Image - Blue to White Selected ROIs - Green to Yellow->Excluded by filters')
imshow(sysVar.combinedImage)
disp('Finish detecting particles');
%% 7) Expand Regions
expandForegroundDist =1; % Distance to dilate the ROIs by to make sure all flourescence from the ROI is measured

%don't touch from here

sysVar.cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(5),' -backInnerRadius ',num2str(25)];
system(sysVar.cmd)
%% Select Pics
jimPos = csvread([workingDir 'Expanded_ROI_Positions_Channel_1.csv'],1,0);

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

picData = h5read([sysVar.pathName,sysVar.fileName],'/locs');
jimPos = csvread([workingDir 'Detected_Filtered_Measurements.csv'],1,0);
numPart = size(jimPos,1);

measData.frame = zeros(numPart,1)+1;
measData.x = jimPos(:,1);
measData.y = jimPos(:,2);
measData.photons = zeros(numPart,1)+mean(picData.photons);
measData.sx = zeros(numPart,1)+mean(picData.sx);
measData.sy = zeros(numPart,1)+mean(picData.sy);
measData.bg = zeros(numPart,1)+mean(picData.bg);
measData.lpx = zeros(numPart,1)+mean(picData.lpx);
measData.lpy = zeros(numPart,1)+mean(picData.lpy);
measData.ellipticity = zeros(numPart,1);
measData.net_gradient = zeros(numPart,1)+5;
measData.len = zeros(numPart,1)+1;
measData.n = zeros(numPart,1)+1;

fileNameIn = sysVar.fileName;
struct2hdf5(measData,'/locs',workingDir(1:end-1),[fileNameIn(1:end-5) '_JIM_COM.hdf5']);
copyfile([sysVar.pathName fileNameIn(1:end-5) '.yaml'],[workingDir fileNameIn(1:end-5) '_JIM_COM.yaml']);

%%
fileNameIn = [workingDir,sysVar.fileName];
COMfile = [fileNameIn(1:end-5) '_JIM_COM.hdf5'];
lastHDF5File = [sysVar.pathName,sysVar.fileName];

copyfile(lastHDF5File,[workingDir sysVar.fileName]);
copyfile([sysVar.pathName sysVar.fileName(1:end-5) '.yaml'],[workingDir sysVar.fileName(1:end-5) '.yaml']);

lastHDF5File = [workingDir,sysVar.fileName];

if driftCorrect
    %sysVar.cmd = ['picasso aim "' lastHDF5File '"'];
    sysVar.cmd = ['picasso undrift "' lastHDF5File '" -d -s ' num2str(max([round(max(picData.frame)/10) 500]))];
    system(sysVar.cmd)
    
    %lastHDF5File = [lastHDF5File(1:end-5) '_aim.hdf5'];
    lastHDF5File = [lastHDF5File(1:end-5) '_undrift.hdf5'];
end

sysVar.cmd = ['picasso align "' COMfile '" "' lastHDF5File '"'];
system(sysVar.cmd)

lastHDF5File = [lastHDF5File(1:end-5) '_align.hdf5'];

sysVar.cmd = ['picasso link "' lastHDF5File '" -d 10 -t 100'];
system(sysVar.cmd)

lastHDF5File = [lastHDF5File(1:end-5) '_link.hdf5'];

%%
picData = h5read(lastHDF5File,'/locs');

picData.group = cast(zeros(length(picData.x),1),'int32');
for i=1:length(picData.x)
    if round(picData.x(i))<1 || round(picData.y(i))<1 || round(picData.x(i))>imWidth || round(picData.y(i))>imHeight
        picData.group(i) = 0;
    else
        picData.group(i) = imPos(round(picData.x(i)),round(picData.y(i)));
    end
end

picData = IndexedStructCopy(picData,picData.group>0);
%%
uniqueGroups = unique(picData.group);
groupCount = arrayfun(@(z) nnz(picData.group==uniqueGroups(z)),1:length(uniqueGroups));
sortedGroupCount = sort(groupCount);

delta = median(groupCount);

minBindingEvents = 1;%sortedGroupCount(max(1,round(0.05*length(sortedGroupCount))));
maxBindingEvents = sortedGroupCount(find([diff(sortedGroupCount) 2.*median(groupCount)]>median(groupCount),1))+median(groupCount)./2;

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
    histogram(groupCount,round(5.*max(groupCount)./median(groupCount)))
    xline(minBindingEvents,'r','LineWidth',2)
    xline(maxBindingEvents','r','LineWidth',2)
hold off
xlabel('Binding Events Per VLP')
ylabel('Count')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
if contains(sysVar.fileName,'filter','IgnoreCase',true)
    print([sysVar.pathName 'filter_ParticlesPerVLP'], '-dpng', '-r600');
    print([sysVar.pathName 'filter_ParticlesPerVLP'], '-depsc', '-r600');
else
    print([sysVar.pathName 'ParticlesPerVLP'], '-dpng', '-r600');
    print([sysVar.pathName 'ParticlesPerVLP'], '-depsc', '-r600');
end


uniqueGroups = uniqueGroups(groupCount<=maxBindingEvents & groupCount>=minBindingEvents);
groupCount = arrayfun(@(z) nnz(picData.group(z)==uniqueGroups)>0,1:length(picData.group))';

%%
[x,idx] = sort(picData.group);

idx = idx(groupCount(idx));

picData.frame = picData.frame(idx);
picData.x = picData.x(idx);
picData.y = picData.y(idx);
picData.photons = picData.photons(idx);
picData.sx = picData.sx(idx);
picData.sy = picData.sy(idx);
picData.bg = picData.bg(idx);
picData.lpx = picData.lpx(idx);
picData.lpy = picData.lpy(idx);
if isfield(picData, 'ellipticity')
    picData.ellipticity = picData.ellipticity(idx);
end
picData.net_gradient = picData.net_gradient(idx);
picData.len = picData.len(idx);
picData.n = picData.n(idx);
picData.photon_rate = picData.photon_rate(idx);
picData.group = picData.group(idx);

uniqueGroups = unique(picData.group);
picData.group = arrayfun(@(z) find(picData.group(z)==uniqueGroups),1:length(picData.group))';


struct2hdf5(picData,'/locs',sysVar.pathName(1:end-1),[sysVar.fileName(1:end-5) '_JIM.hdf5']);
fileNameIn = [sysVar.pathName,sysVar.fileName];
copyfile([sysVar.pathName sysVar.fileName(1:end-5) '.yaml'],[sysVar.pathName sysVar.fileName(1:end-5) '_JIM.yaml']);

%% Batch Files
sysVar.topfileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.topfileName=[sysVar.topfileName,filesep]; 

sysVar.allFiles = dir(fullfile(sysVar.topfileName, '**\*.hdf5'));
sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'JIM.hdf5','IgnoreCase',true),1:length(sysVar.allFiles));
sysVar.dontselect = arrayfun(@(z) ~contains([sysVar.allFiles(z).folder],'Jim_Picasso_Workings','IgnoreCase',true),1:length(sysVar.allFiles));

%sysVar.allHDF5Files = arrayfun(@(z){sysVar.allFiles(z).folder,sysVar.allFiles(z).folder},find(sysVar.toselect),'UniformOutput',false)';
allHDF5Files = arrayfun(@(z)sysVar.allFiles(z),find(~sysVar.toselect & sysVar.dontselect),'UniformOutput',false)';
%%
dontAlign = [];
%%
for fileNo = 1:length(allHDF5Files)
    sysVar.fileName = allHDF5Files{fileNo}.name;
    sysVar.pathName = [allHDF5Files{fileNo}.folder filesep];
    sysVar.allFiles = dir(fullfile(sysVar.pathName, '**\*.ti*'));
    sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'before','IgnoreCase',true),1:length(sysVar.allFiles));
    beforeImage = arrayfun(@(z)[sysVar.allFiles(z).folder filesep sysVar.allFiles(z).name],find(sysVar.toselect),'UniformOutput',false);
    beforeImage = beforeImage{1};
    
    workingDir=[sysVar.pathName 'Jim_Picasso_Workings' filesep];
    
    if ~exist(workingDir, 'dir')
       mkdir(workingDir)%make a subfolder with that name
    end

    sysVar.cmd = [sysConst.JIM,'Detect_Particles',sysConst.fileEXE,' "',beforeImage,'" "',workingDir,'Detected" -BinarizeCutoff ', num2str(detectionCutoff),' -minLength ',num2str(detectMinLength),' -maxLength ',num2str(detectMaxLength),' -minCount ',num2str(detectMinCount),' -maxCount ',num2str(detectMaxCount),' -minEccentricity ',num2str(detectMinEccentricity),' -maxEccentricity ',num2str(detectMaxEccentricity),' -left ',num2str(detectLeftEdge),' -right ',num2str(detectRightEdge),' -top ',num2str(detectTopEdge),' -bottom ',num2str(detectBottomEdge),' -maxDistFromLinear ',num2str(detectMaxDistFromLinear),' -minSeparation ',num2str(detectMinSeparation)]; % Run the program Find_Particles.exe with the users values and write the output to the results sysVar.file with the prefix Detected_
    system(sysVar.cmd)

    sysVar.cmd = [sysConst.JIM,'Expand_Shapes',sysConst.fileEXE,' "',workingDir,'Detected_Filtered_Positions.csv" "',workingDir,'Detected_Positions.csv" "',workingDir,'Expanded" -boundaryDist ', num2str(expandForegroundDist),' -backgroundDist ',num2str(5),' -backInnerRadius ',num2str(25)];
    system(sysVar.cmd)

    jimPos = csvread([workingDir 'Expanded_ROI_Positions_Channel_1.csv'],1,0);

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
    
    picData = h5read([sysVar.pathName,sysVar.fileName],'/locs');
    jimPos = csvread([workingDir 'Detected_Filtered_Measurements.csv'],1,0);
    numPart = size(jimPos,1);
    
    measData.frame = zeros(numPart,1)+1;
    measData.x = jimPos(:,1);
    measData.y = jimPos(:,2);
    measData.photons = zeros(numPart,1)+mean(picData.photons);
    measData.sx = zeros(numPart,1)+mean(picData.sx);
    measData.sy = zeros(numPart,1)+mean(picData.sy);
    measData.bg = zeros(numPart,1)+mean(picData.bg);
    measData.lpx = zeros(numPart,1)+mean(picData.lpx);
    measData.lpy = zeros(numPart,1)+mean(picData.lpy);
    measData.ellipticity = zeros(numPart,1);
    measData.net_gradient = zeros(numPart,1)+5;
    measData.len = zeros(numPart,1)+1;
    measData.n = zeros(numPart,1)+1;
    
    fileNameIn = sysVar.fileName;
    struct2hdf5(measData,'/locs',workingDir(1:end-1),[fileNameIn(1:end-5) '_JIM_COM.hdf5']);
    copyfile([sysVar.pathName fileNameIn(1:end-5) '.yaml'],[workingDir fileNameIn(1:end-5) '_JIM_COM.yaml']);
    
    
    fileNameIn = [workingDir,sysVar.fileName];
    COMfile = [fileNameIn(1:end-5) '_JIM_COM.hdf5'];
    lastHDF5File = [sysVar.pathName,sysVar.fileName];
    
    copyfile(lastHDF5File,[workingDir sysVar.fileName]);
    copyfile([sysVar.pathName sysVar.fileName(1:end-5) '.yaml'],[workingDir sysVar.fileName(1:end-5) '.yaml']);
    
    lastHDF5File = [workingDir,sysVar.fileName];
    
    if driftCorrect
        %sysVar.cmd = ['picasso aim "' lastHDF5File '"'];
        sysVar.cmd = ['picasso undrift "' lastHDF5File '" -d -s ' num2str(max([round(max(picData.frame)/10) 500]))];
        system(sysVar.cmd)
        
        %lastHDF5File = [lastHDF5File(1:end-5) '_aim.hdf5'];
        lastHDF5File = [lastHDF5File(1:end-5) '_undrift.hdf5'];
    end     
    if nnz(dontAlign==fileNo)==0
        sysVar.cmd = ['picasso align "' COMfile '" "' lastHDF5File '"'];
        system(sysVar.cmd)
        
        lastHDF5File = [lastHDF5File(1:end-5) '_align.hdf5'];
    end

    sysVar.cmd = ['picasso link "' lastHDF5File '" -d 10 -t 100'];
    system(sysVar.cmd)
    
    lastHDF5File = [lastHDF5File(1:end-5) '_link.hdf5'];
    
    
    picData = h5read(lastHDF5File,'/locs');
    
    picData.group = cast(zeros(length(picData.x),1),'int32');
    for i=1:length(picData.x)
        if round(picData.x(i))<1 || round(picData.x(i))>imWidth || round(picData.y(i))<1 || round(picData.y(i))>imHeight
            picData.group(i) = 0;
        else
            picData.group(i) = imPos(round(picData.x(i)),round(picData.y(i)));
        end
    end
    
    picData = IndexedStructCopy(picData,picData.group>0);
    
    uniqueGroups = unique(picData.group);
    groupCount = arrayfun(@(z) nnz(picData.group==uniqueGroups(z)),1:length(uniqueGroups));
    sortedGroupCount = sort(groupCount);
    
    
    minBindingEvents = 1;%sortedGroupCount(max(1,round(0.05*length(sortedGroupCount))));
    %maxBindingEvents = find([arrayfun(@(z) nnz(groupCount==z)+nnz(groupCount==z+1)+nnz(groupCount==z+2)+nnz(groupCount==z+3),5:max(groupCount)) 0]==0,1)+5;%sortedGroupCount(max(length(sortedGroupCount),round(0.95*length(sortedGroupCount))));
    %maxBindingEvents = find([arrayfun(@(z) nnz(floor(groupCount./median(groupCount))==z),1:floor(max(groupCount)./median(groupCount))) 0]==0,1).*median(groupCount);%sortedGroupCount(max(length(sortedGroupCount),round(0.95*length(sortedGroupCount))));
    maxBindingEvents = sortedGroupCount(find([diff(sortedGroupCount) 4.*median(groupCount)]>2.*median(groupCount),1))+median(groupCount);


    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',num2str(fileNo)); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
        histogram(groupCount,round(3.*max(groupCount)./median(groupCount)))
        xline(minBindingEvents,'r','LineWidth',2)
        xline(maxBindingEvents','r','LineWidth',2)
    hold off
    xlabel('Binding Events Per VLP')
    ylabel(['Count'])
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    if contains(sysVar.fileName,'filter','IgnoreCase',true)
        print([sysVar.pathName 'filter_ParticlesPerVLP'], '-dpng', '-r600');
        print([sysVar.pathName 'filter_ParticlesPerVLP'], '-depsc', '-r600');
    else
        print([sysVar.pathName 'ParticlesPerVLP'], '-dpng', '-r600');
        print([sysVar.pathName 'ParticlesPerVLP'], '-depsc', '-r600');
    end
    
    
    
    uniqueGroups = uniqueGroups(groupCount<=maxBindingEvents & groupCount>=minBindingEvents);
    groupCount = arrayfun(@(z) nnz(picData.group(z)==uniqueGroups)>0,1:length(picData.group))';
    
    
    [x,idx] = sort(picData.group);
    
    idx = idx(groupCount(idx));
    
    picData.frame = picData.frame(idx);
    picData.x = picData.x(idx);
    picData.y = picData.y(idx);
    picData.photons = picData.photons(idx);
    picData.sx = picData.sx(idx);
    picData.sy = picData.sy(idx);
    picData.bg = picData.bg(idx);
    picData.lpx = picData.lpx(idx);
    picData.lpy = picData.lpy(idx);
    if isfield(picData, 'ellipticity')
        picData.ellipticity = picData.ellipticity(idx);
    end
    picData.net_gradient = picData.net_gradient(idx);
    picData.len = picData.len(idx);
    picData.n = picData.n(idx);
    picData.photon_rate = picData.photon_rate(idx);
    picData.group = picData.group(idx);
    
    uniqueGroups = unique(picData.group);
    picData.group = arrayfun(@(z) find(picData.group(z)==uniqueGroups),1:length(picData.group))';
    
    
    struct2hdf5(picData,'/locs',sysVar.pathName(1:end-1),[sysVar.fileName(1:end-5) '_JIM.hdf5']);
    copyfile([sysVar.pathName sysVar.fileName(1:end-5) '.yaml'],[sysVar.pathName sysVar.fileName(1:end-5) '_JIM.yaml']);
end
%% Fit on and off rates
doubleExpOff = true;

identifiers = {'ome'};
timeVals = [0.13];
timeUnits = 's';

conidentifiers = {'5pM','2.5pM','7.5pM', '10pM', '12.5pM','15pM'};
conVals = [5 2.5 7.5 10 12.5 15];

results = cell(length(allHDF5Files),8);

allBindingTimes = cell(length(allHDF5Files),1);
allDarkTimes = cell(length(allHDF5Files),1);

allBestFitParams = [];

for expToFit = 1:length(allHDF5Files)
    
    sysVar.fileName = allHDF5Files{expToFit}.name;
    sysVar.pathName = [allHDF5Files{expToFit}.folder filesep];
    picData = h5read([sysVar.pathName sysVar.fileName(1:end-5) '_JIM.hdf5'],'/locs');
    
    results{expToFit,1} = sysVar.fileName;
    results{expToFit,2} = sysVar.pathName;
    
    timePerFrame = 0;
    for i=1:length(identifiers)
        if contains([sysVar.pathName sysVar.fileName(1:end-5) '_JIM.hdf5'],identifiers{i})
            timePerFrame = timeVals(i);
        end
    end

    concentration = 0;
    for i=1:length(conidentifiers)
        if contains([sysVar.pathName sysVar.fileName(1:end-5) '_JIM.hdf5'],conidentifiers{i})
            concentration = conVals(i);
        end
    end
    
    results{expToFit,3} = timePerFrame;
    
    if timePerFrame==0
        break;
    end
    
    % Off Rate with single exponential
    sysVar.len = cast(vertcat(picData.len),'double')';
    allBindingTimes{expToFit} = sysVar.len.*timePerFrame;
    % x = sort(sysVar.len).*timePerFrame;
    % y =100.* [1:length(x)]./length(x);

    x = min(sysVar.len):max(sysVar.len);
    y = arrayfun(@(z) nnz(sysVar.len<=z),x).*100./length(sysVar.len);
    x = x.*timePerFrame;

    if doubleExpOff
        by2 = @(b,bx)(abs(b(1))+abs(b(3))-abs(b(1))*exp(-b(2)*bx)-abs(b(3))*exp(-b(4)*bx));             % Objective function
        OLS = @(b) sum((by2(b,x) - y).^2);          % Ordinary Least Squares cost function
        opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
        %bestFitParams2 = fminsearch(OLS, [max(100.*nnz(x<3.*timePerFrame)./length(x),50) 1/mean(x(1:round(length(x)/2))) min(100-100.*nnz(x<3.*timePerFrame)./length(x),50) 1/mean(x(round(length(x)/2):end))], opts);
    
        bestFitParams2 = fminsearch(OLS, [100.*nnz(sysVar.len<=4)./length(sysVar.len) 1/(mean(sysVar.len(sysVar.len<4)).*timePerFrame) 100.*nnz(sysVar.len>4)./length(sysVar.len) 1/(mean(sysVar.len(sysVar.len>4)).*timePerFrame)], opts);
    
        bestFitParams2 = abs(bestFitParams2);
        if(bestFitParams2(4)>bestFitParams2(2))
            bestFitParams2 = [bestFitParams2(3) bestFitParams2(4) bestFitParams2(1) bestFitParams2(2)]
        end

        disp(['Double Exp Off rate fit: State 1 = ' num2str(bestFitParams2(1)) '% with rate ' num2str(bestFitParams2(2)) ' ' timeUnits '^{-1} and State 2 = ' num2str(bestFitParams2(3)) '% with rate ' num2str(bestFitParams2(4)) ' ' timeUnits '^{-1}']);
        
        results{expToFit,4} = bestFitParams2(1);
        results{expToFit,5} = bestFitParams2(2);
        results{expToFit,6} = bestFitParams2(3);
        results{expToFit,7} = bestFitParams2(4);

    else
        x = x(y>2 & y<98);
        y = y(y>2 & y<98);


        meanGuess = mean(sysVar.len).*timePerFrame;
        
        by2 = @(b,bx)( b(1)*(1-exp(-b(2)*bx))+b(3));             % Objective function
        OLS = @(b) sum((by2(b,x) - y).^2);          % Ordinary Least Squares cost function
        opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
        bestFitParams2 = fminsearch(OLS, [100 1./meanGuess 0], opts);
        
        disp(['Single Exp Off rate fit = ' num2str(bestFitParams2(2)) ' ' timeUnits '^{-1} and mean of ' num2str(1/bestFitParams(2)) ' ' timeUnits]);
    
        results{expToFit,4} = 100;
        results{expToFit,5} = bestFitParams2(2);
        results{expToFit,6} = 0;
        results{expToFit,7} = 0;

    end
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',num2str(expToFit)); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
    axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
    plot(x,y,'LineWidth',2)
    plot(x,by2(bestFitParams2,x),'LineWidth',2)
    hold off
    xlim([0.9.*min(x),max(x)])
    ylim([0 105])
    xlabel(['Time (' timeUnits ')'])
    ylabel('Dissociated Molecules (%)')
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';


    if contains(sysVar.fileName,'filter','IgnoreCase',true)
        print([sysVar.pathName 'filter_OffRate_double_Exp'], '-dpng', '-r600');
        print([sysVar.pathName 'filter_OffRate_double_Exp'], '-depsc', '-r600');
    else
        print([sysVar.pathName 'OffRate_double_Exp'], '-dpng', '-r600');
        print([sysVar.pathName 'OffRate_double_Exp'], '-depsc', '-r600');
    end
    

    
    % fit on rate
    minDarkFrames = 10;
    
    sysVar.frame = cast(vertcat(picData.frame),'double')';
    sysVar.group = cast(vertcat(picData.group),'double')';
    
    
    xIn = diff(sysVar.frame)-sysVar.len(1:end-1);
    xIn=xIn(diff(sysVar.group)<0.5 & xIn>minDarkFrames);

    
    x = max(minDarkFrames,min(xIn)):max(xIn);
    y = arrayfun(@(z) nnz(xIn<z),x).*100./length(xIn);
    xIn = xIn.*timePerFrame;
    x = x.*timePerFrame;

    allDarkTimes{expToFit} = xIn.*concentration;

    x = x(y>2 & y<98);
    y = y(y>2 & y<98);
    
    % x = sort(xIn(xIn>minDarkFrames)).*timePerFrame;
    % y =100.* [1:length(x)]./length(x);
    
    meanGuess = mean(xIn(xIn>x(1)))-x(1);
    
    by = @(b,bx)( b(1)*(1-exp(-b(2)*bx))+b(3));             % Objective function
    OLS = @(b) sum((by(b,x) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [100+100.*(1-exp(-x(1)./meanGuess)) 1./meanGuess -100.*(1-exp(-x(1)./meanGuess))], opts);
    
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',num2str(expToFit)); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
    axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
    plot(x,y,'LineWidth',2)
    plot(x,by(bestFitParams,x),'LineWidth',2)
    %plot(x,by([100+100.*(1-exp(-x(1)./meanGuess)) 1./meanGuess -100.*(1-exp(-x(1)./meanGuess))],x),'LineWidth',2)
    hold off
    xlabel(['Time (' timeUnits ')'])
    ylabel('Associated Molecules (%)')
    hold off
    xlim([min(x),x(round(0.999*length(x)))])
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';

    if contains(sysVar.fileName,'filter','IgnoreCase',true)
        print([sysVar.pathName 'filter_OnRate_Single_Exp'], '-dpng', '-r600');
        print([sysVar.pathName 'filter_OnRate_Single_Exp'], '-depsc', '-r600');
    else
        print([sysVar.pathName 'OnRate_Single_Exp'], '-dpng', '-r600');
        print([sysVar.pathName 'OnRate_Single_Exp'], '-depsc', '-r600');
    end

    disp(['Single Exp On rate fit = ' num2str(bestFitParams(2)) ' ' timeUnits '^{-1} and mean of ' num2str(1/bestFitParams(2)) ' ' timeUnits]);
    
    results{expToFit,8} = bestFitParams(2);

    allBestFitParams = [allBestFitParams;bestFitParams];


    results{expToFit,9} = length(x);
    results{expToFit,10} = length(x)./max(sysVar.group);

    results{expToFit,11} = concentration;
    results{expToFit,12} = bestFitParams(2)./concentration;

end
% Write out results

T = cell2table(results,...
    "VariableNames",["File Name" "Folder Name" "Seconds Per Frame" "Off State 1 %" "Off State 1 Rate" "Off State 2 %" "Off State 2 Rate" "On Rate" "Total Blinks" "Average Blinks Per Particle" "Concentration" "On Rate Constant"]);

writetable(T,[sysVar.topfileName 'Combined_Results.csv']);
%%
picassoThreshold = 200;
picassoDriftSegments = 0;
    cmd = [sysConst.JIM,'Picasso_Raw_Converter',sysConst.fileEXE,' "',workingDir 'Alignment_Channel_2_Aligned_Stack.tiff" "',workingDir,'Alignment_Channel_2_Aligned_Stack"'];
    system(cmd);
    cmd = ['picasso localize "' workingDir 'Alignment_Channel_2_Aligned_Stack.raw" -b 9 -g ' num2str(picassoThreshold) ' -bl 100 -d ',num2str(picassoDriftSegments)];
    system(cmd);
    

%% On Rates
x = cell2mat(results(:,11));
y = cell2mat(results(:,8));

onRateConstant = dot(y,x)/dot(x,x);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Percentages"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on

plot([0, max(x)],[0, max(x)].*onRateConstant,'LineWidth',2)
scatter(x,y,20)



xlabel('Concentration (pM)')
ylabel('Observed On Rate (s^{-1})');

hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
xlim([0, max(x)])


print([sysVar.topfileName 'On_Rates'], '-dpng', '-r600');
print([sysVar.topfileName 'On_Rates'], '-depsc', '-r600'); 

%% Fast Off Rate

x = cell2mat(results(:,11));
y = cell2mat(results(:,5));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Percentages"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
plot([0 max(x)],[mean(y) mean(y)],'LineWidth',2)
scatter(x,y,20)
hold off
xlabel('Concentration (pM)')
ylabel('Transient State Off Rate (s^{-1})');

set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';

ylim([0 2.5])

print([sysVar.topfileName 'Fast_Bound_Time'], '-dpng', '-r600');
print([sysVar.topfileName 'Fast_Bound_Time'], '-depsc', '-r600'); 
%% Slow Off Rate

x = cell2mat(results(:,11));
y = cell2mat(results(:,7));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Percentages"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
plot([0 max(x)],[mean(y) mean(y)],'LineWidth',2)
scatter(x,y,20)
hold off
xlabel('Concentration (pM)')
ylabel('Stable State Off Rate (s^{-1})');

set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';

ylim([0 0.5])

print([sysVar.topfileName 'Slow_Bound_Time'], '-dpng', '-r600');
print([sysVar.topfileName 'Slow_Bound_Time'], '-depsc', '-r600'); 
%% State Ratio

x = cell2mat(results(:,11));
y = 100.*cell2mat(results(:,6))./(cell2mat(results(:,4))+cell2mat(results(:,6)));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',"Popping Percentages"); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
plot([0 max(x)],[mean(y) mean(y)],'LineWidth',2)
scatter(x,y,20)
hold off
xlabel('Concentration (pM)')
ylabel('Stable State Percent (%)');

set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';

ylim([0 100])

print([sysVar.topfileName 'State_Ratio'], '-dpng', '-r600');
print([sysVar.topfileName 'State_Ratio'], '-depsc', '-r600'); 


%% make combined survival curves
lenIn = cell2mat(allBindingTimes');

x1 = 0.13:0.13:200;

y1 = arrayfun(@(z) nnz(lenIn<=z),x1).*100./length(lenIn);

by2 = @(b,bx)(abs(b(1))+abs(b(3))-abs(b(1))*exp(-b(2)*bx)-abs(b(3))*exp(-b(4)*bx));
meanfit = [mean(cell2mat(results(:,4))) mean(cell2mat(results(:,5))) mean(cell2mat(results(:,6))) mean(cell2mat(results(:,7)))];

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',num2str(expToFit)); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
    axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
    ax = gca;
    plot(x1,y1,'LineWidth',2)
    plot(x1,by2(meanfit,x1),'LineWidth',2)
    hold off
    %xlim([0.02 1000])
    ylim([0 105])
    xlabel(['Time (' timeUnits ')'])
    ylabel('Dissociated Molecules (%)')
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';

print([sysVar.topfileName 'Binding_Time_CDF'], '-dpng', '-r600');
print([sysVar.topfileName 'Binding_Time_CDF'], '-depsc', '-r600');

%% On Rates

lenIn = cell2mat(allDarkTimes');

x1 = 100:10000;
y1 = arrayfun(@(z) nnz(lenIn<=z),x1).*100./length(lenIn);

 by = @(b,bx)( b(1)*(1-exp(-b(2)*bx))+b(3));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8.5;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',num2str(expToFit)); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
    axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
    ax = gca;
    plot(x1,y1,'LineWidth',2)
    plot(x1,by([mean(allBestFitParams(:,1)) onRateConstant mean(allBestFitParams(:,3))],x1),'LineWidth',2)
    hold off
    %xlim([1 1000])
    ylim([0 105])
    xlabel(['Normalized Time ( pM s)'])
    ylabel('Associated Molecules (%)')
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';

print([sysVar.topfileName 'Dark_Time_CDF'], '-dpng', '-r600');
print([sysVar.topfileName 'Dark_Time_CDF'], '-depsc', '-r600');
