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

%% run this only if channel 2 is your substrate
chhold = channel2;
channel2=channel1;
channel1 = chhold;

chhold = channel2b;
channel2b=channel1b;
channel1b = chhold;

%% 3) Extract Traces read in file to check
threshold = 0.6;
twochannel = true;
solexchangechannel = 1;

exampletoplot =1;
pagenumber = 1;


allmeantraces = {};
allmeansinglesteptraces = {};
allpoptimeshist = {};
allpoptimeshistedges = {};
allmeanch2traces = {};
allch2popint = {};
allch2popintedge = {};
allch2singlesteptrace = {};
allpoptimes = {};
backmean1={};
backmean2={};

for fileno=1:numofexps %change this to select certain files for example fileno = [1 2 5 7]
    
    disp(['Analysing file ' channel1{fileno}]);
    traces=csvread(channel1{fileno},1);   
    back1 = csvread(channel1b{fileno},1); 
    if twochannel
        tracesch2 =csvread(channel2{fileno},1);
        back2 = csvread(channel2b{fileno},1); 
    end

    if fileno==exampletoplot
          figure
        set(gcf, 'Position', [100, 100, 1500, 800])
        for i=1:36
            subplot(6,6,i)
            hold on
            plot(traces(i+36*(pagenumber-1),:)./max(traces(i+36*(pagenumber-1),:)),'-r');
            if twochannel
               plot(tracesch2(i+36*(pagenumber-1),:)./max(tracesch2(i+36*(pagenumber-1),:)),'-b'); 
            end
            plot([0 size(traces(i+36*(pagenumber-1),:),2)],[0 0] ,'-black');
            hold off
        end
    end

    FHEXEC = @(FH) FH();
    FHSELECT = @(TF,CONDITION) TF(CONDITION==[true,false]);
    IF = @(CONDITION,TRUEFUNC,FALSEFUNC) FHEXEC( FHSELECT([TRUEFUNC,FALSEFUNC],CONDITION)); 
    if solexchangechannel == 1
        meanback = mean(back1);
    else
        meanback = mean(back2);
    end
    
    bx = 1:length(meanback);
    byx = meanback;
    x0 = mean(meanback(1:5));
    x1 = x0+0.1*(max(meanback)-mean(meanback(1:5)));
    by = @(b,bx)(arrayfun(@(k) IF(k<b, x0, x1),bx));             % Objective function
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    alldiffs = arrayfun(@(k) OLS(k),bx);
    [~,solexchange] = min(alldiffs);
    disp(['Background exchange occurs in Frame  ',num2str(solexchange)]);


