%%
clear
%% 1) Select Input Folder
filesInSubFolders = true;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
fileEXE = '"';
fileSep = '';
if ismac
    JIM = ['"',fileparts(JIM),'/c++_Base_Programs/Mac/'];
    fileSep = '/';
elseif ispc
    JIM = ['"',fileparts(JIM),'\c++_Base_Programs\Windows\'];
    fileEXE = '.exe"';
    fileSep = '\';
else
    disp('Platform not supported')
end

fileName = uigetdir('G:\My_Jim\SLO_Output','Select Folder Containing All Traces'); % open the dialog box to select the folder for batch files
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

parfor i=1:NumberOfFiles
    disp(['Step Fitting Experiment ',num2str(i),' - ',channel1{i}]);
    cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',channel1{i},'" "',fileparts(channel1{i}),fileSep,'Stepfit" -FitSingleSteps -Iterations ',num2str(stepfitIterations)];
    system(cmd);

end
disp('Step fitting completed');

%% 3) View Single Step Filters
    fileToCheck = 1;
    pageNumber = 1;
    
    minFirstStepProb = 0.5;
    maxSecondMeanFirstMeanRatio=0.25;
    maxMoreStepProb=0.999;
    
    
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

allResults = zeros(NumberOfFiles+3,21);
    
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
allResults(end-2,1) = mean(allResults(1:NumberOfFiles,1));
allResults(end-1,1) = std(allResults(1:NumberOfFiles,1));

allResults(end,2) = sum(allResults(1:NumberOfFiles,2));
allResults(end-2,2) = mean(allResults(1:NumberOfFiles,2));
allResults(end-1,2) = std(allResults(1:NumberOfFiles,2));

allResults(end,19) = sum(allResults(1:NumberOfFiles,19));

    photobleachFile = [fileName 'Compiled_Photobleaching_Analysis' fileSep];
    if ~exist(photobleachFile, 'dir')
        mkdir(photobleachFile)%make a subfolder with that name
    end

%% 5) Fit Bleach Times

    YMinPercent = 0;
    YMaxPercent = 95;
    


allData = [];

for fileNo = 1:NumberOfFiles    

    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 

    dataIn = sort(singleStepStepData(:,4));
    allData = [allData;dataIn];
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn>z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [100 1/mean(dataIn) 0], opts);
    allResults(fileNo,3) = bestFitParams(2);
    allResults(fileNo,4) = log(2)./bestFitParams(2);
    allResults(fileNo,5) = log(10/9)./bestFitParams(2);
end

X = 1:max(allData);
Y = arrayfun(@(z) 100.*nnz(allData>z)./length(allData),X);
Xin = X(Y<YMaxPercent & Y>YMinPercent);
Yin = Y(Y<YMaxPercent & Y>YMinPercent);

by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [100 1/mean(dataIn) 0], opts);
allResults(end,3) = bestFitParams(2);
allResults(end,4) = log(2)./bestFitParams(2);
allResults(end,5) = log(10/9)./bestFitParams(2);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
plot(X,Y,'LineWidth',2)
plot(X,by(bestFitParams,X),'LineWidth',2)
hold off
set(gca,'Layer','top')
xlabel('Frame','FontSize', 9)
ylabel('Remaining Particles (%)','FontSize', 9)
leg = legend({'Data', 'Exp. Fit'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
print([photobleachFile 'Bleaching_Rate'], '-dpng', '-r600');
print([photobleachFile 'Bleaching_Rate'], '-dsvg', '-r600'); 

disp(['The pooled bleaching rate of ' num2str(allResults(end,3)) ' corresponds to a halflife of ' num2str(allResults(end,4)) ...
        ' and a 10% beaching frame of ' num2str(allResults(end,5))]);

  
%% 6) Fit Step Heights

    YMinPercent = 0;
    YMaxPercent = 95;
    
 allData = [];

for fileNo = 1:NumberOfFiles    

    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 

    dataIn = sort(singleStepStepData(:,5)-singleStepStepData(:,6));
    
    
    allData = [allData;dataIn];
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    allResults(fileNo,6) = bestFitParams(1);
    allResults(fileNo,7) = bestFitParams(2);
    allResults(fileNo,8) = mean(dataIn);
    allResults(fileNo,9) = std(dataIn);
    allResults(fileNo,10) = median(dataIn);
    
    by2 = @(b,bx)(100.*normcdf(log(bx),b(1),b(2)));                % Objective function
    OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
    allResults(fileNo,11) = exp(bestFitParams2(1)+(bestFitParams2(2)^2)./2);
    allResults(fileNo,12) = sqrt((exp(bestFitParams2(2)^2)-1)*exp(2*bestFitParams2(1)+bestFitParams2(2)^2));

end

X = 1:max(allData);
Y = arrayfun(@(z) 100.*nnz(allData<z)./length(allData),X);
Xin = X(Y<YMaxPercent & Y>YMinPercent);
Yin = Y(Y<YMaxPercent & Y>YMinPercent);


OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [mean(allData) std(allData)], opts);
allResults(end,6) = bestFitParams(1);
allResults(end,7) = bestFitParams(2);
allResults(end,8) = mean(allData);
allResults(end,9) = std(allData);
allResults(end,10) = median(allData);

OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
allResults(end,11) = exp(bestFitParams2(1)+(bestFitParams2(2)^2)./2);
allResults(end,12) = sqrt((exp(bestFitParams2(2)^2)-1)*exp(2*bestFitParams2(1)+bestFitParams2(2)^2));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Step Height','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData(allData< max(X(Y<99))),50,'Normalization','pdf','HandleVisibility','off')
plot(X,normpdf(X,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
plot(X,1./X.*normpdf(log(X),bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
xlim([0 max(X(Y<99))])
leg = legend({'Gaussian','Log Norm'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Step_Height_Distribution'], '-dpng', '-r600');
print([photobleachFile 'Step_Height_Distribution'], '-dsvg', '-r600'); 
%% 6) Pre-Step Signal Distribution

    YMinPercent = 0;
    YMaxPercent = 95;
    
 allData = [];

for fileNo = 1:NumberOfFiles    

    traces = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Traces.csv'],1,0); 
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0);
    %dataIn = arrayfun(@(z)traces(z,1:singleStepStepData(z,4))',1:size(traces,1),'UniformOutput',false);
    dataIn = arrayfun(@(z)traces(z,1:min(5,singleStepStepData(z,4)))',1:size(traces,1),'UniformOutput',false);
    dataIn = sort(cat(1,dataIn{:}));
    
    allData = [allData;dataIn];
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    allResults(fileNo,6) = bestFitParams(1);
    allResults(fileNo,7) = bestFitParams(2);
    allResults(fileNo,8) = mean(X);
    allResults(fileNo,9) = std(X);
    allResults(fileNo,10) = median(X);
    
    by2 = @(b,bx)(100.*normcdf(log(bx),b(1),b(2)));                % Objective function
    OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
    allResults(fileNo,11) = exp(bestFitParams2(1)+(bestFitParams2(2)^2)./2);
    allResults(fileNo,12) = sqrt((exp(bestFitParams2(2)^2)-1)*exp(2*bestFitParams2(1)+bestFitParams2(2)^2));

    
end

X = 1:max(allData);
Y = arrayfun(@(z) 100.*nnz(allData<z)./length(allData),X);
Xin = X(Y<YMaxPercent & Y>YMinPercent);
Yin = Y(Y<YMaxPercent & Y>YMinPercent);


OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [mean(allData) std(allData)], opts);
allResults(end,6) = bestFitParams(1);
allResults(end,7) = bestFitParams(2);
allResults(end,8) = mean(X);
allResults(end,9) = std(X);
allResults(end,10) = median(X);

OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
allResults(end,11) = exp(bestFitParams2(1)+(bestFitParams2(2)^2)./2);
allResults(end,12) = sqrt((exp(bestFitParams2(2)^2)-1)*exp(2*bestFitParams2(1)+bestFitParams2(2)^2));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Pre-Step Intensity','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData,'Normalization','pdf','HandleVisibility','off')
plot(X,normpdf(X,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
plot(X,1./X.*normpdf(log(X),bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
xlim([0 max(X(Y<99))])
leg = legend({'Gaussian','Log Norm'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'PreStep_Intensities_Distribution'], '-dpng', '-r600');
print([photobleachFile 'PreStep_Intensities_Distribution'], '-dsvg', '-r600'); 
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Pre-Step Intensity','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData,'Normalization','pdf','HandleVisibility','off')
plot(X,normpdf(X,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
plot(X,1./X.*normpdf(log(X),bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
xlim([0 max(X(Y<99))])
leg = legend({'Gaussian','Log Norm'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'PreStep_Intensities_Distribution'], '-dpng', '-r600');
print([photobleachFile 'PreStep_Intensities_Distribution'], '-dsvg', '-r600'); 

%% 6) Pre-Step Noise Distribution

    YMinPercent = 0;
    YMaxPercent = 95;
    
 allData = [];

for fileNo = 1:NumberOfFiles    

    traces = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Traces.csv'],1,0); 
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0);
    dataIn = arrayfun(@(z)(traces(z,1:singleStepStepData(z,4)-1)'-singleStepStepData(z,5))./sqrt(singleStepStepData(z,5)),1:size(traces,1),'UniformOutput',false);
    %dataIn = arrayfun(@(z)traces(z,singleStepStepData(z,4)+1:end)'-singleStepStepData(z,6),1:size(traces,1),'UniformOutput',false);

    dataIn = sort(cat(1,dataIn{:}));
    
    allData = [allData;dataIn];
    X = min(dataIn):max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    %ADD SAVING THESE

end

X = min(allData):max(allData);
Y = arrayfun(@(z) 100.*nnz(allData<z)./length(allData),X);
Xin = X(Y<YMaxPercent & Y>YMinPercent);
Yin = Y(Y<YMaxPercent & Y>YMinPercent);


OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [mean(allData) std(allData)], opts);
%AND SAVE THESE

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('(Int.-\mu) / \mu^{1/2} ','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData,'Normalization','pdf','HandleVisibility','off')
plot(X,normpdf(X,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
%xlim([min(X(Y>1)) max(X(Y<99))])
xlim([-60 60]) % CHANGE THIS BACK
leg = legend({'Gaussian'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Prestep_Noise_Distribution'], '-dpng', '-r600');
print([photobleachFile 'Prestep_Noise_Distribution'], '-dsvg', '-r600'); 


%% 7) Find Signal to Noise

    allData = [];

    for fileNo = 1:NumberOfFiles    
    singleStepStepData = csvread([fileparts(channel1{fileNo}) fileSep 'Single_Step_Step_Fit.csv'],1,0); 
    dataIn = (singleStepStepData(:,5)'-singleStepStepData(:,6)')./(singleStepStepData(:,8)');
    allData = [allData dataIn];
    allResults(fileNo,13) = mean(dataIn); 
    end 
    
    allResults(end,13) = mean(allData);
    allData = sort(allData);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    %title('Signal to Noise Distribution')
    xlabel('Step Height/Residual Std. Dev.')
    ylabel('Probability (PDF)')
    histogram(allData,'Normalization','pdf')
    hold off
    xlim([0 allData(round(0.99.*size(allData,2)))])
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Signal_to_Noise'], '-dpng', '-r600')

%% 8) Initial Particle Intensity Distribution using normal distribution

allData = [];
for fileNo=1:NumberOfFiles
    traces=csvread(channel1{fileNo},1);

    dataIn = traces(:,1);
    allData = [allData;dataIn];
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);

    by = @(b,bx)(abs(b(1)).*normcdf(bx,1.*bestFitParams(1),sqrt(1).*bestFitParams(2))...
        + abs(b(2)).*normcdf(bx,2.*bestFitParams(1),sqrt(2).*bestFitParams(2))...
        + abs(b(3)).*normcdf(bx,3.*bestFitParams(1),sqrt(3).*bestFitParams(2))...
        + abs(b(4)).*normcdf(bx,4.*bestFitParams(1),sqrt(4).*bestFitParams(2))...
    );   
    OLS = @(b) sum((by(b,X) - Y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    initialNumbers = abs(fminsearch(OLS, [100 0 0 0], opts));

    for i = 1:4
        allResults(fileNo,17+i) = initialNumbers(i);
    end

end
    
X = 1:max(allData);
Y = arrayfun(@(z) 100.*nnz(allData<z)./length(allData),X);

OLS = @(b) sum((by(b,X) - Y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
initialNumbers = abs(fminsearch(OLS, [100 0 0 0], opts));
    for i = 1:4
        allResults(end,13+i) = initialNumbers(i);
    end
    
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Initial Intensities','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData,'Normalization','pdf','HandleVisibility','off')
plot(X,initialNumbers(1)./100.*normpdf(X,1.*bestFitParams(1),sqrt(1).*bestFitParams(2)),'LineWidth',2)
plot(X,initialNumbers(2)./100.*normpdf(X,2.*bestFitParams(1),sqrt(2).*bestFitParams(2)),'LineWidth',2)
plot(X,initialNumbers(3)./100.*normpdf(X,3.*bestFitParams(1),sqrt(3).*bestFitParams(2)),'LineWidth',2)
plot(X,initialNumbers(4)./100.*normpdf(X,4.*bestFitParams(1),sqrt(4).*bestFitParams(2)),'LineWidth',2)
xlim([0 max(X(Y<99))])
leg = legend({'Monomer','Dimer','Trimer','Tetramer'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Labelling_Number_normal'], '-dpng', '-r600');
print([photobleachFile 'Labelling_Number_normal'], '-dsvg', '-r600'); 
disp(['Using normal Distribution Fit Gives ' num2str(initialNumbers(1)) '% monomer, '...
     num2str(initialNumbers(2)) '% dimer, '  num2str(initialNumbers(3)) '% trimer, and '  num2str(initialNumbers(4)) '% Tetramer ']);
%% 8) Initial Particle Intensity Distribution using log normal distribution

allData = [];
for fileNo=1:NumberOfFiles
    traces=csvread(channel1{fileNo},1);

    dataIn = traces(:,1);
    allData = [allData;dataIn];
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);

    by2 = @(b,bx)(abs(b(1)).*normcdf(log(bx),log(1)+bestFitParams2(1),bestFitParams2(2))...
        + abs(b(2)).*normcdf(log(bx),log(2)+bestFitParams2(1),bestFitParams2(2))...
        + abs(b(3)).*normcdf(log(bx),log(3)+bestFitParams2(1),bestFitParams2(2))...
        + abs(b(4)).*normcdf(log(bx),log(4)+bestFitParams2(1),bestFitParams2(2))...
    );   
    OLS = @(b) sum((by2(b,X) - Y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    initialNumbers = abs(fminsearch(OLS, [100 0 0 0], opts));

    for i = 1:4
        allResults(fileNo,13+i) = initialNumbers(i);
    end

end
    
X = 1:max(allData);
Y = arrayfun(@(z) 100.*nnz(allData<z)./length(allData),X);

OLS = @(b) sum((by2(b,X) - Y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
initialNumbers = abs(fminsearch(OLS, [100 0 0 0], opts));
    for i = 1:4
        allResults(end,13+i) = initialNumbers(i);
    end
    
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
xlabel('Initial Intensities','FontSize', 9)
ylabel('Probability (PDF)','FontSize', 9)
histogram(allData,'Normalization','pdf','HandleVisibility','off')
plot(X,initialNumbers(1)./100./X.*normpdf(log(X),log(1)+bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
plot(X,initialNumbers(2)./100./X.*normpdf(log(X),log(2)+bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
plot(X,initialNumbers(3)./100./X.*normpdf(log(X),log(3)+bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
plot(X,initialNumbers(4)./100./X.*normpdf(log(X),log(4)+bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
xlim([0 max(X(Y<99))])
leg = legend({'Monomer','Dimer','Trimer','Tetramer'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [10,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Labelling_Number_lognormal'], '-dpng', '-r600');
print([photobleachFile 'Labelling_Number_lognormal'], '-dsvg', '-r600');     
    
disp(['Using Log-Normal Distribution Fit Gives ' num2str(initialNumbers(1)) '% monomer, '...
     num2str(initialNumbers(2)) '% dimer, '  num2str(initialNumbers(3)) '% trimer, and '  num2str(initialNumbers(4)) '% Tetramer ']);
 
 
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
    T.Properties.VariableNames= matlab.lang.makeValidName({'Num_of_Particles','Num_of_Single_Steps','Bleach_Rate_per_frames','Half_Life','Ten_Percent_Bleached','Gauss_Fit_Mean', 'Gauss_Fit_Std_Dev','Mean_Step_Height', 'Std_Dev_Step_Height','Median_Step_Height','Mode_Step_Height','Log_Normal_Mean','Log_Normal_Std_Dev','Mean_Signal_to_Noise','Submonomer_Fraction','Monomer_Fraction','Dimer_Fraction', 'Higher_Order_Fraction','No_Step_Count'});
    T.Properties.RowNames = t.RowName;
    writetable(T, [photobleachFile,'Bleaching_Summary.csv'],'WriteRowNames',true);
    
    
    variableString = ['Date, ', datestr(datetime('today')),'\n'...
    ,'iterations,',num2str(stepfitIterations),'\nminFirstStepProb,', num2str(minFirstStepProb),'\nmaxSecondMeanFirstMeanRatio,', num2str(maxSecondMeanFirstMeanRatio),'\n'...
    ,'maxMoreStepProb,',num2str(maxMoreStepProb),'\nexpYMinPercent,', num2str(expYMinPercent),'\nexpYMaxPercent,', num2str(expYMaxPercent),'\n'...
    ,'gausYMinPercent,',num2str(gausYMinPercent),'\ngausYMaxPercent,', num2str(gausYMaxPercent)];

    fileID = fopen([photobleachFile,'Single_Molecule_Photobleaching_Parameters.csv'],'w');
    fprintf(fileID, variableString);
    fclose(fileID);
    