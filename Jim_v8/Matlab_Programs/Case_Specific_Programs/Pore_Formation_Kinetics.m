%%
clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% 2) Find all traces
insubfolders = true;

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
            channel1b = [channel1 [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Backgrounds.csv']];
             channel2b = [channel2 [pathname,allfiles(i).name,'\Channel_2_Fluorescent_Backgrounds.csv']]
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);

%%
twochannel = true;

for fileno=14:14%numofexps %change this to select certain files for example fileno = [1 2 5 7]
    
    disp(['Analysing file ' channel1{fileno}]);
    traces=csvread(channel1{fileno},1);   
    back1 = csvread(channel1b{fileno},1); 
    if twochannel
        tracesch2 =csvread(channel2{fileno},1);
        back2 = csvread(channel2b{fileno},1); 
    end
    
end
%%
%    tracesToSelect = max(tracesch2')'>minMaxVal & max(tracesch2')'<maxMaxVal & min(tracesch2')' < minMinVal & min(tracesch2')'>maxMinVal...
 %       & tracesch2(:,1) > minInitial & tracesch2(:,1) < maxInitial & tracesch2(:,end) > minFinal & tracesch2(:,end) < maxFinal;
    
 singleMolIntensity = 2500;
 InitialmaxliposomeIntensity = 500000;
 InitialminliposomeIntensity = 20000;
 
    minFinal = 10*singleMolIntensity;
    tracesToSelect =tracesch2(:,end) > minFinal & tracesch2(:,1) < 2*singleMolIntensity; % & traces(:,1) < InitialmaxliposomeIntensity& traces(:,1) > InitialminliposomeIntensity;
    filteredTraces = tracesch2(tracesToSelect,:);
    filteredliposomes = traces(tracesToSelect,:);
    
    nucframe=arrayfun(@(x)find(filteredTraces(x,:)<2*singleMolIntensity,1,'last'),1:size(filteredTraces,1))';
    %%
    figure
    plot(sort(nucframe),size(nucframe,1):-1:1)
        %%
    figure
    scatter(filteredliposomes(:,1),nucframe)
    %%
    figure
    plot(filteredliposomes')
    %% 
    figure
    plot(filteredTraces'./2500)
    ylim([0 50])
    %%
    figure
    histogram(filteredTraces(:,end)./2500,50)
    
    
    
    %%
    framesPerSecond = 0.1;
    singleMolIntensity = 2500;
    poppingthreshold = 0.6;
    twochannel = true;
    
    %tomeasure = 1:7;
    tomeasure = 8:14;
    concentrations = [1 0.5 2 5 3 1.5 0.75];
    
    nucrates = zeros(size(tomeasure,2),1);
    polyrates = zeros(size(tomeasure,2),1);
    polyratesafterpop = zeros(size(tomeasure,2),1);
    cmp = get(gca,'colororder');
figure
hold on
for fileno=tomeasure%numofexps %change this to select certain files for example fileno = [1 2 5 7]
    
    disp(['Analysing file ' channel1{fileno}]);
    traces=csvread(channel1{fileno},1);   
    back1 = csvread(channel1b{fileno},1); 
    if twochannel
        tracesch2 =csvread(channel2{fileno},1);
        back2 = csvread(channel2b{fileno},1); 
    end
     
 
    minFinal = 10*singleMolIntensity;
    tracesToSelect =tracesch2(:,end) > minFinal & tracesch2(:,1) < 2*singleMolIntensity; % & traces(:,1) < InitialmaxliposomeIntensity& traces(:,1) > InitialminliposomeIntensity;
    filteredTraces = tracesch2(tracesToSelect,:);
    filteredliposomes = traces(tracesToSelect,:);
    
    nucframe=arrayfun(@(x)find(filteredTraces(x,:)<2*singleMolIntensity,1,'last'),1:size(filteredTraces,1))';
    
    bxin = sort(nucframe./framesPerSecond);
    byin = (size(nucframe,1):-1:1)./size(nucframe,1);
    
    byin2 = byin(byin<1);
    byx = byin2(byin2>0);
    
    bxin2=bxin(byin<1);
    bx = bxin2(byin2>0)';


    by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [1 3/max(bxin) 0], opts);
    
    by1 = @(b,bx)( exp(-b(2)*bx));
    
  % plot(bxin,(byin-Bb(3))./Bb(1),'Color',cmp(find(tomeasure==fileno,1),:))
    bxin = 0:max(bxin);
    byxin = by1(Bb,bxin);
   % plot(bxin,byxin,'Color',cmp(find(tomeasure==fileno,1),:),'LineWidth',3)
    
    nucrates(find(tomeasure==fileno,1)) = Bb(2);
    
    nucaligned = cell2mat(arrayfun(@(x)[filteredTraces(x,nucframe(x)+1:end) zeros(nucframe(x),1)']',1:size(filteredTraces,1),'UniformOutput',false))';
    meanpoly = mean(nucaligned)';
    meanpoly = meanpoly(21:70)-meanpoly(21);
    %plot([1:size(meanpoly,1)]./framesPerSecond,meanpoly)
    
    polyrates(find(tomeasure==fileno,1)) = mean(meanpoly./([1:size(meanpoly,1)]'))./framesPerSecond;
    
    
    allbeforepops = [];
    allafterpops = [];
    for i=1:size(filteredliposomes,1)
        tracein = filteredliposomes(i,:)';
        normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
        steps = findchangepts(normedtrace,'MinThreshold', poppingthreshold, 'Statistic', 'mean');
        if size(steps,1)==1 && steps(1)>50
            allbeforepops = [allbeforepops;filteredTraces(i,steps(1)-49:steps(1))];
        end
        if size(steps,1)==1 && steps(1)<310
            allafterpops = [allafterpops;filteredTraces(i,steps(1):steps(1)+50)];
        end
    end
    
    meanafterpop = mean(allafterpops);
    meanafterpop = meanafterpop - meanafterpop(1);
    plot(-490:10:0,mean(allbeforepops))
    %plot(0:10:500,meanafterpop)
    
    polyratesafterpop(find(tomeasure==fileno,1)) = mean(meanafterpop./([1:size(meanafterpop,1)]'))./framesPerSecond;
end
%ylim([-0.1,1.1])
hold off
%%
figure
plot(meanpoly)

%%
figure
plot(median(allbeforepops))
%%
figure
scatter(concentrations,nucrates)
%%
figure
hold on
scatter(concentrations,polyrates)
P = polyfit(concentrations(concentrations~=5),polyrates(concentrations~=5)',1);
plot(0:5,P(1).*[0:5]+P(2));
hold off

%%
figure
hold on
scatter(concentrations,polyratesafterpop)
P = polyfit(concentrations(concentrations~=5),polyratesafterpop(concentrations~=5)',1);
plot(0:5,P(1).*[0:5]+P(2));
hold off