%      if fileno == 4
%          solexchange=solexchange+16;
%      end
%      if fileno == 5
%          solexchange=solexchange+5;
%      end
%      if fileno >= 6 && fileno <= 9
%          solexchange=solexchange-2;
%      end

    traces=traces(:,solexchange:end); 
    back1 = back1(:,max([solexchange-10 1]):end); 
    if twochannel
        tracesch2 =tracesch2(:,solexchange:end);
        back2 = back2(:,max([solexchange-10 1]):end); 
    end
    

    % 5) Step Fit
    bleachtime = [];
    stepheight = [];
    singlesteptrace = [];
    stepmeans=[];
    snr = [];
    meanch2traces = [];
	ch2popint = [];
    ch2singlesteptrace=[];
    
    traces = traces(max(traces')>0,:);
    for i=1:size(traces,1)
        tracein = traces(i,:)';
              

        normedtrace = (tracein-min(tracein))./(max(tracein)-min(tracein));
        steps = findchangepts(normedtrace,'MinThreshold', threshold, 'Statistic', 'mean');
        if size(steps,1)==1
            meanhigh = mean(tracein(1:steps));
            meanlow = mean(tracein(1+steps:end));
            if 0.8*meanhigh<(meanhigh-meanlow)&meanhigh>0 
                bleachtime = [bleachtime steps];
                stepheight = [stepheight meanhigh-meanlow];
                singlesteptrace = [singlesteptrace tracein];
                stepmeans = [stepmeans; [meanhigh meanlow]];
                snr = [snr;(meanhigh-meanlow)./std([(tracein(1:steps)-meanhigh); tracein(1+steps:end)-meanlow])]; 

                if twochannel
                ch2popint = [ch2popint; tracesch2(i,steps)];
                ch2singlesteptrace = [ch2singlesteptrace;tracesch2(i,:)];
                end
            end

        end
    end
    % 6) Plot single step traces
    if fileno==exampletoplot
        figure
        set(gcf, 'Position', [100, 100, 1500, 800])

        for i=1:36
            subplot(6,6,i)
            hold on
            plot(singlesteptrace(:,i+36*(pagenumber-1))./max(singlesteptrace(:,i+36*(pagenumber-1))),'-r');
            if twochannel
                plot(ch2singlesteptrace(i+36*(pagenumber-1),:)./max(ch2singlesteptrace(i+36*(pagenumber-1),:)),'-B');
            end
            plot([0 size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[0 0] ,'-black');
            plot([0 bleachtime(i+36*(pagenumber-1)) bleachtime(i+36*(pagenumber-1)) size(singlesteptrace(:,i+36*(pagenumber-1)),1)],[stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),1) stepmeans(i+36*(pagenumber-1),2) stepmeans(i+36*(pagenumber-1),2)]./max(singlesteptrace(:,i+36*(pagenumber-1))) ,'-black');
            hold off
        end
        
        figure
            plot(mean(traces))
            title('Mean of all traces');
        figure
            plot(mean(singlesteptrace,2))
            title('Mean of single step traces')
        figure
            histogram(bleachtime,30)
            title('Popping Times')
    end
    
    allmeantraces = [allmeantraces;mean(traces)];
    allmeansinglesteptraces = [allmeansinglesteptraces;mean(singlesteptrace,2)'];
    [h,hedges] = histcounts(bleachtime,25,'Normalization','pdf');
    allpoptimeshist = [allpoptimeshist;h];
    allpoptimeshistedges = [allpoptimeshistedges;0.5*hedges(1:end-1)+0.5*hedges(2:end)];
    allpoptimes = [allpoptimes bleachtime];
    
    backmean1 = [backmean1;mean(back1)];
    
    if twochannel
        [h,hedges] = histcounts(ch2popint,-2500:5000:100000,'Normalization','pdf');
        allch2popint = [allch2popint;h];
        allch2popintedge = [allch2popintedge;0.5*hedges(1:end-1)+0.5*hedges(2:end)];
        allmeanch2traces = [allmeanch2traces;mean(tracesch2)];
        allch2singlesteptrace = [allch2singlesteptrace;mean(ch2singlesteptrace)];
        backmean2 = [backmean2;mean(back2)];
    end 
end


%%
frameinterval = 10;
concentrations = ['1   nM';'0.5 nM';'2   nM';'5   nM';'3   nM';'1.5 nM';'0.8 nM'];
connum = [1 0.5 2 5 3 1.5 0.75];

figure
hold on
g  = [1:7];
for i =1:length(g)
    diffsout = diff(allpoptimeshistedges{g(i)});
    plot(frameinterval.*allpoptimeshistedges{g(i)},1-diffsout(1).*cumsum(allpoptimeshist{g(i)}))
end
title('Popping Survival Curve');
xlabel('Time (s)')
ylabel('Percent Unpopped')
xlim([0 3600])
hold off
legend(concentrations)

%%
figure
hold on
for i =1:length(g)
    diffsout = diff(allpoptimeshistedges{g(i)});
    plot(frameinterval.*allpoptimeshistedges{g(i)},allpoptimeshist{g(i)})
end
title('Popping Time Distribution');
xlabel('Time (s)')
ylabel('Percent Popping')
xlim([0 3600])
hold off
legend(concentrations)

%%
figure
hold on
for i =1: length(g)
    toplot = rescale(backmean2{g(i)});
    plot(1:length(toplot),toplot)
end
title('Mean of Channel 1 backgrounds MES pH 6.5 Max Pixel Count 40');
xlim([-10 40])
hold off
title('Solution Exchange');
xlabel('Frame')
ylabel('Background Intensity')
hold off
legend(concentrations,'Location','northwest')


%%
figure
hold on
for i =1: length(g)
    toplot = rescale(backmean2{g(i)});
    plot(1:length(toplot),toplot)
end
title('Mean of Channel 1 backgrounds MES pH 6.5 Max Pixel Count 40');
xlim([-10 200])
hold off
title('Binder Background Intensity');
xlabel('Frame')
ylabel('Background Intensity')
hold off
legend(concentrations,'Location','southeast')

%%
figure
hold on
for i =1: length(g)
plot(frameinterval.*([1:length(allch2singlesteptrace{g(i)})]),allch2singlesteptrace{g(i)})
end
title('Mean of All Binding to Single Popping Liposome');
hold off
xlim([0 3600])
xlabel('Time (s)')
ylabel('Intensity')
legend(concentrations,'Location','northwest')
%%
figure
hold on
for i =1: length(g)
    toplot = allch2singlesteptrace{g(i)};
    toplot = toplot(1:60);
    plot(frameinterval.*([1:length(toplot)]),rescale(toplot))
end
title('Mean of All Binding to Single Popping Liposome');
hold off
xlabel('Time (s)')
ylabel('Intensity')
legend(concentrations,'Location','northwest')
%%
figure
hold on
for i =1: length(g)
    toplot = allch2singlesteptrace{g(i)};
    toplot = toplot(1:30);
    plot(frameinterval.*([1:length(toplot)]),toplot./connum(i))
end
title('Mean of All Binding per nM');
hold off
xlabel('Time (s)')
ylabel('Intensity per nM')
legend(concentrations,'Location','northwest')
%%
figure
hold on
for i =1:length(g)
plot(allch2popintedge{g(i)},allch2popint{g(i)})
end
title('Popping Intensity');
hold off
xlim([0,100000])
xlabel('Intensity')
ylabel('Probability')
legend(concentrations,'Location','northeast')
%%
figure
hold on
%g  = [1:17];
% for i=1:15%size(allmeansinglesteptraces,1)
for i =1: length(g)
    toplot = allmeansinglesteptraces{g(i)};
    plot(toplot./max(toplot))
end
        title('Mean of all single step traces MES pH 6.5 Max Pixel Count 40');
hold off





