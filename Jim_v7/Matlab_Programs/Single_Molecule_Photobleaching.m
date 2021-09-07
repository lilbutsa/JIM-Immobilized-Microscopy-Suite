%%
clear
%% 1) Select Input Folder
filesInSubFolders = true;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
fileEXE = '"';
fileSep = '';
if ismac
    JIM = ['"',fileparts(JIM),'/Jim_Programs_Mac/'];
    fileSep = '/';
elseif ispc
    JIM = ['"',fileparts(JIM),'\Jim_Programs\'];
    fileEXE = '.exe"';
    fileSep = '\';
else
    disp('Platform not supported')
end

fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep]; 

allFolders = arrayfun(@(x)[fileName,x.name],dir(fileName),'UniformOutput',false); % find everything in the input folder
allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
allFolders = allFolders(3:end);
allFolders = arrayfun(@(x)[x{1},fileSep],allFolders,'UniformOutput',false);

if filesInSubFolders
    allSubFolders = allFolders;
    allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allSubFolders,'UniformOutput',false);
    allFolders = arrayfun(@(x)x{:}(3:end),allFolders,'UniformOutput',false);
    allFolders = horzcat(allFolders{:})';
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = arrayfun(@(x)[x{1},fileSep],allFolders,'UniformOutput',false);
end

allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
channel1 = allFiles(contains(allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));
NumberOfFiles=size(channel1,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% 2) Stepfit Traces
stepfitIterations = 10000;

useMatlabChangePoint = false;


