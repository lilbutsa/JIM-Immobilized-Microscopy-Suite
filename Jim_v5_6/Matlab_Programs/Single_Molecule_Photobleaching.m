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
useMatlabChangePoint = true;

for i=1:NumberOfFiles
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
        fid = fopen([fileparts(channel1{filetocheck}) '\Stepfit_Single_Step_Fits.csv'],'w'); 
        fprintf(fid,'%s\n','No step mean,One or more Step Probability,Step Position, Initial Mean, Final Mean, Probability of more initial steps, Probability of more final steps');
        fclose(fid);
        dlmwrite([fileparts(channel1{filetocheck}) '\Stepfit_Single_Step_Fits.csv'],toout,'-append');       
    else
        cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',channel1{i},'" "',fileparts(channel1{i}),'\Stepfit" -FitSingleSteps'];
        system(cmd);
    end
end
disp('Step fitting completed');
%% Check Individual File
filetocheck = 1;

traces=csvread(channel1{filetocheck},1);
stepsdata = csvread([fileparts(channel1{filetocheck}) '\Stepfit_Single_Step_Fits.csv'],1);

