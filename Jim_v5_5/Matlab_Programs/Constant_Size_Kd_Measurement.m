clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];

%% Find all traces
insubfolders = false;

channel1 = {};
channel2 = {};
channel1b={};
channel2b={};

allfiles = dir(pathname);
allfiles(~[allfiles.isdir]) = [];
allfiles=allfiles(3:end);

if insubfolders
    for i=1:size(allfiles,1)
        innerfolder = dir([pathname,allfiles(i).name,'\']);
        innerfolder(~[innerfolder.isdir]) = [];
        innerfolder=innerfolder(3:end);
        for j=1:size(innerfolder,1)
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Intensities.csv']];
                 channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Fluorescent_Intensities.csv']];
                channel1b = [channel1b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Fluorescent_Backgrounds.csv']];
                 channel2b = [channel2b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Fluorescent_Backgrounds.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']];
             channel2 = [channel2 [pathname,allfiles(i).name,'\Channel_2_Fluorescent_Intensities.csv']];
            channel1b = [channel1b [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Backgrounds.csv']];
             channel2b = [channel2b [pathname,allfiles(i).name,'\Channel_2_Fluorescent_Backgrounds.csv']]
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%% 3) Extract Concentrations
Concentrationunits = 'nM';

concentration = [];

for i=1:numofexps
    channelin = channel1(i);
    found = regexp(channelin{1},['\d+\.?\d+',Concentrationunits,'*'],'match');
    if size(found,2)==0
        found=regexp(channelin{1},['\d',Concentrationunits,'*'],'match');
    end
    found = found(1);
    found = found{1};
    conout = regexp(found,['\d+\.?\d*'],'match');
    concentration = [concentration str2double(conout{1})];
end

disp(concentration);

%% 4) Or Run Manual Input
concentration = [0.2 0.2 0.2 1 1 1 10 10 10 0.5 0.5 0.5 5 5 5 0.1 0.1 0.1 20 20 20];
%% Find Intensity of substrate
channel1reference = false;
substrateints = [];
binderints = [];
for i=1:numofexps
    if channel1reference
        d1=csvread(channel1{i},1);
    else
        d1=csvread(channel2{i},1);
    end
    substrateints = [substrateints;mean(d1,2)];
end

figure
histogram(substrateints,1000);
xlim([0 median(substrateints)+3*std(substrateints)]);
%% 5) Measure the ratio of flourescence between channels for each area
substratecutoffs = [500 5000];

channel1reference = false;
pagenumber = 1;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

binderintensity = zeros(numofexps,1);
substratebackground = zeros(numofexps,1);
binderbackground = zeros(numofexps,1);
for i=1:numofexps
    d1=csvread(channel1{i},1);
    d2=csvread(channel2{i},1);
    b1=csvread(channel1b{i},1);
    b2=csvread(channel2b{i},1);

    numparticles = size(d1,1);

    intensityin = zeros(numparticles,4);
    if channel1reference
        intensityin(:,1) = mean(d1,2);
        intensityin(:,2) = mean(d2,2);
        intensityin(:,3) = mean(b1,2);
        intensityin(:,4) = mean(b2,2);
    else
        intensityin(:,1) = mean(d2,2);
        intensityin(:,2) = mean(d1,2);
        intensityin(:,3) = mean(b2,2);
        intensityin(:,4) = mean(b1,2);
    end
    
    filtered = find(intensityin(:,1)>substratecutoffs(1)&intensityin(:,1)<substratecutoffs(2));
    
    filtints = intensityin(filtered,:);
    
    binderintensity(i) = median(filtints(:,2));
    substratebackground(i) = median(filtints(:,3));
    binderbackground(i) = median(filtints(:,4));
  
    samplenum = (i-36*(pagenumber-1));
    if samplenum<=36 && samplenum>0
        subplot(6,6,samplenum)
        hold on
        %scatter(filtints(:,1),filtints(:,2))
        histObj = histogram(filtints(:,2),20,'Normalization','pdf');
        title([num2str(i) ' - ' num2str(concentration(i)) ' ' Concentrationunits])
        xlabel('Subtrate')
        ylabel('Binder')

       % plot(substratecutoffs,[binderintensity(i) binderintensity(i)],'-r')
       plot([binderintensity(i) binderintensity(i)],[0 max(histObj.Values)],'-r')
        %xlim(substratecutoffs)
        xlim([min(filtints(:,2)) max(filtints(:,2))])
        hold off
    end    
end

%% Check Backgrounds for linearity as sanity check
figure

hold on 
bx = concentration';
byx = substratebackground;
by = @(b,bx)( b(1)*bx +b(2));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [0 0], opts);

bxout = 0:max(bx);
byout = by(Bb,bxout);

scatter(bx,byx, 'ob')
plot(bxout,byout,'-b');

disp(['Best fit of substrate is ' num2str(Bb(2)) ' + ' num2str(Bb(1)) ' x ']);



title('Background Intensity (Blue substrate, Red Binder)')
xlabel(['Concentration (' Concentrationunits ')'])
ylabel('Intensity (a.u.)')

bx = concentration';
byx = binderbackground;
by = @(b,bx)( b(1)*bx +b(2));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [0 0], opts);

bxout = 0:max(bx);
byout = by(Bb,bxout);

scatter(bx,byx, 'or')
plot(bxout,byout,'-r');
hold off

disp(['Best fit of binder is ' num2str(Bb(2)) ' + ' num2str(Bb(1)) ' x ']);

%% 6) Fit binding Curve using least squares
binder_photobleaching = 500;
binder_partial_labelling = 1;%(1./concentration')

x = concentration';
yx = binderintensity./binder_photobleaching./binder_partial_labelling;%./[1./SingleMoleculeBleachingRatio].*LabellingRatio;

y = @(b,x)( b(1).*x./(b(2)+x));             % Objective function
OLS = @(b) sum((y(b,x) - yx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
B = fminsearch(OLS, [max(yx) 10], opts);
disp(['Kd was calculated at ',num2str(B(2)),' ',Concentrationunits,' and maximum number of binding sites of ',num2str(B(1))]);

xout = 0:0.1:1.5*max(x);
yout = y(B,xout);
figure
scatter(x,yx)
hold on
xlabel(['Concentration (',Concentrationunits ')']) % x-axis label
ylabel('Number Bound') % y-axis label
plot(xout,yout)
hold off
