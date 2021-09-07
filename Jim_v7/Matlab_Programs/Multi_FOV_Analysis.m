clear
%% 1) Select Input Folder
filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

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
channel2 = allFiles(contains(allFiles,'Channel_2_Fluorescent_Intensities.csv','IgnoreCase',true));
channel1b = allFiles(contains(allFiles,'Channel_1_Fluorescent_Backgrounds.csv','IgnoreCase',true));
channel2b = allFiles(contains(allFiles,'Channel_2_Fluorescent_Backgrounds.csv','IgnoreCase',true));

NumberOfFiles=size(channel1,1);

disp(['There are ',num2str(NumberOfFiles),' files to analyse']);

Kd_Analysis_File = [fileName 'Compiled_Multi_FOV_Analysis' fileSep];
if ~exist(Kd_Analysis_File, 'dir')
    mkdir(Kd_Analysis_File)%make a subfolder with that name
end

%% 2) Automatic Variable Unit Extraction
Concentrationunits = 'uM';

concentration = [];
for i=1:NumberOfFiles
    channelin = channel1{i};
    found = regexp(channelin,['\d+\.?\d+',Concentrationunits,'*'],'match');
    if size(found,2)==0
        found=regexp(channelin,['\d',Concentrationunits,'*'],'match');
    end
    
    if size(found,1)~=0
        found = found(1);
        found = found{1};
        conout = regexp(found,['\d+\.?\d*'],'match');
        concentration = [concentration str2double(conout{1})];
    else
        concentration = [concentration -1];
    end
end

disp(concentration);

%% 2b) Or Manual Variable Unit Extraction
Concentrationunits = 'nM';

 %concentration = [3.5 3.5 3.5 3.5 3.5 3.5 3.5 3.5];
 concentration = zeros(NumberOfFiles,1)+1;

%% Read in data
singleChannelData = false;
channelOneSubstrate = false;

substrate_photobleaching = 1;
binder_photobleaching = 6591;
substrate_partial_labelling = 1;
binder_partial_labelling = 1;


allbinder = cell(NumberOfFiles,1);
allsubstrate = cell(NumberOfFiles,1);
allbinderbackground = cell(NumberOfFiles,1);
allsubstratebackground = cell(NumberOfFiles,1);

for i=1:NumberOfFiles
    if singleChannelData
        allbinder{i}=mean(csvread(channel1{i},1),2)./binder_photobleaching./binder_partial_labelling(min(i,end));
        allbinderbackground{i}=mean(csvread(channel1b{i},1),2)./binder_partial_labelling(min(i,end));        
    else
        if channelOneSubstrate
            allsubstrate{i}=mean(csvread(channel1{i},1),2)./substrate_photobleaching./substrate_partial_labelling(min(i,end));
            allsubstratebackground{i}=mean(csvread(channel1b{i},1),2)./substrate_partial_labelling(min(i,end));    
            allbinder{i}=mean(csvread(channel2{i},1),2)./binder_photobleaching./binder_partial_labelling(min(i,end));
            allbinderbackground{i}=mean(csvread(channel2b{i},1),2)./binder_partial_labelling(min(i,end));
        else
            allsubstrate{i}=mean(csvread(channel2{i},1),2)./substrate_photobleaching./substrate_partial_labelling(min(i,end));
            allsubstratebackground{i}=mean(csvread(channel2b{i},1),2)./substrate_partial_labelling(min(i,end));    
            allbinder{i}=mean(csvread(channel1{i},1),2)./binder_photobleaching./binder_partial_labelling(min(i,end));
            allbinderbackground{i}=mean(csvread(channel1b{i},1),2)./binder_partial_labelling(min(i,end));
        end
        
    end
end
%% Plot Intensity Distributions and Filter

minSubstrate = 4300;
maxSubstrate = 200000;
minBinder = -1;
maxBinder = 10;

%don't touch from here
combinedSubstrate = [];
combinedBinder= [];

selectedbinder = cell(NumberOfFiles,1);
selectedsubstrate = cell(NumberOfFiles,1);

medianselectedbinderbackground = zeros(NumberOfFiles,1);
medianselectedsubstratebackground = zeros(NumberOfFiles,1);

