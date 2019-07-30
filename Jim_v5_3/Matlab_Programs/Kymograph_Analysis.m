%%
clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
workingdir = [pathname,'Kymograph_Analysis\'];
mkdir(workingdir);
%% 2) Find all kymographs
allfiles = dir(pathname);
toselect = arrayfun(@(x) ~isempty(regexp(x.name,'.tif','ONCE'))&&isempty(regexp(x.name,'Background','ONCE')),allfiles);
foregroundfiles = arrayfun(@(x) [pathname,x.name],allfiles(toselect),'UniformOutput',false);
toselect = arrayfun(@(x) ~isempty(regexp(x.name,'.tif','ONCE'))&&~isempty(regexp(x.name,'Background','ONCE')),allfiles);
backgroundfiles = arrayfun(@(x) [pathname,x.name],allfiles(toselect),'UniformOutput',false);
disp(['There are ' num2str(length(foregroundfiles)) ' files to analyse']);



%% find cutoff
allfore = [];
for i=1:length(backgroundfiles)
    allfore = [allfore im2double(imread(foregroundfiles{i}))];
end

allfore = reshape(allfore,1,[]);
allfore = allfore(allfore>0.00000001);

figure
histogram(allfore)
%%
cutoff = 0.0009;
%% Batch analyse all files

pathname = uigetdir(); % open the dialog box to select the folder for batch files
pathname=[pathname,'\'];

%% 2) detect files to analyze
insubfolders = true; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder
workingpathlist = [];
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
    filenum=size(allfilescells,1);
end

