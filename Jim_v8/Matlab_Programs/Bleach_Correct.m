%%
clear
%% 1) Select Input Folder
numberOfChannels = 2;

sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
sysVar.fileName=[sysVar.fileName,filesep]; 

sysVar.allFiles = dir(fullfile(sysVar.fileName, '**\*.*'));
sysVar.toselect = arrayfun(@(z)contains([sysVar.allFiles(z).name],'Channel_1_Fluorescent_Intensities.csv','IgnoreCase',true),1:length(sysVar.allFiles));

sysVar.allFiles = arrayfun(@(z)sysVar.allFiles(z).folder,find(sysVar.toselect),'UniformOutput',false)';

clear("allData");
for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    for i=1:numberOfChannels
        allData(j).intensityFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
        allData(j).backgroundFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
        allData(j).bleachCorrectedFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Corrected.csv'];
        allData(j).bleachFitFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_Bleach_Fit.csv'];
        allData(j).stepPointsFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepPoints.csv'];
        allData(j).stepMeansFileNames{i} = [sysVar.allFiles{j} filesep 'Channel_',num2str(i),'_StepMeans.csv'];
    end
end

NumberOfFiles=length(sysVar.allFiles);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

%%
bleachCorrectChannel = 2;
meanBleachFrame = 27.26*10;


allSteps = cell(NumberOfFiles,1);

parfor fileNo=1:length(allData)
    

    traces = csvread(allData(fileNo).intensityFileNames{bleachCorrectChannel},1);

    disp([fileNo,size(traces,1) ,size(traces,2)]);

    Amat = zeros(length(traces(1,:)),length(traces(1,:)));
    for i=1:length(traces(1,:))
        for j=1:i
            Amat(i,j) = exp((j-i)./meanBleachFrame);
        end
    end

    correctedSteps = cell2mat(arrayfun(@(z) lsqnonneg(Amat,traces(z,:)') ,1:size(traces,1),'UniformOutput' ,false))';

    bleachCorrected = cumsum(correctedSteps')';

    bleachFit = cell2mat(arrayfun(@(z) Amat*(correctedSteps(z,:)') ,1:size(traces,1),'UniformOutput' ,false))';

    outputString = ['Each row is a particle. Each column is a Frame,Bleach Corrected With Mean Bleach Frame =,' num2str(meanBleachFrame) '\n ' strjoin(arrayfun(@(z) strjoin(arrayfun(@num2str,bleachCorrected(z,:),'UniformOutput',false),','),1:size(bleachCorrected,1),'UniformOutput',false),'\n')];

    fileID = fopen(allData(fileNo).bleachCorrectedFileNames{bleachCorrectChannel},'w');
    fprintf(fileID, outputString);
    fclose(fileID);


    outputString = ['Each row is a particle. Each column is a Frame,Bleach Corrected With Mean Bleach Frame =,' num2str(meanBleachFrame) '\n ' strjoin(arrayfun(@(z) strjoin(arrayfun(@num2str,bleachFit(z,:),'UniformOutput',false),','),1:size(bleachFit,1),'UniformOutput',false),'\n')];


    fileID = fopen(allData(fileNo).bleachFitFileNames{bleachCorrectChannel},'w');
    fprintf(fileID, outputString);
    fclose(fileID);

    correctedSteps = correctedSteps(:);
    correctedSteps = correctedSteps(correctedSteps>0.0001);
    allSteps{fileNo} = correctedSteps;

end

%%
fileNo=23;
traces = csvread(allData(fileNo).intensityFileNames{bleachCorrectChannel},1);
bleachFit = csvread(allData(fileNo).bleachFitFileNames{bleachCorrectChannel},1);
bleachCorrected = csvread(allData(fileNo).bleachCorrectedFileNames{bleachCorrectChannel},1);

traceNo = 150;
figure
hold on
plot(traces(traceNo,:))
plot(bleachFit(traceNo,:))
plot(bleachCorrected(traceNo,:))
hold off

%%
combinedSteps = cell2mat(allSteps);
disp(mean(combinedSteps))
combinedSteps = combinedSteps(combinedSteps<prctile(combinedSteps,99));
%%
figure
histogram(combinedSteps)
disp(mean(combinedSteps))
%%
x = 1:max(combinedSteps)/1000:max(combinedSteps);
y = 100.*arrayfun(@(z) nnz(combinedSteps>z),x)./length(combinedSteps);

by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
OLS = @(b) sum((by(b,x) - y).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
bestFitParams = fminsearch(OLS, [100 1/mean(combinedSteps) 0], opts);


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
plot(x,y,'LineWidth',2)
plot(x,by(bestFitParams,x),'--')

ylim([0 100])
xlim([0 3./bestFitParams(2)])
xlabel('Step Height')
ylabel('Steps Larger (%)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
disp(1./bestFitParams(2))
%print([saveFolder 'Step_Height_Fit'], '-dpng', '-r600');
%print([saveFolder 'Step_Height_Fit'], '-depsc', '-r600');
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 7;opts.height= 5;opts.fontType= 'Myriad Pro';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('XScale', 'log', 'YScale', 'linear','LineWidth',1.5, 'FontName','Myriad Pro')
hold on
plot(x,100-y,'LineWidth',2)
plot(x,100-by(bestFitParams,x),'--')

ylim([0 100])
xlim([1 max(x)])
xlabel('Step Height')
ylabel('Steps Smaller (%)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
%print([saveFolder 'Log_Bleaching_Survival_Curve'], '-dpng', '-r600');
%print([saveFolder 'Log_Bleaching_Survival_Curve'], '-depsc', '-r600');
%%
meanSteps = arrayfun(@(z) mean(allSteps{z}),1:NumberOfFiles);

figure
scatter(1:NumberOfFiles,meanSteps)
%%
figure
hold on
for fileNo=[1 10]
traces = csvread(allData(fileNo).intensityFileNames{bleachCorrectChannel},1);
bleachFit = csvread(allData(fileNo).bleachFitFileNames{bleachCorrectChannel},1);
bleachCorrected = csvread(allData(fileNo).bleachCorrectedFileNames{bleachCorrectChannel},1);

plot(mean(bleachCorrected))
end
hold off