if ~singleChannelData
    for i=1:NumberOfFiles
        combinedSubstrate = [combinedSubstrate ; allsubstrate{i}];
    end
    
    fileout = [Kd_Analysis_File 'Combined_Substrate_Intensities.csv'];
    filein = [Kd_Analysis_File 'Combined_Substrate_'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each Line is the step height from a single experiment');
    fclose(fid);
    dlmwrite(fileout,combinedSubstrate','-append');   
    cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
    system(cmd);    
    hists = csvread([filein,'_Histograms.csv'],1,0);
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Substrate Size Distribution')
    xlabel('Molecules in Substrate')
    ylabel('Probability (PDF)')
    plot(hists(1,:),hists(2,:))
    combinedSubstrate = sort(combinedSubstrate);
    xlim([-1 combinedSubstrate(round(0.95.*size(combinedSubstrate,1)))])
    xline(minSubstrate,'Color',[0.8500, 0.3250, 0.0980]);
    xline(maxSubstrate,'Color',[0.8500, 0.3250, 0.0980]);
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([Kd_Analysis_File 'Substrate_Intensity_Distribution'], '-dpng', '-r600')   
end

for i=1:NumberOfFiles
    combinedBinder = [combinedBinder;allbinder{i}];
end
    fileout = [Kd_Analysis_File 'Combined_Binder_Intensities.csv'];
    filein = [Kd_Analysis_File 'Combined_Binder_'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each Line is the step height from a single experiment');
    fclose(fid);
    dlmwrite(fileout,combinedBinder','-append');   
    cmd = [JIM,'Make_Histogram',fileEXE,' "',fileout,'" "',filein,'"'];
    system(cmd);    
    hists = csvread([filein,'_Histograms.csv'],1,0);
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title('Binder Size Distribution')
    xlabel('Molecules Bound to Substrate')
    ylabel('Probability (PDF)')
    plot(hists(1,:),hists(2,:))
    combinedBinder = sort(combinedBinder);
    xlim([-1 combinedBinder(round(0.95.*size(combinedBinder,1)))])
    xline(minBinder,'Color',[0.8500, 0.3250, 0.0980]);
    xline(maxBinder,'Color',[0.8500, 0.3250, 0.0980]);
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([Kd_Analysis_File 'Binder_Intensity_Distribution'], '-dpng', '-r600')
    
    
 for i=1:NumberOfFiles   
    toselect = allbinder{i}>minBinder & allbinder{i}<maxBinder;

    if ~singleChannelData        
        toselect = toselect & allsubstrate{i}>minSubstrate & allsubstrate{i}<maxSubstrate;
        
        selectedsubstrate{i} = allsubstrate{i}(toselect);
        medianselectedsubstratebackground(i) = median(allsubstratebackground{i}(toselect));
    else
        medianselectedsubstratebackground(i) =0;
    end
    selectedbinder{i} = allbinder{i}(toselect);
    medianselectedbinderbackground(i) = median(allbinderbackground{i}(toselect));
 end
 
%% Check Background Linearity
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on

fileout = [Kd_Analysis_File 'Background_Fits.csv'];  
fid = fopen(fileout,'w'); 

if ~singleChannelData
    x = concentration';
    y = medianselectedsubstratebackground;
    a = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(length(x).*dot(x,x)-sum(x).*sum(x));
    b = (length(x).*dot(x,y)-sum(x).*sum(y))/(length(x).*dot(x,x)-sum(x).*sum(x));

    scatter(x,y,'MarkerEdgeColor',[0 0.4470 0.7410],'HandleVisibility','off')
    plot([0 max(x)],[a a+b.*max(x)],'Color',[0 0.4470 0.7410]);
    disp(['Best fit of substrate is ' num2str(a) ' + ' num2str(b) ' [con] ']);

    fprintf(fid,'%s\n',['Substrate Offset,',num2str(a)]);
    fprintf(fid,'%s\n',['Substrate Gradient,',num2str(b)]);
end

x = concentration';
y = medianselectedbinderbackground;
a = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(length(x).*dot(x,x)-sum(x).*sum(x));
b = (length(x).*dot(x,y)-sum(x).*sum(y))/(length(x).*dot(x,x)-sum(x).*sum(x));

disp(['Best fit of binder is ' num2str(a) ' + ' num2str(b) ' [con] ']);

scatter(x,y,'MarkerEdgeColor',[0.8500, 0.3250, 0.0980],'HandleVisibility','off')
plot([0 max(x)],[a a+b.*max(x)],'Color',[0.8500, 0.3250, 0.0980]);

if ~singleChannelData
    lgd = legend('Substrate','Binder');
    lgd.Location = 'northwest';
end
title('Background Intensity')
xlabel(['Concentration (' Concentrationunits ')'])
ylabel('Intensity (a.u.)')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([Kd_Analysis_File 'Background_Intensities'], '-dpng', '-r600')

fprintf(fid,'%s\n',['Binder Offset,',num2str(a)]);
fprintf(fid,'%s\n',['Binder Gradient,',num2str(b)]);

fclose(fid); 

    
%% 3) Measure Fluorescence Intensities 
constantSizeSubstrate = true;

discreteSingleMoleculeBinding = true;
singleMoleculeCutoff = 7.5;

displayDensityPlot = false;
subDivisions = 20;


bindingIntensity = zeros(NumberOfFiles,1);

for i=1:NumberOfFiles
    
    if mod(i,25)==1
            opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 40;opts.height= 24;opts.fontType= 'Times';opts.fontSize= 9;
            fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
            set(fig.Children, 'FontName','Times', 'FontSize', 9);fig.Position(1)=1;fig.Position(2)=1;
    end
    pagenumber = ceil(i/25);
    samplenum = (i-25*(pagenumber-1));

    if singleChannelData
        bindingIntensity(i) = median(selectedbinder{i});

        subplot(5,5,samplenum)
        hold on
        histogram(selectedbinder{i})
        xline(bindingIntensity(i),'Color',[0.8500, 0.3250, 0.0980],'LineWidth',2);
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Binder Intensity')
        ylabel('Count')
        hold off  
        
    elseif discreteSingleMoleculeBinding
        
        bindingIntensity(i) = nnz(selectedbinder{i}>singleMoleculeCutoff)./length(selectedbinder{i});
        x = selectedsubstrate{i};
        y = selectedbinder{i};       
        subplot(5,5,samplenum)
        hold on
        if displayDensityPlot
            histdata = histogram2(x,y,0:max(x)/subDivisions:max(x),0:max(y)/subDivisions:max(y),'DisplayStyle','tile');
        else
            scatter(x,y,'filled')
        end
        
        yline(singleMoleculeCutoff,'Color',[0.8500, 0.3250, 0.0980],'LineWidth',2);
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Subtrate')
        ylabel('Binder')
        xlim([0 max(x)])
        ylim([0 max(y)])
        hold off 
        
    elseif constantSizeSubstrate
        bindingIntensity(i) = median(selectedbinder{i});
        x = selectedsubstrate{i};
        y = selectedbinder{i}; 
        subplot(5,5,samplenum)
        hold on
        if displayDensityPlot
            histdata = histogram2(x,y,0:max(x)/subDivisions:max(x),0:max(y)/subDivisions:max(y),'DisplayStyle','tile');
        else
            scatter(x,y,'filled')
        end
        yline(bindingIntensity(i),'Color',[0.8500, 0.3250, 0.0980],'LineWidth',2);
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Subtrate')
        ylabel('Binder')
        xlim([0 max(x)])
        ylim([0 max(y)])
        hold off               
    else
        x = selectedsubstrate{i};
        y = selectedbinder{i}; 
        bindingIntensity(i) =dot(x,y)./dot(x,x);
        xout2 = [0 max(x)];
        yout2 = [0 max(x).*bindingIntensity(i)];
        subplot(5,5,samplenum)
        hold on
        if displayDensityPlot
            histdata = histogram2(x,y,0:max(x)/subDivisions:max(x),0:max(y)/subDivisions:max(y),'DisplayStyle','tile');
        else
            scatter(x,y,'filled')
        end
        plot(xout2,yout2,'Color',[0.8500, 0.3250, 0.0980],'LineWidth',2)
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Subtrate')
        ylabel('Binder')
        xlim([0 max(x)])
        ylim([0 max(y)])
        hold off

    end
    
    if mod(i,25)==0 || i==NumberOfFiles
        set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
        fig.PaperPositionMode   = 'auto';
        print([Kd_Analysis_File 'Intensity_Ratio_Fits_Page_' num2str(pagenumber)], '-dpng', '-r600')
    end

end

    fileout = [Kd_Analysis_File 'Binding_Intensities.csv'];  
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Concentration, Binding Intensity, Substrate Background, Binder Background');
    fclose(fid);    
    dlmwrite(fileout,horzcat(concentration,bindingIntensity,medianselectedsubstratebackground,medianselectedbinderbackground),'-append');

    f=figure;
    set(gcf, 'Position', [100, 100, 600, 300])
    t=uitable(f,'Data',horzcat(concentration,bindingIntensity,medianselectedsubstratebackground,medianselectedbinderbackground),'Position', [0, 0, 600, 300]);
    t.ColumnName = {'Concentration','Binding Intensity','Substrate Background','Binder Background'};

    
    fileout = [Kd_Analysis_File 'Multi_FOV_Parameters.csv'];  
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n',['constantSizeSubstrate, ',convertStringsToChars(string(constantSizeSubstrate))]);
    fprintf(fid,'%s\n',['discreteSingleMoleculeBinding, ',convertStringsToChars(string(discreteSingleMoleculeBinding))]);
    fprintf(fid,'%s\n',['singleChannelData, ',convertStringsToChars(string(singleChannelData))]);
    fprintf(fid,'%s\n',['channelOneSubstrate, ',convertStringsToChars(string(channelOneSubstrate))]);

    fprintf(fid,'%s\n',['substrate_photobleaching,',num2str(substrate_photobleaching)]);
    fprintf(fid,'%s\n',['binder_photobleaching,',num2str(binder_photobleaching)]);
    fprintf(fid,'%s\n',['substrate_partial_labelling,',num2str(substrate_partial_labelling)]);
    fprintf(fid,'%s\n',['binder_partial_labelling,',num2str(binder_partial_labelling)]);

    fprintf(fid,'%s\n',['minSubstrate,',num2str(minSubstrate)]);
    fprintf(fid,'%s\n',['maxSubstrate,',num2str(maxSubstrate)]);
    fprintf(fid,'%s\n',['minBinder,',num2str(minBinder)]);
    fprintf(fid,'%s\n',['maxBinder,',num2str(maxBinder)]);

    fclose(fid); 
    %%
    
%%
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
axes('XScale', 'linear', 'YScale', 'linear','LineWidth',1.5, 'FontName','Times')
hold on
%swarmchart(ones(size(bindingIntensity,1),1),bindingIntensity','filled')
errorbar(1,mean(bindingIntensity),0,'Linewidth',2,'CapSize',40)
ax = gca;
ax.ColorOrderIndex = 2;
errorbar(1,mean(bindingIntensity),std(bindingIntensity),'Linewidth',2,'CapSize',20)
set(gca,'XTick',[]);
hold off
%xlim([0.3 1.7])
ylim([0 0.2])
ylabel('Encapsulation_Percentage')
disp(mean(bindingIntensity));
disp(std(bindingIntensity));
pbaspect([0.4 1 1])
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';

%% (Option 1) Fit Equilibrium Kd binding Curve

x = concentration;
y = bindingIntensity';

toselect = x>0 & y>0;
x = x(toselect);
y = y(toselect);
y1 = x./y;
a = (dot(x,x).*sum(y1)-sum(x).*dot(x,y1))/(length(x).*dot(x,x)-sum(x).*sum(x));
b = (length(x).*dot(x,y1)-sum(x).*sum(y1))/(length(x).*dot(x,x)-sum(x).*sum(x));

Bmax = 1/b;
Kd = a.*Bmax;
disp(['Least squares Kd was calculated at ',num2str(Kd),' ',Concentrationunits,' and maximum binding amount of ',num2str(Bmax)]);

fileout = [Kd_Analysis_File 'Kd_Fit.csv'];  
fid = fopen(fileout,'w'); 
fprintf(fid,'%s\n',['Kd,',num2str(Kd),',',Concentrationunits]);
if constantSizeSubstrate
    fprintf(fid,'%s\n',['Maximum Binding,',num2str(Bmax),', Molecules']);
else
    fprintf(fid,'%s\n',['Maximum Binding Ratio,',num2str(Bmax),', Moleulces per Substrate']);
end
fclose(fid); 

xout = 0:0.1:1.25*max(x);
yout = Bmax.*xout./(Kd+xout);
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('visible','off'); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
plot(xout,yout)
scatter(x,y)
title('Equilibrium Binding Curve')
xlabel(['Concentration (',Concentrationunits ')']) % x-axis label
if constantSizeSubstrate
    ylabel('Bound Binder (Molecules)')
else
    ylabel('Bound Binder per Subtrate') % y-axis label
end

hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([Kd_Analysis_File 'Equilibrium_Binding_Curve'], '-dpng', '-r600')

% 7) Log Linear Plot
xout = 0.25*min(x):0.1:4*max(x);
yout = Bmax.*xout./(Kd+xout);
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('visible','off'); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
plot(xout,yout)
scatter(x,y)
ax = gca;
ax.XScale = 'log';
title('Log Plot Equilibrium Binding Curve')
xlabel(['Concentration (',Concentrationunits ')']) % x-axis label
if constantSizeSubstrate
    ylabel('Bound Binder (Molecules)')
else
    ylabel('Bound Binder per Subtrate') % y-axis label
end
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([Kd_Analysis_File 'Log_Linear_Equilibrium_Binding_Curve'], '-dpng', '-r600')

% 8) Plot Linearized Binding Curve
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('visible','off'); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
plot(x,(Kd+x)./Bmax)
scatter(x,y1)
title('Linearized Binding Equation')
xlabel(['Concentration (',Concentrationunits ')']) % x-axis label
ylabel('Concentration/Binding Ratio') % y-axis label
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([Kd_Analysis_File 'Linearized_Binding_Equation'], '-dpng', '-r600')


    fig = figure;
    img1 = imread([Kd_Analysis_File 'Equilibrium_Binding_Curve.png']);
    img2 = imread([Kd_Analysis_File 'Log_Linear_Equilibrium_Binding_Curve.png']);
    img3 = imread([Kd_Analysis_File 'Linearized_Binding_Equation.png']);
    img4 = imread([Kd_Analysis_File 'Background_Intensities.png']);

    montage({img1,img2,img3,img4},'BorderSize',[10 100],'BackgroundColor','white','ThumbnailSize',[]);
    text(10,100,'A','FontSize',24) 
    text(2100,100,'B','FontSize',24) 
    text(10,1500,'C','FontSize',24)
    text(2100,1500,'D','FontSize',24)
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0));
    fig.PaperPositionMode   = 'auto';
    print([Kd_Analysis_File 'Combined_Figure'], '-dpng', '-r600')
 
