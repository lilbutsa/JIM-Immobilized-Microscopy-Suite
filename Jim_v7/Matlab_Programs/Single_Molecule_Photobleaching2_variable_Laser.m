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
%% Detect Laser Intensities
multipleLaserIntensities = true;
beforelaserIdentifier = '\';
afterlaserIdentifier = 'ms_';
uniqueInts = [50];

if multipleLaserIntensities
    laserInts = zeros(NumberOfFiles,1);
    for i=1:NumberOfFiles
       for j= uniqueInts
           if contains(channel1{i},[beforelaserIdentifier num2str(j) afterlaserIdentifier]) 
               laserInts(i) = j;
           end
       end
    end
end
%% 2) Stepfit Traces
stepfitIterations = 10000;

parfor i=1:NumberOfFiles
    disp(['Step Fitting Experiment ',num2str(i),' - ',channel1{i}]);
    cmd = [JIM,'Change_Point_Analysis',fileEXE,' "',channel1{i},'" "',fileparts(channel1{i}),fileSep,'Stepfit" -FitSingleSteps -Iterations ',num2str(stepfitIterations)];
    system(cmd);

end
disp('Step fitting completed');

%% 3) View Single Step Filters
fileToCheck = 11;
pageNumber = 1;

minFirstStepProb = 0.05;
maxSecondMeanFirstMeanRatio=0.25;
maxMoreStepProb=1.01;


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

allResults = zeros(NumberOfFiles,21);
allSingleStepTraces = cell(NumberOfFiles,1);
allSingleStepData = cell(NumberOfFiles,1);
    
for fileNo = 1:NumberOfFiles

    traces=csvread(channel1{fileNo},1);
    stepsdata = csvread([fileparts(channel1{fileNo}) fileSep 'Stepfit_Single_Step_Fits.csv'],1);
    
    singleStepTraceQ = stepsdata(:,3)>minFirstStepProb  & stepsdata(:,5)>0 & abs(stepsdata(:,6)) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb;
    singleStepTraces = traces(singleStepTraceQ,:);
    multiStepTraces = traces(~singleStepTraceQ,:);
    singleStepStepData = stepsdata(singleStepTraceQ,:);
    multiStepStepData = stepsdata(~singleStepTraceQ,:);
    
    allSingleStepTraces{fileNo} = singleStepTraces;
    allSingleStepData{fileNo} = singleStepStepData;
    
    allResults(fileNo,1) = size(traces,1);%Numberof Particles
    allResults(fileNo,2) = size(singleStepStepData,1);%Number of single steps
    allResults(fileNo,3) = nnz(abs(stepsdata(:,6)) > 0.75 .* stepsdata(:,5)); % no step

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

photobleachFile = [fileName 'Compiled_Photobleaching_Analysis' fileSep];
if ~exist(photobleachFile, 'dir')
    mkdir(photobleachFile)%make a subfolder with that name
end
%% Particles detected per laser power
if multipleLaserIntensities
    toplot = arrayfun(@(z) mean(allResults(laserInts==z,1)),uniqueInts);
    toplot2 = arrayfun(@(z) std(allResults(laserInts==z,1)),uniqueInts);

    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
        fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
    hold on
    ax = gca;
    scatter(uniqueInts,toplot)
    errorbar(uniqueInts,toplot,toplot2,'LineStyle','none','Color',[0 0 0],'CapSize',3)

    ylim([0 1.1*max(toplot+toplot2)])
    hold off
    xlabel('Laser Int. (mW)')
    ylabel('Particles per FOV')
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([photobleachFile 'Number_Of_Particles'], '-dpng', '-r600');
    print([photobleachFile 'Number_Of_Particles'], '-depsc', '-r600');                                  
end
%% Single Steps
figure
scatter(laserInts,allResults(:,2))
%% Single Steps
figure
plot(allResults(:,2))
%% Single Step Percentage
figure
scatter(laserInts,100.*allResults(:,2)./allResults(:,1))
ylim([0 100])
%%
toplot = arrayfun(@(z) mean(100.*allResults(laserInts==z,2)./allResults(laserInts==z,1)),uniqueInts);
toplot2 = arrayfun(@(z) std(100.*allResults(laserInts==z,2)./allResults(laserInts==z,1)),uniqueInts);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
scatter(uniqueInts,toplot)
errorbar(uniqueInts,toplot,toplot2,'LineStyle','none','Color',[0 0 0],'CapSize',3)

ylim([0 105])
hold off
xlabel('Laser Int. (mW)')
ylabel('Percent of Single Steps')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Single_Step_Percentage'], '-dpng', '-r600');
print([photobleachFile 'Single_Step_Percentage'], '-depsc', '-r600');

