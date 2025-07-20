%%
clear
%% 1) Select Input Folder
filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

fileName = uigetdir('G:\My_Jim\SLO_Output','Select Folder Containing All Traces'); % open the dialog box to select the folder for batch files
fileName=[fileName,filesep]; 

allFolders = arrayfun(@(x)[fileName,x.name],dir(fileName),'UniformOutput',false); % find everything in the input folder
allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
allFolders = allFolders(3:end);
allFolders = arrayfun(@(x)[x{1},filesep],allFolders,'UniformOutput',false);

if filesInSubFolders
    allSubFolders = allFolders;
    allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allSubFolders,'UniformOutput',false);
    allFolders = arrayfun(@(x)x{:}(3:end),allFolders,'UniformOutput',false);
    allFolders = horzcat(allFolders{:})';
    allFolders = allFolders(arrayfun(@(x) isfolder(cell2mat(x)),allFolders));
    allFolders = arrayfun(@(x)[x{1},filesep],allFolders,'UniformOutput',false);
end

allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),allFolders','UniformOutput',false);
allFiles = horzcat(allFiles{:})';
channel1 = allFiles(contains(allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));
NumberOfFiles=size(channel1,1);
disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select Output File
fileName = uigetdir(); % open the dialog box to select the folder for batch files
saveFolder=[fileName,filesep];

%% approximate step count

fileToCheck = 1;
pageNumber = 1;

maxStepRatio=0.75;

