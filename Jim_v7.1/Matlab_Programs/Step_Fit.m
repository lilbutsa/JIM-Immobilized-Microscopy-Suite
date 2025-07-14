%% 1) Select Input Folder
imStackNumberOfChannels = 2;

filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%get JIM Folder

%Set JIM folder here if you have moved the generate traces file away from
%its normal location
%sysConst.JIM = 'C:\Users\jameswa\Google Drive\Jim\Jim_Compressed_v2';

sysConst.fileEXE = '"';
if ismac
    sysConst.JIM = [fileparts(sysConst.JIM),'/c++_Base_Programs/Mac/'];
    source = dir([sysConst.JIM,'/*']);
    for j=1:length(source)
        cmd = ['chmod +x "',sysConst.JIM,source(j).name,'"'];
        system(cmd);
    end
    sysConst.JIM = ['"',sysConst.JIM];
    
elseif ispc
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'\c++_Base_Programs\Windows\'];
    sysConst.fileEXE = '.exe"';
else
    sysConst.JIM = ['"',fileparts(sysConst.JIM),'/c++_Base_Programs/Linux/'];
end




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
    allData(j).intensityFileNames = cell(imStackNumberOfChannels,1);
    allData(j).backgroundFileNames = cell(imStackNumberOfChannels,1);
    for i=1:imStackNumberOfChannels
    allData(j).intensityFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Intensities.csv'];
    allData(j).backgroundFileNames{i} = [fileparts(sysVar.allFiles{j}) filesep 'Channel_' num2str(i) '_Fluorescent_Backgrounds.csv'];
    end
end

NumberOfFiles=length(allData);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);
%%
stepfitChannel = 1;
stepfitThreshold = 20;
fileToCheck = 1;


workingDir = [fileparts(allData(fileToCheck).intensityFileNames{stepfitChannel}),filesep];
sysVar.cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
system(sysVar.cmd);

%% plot fits
montage.pageNumber =2; % Select the page number for traces. 28 traces per page. So traces from(n-1)*28+1 to n*28
montage.timePerFrame = 1;%Set to zero to just have frames
montage.timeUnits = 'frames'; % Unit to use for x axis 
montage.showStepfit = true;

%don't touch from here

if ~exist([workingDir 'Examples' filesep], 'dir')
    mkdir([workingDir 'Examples' filesep])%make a subfolder with that name
end


sysVar.allTraces = cell(imStackNumberOfChannels,1);
for j=1:imStackNumberOfChannels
    sysVar.allTraces{j} = csvread([workingDir,'Channel_',num2str(j),'_Fluorescent_Intensities.csv'],1);
end

sysVar.traces1=sysVar.allTraces{1};
sysVar.fact(1) = ceil(log10(max(max(sysVar.traces1))))-2;

if imStackNumberOfChannels>1
    sysVar.traces2=sysVar.allTraces{2};
    sysVar.fact(2) = ceil(log10(max(max(sysVar.traces2))))-2;
end



sysVar.allstepPoints = cell(imStackNumberOfChannels,1);
sysVar.allstepPoints = cell(imStackNumberOfChannels,1);
for i=1:imStackNumberOfChannels
    if exist([workingDir,'Channel_',num2str(i),'_StepPoints.csv'], 'file')
        sysVar.allstepPoints{i} = csvread([workingDir,'Channel_',num2str(i),'_StepPoints.csv'],1);
        sysVar.allstepMeans{i} = csvread([workingDir,'Channel_',num2str(i),'_StepMeans.csv'],1);
    end
end

sysVar.opts.Colors= get(groot,'defaultAxesColorOrder');sysVar.opts.width= 17.78;sysVar.opts.height= 22.86;sysVar.opts.fontType= 'Myriad Pro';sysVar.opts.fontSize= 9;
sysVar.fig = figure; sysVar.fig.Units= 'centimeters';sysVar.fig.Position(3)= sysVar.opts.width;sysVar.fig.Position(4)= sysVar.opts.height;
set(sysVar.fig.Children, 'FontName','Myriad Pro', 'FontSize', 9);
axes('LineWidth',1.5, 'FontName','Myriad Pro')
%set(gcf, 'Position', [100, 100, 1500, 800])
yyaxis left

montage.timeaxis = [1:size(sysVar.traces1,2)];
if montage.timePerFrame ~= 0
    montage.timeaxis = (montage.timeaxis-1).*montage.timePerFrame;
end