%% No Steps
figure
scatter(laserInts,100.*allResults(:,2)./allResults(:,1))
%%
toplot = arrayfun(@(z) mean(100.*allResults(laserInts==z,3)./allResults(laserInts==z,1)),uniqueInts);
toplot2 = arrayfun(@(z) std(100.*allResults(laserInts==z,3)./allResults(laserInts==z,1)),uniqueInts);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
scatter(uniqueInts,toplot)
errorbar(uniqueInts,toplot,toplot2,'LineStyle','none','Color',[0 0 0],'CapSize',3)

ylim([0 10])
hold off
xlabel('Laser Int. (mW)')
ylabel('No Steps (%)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'No_Step_Percentage'], '-dpng', '-r600');
print([photobleachFile 'No_Step_Percentage'], '-depsc', '-r600');


%% Plot Bleaching Distributions

YMinPercent = 0;
YMaxPercent = 95;
    
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'log','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;

for fileNo = 1:length(uniqueInts)    

    dataIn = cell2mat(allSingleStepData(laserInts==uniqueInts(fileNo)));
    
    dataIn = sort(dataIn(:,4));

    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn>z)./length(dataIn),X);

    ax.ColorOrderIndex = fileNo;
    plot(X,Y,'LineWidth',2)

end
xlim([0 50])
ylim([5 100])
hold off
xlabel('Frames')
ylabel('Remaining Particles (%)')
leg = legend(arrayfun(@(x)[num2str(x),' mW'],uniqueInts,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 9);

leg.ItemTokenSize = [15,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Log_Bleaching_Survival_Curve'], '-dpng', '-r600');
print([photobleachFile 'Log_Bleaching_Survival_Curve'], '-depsc', '-r600');

%% not log Plot Bleaching Distributions

YMinPercent = 0;
YMaxPercent = 95;
    
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;

for fileNo = 1:length(uniqueInts)    

    dataIn = cell2mat(allSingleStepData(laserInts==uniqueInts(fileNo)));
    
    dataIn = sort(dataIn(:,4));

    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn>z)./length(dataIn),X);

    ax.ColorOrderIndex = fileNo;
    plot(X,Y,'LineWidth',2)

end
xlim([0 50])
ylim([5 100])
hold off
xlabel('Frames')
ylabel('Remaining Particles (%)')
leg = legend(arrayfun(@(x)[num2str(x),' mW'],uniqueInts,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 9);

leg.ItemTokenSize = [15,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Bleaching_Survival_Curve'], '-dpng', '-r600');
print([photobleachFile 'Bleaching_Survival_Curve'], '-depsc', '-r600');
%% 5) Fit Bleach Times

YMinPercent = 0;
YMaxPercent = 95;

for fileNo = 1:NumberOfFiles   

    dataIn = allSingleStepData{fileNo};
    
    dataIn = sort(dataIn(:,4));
    
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn>z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [100 1/mean(dataIn) 0], opts);
    allResults(fileNo,4) = bestFitParams(2);
    allResults(fileNo,5) = log(2)./bestFitParams(2);
    allResults(fileNo,6) = log(10/9)./bestFitParams(2);
    
end
%% Bleach Rate Versus Laser Int
figure
scatter(laserInts,allResults(:,4))
%%
toplot = arrayfun(@(z) mean(allResults(laserInts==z,4)),uniqueInts);
toplot2 = arrayfun(@(z) std(allResults(laserInts==z,4)),uniqueInts);