parfor i=1:NumberOfFiles
    disp(['Step Fitting Experiment ',num2str(i),' - ',channel1{i}]);
    if useMatlabChangePoint
        traces=csvread(channel1{i},1);
        onemean = mean(traces')';
        steps = arrayfun(@(x) findchangepts(traces(x,:), 'Statistic', 'mean','MaxNumChanges',1),1:size(traces,1),'UniformOutput',false)';
        steps(cellfun('isempty',steps)) = {2};
        steps = cell2mat(steps);
        normedtraces = cell2mat(arrayfun(@(x)(traces(x,:)-min(traces(x,:)))/(max(traces(x,:))-min(traces(x,:))),1:size(traces,1),'UniformOutput',false)');
        steps2 = arrayfun(@(x) size(findchangepts(normedtraces(x,:),'MinThreshold', 1, 'Statistic', 'mean'),2),1:size(traces,1))';
        means1 = arrayfun(@(x) mean(traces(x,1:steps(x)-1)),1:size(steps2,1))';
        means2 = arrayfun(@(x) mean(traces(x,steps(x):end)),1:size(steps2,1))';
        toout = cat(2,onemean,steps2>0,steps,means1,means2,steps2>1,steps2>1);
        fid = fopen([fileparts(channel1{fileToCheck}) '\Stepfit_Single_Step_Fits.csv'],'w'); 
        fprintf(fid,'%s\n','No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more initial steps, Probability of more final steps');
        fclose(fid);
        dlmwrite([fileparts(channel1{fileToCheck}) fileSep 'Stepfit_Single_Step_Fits.csv'],toout,'-append');       
    else
        cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',channel1{i},'" "',fileparts(channel1{i}),fileSep,'Stepfit" -FitSingleSteps -Iterations ',num2str(stepfitIterations)];
        system(cmd);
    end
end
disp('Step fitting completed');

%% 3) View Single Step Filters
    fileToCheck = 6;
    pageNumber = 1;
    
    minFirstStepProb = 0.5;
    maxSecondMeanFirstMeanRatio=0.25;
    maxMoreStepProb=0.99;
    
    
    traces=csvread(channel1{fileToCheck},1);
    stepsdata = csvread([fileparts(channel1{fileToCheck}) fileSep 'Stepfit_Single_Step_Fits.csv'],1);
    
    
    singleStepTraceQ = stepsdata(:,3)>minFirstStepProb & stepsdata(:,5)>0 & abs(stepsdata(:,6)) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb;
    singleStepTraces = traces(singleStepTraceQ,:);
    multiStepTraces = traces(~singleStepTraceQ,:);
    singleStepStepData = stepsdata(singleStepTraceQ,:);
    multiStepStepData = stepsdata(~singleStepTraceQ,:);
    
    figure('Name','Single Step Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])

    for i=1:36
        if i+36*(pageNumber-1)<size(singleStepTraces,1)
            subplot(6,6,i)
            hold on
            title(['No. ' num2str(singleStepStepData(i+36*(pageNumber-1),1)) ' P1 ' num2str(round(singleStepStepData(i+36*(pageNumber-1),3),2,'significant')) ' R ' num2str(round(singleStepStepData(i+36*(pageNumber-1),6)./singleStepStepData(i+36*(pageNumber-1),5),2,'significant')) ' P2 ' num2str(round(singleStepStepData(i+36*(pageNumber-1),7),2,'significant'))])
            plot(singleStepTraces(i+36*(pageNumber-1),:),'-r');
            plot([0 size(singleStepTraces(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
            plot([1 singleStepStepData(i+36*(pageNumber-1),4) singleStepStepData(i+36*(pageNumber-1),4)+1 size(singleStepTraces(i+36*(pageNumber-1),:),2)],[singleStepStepData(i+36*(pageNumber-1),5) singleStepStepData(i+36*(pageNumber-1),5) singleStepStepData(i+36*(pageNumber-1),6) singleStepStepData(i+36*(pageNumber-1),6)] ,'-blue');
            hold off
        end
    end
   
    
    figure('Name','Excluded Traces')
    set(gcf, 'Position', [100, 100, 1500, 800])

    for i=1:36
        if i+36*(pageNumber-1)<size(multiStepTraces,1)
        subplot(6,6,i)
        hold on
        title(['No. ' num2str(multiStepStepData(i+36*(pageNumber-1),1)) ' P1 ' num2str(round(multiStepStepData(i+36*(pageNumber-1),3),2,'significant')) ' R ' num2str(round(multiStepStepData(i+36*(pageNumber-1),6)./multiStepStepData(i+36*(pageNumber-1),5),2,'significant')) ' P2 ' num2str(round(multiStepStepData(i+36*(pageNumber-1),7),2,'significant'))])
        plot(multiStepTraces(i+36*(pageNumber-1),:),'-r');
        plot([0 size(multiStepTraces(i+36*(pageNumber-1),:),2)],[0 0] ,'-black');
        plot([1 multiStepStepData(i+36*(pageNumber-1),4) multiStepStepData(i+36*(pageNumber-1),4)+1 size(multiStepTraces(i+36*(pageNumber-1),:),2)],[multiStepStepData(i+36*(pageNumber-1),5) multiStepStepData(i+36*(pageNumber-1),5) multiStepStepData(i+36*(pageNumber-1),6) multiStepStepData(i+36*(pageNumber-1),6)] ,'-blue');
        hold off
        end
    end

    
%% 4) Filter All Files for Single Steps

allResults = zeros(NumberOfFiles+3,19);
    
for fileNo = 1:NumberOfFiles

    traces=csvread(channel1{fileNo},1);
    stepsdata = csvread([fileparts(channel1{fileNo}) fileSep 'Stepfit_Single_Step_Fits.csv'],1);
    
    singleStepTraceQ = stepsdata(:,3)>minFirstStepProb  & stepsdata(:,5)>0 & abs(stepsdata(:,6)) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb;
    singleStepTraces = traces(singleStepTraceQ,:);
    multiStepTraces = traces(~singleStepTraceQ,:);
    singleStepStepData = stepsdata(singleStepTraceQ,:);
    multiStepStepData = stepsdata(~singleStepTraceQ,:);
    
    allResults(fileNo,1) = size(traces,1);
    allResults(fileNo,2) = size(singleStepStepData,1);
    allResults(fileNo,2) = size(singleStepStepData,1);
    allResults(fileNo,19) = nnz(stepsdata(:,7)>0.999);

    fileout = [fileparts(channel1{fileNo}) fileSep 'Single_Step_Traces.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame');
    fclose(fid);
    dlmwrite(fileout,singleStepTraces,'-append');
    
    fileout = [fileparts(channel1{fileNo}) fileSep 'Multi_Step_Traces.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame');
    fclose(fid);
    dlmwrite(fileout,singleStepTraces,'-append');
    
    fileout = [fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps, Residual Standard Deviation  ');
    fclose(fid);
    dlmwrite(fileout,singleStepStepData,'-append');
    
    fileout = [fileparts(channel1{fileNo}) fileSep 'Multi_Step_Step_Fit.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps, Residual Standard Deviation  ');
    fclose(fid);
    dlmwrite(fileout,multiStepStepData,'-append');   
    
end

allResults(end,1) = sum(allResults(1:NumberOfFiles,1));
allResults(end,2) = sum(allResults(1:NumberOfFiles,2));
allResults(end,19) = sum(allResults(1:NumberOfFiles,19));

%% 5) Fit Bleach Times

    expYMinPercent = 0;
    expYMaxPercent = 0.75;
    
    
    photobleachFile = [fileName 'Compiled_Photobleaching_Analysis' fileSep];
    if ~exist(photobleachFile, 'dir')
        mkdir(photobleachFile)%make a subfolder with that name
    end
    
    
    
    fileout = [photobleachFile 'Bleaching_Survival_Curves.csv'];
    filein = [photobleachFile 'Bleaching_Survival_Curves'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each First Line is the frame number, Each Second Line is Number of Unbleached Particles after that number of Frames');
    fclose(fid);
    
    fid2 = fopen([photobleachFile 'Bleaching_File_Names.csv'],'w'); 
    fprintf(fid2,'%s\n','File Names used for photobleaching analysis' );

    allBleachingX = [];
    
for fileNo = 1:NumberOfFiles    
    
    fprintf(fid2,'%s\n',channel1{fileNo} );
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 

    bleachingX = sort(singleStepStepData(:,4))';
    bleachingY = size(bleachingX,2):-1:1;
    
    allBleachingX = [allBleachingX,bleachingX];
    dlmwrite(fileout,bleachingX,'-append');   
    dlmwrite(fileout,bleachingY,'-append');
    
end    
    fclose(fid2);
        
    allBleachingX = sort(allBleachingX);
    allBleachingY = size(allBleachingX,2):-1:1;
    dlmwrite(fileout,allBleachingX,'-append');   
    dlmwrite(fileout,allBleachingY,'-append');
    
    cmd = [JIM,'Exponential_Fit',fileEXE,' "',fileout,'" "',filein,'" -ymaxPercent ',num2str(expYMaxPercent),' -yminPercent ',num2str(expYMinPercent)];
    system(cmd);
    
    bleachFits = csvread([filein,'_ExpFit.csv'],1,0);
    
    allResults(1:NumberOfFiles,3) = bleachFits(1:end-1,3);
    allResults(end,3) = bleachFits(end,3);
    allResults(1:NumberOfFiles,4) = log(2)./bleachFits(1:end-1,3);
    allResults(end,4) = log(2)./bleachFits(end,3);
    allResults(1:NumberOfFiles,5) = log(10/9)./bleachFits(1:end-1,3);
    allResults(end,5) = log(10/9)./bleachFits(end,3);

    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Bleaching Rate')
    xlabel('Frame')
    ylabel('Remaining Particles')
    plot(allBleachingX,allBleachingY);
    plot(1:max(allBleachingX),bleachFits(end,1)+bleachFits(end,2).*exp(-bleachFits(end,3).*[1:max(allBleachingX)]));
    legend('Experiment','Exponential Fit')
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Bleaching_Rate'], '-dpng', '-r600')
    
    
    
    
    disp(['The pooled bleaching rate of ' num2str(bleachFits(end,3)) ' corresponds to a halflife of ' num2str(log(2)/bleachFits(end,3)) ...
        ' and a 10% beaching frame of ' num2str(log(10/9)/bleachFits(end,3))]);
    
%% 6) Fit Step Heights

    gausYMinPercent = 0;
    gausYMaxPercent = 0.9;
    
    
    fileout = [photobleachFile 'Step_Heights.csv'];
    filein = [photobleachFile 'Step_Heights'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each Line is the step height from a single experiment');
    fclose(fid);
    
    
    fileout2 = [photobleachFile 'Step_Heights_Logs.csv'];
    filein2 = [photobleachFile 'Step_Heights_Logs'];
    fid = fopen(fileout2,'w'); 
    fprintf(fid,'%s\n','Each Line is the log of the step height from a single experiment');
    fclose(fid);    
    
    allStepHeights = [];
    
for fileNo = 1:NumberOfFiles    
    
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 

    stepHeights = singleStepStepData(:,5)'-singleStepStepData(:,6)';
    allStepHeights = [allStepHeights,stepHeights];
    dlmwrite(fileout,stepHeights,'-append');   
    dlmwrite(fileout2,log(stepHeights),'-append'); 
end    
        

    dlmwrite(fileout,allStepHeights,'-append');
    dlmwrite(fileout2,log(allStepHeights),'-append'); 
    
    cmd = [JIM,'Gaussian_Fit',fileEXE,' "',fileout,'" "',filein,'" -ymaxPercent ',num2str(gausYMaxPercent),' -yminPercent ',num2str(gausYMinPercent)];
    system(cmd);
    
    cmd = [JIM,'Gaussian_Fit',fileEXE,' "',fileout2,'" "',filein2,'" -ymaxPercent ',num2str(gausYMaxPercent),' -yminPercent ',num2str(gausYMinPercent)];
    system(cmd);
    
    cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
    system(cmd);    


    bleachFits = csvread([filein,'_GaussFit.csv'],1,0);
    logfits = csvread([filein2,'_GaussFit.csv'],1,0);
    hists = csvread([filein,'_Histograms.csv'],1,0);

    singleMolIntMode = zeros(size(hists,1)/2,1);
    for i=1:2:size(hists,1)
        [~,pos] = max(hists(i+1,:));
        singleMolIntMode((i+1)/2) = hists(i,pos);
    end

    allResults(1:NumberOfFiles,6:10) = bleachFits(1:end-1,:);
    allResults(end,6:10) = bleachFits(end,:);    
    allResults(1:NumberOfFiles,11) = singleMolIntMode(1:end-1,:);
    allResults(end,11) = singleMolIntMode(end,:);
    
    allResults(1:NumberOfFiles,12:13) = exp(logfits(1:end-1,1:2));
    allResults(end,12:13) = exp(logfits(end,1:2));
    
    allStepHeights = sort(allStepHeights);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Step Height Distribution')
    xlabel('Step Height')
    ylabel('Probability (PDF)')
    plot(hists(end-1,:),hists(end,:))
    plot(1:max(allStepHeights),1/(sqrt(2.*3.1415926.*bleachFits(end,2).^2)).*exp(-(([1:max(allStepHeights)]-bleachFits(end,1)).^2)./(2.*bleachFits(end,2).^2)))
    plot(1:max(allStepHeights),1./((1:max(allStepHeights)).*sqrt(2.*3.1415926.*logfits(end,2).^2)).*exp(-((log((1:max(allStepHeights)))-logfits(end,1)).^2)./(2.*logfits(end,2).^2)))
    xlim([0 allStepHeights(round(0.99.*size(allStepHeights,2)))])
    leg = legend('Experiment','Gaussian','Log Norm','FontSize', 9,'Box','off');

    leg.ItemTokenSize = [10,30];
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Step_Height_Distribution'], '-dpng', '-r600')
    
%% 7) Find Signal to Noise

    allSNR = [];
    fileout = [photobleachFile 'Signal_to_Noise.csv'];
    filein = [photobleachFile 'Signal_to_Noise'];
    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each Line is the step height divided my the std. dev. of the residual from a single experiment');
    fclose(fid);
    
    for fileNo = 1:NumberOfFiles    
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 
    SNR = (singleStepStepData(:,5)'-singleStepStepData(:,6)')./(singleStepStepData(:,8)');
    allSNR = [allSNR,SNR];
    dlmwrite(fileout,SNR,'-append');
    allResults(fileNo,14) = mean(SNR);
     
    end 
    dlmwrite(fileout,allSNR,'-append');
    
    allResults(end,14) = mean(allSNR);
    
    
    cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
    system(cmd);
    
    hists = csvread([filein,'_Histograms.csv'],1,0);
    
    allSNR = sort(allSNR);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Signal to Noise Distribution')
    xlabel('Step Height/Residual Std. Dev.')
    ylabel('Probability (PDF)')
    plot(hists(end-1,:),hists(end,:))
    hold off
    xlim([0 allSNR(round(0.99.*size(allSNR,2)))])
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Signal_to_Noise'], '-dpng', '-r600')
    
    
%% 8) Initial Particle Intensity Distribution
    
    fileout = [photobleachFile 'Initial_Intensities.csv'];
    filein = [photobleachFile 'Initial_Intensities'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each Line is the Initial Intensity of each particle from a single experiment');
    fclose(fid);

    allInitialInt = [];
    for i=1:NumberOfFiles
        traces=csvread(channel1{i},1);
        initialint = traces(:,1)'./singleMolIntMode(i);
        allInitialInt = [allInitialInt traces(:,1)'./singleMolIntMode(end)];
        dlmwrite(fileout,initialint,'-append');
        
    end

    dlmwrite(fileout,allInitialInt,'-append');  

    cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
    system(cmd);
    
    hists = csvread([filein,'_Histograms.csv'],1,0);
    
    for i=1:NumberOfFiles
        allResults(i,15) = sum(hists(2*i,hists(2*i-1,:)<0.5))./sum(hists(2*i,:));
        allResults(i,16) = sum(hists(2*i,hists(2*i-1,:)>=0.5 & hists(2*i-1,:)<1.5))./sum(hists(2*i,:));
        allResults(i,17) = sum(hists(2*i,hists(2*i-1,:)>=1.5 & hists(2*i-1,:)<2.5))./sum(hists(2*i,:));
        allResults(i,18) = sum(hists(2*i,hists(2*i-1,:)>=2.5))./sum(hists(2*i,:));
    end
    
    allResults(end,15) = sum(hists(end,hists(end-1,:)<0.5))./sum(hists(end,:));
    allResults(end,16) = sum(hists(end,hists(end-1,:)>=0.5 & hists(end-1,:)<1.5))./sum(hists(end,:));
    allResults(end,17) = sum(hists(end,hists(end-1,:)>=1.5 & hists(end-1,:)<2.5))./sum(hists(end,:));
    allResults(end,18) = sum(hists(end,hists(end-1,:)>=2.5))./sum(hists(end,:)); 
    
    allInitialInt = sort(allInitialInt);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Particle Intensity Distribution')
    xlabel('Particle Intensities (# Molecules)')
    ylabel('Probability (PDF)')
    plot(hists(end-1,:),hists(end,:))
    xlim([-1 allInitialInt(round(0.99.*size(allInitialInt,2)))])
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'All_Particle_Intensities'], '-dpng', '-r600')
    
%% 9) Create Combined Figure and Table

    fig = figure;
    img1 = imread([photobleachFile 'Bleaching_Rate.png']);
    img2 = imread([photobleachFile 'Step_Height_Distribution.png']);
    img3 = imread([photobleachFile 'Signal_to_Noise.png']);
    img4 = imread([photobleachFile 'All_Particle_Intensities.png']);

    montage({img1,img2,img3,img4},'BorderSize',[10 100],'BackgroundColor','white','ThumbnailSize',[]);
    text(50,100,'A','FontSize',24) 
    text(2100,100,'B','FontSize',24) 
    text(50,1500,'C','FontSize',24)
    text(2100,1500,'D','FontSize',24)
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Combined_Figure'], '-dpng', '-r600')
 %%   
    for i=1:18
        allResults(NumberOfFiles+1,i) = mean(allResults(1:NumberOfFiles,i));
        if NumberOfFiles>1
            allResults(NumberOfFiles+2,i) = std(allResults(1:NumberOfFiles,i));
        end
    end
    
    f=figure;
    set(gcf, 'Position', [100, 100, 1300, 300])
    t=uitable(f,'Data',allResults,'Position', [0, 0, 1300, 300]);
    t.ColumnName = {'Num of Particles','Num of Single Steps','Bleach Rate (1/frames)','Half Life (frames)','10% Bleached (frames)','Gauss Fit Mean', 'Gauss Fit Std. Dev.','Mean Step Height', 'Std. Dev. Step Height','Median Step Height','Mode Step Height','Log Normal Mean','Log Normal Std. Dev.','Mean Signal to Noise','Submonomer Fraction','Monomer Fraction','Dimer Fraction', 'Higher Order Fraction'};
    t.RowName = num2cell([1:NumberOfFiles]);
    t.RowName(NumberOfFiles+1) = {'Mean'};
    t.RowName(NumberOfFiles+2) = {'Std. Dev.'};
    t.RowName(NumberOfFiles+3) = {'Pooled'};

 

    T = array2table(allResults);
    T.Properties.VariableNames= matlab.lang.makeValidName({'Num_of_Particles','Num_of_Single_Steps','Bleach_Rate_per_frames','Half_Life','Ten_Percent_Bleached','Gauss_Fit_Mean', 'Gauss_Fit_Std_Dev','Mean_Step_Height', 'Std_Dev_Step_Height','Median_Step_Height','Mode_Step_Height','Log_Normal_Mean','Log_Normal_Std_Dev','Mean_Signal_to_Noise','Submonomer_Fraction','Monomer_Fraction','Dimer_Fraction', 'Higher_Order_Fraction'});
    T.Properties.RowNames = t.RowName;
    writetable(T, [photobleachFile,'Bleaching_Summary.csv'],'WriteRowNames',true);
    
    
    variableString = ['Date, ', datestr(datetime('today')),'\n'...
    ,'iterations,',num2str(stepfitIterations),'\nminFirstStepProb,', num2str(minFirstStepProb),'\nmaxSecondMeanFirstMeanRatio,', num2str(maxSecondMeanFirstMeanRatio),'\n'...
    ,'maxMoreStepProb,',num2str(maxMoreStepProb),'\nexpYMinPercent,', num2str(expYMinPercent),'\nexpYMaxPercent,', num2str(expYMaxPercent),'\n'...
    ,'gausYMinPercent,',num2str(gausYMinPercent),'\ngausYMaxPercent,', num2str(gausYMaxPercent)];

    fileID = fopen([photobleachFile,'Single_Molecule_Photobleaching_Parameters.csv'],'w');
    fprintf(fileID, variableString);
    fclose(fileID);
    