for i=1:28

    if i+28*(montage.pageNumber-1)<=size(sysVar.traces1,1)
        subplot(7,4,i)
        hold on
        %title(['No. ' num2str(i+28*(montage.pageNumber-1)) ' x ' num2str(round(sysVar.measures(i+28*(montage.pageNumber-1),1))) ' y ' num2str(round(sysVar.measures(i+28*(montage.pageNumber-1),2)))])
        %title(['Particle ' num2str(i+28*(montage.pageNumber-1))],'FontName','Myriad Pro','FontSize',9)
        if imStackNumberOfChannels>1
            yyaxis left
        end
        if i==13
             ylabel(['Channel 1 Intensity (x10^{',num2str(sysVar.fact(1)),'} a.u.)'],'FontWeight','bold','FontSize',14)
        end

        plot(montage.timeaxis,sysVar.traces1(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(1)),'LineWidth',2)
        
        plot([0 max(montage.timeaxis)],[0 0] ,'-black');
       

        if imStackNumberOfChannels>1
            yyaxis right
            if i==16
                ylabel(['Channel 2 Intensity (x10^{',num2str(sysVar.fact(2)),'} a.u.)'],'FontWeight','bold','FontSize',14)
            end
            plot(montage.timeaxis,sysVar.traces2(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(2)),'LineWidth',2)

            for j=3:imStackNumberOfChannels
                traces=sysVar.allTraces{j};
                montage.c = colororder;
                plot(montage.timeaxis,traces(i+28*(montage.pageNumber-1),:).*max(sysVar.traces2(i+28*(montage.pageNumber-1),:))./(10.^sysVar.fact(2))./max(traces(i+28*(montage.pageNumber-1),:)),'-','LineWidth',2,'Color',montage.c(j,:))
            end

            [sysVar.yliml(1),sysVar.yliml(2)] = bounds(sysVar.traces1(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(1)),'all');
            [sysVar.ylimr(1),sysVar.ylimr(2)] = bounds(sysVar.traces2(i+28*(montage.pageNumber-1),:)./(10.^sysVar.fact(2)),'all');
            sysVar.ratio = min([sysVar.yliml(1)/sysVar.yliml(2) sysVar.ylimr(1)/sysVar.ylimr(2) -0.05]);
            set(gca,'Ylim',sort([sysVar.ylimr(2)*sysVar.ratio sysVar.ylimr(2)]))
            yyaxis left
            set(gca,'Ylim',sort([sysVar.yliml(2)*sysVar.ratio sysVar.yliml(2)]))
        end

        for stepfitChannel = 1:imStackNumberOfChannels
            if ~isempty(sysVar.allstepPoints{stepfitChannel})
                sysVar.stepPoints = sysVar.allstepPoints{stepfitChannel};
                sysVar.stepMeans = sysVar.allstepMeans{stepfitChannel};
    
                sysVar.count = 0;
                sysVar.stepPlot = 0.*[1:size(sysVar.traces1,2)];
                for j=1:size(sysVar.traces1,2)
                    if ismember(j-1,sysVar.stepPoints(i+28*(montage.pageNumber-1),:))
                        sysVar.count = sysVar.count +1;
                    end
                    sysVar.stepPlot(j) = sysVar.stepMeans(i+28*(montage.pageNumber-1),sysVar.count);
                end
                if stepfitChannel == 1
                    if imStackNumberOfChannels>1
                        yyaxis left
                    end
                    plot(montage.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(1)),'-black','LineWidth',2)
                elseif stepfitChannel == 2
                    yyaxis right
                    plot(montage.timeaxis,sysVar.stepPlot./(10.^sysVar.fact(2)),'-black','LineWidth',2)
                else
                    yyaxis right
                    plot(montage.timeaxis,sysVar.stepPlot.*max(sysVar.traces2(i+28*(montage.pageNumber-1),:))./(10.^sysVar.fact(2))./max(traces(i+28*(montage.pageNumber-1),:)),'-black','LineWidth',2)
                end
            end
        end

        xlim([0 max(montage.timeaxis)])
        hold off
    end
end
h = annotation('textbox',[0.5,0.08,0,0],'string',['Time (',montage.timeUnits,')'],'FontSize',14,'EdgeColor',"none",'FitBoxToText',true,'HorizontalAlignment','center','FontWeight','bold');
movegui(sysVar.fig);
%set(findobj(gcf,'type','axes'),'FontName','Myriad Pro','FontSize',9,'LineWidth', 1.5);
print([workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-dpng', '-r600');
print([workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)], '-depsc', '-r600');
savefig(sysVar.fig,[workingDir 'Examples' filesep 'Example_Page_' num2str(montage.pageNumber)],'compact');


%% Batch all files

for i=1:length(allData)
    workingDir = [fileparts(allData(i).intensityFileNames{stepfitChannel}),filesep];
    sysVar.cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
    system(sysVar.cmd);
end

disp('Step fitting completed');