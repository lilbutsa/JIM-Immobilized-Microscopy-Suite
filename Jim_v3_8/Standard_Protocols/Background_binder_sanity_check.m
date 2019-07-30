clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = true;

channel1 = {};
channel2 = {};

allfiles = dir(pathname);
allfiles(~[allfiles.isdir]) = [];
allfiles=allfiles(3:end);

if insubfolders
    for i=1:size(allfiles,1)
        innerfolder = dir([pathname,allfiles(i).name,'\']);
        innerfolder(~[innerfolder.isdir]) = [];
        innerfolder=innerfolder(3:end);
        for j=1:size(innerfolder,1)
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_traces.csv']];
                channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_traces.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_traces.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_traces.csv']];
            channel2 = [channel2 [pathname,allfiles(i).name,'\Channel_2_traces.csv']];
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

%% 4) Manual Input
% concentration = [0.2 0.2 0.2 1 1 1 10 10 10 0.5 0.5 0.5 5 5 5 0.1 0.1 0.1 20 20 20];

%% 5) Measure the ratio of flourescence between channels for each area 
channel1reference = false; %if channel 2 is reference, put false

medianintensityratio = zeros(numofexps,1);
for i=1:numofexps
    channelin = channel1(i);
    d1=csvread(channelin{1},1);
    channelin = channel2(i);
    d2=csvread(channelin{1},1);

    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    intensityratioin = zeros(numparticles,1);
    for j=1:numparticles
        meanin1 = mean(d1(d1(:,1)==j-1,15));
        meanin2 = mean(d2(d2(:,1)==j-1,15));

        intensityratioin(j) = meanin1;
        if channel1reference
            intensityratioin(j) = meanin2;
        end
    end

    medianintensityratio(i) = median(intensityratioin);
end

%% 6) Fit binding Curve

x = concentration';
yx = medianintensityratio;%./[1./SingleMoleculeBleachingRatio].*LabellingRatio;

%Only plotting a subset of concentrations, handpicking data
% yx = yx(x==1 | x==5 | x==10 | x ==20 | x==30 | x==50 | x==100);
% x = x(x==1 | x==5 | x==10 | x ==20 | x==30 | x==50 | x==100);


y = @(b,x)( b(1).*x+b(2));             % Objective function
OLS = @(b) sum((y(b,x) - yx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
B = fminsearch(OLS, [median(yx./x) 0], opts);
disp(['Positive offset was calculated at ',num2str(B(2)),' and slope of ',num2str(B(1))]);
%% Plot Binding Curve

xout = 0:0.1:1.1*max(x);
yout = y(B,xout);
figure
scatter(x,yx)
hold on
title('Background of binder')
xlabel(['Concentration of binder (', Concentrationunits,')']) % x-axis label
ylabel('Binder channel background intensity (a.u.)') % y-axis label
plot(xout,yout)
hold off