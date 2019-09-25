%%
clear
%% 1) get the working folder
[jimpath,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
JIM = [fileparts(jimpath),'\Jim_Programs\'];
pathname = uigetdir();
pathname=[pathname,'\'];

%% 2) Find all traces
insubfolders = false;

channel1 = {};

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
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Fluorescent_Intensities.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%%
threshold =1.25;%1.35;%0.4;
singleintensity = 12600;


exptoplot = 5;
pagenumber = 1;

firststeps = [];
allmeans = [];
diffmeans = [];
filtereddiffmeans = [];
posdeltatsteps = [];
firstposdeltatsteps = [];
alldeltatsteps = [];

allfirststeps = [];

fltotal = 0;

figure
set(gcf, 'Position', [100, 100, 1500, 800])

for expcount=8:10%2:numofexps
   
    traces=csvread(channel1{expcount},1);
    
    tracestoselect = [];
    for i=1:size(traces,1)
        last0 = find(traces(i,:)./singleintensity<0.5,1,'last');
        if size(last0,2)>0 && max(traces(i,last0:end))/singleintensity>0.5 && traces(i,end)/singleintensity>0.2
            tracestoselect  = [tracestoselect i];
        end
    end
    filteredtraces = traces(tracestoselect,:);
    
    for i=1:size(filteredtraces,1)
        tracein = filteredtraces(i,:)'./singleintensity;
        steps = findchangepts(tracein,'MinThreshold', threshold, 'Statistic', 'mean');
        
        if size(steps,1)>0
            means = zeros(size(steps,1)+1,1);
            steplinex = zeros(2.*size(means,1),1);
            stepliney = zeros(2.*size(means,1),1);
            means(1) = mean(tracein(1:steps(1)-1));
            means(size(means,1)) = mean(tracein(steps(size(steps,1)):end));

            steplinex(1) = 0;
            steplinex(2) = steps(1)-0.5;
            steplinex(2*size(means,1)-1) = steps(size(steps,1))-0.5;
            steplinex(2*size(means,1)) = size(tracein,1);

            for j=2:size(steps,1)

                means(j) = mean(tracein(steps(j-1):steps(j)-1));
                steplinex(2*j-1) = steps(j-1)-0.5;
                steplinex(2*j) = steps(j)-0.5;

            end

            for j=1:size(means,1)
                stepliney(2*j-1) = means(j);
                stepliney(2*j) = means(j);
            end

        else
            means = mean(tracein);
            steplinex = [0 size(tracein,1)];
            stepliney = [mean(tracein) mean(tracein)];
        end
        
        idx = find(means<0.5,1,'last');
        
        allmeans = [allmeans;means];
        diffmeans = [diffmeans;diff(means)];
        
         filtereddiffmeans = [filtereddiffmeans;diff(means(idx:end))];
 
         stepdiff = diff(steps);
            alldeltatsteps = [alldeltatsteps;stepdiff];

        
        fltotal=fltotal+sum(tracein(1:end));

        
         if idx<size(means,1)
             firststeps = [firststeps means(idx+1)-means(idx)];

         end
         
         if size(idx,1)==0
             idx=size(diff(means),1)+1;
         end
         
         if size(means,1)>1 
             stepsign= sign(diff(means))==1 & ((1:size(diff(means),1))>=idx)';
             if size(find(stepsign==1),1)>1
                 posstepsin = diff(steps(stepsign));
                posdeltatsteps = [posdeltatsteps;posstepsin];
                 firstposdeltatsteps = [firstposdeltatsteps;posstepsin(1)];
             end
         end
         
         
         idx = intersect(find(means<0.5),find(means>0.5)-1);
         idx = idx(idx<=size(stepdiff,1));
         allfirststeps = [allfirststeps;stepdiff(idx)];

            if i > 36*(pagenumber-1)&& i <= 36*(pagenumber) && expcount==exptoplot
                subplot(6,6,i-36*(pagenumber-1))
                hold on
                plot(tracein,'-r');
                plot([0 size(tracein,1)],[0 0] ,'-black');
                plot(steplinex,stepliney,'-b');
                hold off
            end
    end

end
    
%%
figure
histogram(filtereddiffmeans,-4:0.1:4) 
xlim([-4 4]);
disp([num2str(100*size(filtereddiffmeans(filtereddiffmeans>0),1)./size(filtereddiffmeans,1)) ' % of the time steps are positive']);
%%
possteps = 12600.*filtereddiffmeans(filtereddiffmeans>0);
posstephistcounts = histcounts(possteps,0:0.1*12600:4*12600);
posstephistcounts = posstephistcounts./sum(posstephistcounts);
%%
%photobleaching = csvread('E:\From_Illy\2018113_NGASTpm18_all_step_heights.csv',0);
%pbhistcounts = histcounts(photobleaching,0:0.1*12600:4*12600);
photobleaching = csvread('G:\Group_Jim_Data\jimilly\Final_Single_Molecule\allnumoffluor_Tpm18.csv',0);
pbhistcounts = histcounts(12600.*photobleaching,0:0.1*12600:4*12600);
pbhistcounts = pbhistcounts./sum(pbhistcounts);
%%
possteps = 12600.*-1.*filtereddiffmeans(filtereddiffmeans<0);
posstephistcounts2 = histcounts(possteps,0:0.1*12600:4*12600);
posstephistcounts2 = posstephistcounts2./sum(posstephistcounts2);
%%
firststep2 = 12600.*firststeps;
firststephist = histcounts(firststep2,0:0.1*12600:4*12600);
firststephist = firststephist./sum(firststephist);
%%
figure
hold on
plot(0.05*12600:0.1*12600:4*12600,posstephistcounts)
plot(0.05*12600:0.1*12600:4*12600,pbhistcounts)
plot(0.05*12600:0.1*12600:4*12600,posstephistcounts2)
plot(0.05*12600:0.1*12600:4*12600,firststephist)
hold off
%%
framespersecond = 4;


tofit = posdeltatsteps;
%tofit = alldeltatsteps+1;


bxin = sort(tofit./framespersecond);
byin = size(tofit,1):-1:1;


byin2 = byin(byin<0.9.*size(tofit,1));
byx = byin2(byin2>0.1.*size(tofit,1));

bxin2=bxin(byin<0.9.*size(tofit,1));
bx = bxin2(byin2>0.1.*size(tofit,1))';


by = @(b,bx)( b(1)*exp(-b(2)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(tofit,1) 3/max(tofit)], opts);

%Bb(2) = 0.285;
%Bb(2) = 0.34;

bxin = 0:max(tofit);
byxin = by(Bb,bxin);


 figure
 hold on
 %histogram(posdeltatsteps,50,'Normalization', 'pdf');
 plot(sort(tofit./framespersecond),size(tofit,1):-1:1);
 plot(bxin,byxin,'-r');
 xlim([0 20])
 hold off
 
disp(['The rate of polymerisation is ' num2str(Bb(2)) ' per second']);


%%
figure 
plot(sort(posdeltatsteps./framespersecond),size(posdeltatsteps,1):-1:1);


%%
figure
histogram(alldeltatsteps./framespersecond)
%%
framespersecond = 4;


tofit = allfirststeps;
%tofit = firstposdeltatsteps;

bxin = sort(tofit./framespersecond);
byin = size(tofit,1):-1:1;


byin2 = byin(byin<0.9.*size(tofit,1));
byx = byin2(byin2>0.001.*size(tofit,1));

bxin2=bxin(byin<0.9.*size(tofit,1));
bx = bxin2(byin2>0.001.*size(tofit,1))';


by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3)*exp(-b(4)*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(tofit,1)/2 100/max(tofit)  size(tofit,1)/2 1/max(tofit)], opts);


by = @(b,bx)( b(1)*exp(-b(2)*bx)+b(3)*exp(-0.39*bx));             % Objective function
OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
Bb = fminsearch(OLS, [size(tofit,1)/2 0.8  size(tofit,1)/2], opts);


bxin = 0:max(tofit);
byxin = by(Bb,bxin);


 figure
 hold on
 histogram(posdeltatsteps,50,'Normalization', 'pdf');
 plot(sort(tofit./framespersecond),size(tofit,1):-1:1);
 plot(bxin,byxin,'-r');
 xlim([0 24])
 hold off
 
disp(['The rate of polymerisation is ' num2str(Bb(2)) ' per second']);

%%
possteps = 12600.*firststeps(firststeps>0);
posstephistcounts3 = histcounts(possteps,0:0.1*12600:4*12600);
posstephistcounts3 = posstephistcounts3./sum(posstephistcounts3);
%%
figure
hold on
%plot(0.05*12600:0.1*12600:4*12600,posstephistcounts)
plot(0.05*12600:0.1*12600:4*12600,pbhistcounts)
plot(0.05*12600:0.1*12600:4*12600,posstephistcounts3)
hold off