%%
clear
%% 1) get the working folder
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

fileName = uigetdir(); % open the dialog box to select the folder for batch files
fileName=[fileName,fileSep];
%% Find all traces
filesInSubFolders = false; % Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

if filesInSubFolders
    allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name,fileSep],dir(cell2mat(y))','UniformOutput',false),dir(fileName),'UniformOutput',false);
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
else
    allFolders = arrayfun(@(x)[fileName,x.name,fileSep],dir(fileName),'UniformOutput',false); % find everything in the input folder
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = allFolders(3:end);
end
allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
channel1 = allFiles(contains(allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));
NumberOfFiles=size(channel1,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%%  Stepfit All experiments
iterations = 10000;

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
        cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',channel1{i},'" "',fileparts(channel1{i}),fileSep,'Stepfit" -FitSingleSteps -Iterations ',num2str(iterations)];
        system(cmd);
    end
end
disp('Step fitting completed');

%% Filter single file for single stepfits
    fileToCheck=1;
    pageNumber = 1;
    
    minFirstStepProb = 0.5;
    maxSecondMeanFirstMeanRatio=0.25;
    maxMoreStepProb=1.1;
    
    
    traces=csvread(channel1{fileToCheck},1);
    stepsdata = csvread([fileparts(channel1{fileToCheck}) fileSep 'Stepfit_Single_Step_Fits.csv'],1);
    
    
    singleStepTraceQ = stepsdata(:,3)>minFirstStepProb  & stepsdata(:,6) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb;
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

    
    %% Filter all files for single stepfits

for fileNo = 1:NumberOfFiles

    traces=csvread(channel1{fileNo},1);
    stepsdata = csvread([fileparts(channel1{fileNo}) fileSep 'Stepfit_Single_Step_Fits.csv'],1);
    
    singleStepTraceQ = stepsdata(:,3)>minFirstStepProb  & stepsdata(:,6) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb;
    singleStepTraces = traces(singleStepTraceQ,:);
    multiStepTraces = traces(~singleStepTraceQ,:);
    singleStepStepData = stepsdata(singleStepTraceQ,:);
    multiStepStepData = stepsdata(~singleStepTraceQ,:);

    fileout = [fileparts(channel1{fileToCheck}) fileSep 'Single_Step_Traces.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame');
    fclose(fid);
    dlmwrite(fileout,singleStepTraces,'-append');
    
    fileout = [fileparts(channel1{fileToCheck}) fileSep 'Multi_Step_Traces.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame');
    fclose(fid);
    dlmwrite(fileout,singleStepTraces,'-append');
    
    fileout = [fileparts(channel1{fileToCheck}) fileSep 'Single_Step_Step_Fit.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps ');
    fclose(fid);
    dlmwrite(fileout,singleStepStepData,'-append');
    
    fileout = [fileparts(channel1{fileToCheck}) fileSep 'Multi_Step_Step_Fit.csv'];   
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Trace Number, No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more steps ');
    fclose(fid);
    dlmwrite(fileout,multiStepStepData,'-append');   
    
end


%% Fit Bleach Times

    expYMinPercent = 0;
    expYMaxPercent = 0.75;
    
    
    fileout = [fileName 'Bleaching_Survival_Curves.csv'];
    filein = [fileName 'Bleaching_Survival_Curves'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each First Line is the frame number, Each Second Line is Number of Unbleached Particles after that number of Frames');
    fclose(fid);
    
    fid2 = fopen([fileName 'Bleaching_File_Names.csv'],'w'); 
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
    
    figure
    hold on
    title('Bleaching Rate')
    xlabel('Frame')
    ylabel('Remaining Particles')
    plot(allBleachingX,allBleachingY,'r');
    plot(1:max(allBleachingX),bleachFits(end,1)+bleachFits(end,2).*exp(-bleachFits(end,3).*[1:max(allBleachingX)]),'-b');
    hold off
    
    disp(['The pooled bleaching rate of ' num2str(bleachFits(end,3)) ' corresponds to a halflife of ' num2str(log(2)/bleachFits(end,3)) ...
        ' and a 10% beaching frame of ' num2str(log(10/9)/bleachFits(end,3))]);
    
%% Fit Step Heights

    gausYMinPercent = 0;
    gausYMaxPercent = 0.75;
    
    
    fileout = [fileName 'Step_Height_Survival_Curves.csv'];
    filein = [fileName 'Bleaching_Survival_Curves'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each First Line is the frame number, Each Second Line is Number of Unbleached Particles after that number of Frames');
    fclose(fid);
    
    fid2 = fopen([fileName 'Bleaching_File_Names.csv'],'w'); 
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
    
    figure
    hold on
    title('Bleaching Rate')
    xlabel('Frame')
    ylabel('Remaining Particles')
    plot(allBleachingX,allBleachingY,'r');
    plot(1:max(allBleachingX),bleachFits(end,1)+bleachFits(end,2).*exp(-bleachFits(end,3).*[1:max(allBleachingX)]),'-b');
    hold off
    
    disp(['The pooled bleaching rate of ' num2str(bleachFits(end,3)) ' corresponds to a halflife of ' num2str(log(2)/bleachFits(end,3)) ...
        ' and a 10% beaching frame of ' num2str(log(10/9)/bleachFits(end,3))]);
        

    

    