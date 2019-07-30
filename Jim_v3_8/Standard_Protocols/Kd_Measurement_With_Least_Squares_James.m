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
disp(['There are ' num2str(numofexps) ' files to analyse']);
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
concentration = [0.2 0.2 0.2 1 1 1 10 10 10 0.5 0.5 0.5 5 5 5 0.1 0.1 0.1 20 20 20];

%% 5) Measure the ratio of flourescence between channels for each area 
channel1reference = false;

medianintsenityratio = zeros(numofexps,1);
leastsquaresratio = zeros(numofexps,1);
for i=1:numofexps
    channelin = channel1(i);
    d1=csvread(channelin{1},1);
    channelin = channel2(i);
    d2=csvread(channelin{1},1);

    numparticles = max(d1(:,1))+1;

    intensityin = zeros(numparticles,2);
    for j=1:numparticles
        intensityin(j,1) = mean(d1(d1(:,1)==j-1,19));
        intensityin(j,2) = mean(d2(d2(:,1)==j-1,19));
    end
    
    if channel1reference
        medianintsenityratio(i) = median(intensityin(:,2)./intensityin(:,1));
        bx = intensityin(:,1);
        byx = intensityin(:,2);
    else
        medianintsenityratio(i) = median(intensityin(:,1)./intensityin(:,2));   
        bx = intensityin(:,2);
        byx = intensityin(:,1);
    end
    
    by = @(b,bx)( b(1)*bx);             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [medianintsenityratio(i)], opts);
    
    leastsquaresratio(i) = Bb(1);
    
    
    
end

%% 5b) Sanity Check for linearity
    exptocheck = 35;
    
    channelin = channel1(exptocheck);
    d1=csvread(channelin{1},1);
    channelin = channel2(exptocheck);
    d2=csvread(channelin{1},1);

    numparticles = max(d1(:,1))+1;
    numframes = max(d1(:,2))+1;

    intensitiesin = zeros(numparticles,2);
    for j=1:numparticles
        meanin1 = mean(d1(d1(:,1)==j-1,19));
        meanin2 = mean(d2(d2(:,1)==j-1,19));

        if channel1reference
            intensitiesin(j,:) = [meanin1 meanin2];
        else
            intensitiesin(j,:) = [meanin2 meanin1];
        end
    end
    
    
    xout = [0 max(intensitiesin(:,1))];
    yout = [0 max(intensitiesin(:,1)).*medianintsenityratio(exptocheck)];
        xout2 = [0 max(intensitiesin(:,1))];
    yout2 = [0 max(intensitiesin(:,1)).*leastsquaresratio(exptocheck)];
    disp(['Concentration is ' num2str(concentration(exptocheck)) ' Median Slope fit is ' num2str(medianintsenityratio(exptocheck)) ' Least squares slope is ' num2str(leastsquaresratio(exptocheck))]);
    figure
    scatter(intensitiesin(:,1),intensitiesin(:,2))
    title('Intensity correlation curve (Median Green, Least Squares Red)')
    xlabel('Subtrate intensity (a.u.)')
    ylabel('Binder intensity (a.u.)')
    hold on
    plot(xout,yout,'-g')
    plot(xout2,yout2,'-r')
    hold off

%% 6) Fit binding Curve
SingleMoleculeIntensityRatio = 1; %ratio of binder to substrate
LabellingRatio = 1./(1./concentration'); 


x = concentration';
yx = medianintsenityratio;%./[1./SingleMoleculeBleachingRatio].*LabellingRatio;

y = @(b,x)( b(1).*x./(b(2)+x));             % Objective function
OLS = @(b) sum((y(b,x) - yx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
B = fminsearch(OLS, [max(yx) 10], opts);
disp(['Median Kd was calculated at ',num2str(B(2)),' ',Concentrationunits,' and maximum binding ratio of ',num2str(B(1))]);
%% Plot Binding Curve

xout = 0:0.1:2*max(x);
yout = y(B,xout);
figure
scatter(x,yx)
hold on
xlabel(['Concentration ',Concentrationunits]) % x-axis label
ylabel('Bound Binder per Subtrate') % y-axis label
plot(xout,yout)
hold off
%% Same using least squares
x = concentration';
yx = leastsquaresratio;%./[1./SingleMoleculeBleachingRatio].*LabellingRatio;

y = @(b,x)( b(1).*x./(b(2)+x));             % Objective function
OLS = @(b) sum((y(b,x) - yx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
B = fminsearch(OLS, [max(yx) 10], opts);
disp(['Least squares Kd was calculated at ',num2str(B(2)),' ',Concentrationunits,' and maximum binding ratio of ',num2str(B(1))]);

%% Plot Binding Curve

xout = 0:0.1:2*max(x);
yout = y(B,xout);
figure
scatter(x,yx)
hold on
xlabel(['Concentration ',Concentrationunits]) % x-axis label
ylabel('Bound Binder per Subtrate') % y-axis label
plot(xout,yout)
hold off