for i=1:length(allfilescells)
    completename = allfilescells{i};
    [pathnamein,name,~] = fileparts(completename);%get the name of the tiff image
    workingdir = [pathnamein,'\',name];
    [pathnamein,name,~] = fileparts(workingdir);
    workingdir = [pathnamein,'\',name,'\Kymographs\'];
    if exist(workingdir, 'dir')
        workingpathlist = [workingpathlist;convertCharsToStrings(workingdir)];
    else
        disp(convertCharsToStrings(workingdir));
    end
end
disp(['There are ',num2str(length(workingpathlist)),' files to analyse']);
%%
peakthreshold = 4;

for imstacknum = 1:length(workingpathlist)
    disp(['Analysing file number ',num2str(imstacknum)]);
    % 2) Find all kymographs
    pathname = convertStringsToChars(workingpathlist(imstacknum)); 
    allfiles = dir(pathname);
    toselect = arrayfun(@(x) ~isempty(regexp(x.name,'.tif','ONCE'))&&isempty(regexp(x.name,'Background','ONCE')),allfiles);
    foregroundfiles = arrayfun(@(x) [pathname,x.name],allfiles(toselect),'UniformOutput',false);
    toselect = arrayfun(@(x) ~isempty(regexp(x.name,'.tif','ONCE'))&&~isempty(regexp(x.name,'Background','ONCE')),allfiles);
    backgroundfiles = arrayfun(@(x) [pathname,x.name],allfiles(toselect),'UniformOutput',false);
    disp(['There are ' num2str(length(foregroundfiles)) ' Kymographs to analyse']);

    workingdir = [pathname,'Kymograph_Analysis\'];
    mkdir(workingdir);

    % Find the background exchange time

    allback = [];
    for i=1:length(backgroundfiles)
        allback = [allback imread(backgroundfiles{i})];
    end

    meanback = mean(allback,2);

    FHEXEC = @(FH) FH();
    FHSELECT = @(TF,CONDITION) TF(CONDITION==[true,false]);
    IF = @(CONDITION,TRUEFUNC,FALSEFUNC) FHEXEC( FHSELECT([TRUEFUNC,FALSEFUNC],CONDITION)); 

    bx = 1:length(meanback);
    byx = meanback';
    x0 = meanback(1);
    x1 = x0+0.25*(meanback(end)-meanback(1));
    by = @(b,bx)(arrayfun(@(k) IF(k<b, x0, x1),bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    alldiffs = arrayfun(@(k) OLS(k),bx);
    [~,solexchange] = min(alldiffs);
    disp(['Background exchange occurs in Frame  ',num2str(solexchange)]);

    toout = figure('visible','off');
    hold on
        plot(meanback)
        plot(by(solexchange,bx))
    hold off
    saveas(toout,[workingdir,'Background.tif']);
    % edge detect
    
%     %Changing Outputs
%     allgradstab = cell(length(foregroundfiles),1);
%     allgradlengths = cell(length(foregroundfiles),1);
%     allnucs = zeros(length(foregroundfiles),1);


    allnucs = cell(length(foregroundfiles),1);
    allnuctimes = cell(length(foregroundfiles),1);
    alloutlines = cell(length(foregroundfiles),1);
    

    
    parfor kymcount=1:length(foregroundfiles)
        disp(kymcount);
        imin = im2double(imread(foregroundfiles{kymcount}))';
        fillength = size(imin,1);
        edgedetect = zeros(fillength,1);
        for i=1:fillength
            byx = imin(i,:);
            bx = 1:length(byx);
            by = @(b,bx)(arrayfun(@(k) IF(k<b, 0, cutoff),bx));             % Objective function
            OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
            alldiffs = arrayfun(@(k) OLS(k),bx);
            [~,edgedetect(i)] = min(alldiffs);
            %disp(i);
        end

        edgedetect = length(imin)-edgedetect;
        edgedetect2 = imgaussfilt(edgedetect,1);
        
        
        %new from here
        [~,peaks]=findpeaks(edgedetect2,'MinPeakProminence',peakthreshold);
        [~,peaks2] = findpeaks(-edgedetect2,'MinPeakProminence',peakthreshold);

        peaks =sort( [1;peaks;peaks2;length(edgedetect)]);


        toout = figure('visible','off');
        imshow(imadjust(imin'))
        hold on
        plot(1:length(edgedetect),length(imin)-edgedetect', 'r', 'Linewidth', 1)
        plot(1:length(edgedetect),length(imin)-edgedetect2', 'b', 'Linewidth', 1)
        plot(peaks,length(imin)-edgedetect2(peaks),'og')
        hold off
        saveas(toout,[workingdir,'Kymograph_',num2str(kymcount),'.tif']);

        solexoutline = length(imin)-edgedetect2-solexchange;
        
        allnucs(kymcount) = {peaks};
        alloutlines(kymcount) = {solexoutline};
        allnuctimes(kymcount) = {solexoutline(peaks)};
    end
    
    fid = fopen([workingdir,'AllNucleationandJointPositions.csv'], 'wt');
    for K = 1 : length(allnucs)
       this_row = allnucs{K};
       fprintf(fid, '%f,', this_row(1:end-1));
       fprintf(fid, '%f\n', this_row(end) );
    end
    fclose(fid);
    
    fid = fopen([workingdir,'AllOutlines.csv'], 'wt');
    for K = 1 : length(alloutlines)
       this_row = alloutlines{K};
       fprintf(fid, '%f,', this_row(1:end-1));
       fprintf(fid, '%f\n', this_row(end) );
    end
    fclose(fid);    

    fid = fopen([workingdir,'AllNucleationandJointTimes.csv'], 'wt');
    for K = 1 : length(allnuctimes)
       this_row = allnuctimes{K};
       fprintf(fid, '%f,', this_row(1:end-1));
       fprintf(fid, '%f\n', this_row(end) );
    end
    fclose(fid);
    
end

        
        
        
%%
%         edgedetect3 = edgedetect(round(0.2*length(edgedetect)):end-round(0.2*length(edgedetect)));
%         edgedetect4 = edgedetect2(round(0.2*length(edgedetect2)):end-round(0.2*length(edgedetect2)));
% 
% 
%         [~,pos]=min(edgedetect3);
%         if pos~=1 && pos~=length(edgedetect3)
%             nuctime = (min(edgedetect3)-solexchange)*length(edgedetect3);
%         else
%             nuctime = -1;
%         end
% 
%         [~,peaks]=findpeaks(edgedetect4,'MinPeakProminence',5);
%         [~,peaks2] = findpeaks(-edgedetect4,'MinPeakProminence',5);
% 
%         peaks =sort( [1;peaks;peaks2;length(edgedetect3)]);
% 
%         gradlengths = diff(peaks);
%         gradtab = zeros(length(peaks)-1,1);
%         for i=1:length(peaks)-1
%             if gradlengths(i)>=5
%                 mdl = fitlm(peaks(i):peaks(i+1),edgedetect3(peaks(i):peaks(i+1)),'RobustOpts','on');
%                 gradtab(i) = mdl.Coefficients.Estimate(2);
%             end
%         end
% 
%         toout = figure('visible','off');
%         imshow(imadjust(imin'))
%         hold on
%         plot(round(0.2*length(edgedetect)):round(0.2*length(edgedetect))+length(edgedetect3)-1,length(imin)-edgedetect3', 'r', 'Linewidth', 1)
%         plot(round(0.2*length(edgedetect)):round(0.2*length(edgedetect))+length(edgedetect4)-1,length(imin)-edgedetect4', 'b', 'Linewidth', 1)
%         plot(round(0.2*length(edgedetect))+peaks,length(imin)-edgedetect4(peaks),'og')
%         hold off
%         saveas(toout,[workingdir,'Kymograph_',num2str(kymcount),'.tif']);
% 
%         allnucs(kymcount) = nuctime;
%         allgradstab(kymcount) = {gradtab};
%         allgradlengths(kymcount) = {gradlengths};
%     end
%     disp('finished running');
% 
%     gradlist = [];
%     gradlengthlist=[];
%     for i=1:length(allgradstab)
%         gradlist = [gradlist;allgradstab{i}];
%         gradlengthlist = [gradlengthlist;allgradlengths{i}];
%     end
%     gradlengthlist = gradlengthlist(abs(gradlist)>0.0000001);
%     gradlist = gradlist(abs(gradlist)>0.0000001);
%     allnucs = allnucs(allnucs>0);
%     
%     csvwrite([workingdir,'Gradients.csv'],gradlist);
%     csvwrite([workingdir,'Gradientlengths.csv'],gradlengthlist);
%     csvwrite([workingdir,'Nucleations.csv'],allnucs);
% end


%%
Concentrationunits = 'nM';

concentration = [];

for i=1:length(workingpathlist)
    channelin = convertStringsToChars(workingpathlist(i));
    found = regexp(channelin,['\d+\.?\d+',Concentrationunits,'*'],'match');
    if size(found,2)==0
        found=regexp(channelin,['\d',Concentrationunits,'*'],'match');
    end
    found = found(1);
    conout = regexp(found,['\d+\.?\d*'],'match');
    concentration = [concentration str2double(conout{1})];
end

disp(concentration);
%%
spf = [12 10 8 6 4 2];
pixelsize = 86.6;
%%
sortedcon = unique(sort(concentration));
sortedcon = sortedcon(1:end);
posgrowthrate = zeros(length(sortedcon),1);
neggrowthrate = zeros(length(sortedcon),1);

for i=1:length(sortedcon)
    sameconfiles = workingpathlist(concentration==sortedcon(i));
    spfin = spf(i);
    allgrads = [];
    alllengths = [];
    allnucs = [];
    for j=1:length(sameconfiles)
        gradstab = csvread([convertStringsToChars(sameconfiles(j)),'Kymograph_Analysis\Gradients.csv'],0,0);
        lengthstab = csvread([convertStringsToChars(sameconfiles(j)),'Kymograph_Analysis\Gradientlengths.csv'],0,0);
        allgrads = [allgrads;pixelsize/spfin./gradstab];
        alllengths = [alllengths;lengthstab];
    end
    
    poslengths = alllengths(allgrads>0);
    posgrads = allgrads(allgrads>0);
    poslengths = poslengths(posgrads>1./(2.*median(posgrads))&posgrads<2.*median(posgrads));
    posgrads = posgrads(posgrads>1./(2.*median(posgrads))&posgrads<2.*median(posgrads));
    posgrowthrate(i) = poslengths'*posgrads/sum(poslengths);
    
    posgrowthrate(i) = median(posgrads);
    
   % figure
   % histogram(posgrads,20)
   % disp(median(posgrads));
    
    poslengths = alllengths(allgrads<0);
    posgrads = -1.*allgrads(allgrads<0);
    poslengths = poslengths(posgrads>1./(3.*median(posgrads))&posgrads<3.*median(posgrads));
    posgrads = posgrads(posgrads>1./(3.*median(posgrads))&posgrads<3.*median(posgrads));
    neggrowthrate(i) = poslengths'*posgrads/sum(poslengths);
    
    neggrowthrate(i) = median(posgrads);
  %  figure
   % histogram(posgrads,20)
   % disp(median(posgrads));
end
%%
bxin = 2:10;
figure
hold on 
plot(sortedcon,posgrowthrate,'or');
plot(sortedcon,neggrowthrate,'ob');
plot(bxin,-1.073+0.6421.*bxin,'r')
plot(bxin,-1.98+1.186.*bxin,'b')
hold off


%%

mdlpos = LinearModel.fit(sortedcon,posgrowthrate);
poscoeff = mdlpos.Coefficients.Estimate;
mdlneg = LinearModel.fit(sortedcon,neggrowthrate);
negcoeff = mdlneg.Coefficients.Estimate;

%%

%%
bxin = 1:10;
figure
hold on 
plot(sortedcon,posgrowthrate,'or');
plot(sortedcon,neggrowthrate,'ob');
plot(bxin,-1.073+0.6421.*bxin,'r')
plot(bxin,-1.98+1.186.*bxin,'b')
plot(bxin,poscoeff(1)+poscoeff(2).*bxin,'r')
plot(bxin,negcoeff(1)+negcoeff(2).*bxin,'b')
hold off




















%%
spf = 2;
pixelsize = 86.6;