x = uniqueInts(uniqueInts<90);
y = toplot(uniqueInts<90);
bleachRateFit = (dot(x,y).*max(size(x))-sum(x).*sum(y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'log','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
plot([1 max(uniqueInts)],bleachRateFit.*[1 max(uniqueInts)],'LineWidth',1.5)
scatter(uniqueInts,toplot,10,[0 0 0],'filled')
errorbar(uniqueInts,toplot,toplot2,'LineStyle','none','Color',[0 0 0],'CapSize',3)

xlim([1 100])
ylim([0.001 1.1*max(toplot)])
hold off
xlabel('Laser Int. (mW)')
ylabel('Bleach Rate (1/frames)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Log_Bleach_Rate_Vs_Laser'], '-dpng', '-r600');
print([photobleachFile 'Log_Bleach_Rate_Vs_Laser'], '-depsc', '-r600');
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
plot([1 max(uniqueInts)],bleachRateFit.*[1 max(uniqueInts)],'LineWidth',1.5)
scatter(uniqueInts,toplot,10,[0 0 0],'filled')
errorbar(uniqueInts,toplot,toplot2,'LineStyle','none','Color',[0 0 0],'CapSize',3)

xlim([1 100])
ylim([0 1.1*max(toplot)])
hold off
xlabel('Laser Int. (mW)')
ylabel('Bleach Rate (1/frames)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([photobleachFile 'Bleach_Rate_Vs_Laser'], '-dpng', '-r600');
print([photobleachFile 'Bleach_Rate_Vs_Laser'], '-depsc', '-r600');

disp(['The pooled bleaching rate of ' num2str(bleachRateFit) ' per frame per mW' ]);

%% 6) Fit Step Heights

    allfits = zeros(length(uniqueInts) ,3);
    YMinPercent = 0;
    YMaxPercent = 99;
     figure('Name','Step_Heights')
    set(gcf, 'Position', [100, 100, 1000, 800])
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',2, 'FontName','Times')
    ax = gca;   

for fileNo = 1:length(uniqueInts)    

    dataIn = cell2mat(allSingleStepData(laserInts==uniqueInts(fileNo)));


    dataIn = sort(dataIn(:,5)-dataIn(:,6));
    %dataIn = dataIn./mean(dataIn);
    %X = 0:0.05:10;
     trimmedData = dataIn(round(max(1,length(dataIn)*YMinPercent/100)):round(length(dataIn)*YMaxPercent/100));
     
     Xin = min(trimmedData):(max(trimmedData)-min(trimmedData))/100:max(trimmedData);
     %Xin = min(trimmedData):max(trimmedData);
     Yin = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),Xin);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    
    by2 = @(b,bx)(100.*normcdf(log(bx),b(1),b(2)));                % Objective function
    OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
    
    middleThird = @(z)(z(length(z)/3+1:2*length(z)/3));
    by3 = @(b,bx)(mean(diff(bx)).*middleThird(100.*conv([zeros(1,length(bx)) normcdf(log(bx),b(1),b(2)) (1+zeros(1,length(bx)))],normpdf(bx,max(bx)/2,b(3)),'same')));
    OLS = @(b) sum((by3(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams3 = fminsearch(OLS, [bestFitParams2(1) bestFitParams2(2) std(dataIn)/4], opts);
    by4 = @(b,bx)(mean(diff(bx)).*middleThird(conv([zeros(1,length(bx)) 1./bx.*normpdf(log(bx),b(1),b(2)) (zeros(1,length(bx)))],normpdf(bx,max(bx)/2,b(3)),'same')));
    allfits(fileNo,:) = bestFitParams3;
    
    subplot(4,4,fileNo)
    hold on
    ax = gca;
    title([num2str(uniqueInts(fileNo)) ' mW'],'FontSize', 9)
    xlabel('Step Height','FontSize', 9)
    ylabel('Probability (PDF)','FontSize', 9)
    histogram(trimmedData,50,'Normalization','pdf','HandleVisibility','off')
    plot(Xin,length(dataIn)./length(trimmedData).*normpdf(Xin,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
    plot(Xin,length(dataIn)./length(trimmedData)./Xin.*normpdf(log(Xin),bestFitParams2(1),bestFitParams2(2)),'LineWidth',2)
    plot(Xin,by4([bestFitParams3(1),bestFitParams3(2),bestFitParams3(3)],Xin),'LineWidth',2)
    xlim([0 max(trimmedData)])
    %leg = legend({'Gaussian','Log Norm'},'Location','northeast','Box','off','FontSize', 9);
    %leg.ItemTokenSize = [10,30];
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));

end
%%

%%
figure
hold on
plot(Xin,Yin)
plot(Xin,by3([bestFitParams2(1),bestFitParams2(2), std(dataIn)/4],Xin),'LineWidth',2)
hold off
%% log normal mean
figure
scatter(uniqueInts,exp(allfits(:,1)+allfits(:,2).*allfits(:,2)./2))
%%
figure
scatter(uniqueInts,sqrt((exp(allfits(:,2).*allfits(:,2))-1).*exp(2.*allfits(:,1)+allfits(:,2).*allfits(:,2))))
%%
figure
scatter(uniqueInts,allfits(:,3))
%% 6) Pre-Step Signal Distribution

    YMinPercent = 2;
    YMaxPercent = 98;
    
    figure
    
    allNoiseFit = zeros(length(uniqueInts),2);

for fileNo = 1:length(uniqueInts)    

    singleStepStepData = cell2mat(allSingleStepData(laserInts==uniqueInts(fileNo))); 
    traces = cell2mat(allSingleStepTraces(laserInts==uniqueInts(fileNo))); 

     %dataIn = arrayfun(@(z)(traces(z,1:singleStepStepData(z,4))-singleStepStepData(z,5))'./sqrt(singleStepStepData(z,5)),1:size(traces,1),'UniformOutput',false);
     dataIn = arrayfun(@(z)(traces(z,1:singleStepStepData(z,4))-singleStepStepData(z,5))',1:size(traces,1),'UniformOutput',false);

     dataIn = dataIn(arrayfun(@(z)length(dataIn{z}),1:length(dataIn))>4);%only take traces with at least 4 points otherwise can't observe noise around mean
     dataIn = sort(cat(1,dataIn{:}));
     
     trimmedData = dataIn(round(length(dataIn)*YMinPercent/100):round(length(dataIn)*YMaxPercent/100));
     
     Xin = min(trimmedData):(max(trimmedData)-min(trimmedData))/100:max(trimmedData);
     Yin = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),Xin);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    
    allNoiseFit(fileNo,1) = bestFitParams(1);
    allNoiseFit(fileNo,2) = bestFitParams(2);
     
    subplot(4,4,fileNo)
    hold on
    ax = gca;
    title([num2str(uniqueInts(fileNo)) ' mW'],'FontSize', 9)
    xlabel('Pre-Step Noise','FontSize', 9)
    ylabel('Probability (PDF)','FontSize', 9)
    histogram(trimmedData,50,'Normalization','pdf','HandleVisibility','off')
    plot(Xin,length(dataIn)/length(trimmedData)*normpdf(Xin,bestFitParams(1),bestFitParams(2)),'LineWidth',2)
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
end
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 5.7;opts.height= 4.3;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'log','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
ax = gca;
ylabel('Pre-Step Noise Variance (a.u.)','FontSize', 9)
xlabel('Laser Power (mW)','FontSize', 9)
scatter(uniqueInts,allNoiseFit(:,2).^2)
ylim([100000,100000000])
hold off

%%

    
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

    





























































%%



figure
hold on
plot(Xin,Yin)
plot(Xin,by3([bestFitParams3(1),bestFitParams3(2),bestFitParams3(3)],Xin))
%xlim([0 max(Xin)])
hold off
%%
by4 = @(b,bx)(middleThird(conv([zeros(1,length(bx)) 1./bx.*normpdf(log(bx),b(1),b(2)) (zeros(1,length(bx)))],normpdf(bx,max(bx)/2,b(3)),'same')));

by4 = @(b,bx)(1./bx.*normpdf(log(bx),b(1),b(2)));


figure
hold on
    histogram(dataIn(dataIn< max(X(Y<99))),50,'Normalization','pdf','HandleVisibility','off')
    plot(X,by4([bestFitParams3(1),bestFitParams3(2),bestFitParams3(3)],X),'LineWidth',2)
    xlim([0 max(X(Y<99))])
    %leg = legend({'Gaussian','Log Norm'},'Location','northeast','Box','off','FontSize', 9);
    %leg.ItemTokenSize = [10,30];
    hold off
%% 6) Fit Step Heights

    YMinPercent = 0;
    YMaxPercent = 95;
    

for fileNo = 1:NumberOfFiles    

    dataIn = allSingleStepData{fileNo}; 

    dataIn = sort(dataIn(:,5)-dataIn(:,6));
    
    
    X = 1:max(dataIn);
    Y = arrayfun(@(z) 100.*nnz(dataIn<z)./length(dataIn),X);
    Xin = X(Y<YMaxPercent & Y>YMinPercent);
    Yin = Y(Y<YMaxPercent & Y>YMinPercent);
    
    by = @(b,bx)(100.*normcdf(bx,b(1),b(2)));             % Objective function
    OLS = @(b) sum((by(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams = fminsearch(OLS, [mean(dataIn) std(dataIn)], opts);
    allResults(fileNo,7) = bestFitParams(1);
    allResults(fileNo,8) = bestFitParams(2);
    allResults(fileNo,9) = mean(dataIn);
    allResults(fileNo,10) = std(dataIn);
    allResults(fileNo,11) = median(dataIn);
    
    by2 = @(b,bx)(100.*normcdf(log(bx),b(1),b(2)));                % Objective function
    OLS = @(b) sum((by2(b,Xin) - Yin).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    bestFitParams2 = fminsearch(OLS, [log(median(dataIn)) sqrt(log(var(dataIn)))], opts);
    allResults(fileNo,12) = exp(bestFitParams2(1)+(bestFitParams2(2)^2)./2);
    allResults(fileNo,13) = sqrt((exp(bestFitParams2(2)^2)-1)*exp(2*bestFitParams2(1)+bestFitParams2(2)^2));

end

%%
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
    