%%
clear
%% 1) Select Input Folder
numberOfChannels = 2;
stepFitting = true;
stepFitChannel = 1;

filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep]; 

sysVar.allFolders = arrayfun(@(x)[sysVar.fileName,x.name],dir(sysVar.fileName),'UniformOutput',false); % find everything in the input folder
sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
sysVar.allFolders = sysVar.allFolders(3:end);
sysVar.allFolders = arrayfun(@(x)[x{1},filesep],sysVar.allFolders,'UniformOutput',false);

if filesInSubFolders
    sysVar.allSubFolders = sysVar.allFolders;
    sysVar.allFolders = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allSubFolders,'UniformOutput',false);
    sysVar.allFolders = arrayfun(@(x)x{:}(3:end),sysVar.allFolders,'UniformOutput',false);
    sysVar.allFolders = horzcat(sysVar.allFolders{:})';
    sysVar.allFolders = sysVar.allFolders(arrayfun(@(x) isfolder(cell2mat(x)),sysVar.allFolders));
    sysVar.allFolders = arrayfun(@(x)[x{1},filesep],sysVar.allFolders,'UniformOutput',false);
end

sysVar.allFiles = arrayfun(@(y)arrayfun(@(x)[cell2mat(y),x.name],dir(cell2mat(y))','UniformOutput',false),sysVar.allFolders','UniformOutput',false);
sysVar.allFiles = horzcat(sysVar.allFiles{:})';

sysVar.allFiles = sysVar.allFiles(contains(sysVar.allFiles,'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true));

allTraceNames = cell(size(sysVar.allFiles,1),2*(numberOfChannels+stepFitting));
for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    for i=1:numberOfChannels
    allData(j).intensityFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
    allData(j).backgroundFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
    end
    if stepFitting
        allData(j).stepPoints = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(stepFitChannel),'_StepPoints.csv'];
        allData(j).stepMeans = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(stepFitChannel),'_StepMeans.csv'];
    end
end

NumberOfFiles=length(allData);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select the folder to save output images to
sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
saveFolder=[sysVar.fileName,filesep];

%% detect experiment settings
concentrationIdentifier = {'_0uM','250uM','_500uM','_750uM','_1000uM'};
concentrations = [0,250,500,750,1000];

minutesPerFrameIdentifier = {'CPSF6'};
minutesPerFrame = [1];

reagentIdentifier = {'CPSF6'};

replicateIdentifier = {'P1'};

for i=1:NumberOfFiles
    for j=1:length(concentrationIdentifier)
        if contains(allData(i).intensityFileNames(1),concentrationIdentifier(j),'IgnoreCase',true) 
            allData(i).concentration = concentrations(j);
            allData(i).expNo = j;
            break;
        end
    end
    for j=1:length(minutesPerFrameIdentifier)
        if contains(allData(i).intensityFileNames(1),minutesPerFrameIdentifier(j),'IgnoreCase',true) 
            allData(i).MPF = minutesPerFrame(j);
            allData(i).expNo = allData(i).expNo*j;
            break;
        end
    end
    for j=1:length(reagentIdentifier)
        if contains(allData(i).intensityFileNames(1),reagentIdentifier(j),'IgnoreCase',true) 
            allData(i).reagent = j;
            allData(i).expNo = allData(i).expNo*j;
            break;
        end
    end
    for j=1:length(replicateIdentifier)
        if contains(allData(i).intensityFileNames(1),replicateIdentifier(j),'IgnoreCase',true) 
            allData(i).rep = j;
            allData(i).expNo = allData(i).expNo*j;
            break;
        end
    end
end
%% Group FOV from the same experiment and read in data
sysVar.detectedExps = sort(unique([allData.expNo]));
numOfExps = length(sysVar.detectedExps);
for i=1:numOfExps
    expData(i).allTraces = cell(numberOfChannels,1);
    for j=1:numberOfChannels
        expData(i).allTraces{j} = cell2mat(arrayfun(@(z) csvread(allData(z).intensityFileNames{1},1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))';
    end
    expData(i).concentration = allData(sysVar.detectedExps(i)).concentration;
    expData(i).MPF = allData(sysVar.detectedExps(i)).MPF;
    expData(i).reagent = allData(sysVar.detectedExps(i)).reagent;
    
    if stepFitting
        expData(i).stepMeans = arrayfun(@(z) csvread(allData(z).stepMeans,1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false);
        sysvar.maxsize = max(arrayfun(@(z)size(expData(i).stepMeans{z},1),1:length(expData(i).stepMeans)));
        expData(i).stepMeans = cell2mat(arrayfun(@(z)resize(expData(i).stepMeans{z},[sysvar.maxsize size(expData(i).stepMeans{z},2)]),1:length(expData(i).stepMeans),'UniformOutput',false))';
        expData(i).stepPoints = arrayfun(@(z) csvread(allData(z).stepPoints,1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false);
        sysvar.maxsize = max(arrayfun(@(z)size(expData(i).stepPoints{z},1),1:length(expData(i).stepPoints)));
        expData(i).stepPoints = cell2mat(arrayfun(@(z)resize(expData(i).stepPoints{z},[sysvar.maxsize size(expData(i).stepPoints{z},2)]),1:length(expData(i).stepPoints),'UniformOutput',false))';

    end
end

%% View inital intensities
expToCheck=1;
figure
histogram(cell2mat(arrayfun(@(z) expData(z).stepMeans(:,1),1:numOfExps,'UniformOutput',false)'))
xlabel('Initial Intensity')
ylabel('count')

%% 3) View Single Step Filters

    expToCheck=1;
    pageNumber = 1;
    
    minInitialIntensity = 100;
    maxInitialIntensity = 15000;
   
    
    maxSecondMeanFirstMeanRatio = 0.25; %Ratio of step heights -  1000 for no step fitting
    
    noStepMinRatio = 0.5;%If step height ratio is greater than this for no step
    
    ch1traces=csvread(sysVar.allFiles{expToCheck},1);
    stepsdata = csvread([fileparts(sysVar.allFiles{expToCheck}) filesep 'Stepfit_Single_Step_Fits.csv'],1);

    
    particleTypeQ = cell(4,NumberOfFiles);%No pop, leaky,opening,closed,other
    particleTypeNames = {'Single Step','Closed','No Pop','Other'};
    
    ch1traces=csvread(sysVar.allFiles{expToCheck},1);
    stepsdata = csvread([fileparts(sysVar.allFiles{expToCheck}) filesep 'Stepfit_Single_Step_Fits.csv'],1);
   
    %Single Step
    particleTypeQ{1,expToCheck} = stepsdata(:,3)>minFirstStepProb & stepsdata(:,5) < maxVLPInt  & stepsdata(:,5)>0 & abs(stepsdata(:,6)) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb ;
    %Closed
    particleTypeQ{2,expToCheck} = abs(stepsdata(:,6)) >noStepMinRatio .* stepsdata(:,5) & stepsdata(:,5) < maxVLPInt & stepsdata(:,6)> noStepMinIntesntiy & ~particleTypeQ{1,expToCheck} ;
    %No Pop
    particleTypeQ{3,expToCheck} = stepsdata(:,5) > maxVLPInt;
    %other
    particleTypeQ{4,expToCheck} = ~particleTypeQ{1,expToCheck} & ~particleTypeQ{2,expToCheck} & ~particleTypeQ{3,expToCheck};
    
  %Plot Traces based on class
  for plottype=1:size(particleTypeQ,1)
    ch1traces=csvread(sysVar.allFiles{expToCheck},1);  
    ch1traces = ch1traces(particleTypeQ{plottype,expToCheck},:);
    if twochannel
        ch2traces = csvread(channel2{expToCheck},1);
        ch2traces = ch2traces(particleTypeQ{plottype,expToCheck},:);
    end 
   
    figure('Name',particleTypeNames{plottype})
    set(gcf, 'Position', [100, 100, 700, 800])
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',2, 'FontName','Times')
    ax = gca;
    for i=1:32
        if size(ch1traces,1)>=i+36*(pageNumber-1)
            subplot(8,4,i)
            hold on
            colororder([0 158/255 115/255;1 0 1])
            if i>=28
                xlabel('Time (minutes)')
            end
            if mod(i,4)==1
            ylabel('VLP Int.')
            end

            toplot = ch1traces(i+36*(pageNumber-1),:);
            plot([1:size(ch1traces(i+36*(pageNumber-1),:),2)].*minutesPerFrame(expToCheck),toplot,'LineWidth',1.5);
            plot([0 size(ch1traces(i+36*(pageNumber-1),:),2)].*minutesPerFrame(expToCheck),[0 0] ,'-black');
            ylim([min([-0.2.*max(toplot) min(toplot)]) max(toplot)])
            %xlim([0 size(ch1traces(i+36*(pageNumber-1),:),2)]);
            xlim([0 size(ch1traces(i+36*(pageNumber-1),:),2)].*minutesPerFrame(expToCheck))

            hold off
        end
    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    print([saveFolder 'Example_' particleTypeNames{plottype} '_Traces_File_' num2str(expToCheck) '_Page_' num2str(pageNumber)], '-dpng', '-r600');
    print([saveFolder 'Example_' particleTypeNames{plottype} '_Traces_File_' num2str(expToCheck) '_Page_' num2str(pageNumber)], '-dsvg', '-r600');
  end

%% Classify All files
allSingleStepsData = cell(NumberOfFiles,1);
for expToCheck = 1:NumberOfFiles
    ch1traces=csvread(sysVar.allFiles{expToCheck},1);
    stepsdata = csvread([fileparts(sysVar.allFiles{expToCheck}) filesep 'Stepfit_Single_Step_Fits.csv'],1);
   
    %Single Step
    particleTypeQ{1,expToCheck} = stepsdata(:,3)>minFirstStepProb & stepsdata(:,5) < maxVLPInt  & stepsdata(:,5)>0 & abs(stepsdata(:,6)) < maxSecondMeanFirstMeanRatio .* stepsdata(:,5) & stepsdata(:,7)<maxMoreStepProb ;
    %Closed
    particleTypeQ{2,expToCheck} = abs(stepsdata(:,6)) >noStepMinRatio .* stepsdata(:,5) & stepsdata(:,5) < maxVLPInt & stepsdata(:,6)> noStepMinIntesntiy & ~particleTypeQ{1,expToCheck};
    %No Pop
    particleTypeQ{3,expToCheck} = stepsdata(:,5) > maxVLPInt;
    %other
    particleTypeQ{4,expToCheck} = ~particleTypeQ{1,expToCheck} & ~particleTypeQ{2,expToCheck} & ~particleTypeQ{3,expToCheck};
    
    allSingleStepsData{expToCheck} = stepsdata(particleTypeQ{1,expToCheck},:);
end 

classCounts = cell2mat(arrayfun(@(y) arrayfun(@(x) nnz(particleTypeQ{y,x}),1:NumberOfFiles),1:4,'UniformOutput',false)');
classcountPerCon =cell2mat(arrayfun(@(x) sum(classCounts(:,concentrations == uniqueCons(x))')',1:length(uniqueCons),'UniformOutput',false));
%%
figure
bar(uniqueCons,100.*classcountPerCon(1,:)./(classcountPerCon(1,:)+classcountPerCon(2,:)))
ylabel('Opened Capsids after 6 hours (%)')
xlabel('Concentration (uM)')
print([saveFolder 'Capsid_Opening_Percents'], '-dpng', '-r600');
print([saveFolder 'Capsid_Opening_Percents'], '-depsc', '-r600');

%%
combStepsData = cell(length(uniqueCons),1);
for i=1:length(uniqueCons)
    combStepsData{i} = cell2mat(allSingleStepsData(concentrations == uniqueCons(i)));
end
%% Survival Curves
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 1:length(uniqueCons)
    toplot = combStepsData{fileNo};
    stepTimes = toplot(:,4)*uniqueMinutesPerFrame(fileNo);
    x = 0:uniqueMinutesPerFrame(fileNo):360;
    y =arrayfun(@(z)nnz(stepTimes>z),x)./size(stepTimes,1);
    ypercent = 100.*(y.*classcountPerCon(1,fileNo)./(classcountPerCon(1,fileNo)+classcountPerCon(2,fileNo))+classcountPerCon(2,fileNo)./(classcountPerCon(1,fileNo)+classcountPerCon(2,fileNo)));
    plot(x./60,ypercent,'LineWidth',2)


end
xlim([0 6])
xlabel('Time (hours)')
ylabel('Intact Capsids (%)')
leg = legend(arrayfun(@(x)[num2str(x),' uM'],uniqueCons,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'survival_curves'], '-dpng', '-r600');
print([saveFolder 'survival_curves'], '-depsc', '-r600');
%% Opening Rates

figure
hold on
expfits = zeros(length(uniqueCons),3);
for fileNo = 1:length(uniqueCons)
    toplot = combStepsData{fileNo};
    stepTimes = toplot(:,4)*uniqueMinutesPerFrame(fileNo);
    x = 0:uniqueMinutesPerFrame(fileNo):360;
    y =arrayfun(@(z)nnz(stepTimes>z),x)./size(stepTimes,1);

    
    
    guess = [max(y) 1./x(nnz(y>max(y)/2)) min(y)]; % initial guess of parameters
    eqn = @(p,x)( p(1).*exp(-p(2).*x)+p(3));%p = parameter   
    OLS = @(p) sum((eqn(p,x) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',5000000, 'MaxIter',1000000);
    expfits(fileNo,:) = fminsearch(OLS, guess, opts);
    
    plot(x,y)
    plot(x,eqn(expfits(fileNo,:),x))
end
hold off

%% Opening Rates
figure
bar(uniqueCons,1./expfits(:,2)./60)
ylabel('Mean Opening Time (hours)')
xlabel('Concentration (uM)')
print([saveFolder 'Capsid_Mean_Opening_Times'], '-dpng', '-r600');
print([saveFolder 'Capsid_Mean_Opening_Times'], '-depsc', '-r600');

















%%
figure 
hold on
allHalfLives = [];
for fileNo = 1:expTotNum
    if expCons(fileNo)>0.0001
        stepTimes = expMPF(fileNo).*cell2mat(allSingleStepTimes(expPos==fileNo));
        x = 0:expMPF(fileNo):max(stepTimes);
        y =arrayfun(@(z)nnz(stepTimes>z),x)./size(stepTimes,1);
        classin = sum(classCounts(:,expPos==fileNo)');
        y2 = (y.*classin(1)+classin(2))./(classin(1)+classin(2));

        plot(x,100.*y2,'LineWidth',2)

        pos = find(y2<0.6,1);
        allHalfLives = [allHalfLives (x(pos)+x(pos-1))/2];
    else
        allHalfLives = [allHalfLives 0];
    end
end
hold off
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(expCons(expCons>0.1),allHalfLives(expCons>0.1))
xlabel('Lenacapavir Concentration (nM)')
ylabel('Capsid Opening Half-Life (mins)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Capsid Opening Half-Life'], '-dpng', '-r600');
print([saveFolder 'Capsid Opening Half-Life'], '-depsc', '-r600');
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(expCons(expCons>0.1),allHalfLives(expCons>0.1))
xlabel('Lenacapavir Concentration (nM)')
ylabel('Capsid Opening Half-Life (mins)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'LogLinear_Capsid Opening Half-Life'], '-dpng', '-r600');
print([saveFolder 'LogLinear_Capsid Opening Half-Life'], '-depsc', '-r600');
%%
mean(allHalfLives(expCons<0.8 & expCons>0.1))
mean(allHalfLives( expCons>14))
%% mean ch2 traces - Note require all experiments at a concentration to be same seconds per frame
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 1:size(uniqueCons,2)
    
    ch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    %ch2traces = mean(cell2mat(allSingleStepch2(uniqueCons(fileNo)==concentrations)));
    plot([1:size(ch2traces,2)].*uniqueMinutesPerFrame(fileNo),ch2traces,'LineWidth',2)
    
end
xlim([0 280])
%ylim([0 100])
xlabel('Time (mins)')
ylabel('CPSF6 Signal')
leg = legend(arrayfun(@(x)[num2str(x),' nM'],uniqueCons,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
%print([saveFolder 'Mean_CPSF6_Intensity_vs_Time'], '-dpng', '-r600');
%print([saveFolder 'Mean_CPSF6_Intensity_vs_Time'], '-depsc', '-r600');
%% Normalised intensities zoomed
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 1:size(uniqueCons,2)
    
    ch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    plot([1:size(ch2traces,2)].*uniqueMinutesPerFrame(fileNo),ch2traces./ch2traces(1),'LineWidth',2)
end
xlim([0 280])
xlabel('Time (mins)')
ylabel('Normalised CPSF6 Signal')
leg = legend(arrayfun(@(x)[num2str(x),' nM'],uniqueCons,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Mean_CPSF6_Intensity_vs_Time_Normalised'], '-dpng', '-r600');
print([saveFolder 'Mean_CPSF6_Intensity_vs_Time_Normalised'], '-depsc', '-r600');
%% Normalised intensities zoomed
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 2:size(uniqueCons,2)
    
    ch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    plot([1:size(ch2traces,2)].*uniqueMinutesPerFrame(fileNo),ch2traces./ch2traces(1),'LineWidth',2)
end
xlim([0 90])
xlabel('Time (mins)')
ylabel('Normalised CPSF6 Signal')
leg = legend(arrayfun(@(x)[num2str(x),' nM'],uniqueCons(2:end),'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Mean_CPSF6_Intensity_vs_Time_Normalised_zoomed'], '-dpng', '-r600');
print([saveFolder 'Mean_CPSF6_Intensity_vs_Time_Normalised_zoomed'], '-depsc', '-r600');
%% Exp fit binding curves
figure
hold on
expfits = zeros(expTotNum,3);
for expNo = 1:expTotNum
    y = mean(cell2mat(allSingleAndNoStepch2(expNo==expPos)));
    x = [-1:size(y,2)-2].*expMPF(expNo);
   % y = y(x>40.*expMPF(expNo));
    %x = x(x>40.*expMPF(expNo));
    
    
    guess = [max(y) 1./x(nnz(y>max(y)/2)) min(y)]; % initial guess of parameters
    eqn = @(p,x)( p(1).*exp(-p(2).*x)+p(3));%p = parameter   
    OLS = @(p) sum((eqn(p,x) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',5000000, 'MaxIter',1000000);
    expfits(expNo,:) = fminsearch(OLS, guess, opts);
    
    plot(x,y)
    plot(x,eqn(expfits(expNo,:),x))
end
hold off


%%
figure
scatter(expCons,expfits(:,2))
%%
x = expCons';
y = 1-expfits(:,3)./(expfits(:,1)+expfits(:,3));


    guess = [max(y) 0.25]; % initial guess of parameters
    eqn = @(p,x)( p(1).*x./(p(2)+x));%p = parameter   
    OLS = @(p) sum((eqn(p,x) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',5000000, 'MaxIter',1000000);
    kdFit = fminsearch(OLS, guess, opts);


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(x,y)
plot(0:0.1:15,kdFit(1).*([0:0.1:15]./(kdFit(2)+[0:0.1:15])),'LineWidth',2)
hold off
xlabel('Lenacapavir Concentration (nM)')
ylabel('Lenacapavir Binding (a.u.)')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'kD_curve'], '-dpng', '-r600');
print([saveFolder 'kD_curve'], '-depsc', '-r600');
%%
individualkDs = kdFit(1).*x(x>0.01)./y(x>0.01)-x(x>0.01);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 4;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
ylabel('Lenacapivir Binding Affinity (nM)')
hold on   
    ax = gca;
    
    ax.ColorOrderIndex = 2;
    plot([0.5 1.5],[kdFit(2) kdFit(2)],'LineWidth',2);
    ax.ColorOrderIndex = 2;
    errorbar(1,kdFit(2),std(individualkDs),'LineWidth',2)
    ax.ColorOrderIndex = 1;
    swarmchart(zeros(size(individualkDs,1),1)+1,individualkDs);
    ylim([0 3]);
    xlim([0.25 1.75]);
set(gca,'Layer','top')
set(ax,'xticklabel',[])
set(gca,'XTick',[])
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'kD_Error'], '-dpng', '-r600');
print([saveFolder 'kD_Error'], '-depsc', '-r600');
disp(std(individualkDs))  
%%
x = expCons;
y = expfits(:,2);


y = y(x<25 & x>0.01);
x = x(x<25 & x>0.01);


b = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));
m = (dot(x,y).*max(size(x))-sum(x).*sum(y))/(max(size(x)).*dot(x,x)-sum(x).*sum(x));


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(x,y)
plot([0 15],m.*[0 15]+b,'LineWidth',2)

hold off
xlabel('Lenacapavir Concentration (nM)')
ylabel('k_{Observed} (min^{-1})')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'kObs_curve'], '-dpng', '-r600');
print([saveFolder 'kObs_curve'], '-depsc', '-r600');


%%
koff = b/60;
kon = m/60*10^9;
kd = koff/kon;
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 4;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
ylabel('Lenacapivir Binding Rate (1/(M s))')
hold on   
    ax = gca;
    
    individiualKons = y./(x')./60.*10^9;

    ax.ColorOrderIndex = 2;
    plot([0.5 1.5],[kon kon],'LineWidth',2);
    ax.ColorOrderIndex = 2;
    errorbar(1,kon,std(individiualKons),'LineWidth',2)
    ax.ColorOrderIndex = 1;
    swarmchart(zeros(size(individiualKons,1),1)+1,individiualKons);
    ylim([0 300000]);
    xlim([0.25 1.75]);
set(gca,'Layer','top')
set(ax,'xticklabel',[])
set(gca,'XTick',[])
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'kOn_Error'], '-dpng', '-r600');
print([saveFolder 'kOn_Error'], '-depsc', '-r600');
disp(std(individiualKons))  
%% converting to len binding
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 1:size(uniqueCons,2)
    
    ch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    plot([1:size(ch2traces,2)].*uniqueMinutesPerFrame(fileNo),100./kdFit(1).*(1-ch2traces./ch2traces(1)),'LineWidth',2)
end
xlim([0 90])
xlabel('Time (mins)')
ylabel('Lenacapavir Occupancy(%)')
leg = legend(arrayfun(@(x)[num2str(x),' nM'],uniqueCons(1:end),'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Lenacapavir_Occupancy_vs_Time'], '-dpng', '-r600');
print([saveFolder 'Lenacapavir_Occupancy_vs_Time'], '-depsc', '-r600');

%%
theoryKon = 6.5e+04;
theoryKoff = 1.4e-05;
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 10;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
theoryConIn = [0.75 1 1.5 2 3 5 10 15];
for theoryCon = theoryConIn
    t = 0:90;
    plot(t,100.*theoryCon./(theoryCon+theoryKoff./theoryKon).*(1-exp(-(theoryCon*1e-9*theoryKon+theoryKoff).*t.*60)),'LineWidth',2)
end
xlim([0 90])
xlabel('Time (mins)')
ylabel('Theoretical Lenacapavir Occupancy(%)')
leg = legend(arrayfun(@(x)[num2str(x),' nM'],theoryConIn,'UniformOutput',false),'Location','eastoutside','Box','off','FontSize', 11);
leg.ItemTokenSize = [20,30];
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Lenacapavir_Occupancy_vs_Time_Theory'], '-dpng', '-r600');
print([saveFolder 'Lenacapavir_Occupancy_vs_Time_Theory'], '-depsc', '-r600');
%% Con at pop
popInt = zeros(size(uniqueCons,2),10);
for fileNo = 1:size(uniqueCons,2)
    meanch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    meanBinding = 100./kdFit(1).*(1-meanch2traces./meanch2traces(1));
    pops = cell2mat(allSingleStepTimes(uniqueCons(fileNo)==concentrations));
    for i=1:length(pops)
        xIn = ceil(meanBinding(pops(i))/10);
        if xIn>0 && xIn<11
            popInt(fileNo,xIn) = popInt(fileNo,xIn)+1;
        end
    end
end
%%
   
figure
set(gcf, 'Position', [100, 100, 700, 800])
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',2, 'FontName','Times')
ax = gca;
for fileNo = 1:size(uniqueCons,2)

    subplot(3,3,fileNo)
    hold on
    colororder([0 158/255 115/255;1 0 1])
    if fileNo>=7
        xlabel('Lenacapavir Occupancy(%)')
    end

    if mod(fileNo,3)==1
    ylabel('Percentage of Capsids (%)')
    end
    
    title([num2str(uniqueCons(fileNo)) ' nM'])

    plot(5:10:95,100.*popInt(fileNo,:)/sum(popInt(fileNo,:)),'LineWidth',2)

    ylim([0 50])
    xlim([0 100])

    hold off

end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
print([saveFolder 'Array_Len_Occupancy_at_Pop_vs_Con'], '-dpng', '-r600');
print([saveFolder 'Array_Len_Occupancy_at_Pop_vs_Con'], '-depsc', '-r600');


%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
for fileNo = 1:size(uniqueCons,2)
    plot(5:10:95,100.*popInt(fileNo,:)/sum(popInt(fileNo,:)),'LineWidth',2)
end
hold off

set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';

%% allPops distribution
allPopInt = zeros(20,1);
for fileNo = 1:size(uniqueCons,2)
    meanch2traces = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    meanBinding = 100./kdFit(1).*(1-meanch2traces./meanch2traces(1));
    pops = cell2mat(allSingleStepTimes(uniqueCons(fileNo)==concentrations));
    for i=1:length(pops)
        xIn = ceil(meanBinding(pops(i))/5);
        if xIn>0 && xIn<21
            allPopInt(xIn) =allPopInt(xIn)+1;
        end
    end
end

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
plot(2.5:5:97.5,allPopInt,'LineWidth',2)
hold off
xlabel('Lenacapavir Occupancy(%)')
ylabel('Capsid Openings (Count)')
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Lenacapavir_Occupancy_at_Pop_Distribution'], '-dpng', '-r600');
print([saveFolder 'Lenacapavir_Occupancy_at_Pop_Distribution'], '-depsc', '-r600');
%% mean binding vs con

meanPopInt = zeros(expTotNum,1);

for expNo=1:expTotNum
    meanch2traces = mean(cell2mat(allSingleAndNoStepch2(expNo==expPos)));
    meanBinding = 100./kdFit(1).*(1-meanch2traces./meanch2traces(1));
    pops = cell2mat(allSingleStepTimes(expNo==expPos));

    meanPopInt(expNo) = mean(arrayfun(@(z)meanBinding(pops(z)),1:size(pops,1)));
    
end


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(expCons(expCons>0.01),meanPopInt(expCons>0.01))
hold off
ylabel('Mean Lenacapavir Occupancy at Opening (%)')
xlabel('Lenacapavir Concentration (nM)')
ylim([0 100])
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([saveFolder 'Mean_Len_Occupancy_at_Pop_vs_Con'], '-dpng', '-r600');
print([saveFolder 'Mean_Len_Occupancy_at_Pop_vs_Con'], '-depsc', '-r600');
%% warning may throw an error without running other analysis as well and declaring noPreCons and noPrePopOccupancy
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(expCons(expCons>0.01),meanPopInt(expCons>0.01))
scatter(noPreCons,noPrePopOccupancy,"^")
hold off
ylabel('Mean Lenacapavir Occupancy at Opening (%)')
xlabel('Lenacapavir Concentration (nM)')
ylim([0 100])
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
savefig([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con' '.fig']);
print([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con'], '-dpng', '-r600');
print([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con'], '-depsc', '-r600');
%% warning may throw an error
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
scatter(expCons(expCons>0.01),meanPopInt(expCons>0.01))
scatter(noPreCons,noPrePopOccupancy,"^")
hold off
ylabel('Mean Lenacapavir Occupancy at Opening (%)')
xlabel('Lenacapavir Concentration (nM)')
ylim([0 100])
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
savefig([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con_LogLinear' '.fig']);
print([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con_LogLinear'], '-dpng', '-r600');
print([saveFolder 'Both_Experiments_Mean_Len_Occupancy_at_Pop_vs_Con_LogLinear'], '-depsc', '-r600');
%% global fit everything fit binding curves

x = [];
y = [];
c = [];
for fileNo = 3:length(uniqueCons)
    yin = mean(cell2mat(allSingleAndNoStepch2(uniqueCons(fileNo)==concentrations)));
    yin = yin./yin(2);
    xin = [-1:size(yin,2)-2].*uniqueMinutesPerFrame(fileNo).*60;
    cin = [-1:size(yin,2)-2].*0+uniqueCons(fileNo);
    
    x = [x xin];
    y = [y yin];
    c = [c cin];
end
    guess = [0.59 1e-4 1e-5]; % kmax kon koff
    eqn = @(p,x,c)( 1-p(1).*c./(p(3)./p(2)+c).*(1-exp(-(p(2).*c+p(3)).*x)));%p = parameter   
    OLS = @(p) sum((eqn(p,x,c) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',5000000, 'MaxIter',10000000000);
    globalExpFit = fminsearch(OLS, guess, opts);


plot(0:0.1:15,globalExpFit(1).*([0:0.1:15]./((globalExpFit(3)./globalExpFit(2))+[0:0.1:15])),'LineWidth',2)





























%% Now only prepop
figure
hold on
expfits = zeros(expTotNum,3);
for expNo = 1:expTotNum
    y = cell2mat(allSingleStepch2(expNo==expPos));
    pops = cell2mat(allSingleStepTimes(expNo==expPos));
    x = [1:size(y,2)];
    
    survival =arrayfun(@(z)nnz(pops>z),x)./length(pops);
    y = arrayfun(@(z)mean(y(pops>z,z)),x);
    
    
    x = [1:size(y,2)].*expMPF(expNo);
    
    y = y(x>2 & survival>0.01);
    x = x(x>2 & survival>0.01);
    
    
    guess = [max(y) 1./x(nnz(y>max(y)/2)) min(y)]; % initial guess of parameters
    eqn = @(p,x)( p(1).*exp(-p(2).*x)+p(3));%p = parameter   
    OLS = @(p) sum((eqn(p,x) - y).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',5000000, 'MaxIter',1000000);
    expfits(expNo,:) = fminsearch(OLS, guess, opts);
    
    plot(x,y)
    plot(x,eqn(expfits(expNo,:),x))
end
hold off
%%
figure
scatter(expCons,expfits(:,2))












