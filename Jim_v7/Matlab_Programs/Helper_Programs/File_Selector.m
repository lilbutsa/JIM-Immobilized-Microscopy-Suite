%%
clear
%% 1) Select Input Folder
numberOfChannels = 2;

filesInSubFolders = true;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

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

for j=1:size(sysVar.allFiles,1)
    allData(j).intensityFileNames = cell(numberOfChannels,1);
    allData(j).backgroundFileNames = cell(numberOfChannels,1);
    allData(j).stepPoints = cell(numberOfChannels,1);
    allData(j).stepMeans = cell(numberOfChannels,1);
    for i=1:numberOfChannels
        allData(j).intensityFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
        allData(j).backgroundFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
        allData(j).stepPointsFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(i),'_StepPoints.csv'];
        allData(j).stepMeansFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_',num2str(i),'_StepMeans.csv'];
    end
end

NumberOfFiles=length(allData);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%% Select the folder to save output images to
sysVar.fileName = uigetdir(); % open the dialog box to select the folder for batch files
saveFolder=[sysVar.fileName,filesep];

%% detect experiment settings

concentrationIdentifier = {'_40pM','_60pM','_80pM','_100pM','_150pM'};
concentrations = [40 60 80 100 150];

minutesPerFrameIdentifier = {'_6spf','_24spf','_30spf'};
minutesPerFrame = [6/60, 24/60, 30/60];

reagentIdentifier = {'Batch1' 'Batch2'};

singleMoleculeIntensities = [1 1;1 1];% have one for each channel each line is for each reagent/rep, set it to one to just keep it as camera intensity


replicateIdentifier = {'Rep1','Rep2','Rep3'};

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
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*j;
            break;
        end
    end
    for j=1:length(reagentIdentifier)
        if contains(allData(i).intensityFileNames(1),reagentIdentifier(j),'IgnoreCase',true) 
            allData(i).reagent = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(minutesPerFrameIdentifier)*j;
            break;
        end
    end
    for j=1:length(replicateIdentifier)
        if contains(allData(i).intensityFileNames(1),replicateIdentifier(j),'IgnoreCase',true) 
            allData(i).rep = j;
            allData(i).expNo = allData(i).expNo+length(concentrationIdentifier)*length(minutesPerFrameIdentifier)*length(reagentIdentifier)*j;
            break;
        end
    end
end