%% (Option 2) Fit Exponential Curve
    
    expYMinPercent = 0;
    expYMaxPercent = 1;
    
    xaxis = 'Time (Minutes)';
    

    x = concentration;
    y = bindingIntensity';


    fileout = [Kd_Analysis_File 'FOV_Analysis_Curves.csv'];
    filein = [Kd_Analysis_File 'FOV_Analysis'];    
    fid = fopen(fileout,'w'); 
    fprintf(fid,'%s\n','Each First Line is the concentration, Each Second Line is Binding Intensity');
    fclose(fid);
    dlmwrite(fileout,x,'-append');   
    dlmwrite(fileout,y,'-append');
    cmd = [JIM,'Exponential_Fit',fileEXE,' "',fileout,'" "',filein,'" -ymaxPercent ',num2str(expYMaxPercent),' -yminPercent ',num2str(expYMinPercent)];
    system(cmd);
    bleachFits = csvread([filein,'_ExpFit.csv'],1,0);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    xlabel(xaxis)
    ylabel('Binding Intensity')
    scatter(x,y);
    plot(0:max(x)/1000:max(x),bleachFits(end,1)+bleachFits(end,2).*exp(-bleachFits(end,3).*[0:max(x)/1000:max(x)]));
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([Kd_Analysis_File 'Exponential_Fit_Plot'], '-dpng', '-r600')
    
%%  (Option 3) Custom Fit

    x = concentration;
    y = bindingIntensity';