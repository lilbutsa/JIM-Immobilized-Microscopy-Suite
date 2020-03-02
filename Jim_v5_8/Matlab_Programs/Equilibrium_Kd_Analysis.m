clear
%% 1) Select Input Folder
filesInSubFolders = false;% Set this to true if each image stack is in it's own folder or false if imagestacks are directly in the main folder

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



%% 3) Extract Concentrations
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

%% 4) Or Run Manual Input
Concentrationunits = 'uM';
 concentration = [0.2 0.2 0.2 1 1 1 10 10 10 0.5 0.5 0.5 5 5 5 0.1 0.1 0.1 20 20 20];

%% 5) Measure the ratio of flourescence between channels for each area 
singleChannelData = true;
channelOneSubstrate = true;
constantSizeSubstrate = true;

substrate_photobleaching = 114;
binder_photobleaching = 265;
substrate_partial_labelling = 1/50; %this is the ratio of label to unlabelled CA, so if it is 1 fluorophore per 50, the ratio is 1/50
binder_partial_labelling = 1./concentration;

minSubstrate = 0;
maxSubstrate = 50000;
minBinder = 100;
maxBinder = 1000000000;


bindingIntensity = zeros(NumberOfFiles,1);
substratebackground = zeros(NumberOfFiles,1);
binderbackground = zeros(NumberOfFiles,1);

Kd_Analysis_File = [fileName 'Compiled_Equilibrium_Kd_Analysis' fileSep];
if ~exist(Kd_Analysis_File, 'dir')
    mkdir(Kd_Analysis_File)%make a subfolder with that name
end


for i=1:NumberOfFiles
    if singleChannelData
        d2=csvread(channel1{i},1);
        b2=csvread(channel1b{i},1);        
    else
        if channelOneSubstrate
            d1=csvread(channel1{i},1);
            b1=csvread(channel1b{i},1);    
            d2=csvread(channel2{i},1);
            b2=csvread(channel2b{i},1);
        else
            d1=csvread(channel2{i},1);
            b1=csvread(channel2b{i},1);    
            d2=csvread(channel1{i},1);
            b2=csvread(channel1b{i},1);
        end
        
    end

    numparticles = size(d2,1);
    intensityin = zeros(numparticles,4);
        
    intensityin(:,2) = mean(d2,2)./binder_photobleaching./binder_partial_labelling(min(i,end));
    intensityin(:,4) = mean(b2,2)./binder_partial_labelling(min(i,end));

    toselect = intensityin(:,2)>minBinder & intensityin(:,2)<maxBinder;

    if ~singleChannelData
        intensityin(:,1) = mean(d1,2)./substrate_photobleaching./substrate_partial_labelling(min(i,end));
        intensityin(:,3) = mean(b1,2)./substrate_partial_labelling(min(i,end));
        
        toselect = toselect & intensityin(:,1)>minSubstrate & intensityin(:,1)<maxSubstrate;
    end
    
    
    intensityin = intensityin(toselect,:);
    
    substratebackground(i) = median(intensityin(:,3));
    binderbackground(i) = median(intensityin(:,4));

    
    if mod(i,25)==1
            opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 40;opts.height= 24;opts.fontType= 'Times';opts.fontSize= 9;
            fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
            set(fig.Children, 'FontName','Times', 'FontSize', 9);fig.Position(1)=1;fig.Position(2)=1;
    end
    pagenumber = ceil(i/25);
    samplenum = (i-25*(pagenumber-1));
    
    
    
    if singleChannelData
        bindingIntensity(i) = median(intensityin(:,2));

        subplot(5,5,samplenum)
        hold on
        histogram(intensityin(:,2))
        xline(bindingIntensity(i),'Color',[0.8500, 0.3250, 0.0980]);
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Binder Intensity')
        ylabel('Count')
        hold off  
        
    elseif constantSizeSubstrate
        bindingIntensity(i) = median(intensityin(:,2));

        subplot(5,5,samplenum)
        hold on
        scatter(x,y)
        yline(bindingIntensity(i),'Color',[0.8500, 0.3250, 0.0980]);
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Subtrate')
        ylabel('Binder')
        xlim([0 max(x)])
        ylim([0 max(y)])
        hold off        
        
    else
        x = intensityin(:,1);
        y = intensityin(:,2);
        bindingIntensity(i) =dot(x,y)./dot(x,x);

        xout2 = [0 max(x)];
        yout2 = [0 max(x).*bindingIntensity(i)];

        subplot(5,5,samplenum)
        hold on
        scatter(x,y)
        plot(xout2,yout2,'Color',[0.8500, 0.3250, 0.0980])
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

fileout = [Kd_Analysis_File 'Binding_Intensity_Ratios.csv'];  
fid = fopen(fileout,'w'); 
fprintf(fid,'%s\n','Concentration, Binding Intensity, Substrate Background, Binder Background');
fclose(fid);    
dlmwrite(fileout,horzcat(concentration',bindingIntensity,substratebackground,binderbackground),'-append'); 


%% Check Backgrounds for linearity as sanity check
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on

if ~singleChannelData
    x = concentration';
    y = substratebackground;
    a = (dot(x,x).*sum(y)-sum(x).*dot(x,y))/(length(x).*dot(x,x)-sum(x).*sum(x));
    b = (length(x).*dot(x,y)-sum(x).*sum(y))/(length(x).*dot(x,x)-sum(x).*sum(x));

    scatter(x,y,'MarkerEdgeColor',[0 0.4470 0.7410],'HandleVisibility','off')
    plot([0 max(x)],[a a+b.*max(x)],'Color',[0 0.4470 0.7410]);
    disp(['Best fit of substrate is ' num2str(a) ' + ' num2str(b) ' [con] ']);

end

y = binderbackground;
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

%% 6) Fit binding Curve using least squares

x = concentration;
y = bindingIntensity';
y1 = x./y;

a = (dot(x,x).*sum(y1)-sum(x).*dot(x,y1))/(length(x).*dot(x,x)-sum(x).*sum(x));
b = (length(x).*dot(x,y1)-sum(x).*sum(y1))/(length(x).*dot(x,x)-sum(x).*sum(x));

Bmax = 1/b;
Kd = a.*Bmax;
disp(['Least squares Kd was calculated at ',num2str(Kd),' ',Concentrationunits,' and maximum binding ratio of ',num2str(Bmax)]);

%% Plot Kd binding Curve
xout = 0:0.1:1.25*max(x);
yout = Bmax.*xout./(Kd+xout);
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
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

%% Log Linear Plot
xout = 0.25*min(x):0.1:4*max(x);
yout = Bmax.*xout./(Kd+xout);
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
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

%% Plot Linearized Binding Curve
opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure; fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
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
%% Create Combined Figure

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