stepMeans = csvread([fileparts(channel1{fileToCheck}) filesep 'Channel_1_StepMeans.csv'],1);
stepNum = arrayfun(@(z) find(stepMeans(z,:)~=0,1,'last')-1,1:length(stepMeans))';
stepHeights = cell2mat(arrayfun(@(z) resize(diff(stepMeans(z,stepMeans(z,:)~=0)),[1 size(stepMeans,2)-1]),1:length(stepNum),'UniformOutput',false)');

posStepQ = max(stepHeights')>0.1.*max(stepMeans');

traces=csvread(channel1{fileToCheck},1);
stepPoints = csvread([fileparts(channel1{fileToCheck}) filesep 'Channel_1_StepPoints.csv'],1);
stepPoints = horzcat(stepPoints,zeros(length(stepPoints),1));
for i=1:length(stepPoints)
    stepPoints(i,stepNum(i)+2) = size(traces,2);
end

stepLenthQ = diff(stepPoints')';
stepLenthQ = arrayfun(@(z) nnz(stepLenthQ(z,:)>0 & stepLenthQ(z,:)<3)==0,1:length(stepLenthQ));

selectQ = cell2mat(arrayfun(@(z) (sum((stepHeights'<-maxStepRatio./z.*max(stepMeans') & ~posStepQ & stepLenthQ))>z-1)',1:4,'UniformOutput',false))';
selectQ(5,:) = (sum(selectQ)==0);


stepFitTraces = cell2mat(arrayfun(@(x) cell2mat(arrayfun(@(z)zeros(stepPoints(x,z+1)-stepPoints(x,z),1)+stepMeans(x,z),1:(stepNum(x)+1),'UniformOutput',false)'),1:length(stepMeans),'UniformOutput',false))';

classNames = {'1 Step Traces','2 Step Trace','3 Step Trace','4 Step Trace','Other'};


for plottype=1:length(classNames)
    toplot = traces(selectQ(plottype,:),:);
    toplot2 = stepFitTraces(selectQ(plottype,:),:);
    
    fig = figure('Name',classNames{plottype})
    set(gcf, 'Position', [100, 100, 700, 800])
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',2, 'FontName','Times')
    for i=1:32
        if i+32*(pageNumber-1)<size(toplot,1)
            subplot(8,4,i)
            hold on
            plot(toplot(i+32*(pageNumber-1),:),'LineWidth',1.5);
            plot(toplot2(i+32*(pageNumber-1),:),'LineWidth',1.5);
            plot([0 size(toplot(i+32*(pageNumber-1),:),2)],[0 0] ,'-black');
            hold off
        end
    end
    han=axes(fig,'visible','off'); 
    han.Title.Visible='on';
    han.XLabel.Visible='on';
    han.YLabel.Visible='on';
    ylabel(han,'Intensity (a.u.)');
    xlabel(han,'Frames');
    title(han,classNames{plottype});

    print([saveFolder 'Example_' strrep(classNames{plottype},' ','_') '_File_' num2str(fileToCheck) '_Page_' num2str(pageNumber)], '-dpng', '-r600');
    print([saveFolder 'Example_' strrep(classNames{plottype},' ','_') '_File_' num2str(fileToCheck) '_Page_' num2str(pageNumber)], '-depsc', '-r600');  
end

%% filter by approx step count
allStepCounts = cell(NumberOfFiles,1);%{1,2,3,4,other}

singleStepTraces = cell(NumberOfFiles,1);
singleStepStepFrames = cell(NumberOfFiles,1);
singleStepStepHeights = cell(NumberOfFiles,1);
allFirstFrameIntensities = cell(NumberOfFiles,1);
dimerRelativeStepHeights = cell(NumberOfFiles,1);
allFirstStepMeans = cell(NumberOfFiles,1);

allResults = zeros(24,1);

for fileToCheck = 1:NumberOfFiles
    traces=csvread(channel1{fileToCheck},1);
    stepPoints = csvread([fileparts(channel1{fileToCheck}) filesep 'Channel_1_StepPoints.csv'],1);
    stepMeans = csvread([fileparts(channel1{fileToCheck}) filesep 'Channel_1_StepMeans.csv'],1);
    stepNum = arrayfun(@(z) find(stepMeans(z,:)~=0,1,'last')-1,1:length(stepMeans))';
    stepHeights = cell2mat(arrayfun(@(z) resize(diff(stepMeans(z,stepMeans(z,:)~=0)),[1 size(stepMeans,2)-1]),1:length(stepNum),'UniformOutput',false)');
    posStepQ = max(stepHeights')>0.1.*max(stepMeans');
    
    selectQ = cell2mat(arrayfun(@(z) (sum((stepHeights'<-maxStepRatio./z.*max(stepMeans') & ~posStepQ))>z-1)',1:4,'UniformOutput',false))';
    selectQ(5,:) = (sum(selectQ)==0);

    allStepCounts{fileToCheck} = arrayfun(@(z) find(selectQ(:,z)==1,1), 1:size(selectQ,2));
    
    singleStepTraces{fileToCheck} = traces(selectQ(1,:),:);

    maxStepHeights = -min(stepHeights'); 
    singleStepStepHeights{fileToCheck} = maxStepHeights(selectQ(1,:))';

    stepPoints = arrayfun(@(z) stepPoints(z,find(stepHeights(z,:) == min(stepHeights(z,:)),1)+1),1:size(stepHeights,1))';
    singleStepStepFrames{fileToCheck} = stepPoints(selectQ(1,:),1);

    allFirstFrameIntensities{fileToCheck} = traces(:,2);

    allFirstStepMeans{fileToCheck} = stepMeans(:,1);

    maxStepHeights = stepHeights(selectQ(2,:),:);
    stepMeans = stepMeans(selectQ(2,:),:);
    stepMeans = max(stepMeans')';
    dimerRelativeStepHeights{fileToCheck} = -cell2mat(arrayfun(@(z) maxStepHeights(z,maxStepHeights(z,:)<-maxStepRatio/2.*stepMeans(z)),1:length(stepMeans),'UniformOutput',false)');
end

% Get the intensity ratios for each labelling ratio
stepCounts = cell2mat(allStepCounts')';
stepMeans = cell2mat(allFirstStepMeans);
intensityRatio = arrayfun(@(z) mean(stepMeans(stepCounts==z))./mean(stepMeans(stepCounts==1)),1:4);
countRatio = arrayfun(@(z) nnz(stepCounts==z)./nnz(stepCounts<5),1:4);

allResults(1) = length(stepCounts)/NumberOfFiles;
allResults(2:5) = 100.*countRatio;

allResults(6:8) = intensityRatio(2:4);

%% Combined Bleaching Rate

stepPoints = cell2mat(singleStepStepFrames);

% stepCounts = cell2mat(allStepCounts');
% stepMeans = cell2mat(allFirstStepMeans);
% stepMeans = stepMeans(stepCounts==1);
% stepPoints = stepPoints(stepMeans>300);


x = 0:max(stepPoints);
y = 100.*arrayfun(@(z) nnz(stepPoints>z),x)./length(stepPoints);


%singlePopPercent = sum(classCounts(1,:))./(sum(classCounts(1,:))+sum(classCounts(2,:)));
%y = y.*singlePopPercent+100.*(1-singlePopPercent);


by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
OLS = @(b) sum((by(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [100 1/mean(stepPoints) 0], opts);


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
plot(x,y,'LineWidth',2)
plot(x,by(bestFitParams,x),'--')

ylim([0 100])
xlim([0 4./bestFitParams(2)])
xlabel('Frames')
ylabel('Remaining Particles (%)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Bleaching_Survival_Curve'], '-dpng', '-r600');
print([saveFolder 'Bleaching_Survival_Curve'], '-depsc', '-r600');

allResults(9) = bestFitParams(2);
allResults(10) = 1./bestFitParams(2);
allResults(11) = log(10/9)./bestFitParams(2);
allResults(12) =  log(2)./bestFitParams(2);

disp(['The pooled bleaching rate of ' num2str(bestFitParams(2)) ' per frame corresponds to a mean of ' num2str(1./bestFitParams(2)) ...
        ' and a 10% beaching frame of ' num2str(log(10/9)./bestFitParams(2))]);

%% As a log plot
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
plot(x,100-y,'LineWidth',2)
plot(x,100-by(bestFitParams,x),'--')

ylim([0 100])
xlim([1 max(x)])
xlabel('Frames')
ylabel('Bleached (%)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Log_Bleaching_Survival_Curve'], '-dpng', '-r600');
print([saveFolder 'Log_Bleaching_Survival_Curve'], '-depsc', '-r600');
%% Intensity vs Bleach Rate
stepPoints = cell2mat(singleStepStepFrames);
stepCounts = cell2mat(allStepCounts');
stepMeans = cell2mat(allFirstStepMeans);
stepMeans = stepMeans(stepCounts==1);

delta = 0.02*(mean(stepMeans)+3.*std(stepMeans));
x = 0:delta:mean(stepMeans)+3*std(stepMeans);
y = arrayfun(@(z) 1/mean(stepPoints(stepMeans>z-delta/2 & stepMeans<z+delta/2)),x);
len = arrayfun(@(z) nnz(stepMeans>z-delta/2 & stepMeans<z+delta/2),x);

x = x(len>10);
y = y(len>10);

linFit(1) = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));
linFit(2) = (dot(x,y).*max(size(x))-sum(x).*sum(y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
scatter(x,y)
plot([0 max(x)],linFit(1)+[0 max(x)].*linFit(2),'LineWidth',2) 
ylim([0 max(y)])
xlim([0 max(x)])
xlabel('Intensity (a.u.)')
ylabel('Bleach Rate (1/frames)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'BleachRate_vs_Intensity'], '-dpng', '-r600');
print([saveFolder 'BleachRate_vs_Intensity'], '-depsc', '-r600');  


%% Measure Read Noise

stepPoints = cell2mat(singleStepStepFrames);
stepMeans = cell2mat(singleStepStepHeights);
traces = cell2mat(singleStepTraces);

%measurementError = cell2mat(arrayfun(@(z) (traces(z,1:stepPoints(z))-stepMeans(z))./sqrt(stepMeans(z)),1:size(traces,1),'UniformOutput',false));
measurementError = cell2mat(arrayfun(@(z) (traces(z,1:stepPoints(z))-stepMeans(z)),1:size(traces,1),'UniformOutput',false));


x = -3*std(measurementError):std(measurementError)/100:3*std(measurementError);
y = arrayfun(@(z) nnz(measurementError<z),x)./length(measurementError);
by2 = @(b,bx)( normcdf(x,b(1),b(2)));             % Objective function
OLS = @(b) sum((by2(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams2 = fminsearch(OLS, [0 std(measurementError)], opts);


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
histogram(measurementError,'Normalization','pdf')
plot(x(1:end-1),diff(by2(bestFitParams2,x))/mean(diff(x)),'LineWidth',2) 
%plot(x,y,'LineWidth',2)
%plot(x,by(bestFitParams2,x),'--') 

xlim([min(x) max(x)])
xlabel('Read Noise (a.u.)')
ylabel('Prob. Density')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Measurement_Error'], '-dpng', '-r600');
print([saveFolder 'Measurement_Error'], '-depsc', '-r600');  

allResults(13) = bestFitParams2(2);
%% measurement error versus intensity
stepPoints = cell2mat(singleStepStepFrames);
stepMeans = cell2mat(singleStepStepHeights);
traces = cell2mat(singleStepTraces);

measurementError = arrayfun(@(z) std(traces(z,1:stepPoints(z))),1:size(traces,1));
stepMeans = stepMeans(measurementError>0.01);
measurementError = measurementError(measurementError>0.01);

delta = 0.02*(mean(stepMeans)+3.*std(stepMeans));
x = 0:delta:mean(stepMeans)+3*std(stepMeans);
y = arrayfun(@(z) mean(measurementError(stepMeans>z-delta/2 & stepMeans<z+delta/2)),x);
len = arrayfun(@(z) nnz(stepMeans>z-delta/2 & stepMeans<z+delta/2),x);

x = x(len>10);
y = y(len>10);

linFit(1) = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));
linFit(2) = (dot(x,y).*max(size(x))-sum(x).*sum(y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
scatter(x,y)
plot([0 max(x)],linFit(1)+[0 max(x)].*linFit(2),'LineWidth',2) 
ylim([0 max(y)])
xlim([0 max(x)])
xlabel('Intensity (a.u.)')
ylabel('Std.Dev. Intensities (a.u.)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Measurement_Error_vs_Intensity'], '-dpng', '-r600');
print([saveFolder 'Measurement_Error_vs_Intensity'], '-depsc', '-r600');  
%% Fit Single Molecule Intensity

stepMeans = cell2mat(singleStepStepHeights);

x = mean(stepMeans)-4*std(stepMeans):std(stepMeans)/100:mean(stepMeans)+4*std(stepMeans);
x = x(x>0);
y = 100.*arrayfun(@(z) nnz(stepMeans<z),x)./length(stepMeans);

middleThird = @(z)(z(length(z)/3+1:2*length(z)/3));
by3 = @(b,bx)(mean(diff(bx)).*middleThird(100.*conv([zeros(1,length(bx)) normcdf(log(bx),b(1),b(2)) (1+zeros(1,length(bx)))],normpdf(bx,max(bx)/2,b(3)),'same')));
OLS = @(b) sum((by3(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams3 = fminsearch(OLS, [log(median(stepMeans)) sqrt(log(var(stepMeans))) bestFitParams2(2)*sqrt(bestFitParams(2))], opts);


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
histogram(stepMeans,'Normalization','pdf')
plot(x(1:end-1),0.01.*diff(by3(bestFitParams3,x))/mean(diff(x)),'LineWidth',2) 

%plot(x,y,'LineWidth',2)
%plot(x,by3(bestFitParams3,x),'--') 
xlim([min(x) max(x)])
xlabel('Single Step Heights (a.u.)')
ylabel('Prob. Density')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Intensity_Distribution'], '-dpng', '-r600');
print([saveFolder 'Intensity_Distribution'], '-depsc', '-r600');  
baselineNormalNoiseStdDev = sqrt(max(bestFitParams3(3)^2-(bestFitParams2(2)*sqrt(bestFitParams(2))).^2,0));
xZero = exp(bestFitParams3(1));

allResults(14) = mean(stepMeans);
allResults(15) = xZero;
allResults(16) = bestFitParams3(2);
allResults(17) = baselineNormalNoiseStdDev;

%% Fit Initial Intensities

firstIntensities = cell2mat(allFirstFrameIntensities);

x = 1:max(firstIntensities)/1000:4*max(firstIntensities);
y = 100.*arrayfun(@(z) nnz(firstIntensities<z),x)./length(firstIntensities);


by4 = @(b,bx)( abs(1-abs(b(1)-1)).* by3([log(1.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+1*bestFitParams2(2)^2)],bx)+...
    abs(1-abs(b(2)-1)).* by3([log(2.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+2*bestFitParams2(2)^2)],bx)+...
    abs(1-abs(b(3)-1)).* by3([log(3.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+3*bestFitParams2(2)^2)],bx)+...
    (1-sum(abs(1-abs(b-1)))).* by3([log(4.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+4*bestFitParams2(2)^2)],bx));
OLS = @(b) sum((by4(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams4 = fminsearch(OLS, countRatio(1:3), opts);
bestFitParams4 = abs(1-abs(bestFitParams4-1));
bestFitParams4(4) = (1-sum(bestFitParams4));


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 9;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
histogram(firstIntensities,'Normalization','pdf')
plot(x(1:end-1),0.01.*diff(by4(bestFitParams4,x))/mean(diff(x)),'LineWidth',2) 
%plot(x(1:end-1),0.01.*diff(by4(countRatio,x))/mean(diff(x)),'LineWidth',2) 
for i=1:4
    plot(x(1:end-1),abs(bestFitParams4(i)).*0.01/mean(diff(x)).*diff(by3([log(i.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+i*bestFitParams2(2)^2)],x)),'LineWidth',2)
    %plot(x(1:end-1),abs(countRatio(i)).*0.01/mean(diff(x)).*diff(by3([log(i.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+i*bestFitParams2(2)^2)],x)),'LineWidth',2)

end
xlim([0 prctile(firstIntensities,99.5)])
leg = legend({'','Combined','Monomer','Dimer','Trimer','Tetramer'},'Location','eastoutside','Box','off','FontSize', 9);
leg.ItemTokenSize = [15,30];
hold off
xlabel('Initial Intensity (a.u.)')
ylabel('Prob. Density')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'MultiStep_Fit_nmer_overlay'], '-dpng', '-r600');
print([saveFolder 'MultiStep_Fit_nmer_overlay'], '-depsc', '-r600');  

allResults(18:21) = 100.*bestFitParams4;

allResults(22) = mean(firstIntensities)./xZero;
allResults(23) = sum(bestFitParams4.*[1 2 3 4]);
allResults(24) = mean(firstIntensities);
%% Check intial Dimers
firstIntensities = cell2mat(allFirstFrameIntensities);
stepCounts = cell2mat(allStepCounts');
firstIntensities = firstIntensities(stepCounts==2);

x = 1:max(firstIntensities)/1000:4*max(firstIntensities);
y = 100.*arrayfun(@(z) nnz(firstIntensities<z),x)./length(firstIntensities);


by4 = @(b,bx)( b(1).* by3([log(2.*xZero) bestFitParams3(2) sqrt(baselineNormalNoiseStdDev^2+2*bestFitParams2(2)^2)],bx));
OLS = @(b) sum((by4(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams5 = fminsearch(OLS, [1], opts);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 9;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
histogram(firstIntensities,'Normalization','pdf')
plot(x(1:end-1),0.01.*diff(by4(bestFitParams5,x))/mean(diff(x)),'LineWidth',2) 
xlim([0 prctile(firstIntensities,99.5)])
hold off
xlabel('Initial Intensity (a.u.)')
ylabel('Prob. Density')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Dimer_Fit_overlay'], '-dpng', '-r600');
print([saveFolder 'Dimer_Fit_overlay'], '-depsc', '-r600');  
%% Relative Dimer Step Height
stepHeights = cell2mat(dimerRelativeStepHeights);
stepMeans = cell2mat(singleStepStepHeights);
%stepHeights = stepHeights(:,2)./stepHeights(:,1);
delta = (mean(stepMeans) + 4*std(stepMeans))/30;
x = 1:delta:(mean(stepMeans) + 4*std(stepMeans));

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
y = 100.*arrayfun(@(z) nnz(stepMeans>z-delta/2 & stepMeans<z+delta/2),x)./length(stepMeans)./delta;
plot(x,y,'LineWidth',2)
y = 100.*arrayfun(@(z) nnz(stepHeights(:,1)>z-delta/2 & stepHeights(:,1)<z+delta/2),x)./length(stepHeights)./delta;
plot(x,y,'LineWidth',2)
y = 100.*arrayfun(@(z) nnz(stepHeights(:,2)>z-delta/2 & stepHeights(:,2)<z+delta/2),x)./length(stepHeights)./delta;
plot(x,y,'LineWidth',2)
hold off
leg = legend({'Single Step', 'Two Step First', 'Two Step Second'},'Location','northeast','Box','off','FontSize', 9);
leg.ItemTokenSize = [15,30];
xlabel('Step Height (a.u.)')
ylabel('Prob. Density')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Dimer_Step Height_overlay'], '-dpng', '-r600');
print([saveFolder 'Dimer_Step Height_overlay'], '-depsc', '-r600'); 
%% Summerise Results

f=figure;
set(gcf, 'Position', [100, 100, 600, 500])
t=uitable(f,'Data',allResults,'Position', [0, 0, 600, 500]);
outputNames = {'Mean Particles per FOV','One Step Percent','Two Step Percent','Three Step Percent','Four Step Percent','Two Step Initial Intensity Ratio','Three Step Initial Intensity Ratio','Four Step Initial Intensity Ratio','Bleach Rate per Frame', 'Mean Bleach Frame','10% Bleaching Frame','Bleaching Half Life'...
    'Read Noise (Std. Dev.)','Mean Single Step Intensity','Log Normal Fit Mean','Log Normal Shape Parameter','Baseline Normal Noise Std Dev','Monomer Fit Percent','Dimer Fit Percent','Trimer Fit Percent','Tetramer Fit Percent','Label Ratio (All Initial/Single Steps)','Label Ratio (Distribution Fit)','Mean Initial Intensity'};
t.RowName = outputNames;
 
outputNames = replace(replace(outputNames,' ','_'),'%','p.c.');
T = array2table(allResults);
T.Properties.RowNames = outputNames;
writetable(T, [saveFolder,'Bleaching_Summary.csv'],'WriteRowNames',true);





























    