% Group FOV from the same experiment and read in data
sysVar.detectedExps = sort(unique([allData.expNo]));
numOfExps = length(sysVar.detectedExps);
for i=1:numOfExps
    expData(i).reagent = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).reagent;
    expData(i).concentration = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).concentration;
    expData(i).MPF = allData(find([allData.expNo]==sysVar.detectedExps(i),1)).MPF;

    expData(i).allTraces = cell(numberOfChannels,1);
    expData(i).allBackgrounds = cell(numberOfChannels,1);
    expData(i).allStepMeans = cell(numberOfChannels,1);
    expData(i).allStepPoints = cell(numberOfChannels,1);
    expData(i).allNumOfSteps = cell(numberOfChannels,1);
    expData(i).allStepHeights = cell(numberOfChannels,1);

    for j=1:numberOfChannels
        expData(i).allTraces{j} = cell2mat(arrayfun(@(z) csvread(allData(z).intensityFileNames{j},1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))'./singleMoleculeIntensities(expData(i).reagent,j);
        expData(i).numOfTraces = size(expData(i).allTraces{1},1);

        if exist(allData(1).backgroundFileNames{j}, 'file')
            expData(i).allBackgrounds{j} = cell2mat(arrayfun(@(z) csvread(allData(z).backgroundFileNames{j},1)',find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false))';
        end

        if exist(allData(1).stepPointsFileNames{j}, 'file')
            sysVar.temp = arrayfun(@(z) csvread(allData(z).stepMeansFileNames{j},1),find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false)';
            sysVar.maxsize = max(arrayfun(@(z)size(sysVar.temp{z},2),1:length(sysVar.temp)));
            expData(i).allStepMeans{j} = cell2mat(arrayfun(@(z)resize(sysVar.temp{z},[size(sysVar.temp{z},1) sysVar.maxsize]),1:length(sysVar.temp),'UniformOutput',false)')./singleMoleculeIntensities(expData(i).reagent,j);

            sysVar.temp = arrayfun(@(z) csvread(allData(z).stepPointsFileNames{j},1),find([allData.expNo]==sysVar.detectedExps(i)),'UniformOutput',false)';
            sysVar.maxsize = max(arrayfun(@(z)size(sysVar.temp{z},2),1:length(sysVar.temp)));
            expData(i).allStepPoints{j} = cell2mat(arrayfun(@(z)resize(sysVar.temp{z},[size(sysVar.temp{z},1) sysVar.maxsize]),1:length(sysVar.temp),'UniformOutput',false)');

            sysVar.temp = expData(i).allStepMeans{j};
            expData(i).allStepHeights{j} = cell2mat(arrayfun(@(z) resize(diff(sysVar.temp(z,sysVar.temp(z,:)~=0)),[1 size(sysVar.temp,2)-1]),1:expData(i).numOfTraces,'UniformOutput',false)')./singleMoleculeIntensities(expData(i).reagent,j);
            expData(i).allNumOfSteps{j} = arrayfun(@(z) nnz(sysVar.temp(z,:))-1,1:length(sysVar.temp));
        end

    end

    
end

%% View inital intensities
toplot = [];
for i=1:numOfExps
    sysVar.temp = expData(i).allStepMeans{1};
    toplot = [toplot;sysVar.temp(:,1)];
end
figure
histogram(toplot)
xlabel('Initial Intensity')
ylabel('count')

%% 3) View Single Step Filters

expToCheck=1;
pageNumber = 1;

channel1Name = 'Liposome Int.';
channel2Name = 'SLO'

minInitialIntensity = 100;
maxInitialIntensity = 10000;

maxRemainingSignalAfterStep = 0.25; %Ratio of step heights -  1000 for no step fitting

maxSignalLossForNoPop = 0.5;%If step height ratio is greater than this for no step

particleTypeNames = {'No Step','Single Step','Multi Step','Other'};

sysVar.SH = expData(expToCheck).allStepHeights{1};
sysVar.temp = expData(expToCheck).allStepMeans{1};
sysVar.NOS = expData(expToCheck).allNumOfSteps{1};

sysVar.maxStepPos = arrayfun(@(z)find(sysVar.SH(z,:)==min(sysVar.SH(z,:)),1),1:length(sysVar.SH))';

sysVar.toselect = sysVar.temp(:,1)<minInitialIntensity | sysVar.temp(:,1)>maxInitialIntensity;
expData(expToCheck).traceType = 4*double(sysVar.toselect);

sysVar.toselect = expData(expToCheck).traceType==0 & ...
    arrayfun(@(z) 1-min(sysVar.temp(z,1:(sysVar.NOS(z)+1)))/max(sysVar.temp(z,1:(sysVar.NOS(z)+1))),1:length(sysVar.temp))'<maxSignalLossForNoPop;
expData(expToCheck).traceType = expData(expToCheck).traceType + 1*double(sysVar.toselect);

sysVar.toselect =  expData(expToCheck).traceType==0 ...
     & arrayfun(@(z)sysVar.temp(z,sysVar.maxStepPos(z)+1) < maxRemainingSignalAfterStep .* sysVar.temp(z,sysVar.maxStepPos(z)),1:length(sysVar.temp))';
expData(expToCheck).traceType = expData(expToCheck).traceType + 2*double(sysVar.toselect);

sysVar.toselect =  expData(expToCheck).traceType==0 & (sysVar.NOS>1)' ...
    & arrayfun(@(z) min(sysVar.temp(z,1:(sysVar.NOS(z)+1)))<maxRemainingSignalAfterStep .*max(sysVar.temp(z,1:(sysVar.NOS(z)+1))),1:length(sysVar.temp))';
expData(expToCheck).traceType = expData(expToCheck).traceType + 3*double(sysVar.toselect);

sysVar.toselect =  expData(expToCheck).traceType==0;
expData(expToCheck).traceType = expData(expToCheck).traceType + 4*double(sysVar.toselect);


%Plot Traces based on class

if ~exist([saveFolder 'Examples' filesep], 'dir')
    mkdir([saveFolder 'Examples' filesep])%make a subfolder with that name
end

for plottype=1:length(particleTypeNames)
    sysVar.tracePos = find(expData(expToCheck).traceType==plottype);

    sysVar.fig = figure('Name',particleTypeNames{plottype});
    set(gcf, 'Position', [100, 100, 700, 800])
    axes('XScale', 'linear', 'YScale', 'linear','LineWidth',2, 'FontName','Times')
    ax = gca;

    sysVar.traces1 = expData(expToCheck).allTraces{1};
    sysVar.traces1 = sysVar.traces1(sysVar.tracePos,:);
    sysVar.fact(1) = ceil(log10(max(max(sysVar.traces1))))-2;

    if numberOfChannels>1
        sysVar.traces2=expData(expToCheck).allTraces{2};
        sysVar.traces2=sysVar.traces2(sysVar.tracePos,:);
        sysVar.fact(2) = ceil(log10(max(max(sysVar.traces2))))-2;
    end

    sysVar.timeaxis = [1:size(sysVar.traces1,2)];
    sysVar.timeaxis = (sysVar.timeaxis-1).*expData(expToCheck).MPF;


    for i=28*(pageNumber-1)+1:min([pageNumber*28 size(sysVar.traces1,1)])

        subplot(7,4,i-28*(pageNumber-1))
        hold on

        if numberOfChannels>1
            yyaxis left
        end
        if i==13
             ylabel([channel1Name ' (x10^{',num2str(sysVar.fact(1)),'} )'],'FontWeight','bold','FontSize',14)
        end

        plot(sysVar.timeaxis,sysVar.traces1(i,:)./(10.^sysVar.fact(1)),'LineWidth',2)
        
        % channel 1 step fit if it exists
        sysVar.stepPoints = expData(expToCheck).allStepPoints{1};
        if(length(sysVar.stepPoints)>1)
            sysVar.stepPoints = sysVar.stepPoints(sysVar.tracePos,:);
            sysVar.stepMeans = expData(expToCheck).allStepMeans{1};
            sysVar.stepMeans = sysVar.stepMeans(sysVar.tracePos,:);

            sysVar.count = 0;
            sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
            for j=1:size(sysVar.traces1,2)
                if ismember(j-1,sysVar.stepPoints(i,:))
                    sysVar.count = sysVar.count +1;
                end
                sysVar.stepPlot(j) = sysVar.stepMeans(i,sysVar.count);
            end
            plot(sysVar.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(1)),'-black','LineWidth',1)
        end
        
        plot([0 max(sysVar.timeaxis)],[0 0] ,'-black');
       

        if numberOfChannels>1
            yyaxis right
            if i==16
                ylabel([channel2Name ' (x10^{',num2str(sysVar.fact(2)),'} )'],'FontWeight','bold','FontSize',14)
            end
            plot(sysVar.timeaxis,sysVar.traces2(i,:)./(10.^sysVar.fact(2)),'LineWidth',2)


            % channel 2 step fit if it exists
            sysVar.stepPoints = expData(expToCheck).allStepPoints{2};
            if(length(sysVar.stepPoints)>1)
                sysVar.stepPoints = sysVar.stepPoints(sysVar.tracePos,:);
                sysVar.stepMeans = expData(expToCheck).allStepMeans{2};
                sysVar.stepMeans = sysVar.stepMeans(sysVar.tracePos,:);
    
                sysVar.count = 0;
                sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
                for j=1:size(sysVar.traces1,2)
                    if ismember(j-1,sysVar.stepPoints(i,:))
                        sysVar.count = sysVar.count +1;
                    end
                    sysVar.stepPlot(j) = sysVar.stepMeans(i,sysVar.count);
                end
                plot(sysVar.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(2)),'-black','LineWidth',1)
            end



            for j=3:numberOfChannels
                sysVar.traces=sysVar.allTraces{j};
                montage.c = colororder;
                sysVar.fact(j) = max(sysVar.traces2(i,:))./(10.^sysVar.fact(2))./max(sysVar.traces(i,:));
                plot(montage.timeaxis,sysVar.traces(i,:).*sysVar.fact(j),'-','LineWidth',2,'Color',montage.c(j,:))

                % channel 2 step fit if it exists
                sysVar.stepPoints = expData(expToCheck).allStepPoints{j};
                if(length(sysVar.stepPoints)>1)
                    sysVar.stepPoints = sysVar.stepPoints(sysVar.tracePos,:);
                    sysVar.stepMeans = expData(expToCheck).allStepMeans{j};
                    sysVar.stepMeans = sysVar.stepMeans(sysVar.tracePos,:);
        
                    sysVar.count = 0;
                    sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
                    for j=1:size(sysVar.traces1,2)
                        if ismember(j-1,sysVar.stepPoints(i,:))
                            sysVar.count = sysVar.count +1;
                        end
                        sysVar.stepPlot(j) = sysVar.stepMeans(i,sysVar.count);
                    end
                    plot(montage.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(j)),'-black','LineWidth',1)
                end

            end

            [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(i,:)./(10.^sysVar.fact(1)),'all');
            [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(i,:)./(10.^sysVar.fact(2)),'all');
            sysVar.ratio = min([sysVar.yliml(1)/sysVar.yliml(2) sysVar.ylimr(1)/sysVar.ylimr(2) -0.05]);
            set(gca,'Ylim',sort([sysVar.ylimr(2)*sysVar.ratio sysVar.ylimr(2)]))
            yyaxis left
            set(gca,'Ylim',sort([sysVar.yliml(2)*sysVar.ratio sysVar.yliml(2)]))
        end


        xlim([0 max(sysVar.timeaxis)])
        hold off
    
end
h = annotation('textbox',[0.5,0.08,0,0],'string',['Time (mins)'],'FontSize',14,'EdgeColor',"none",'FitBoxToText',true,'HorizontalAlignment','center','FontWeight','bold');
%movegui(sysVar.fig);
%set(findobj(gcf,'type','axes'),'FontName','Myriad Pro','FontSize',9,'LineWidth', 1.5);

print([saveFolder 'Examples' filesep 'Example_Page_' num2str(pageNumber) '_ExpNo_' num2str(expToCheck)], '-dpng', '-r600');
print([saveFolder 'Examples' filesep 'Example_Page_' num2str(pageNumber) '_ExpNo_' num2str(expToCheck)], '-depsc', '-r600');
savefig(sysVar.fig,[saveFolder 'Examples' filesep 'Example_Page_' num2str(pageNumber) '_ExpNo_' num2str(expToCheck)],'compact');


end



