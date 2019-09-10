%%
clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];
%% If channel 2 reference, change the Channel_1 flourescence to Channel_2 (line 30 and 31)
insubfolders = true;

channel1 = {};
measurements = {};

allfiles = dir(pathname);
allfiles(~[allfiles.isdir]) = [];
allfiles=allfiles(3:end);

if insubfolders
    for i=1:size(allfiles,1)
        innerfolder = dir([pathname,allfiles(i).name,'\']);
        innerfolder(~[innerfolder.isdir]) = [];
        innerfolder=innerfolder(3:end);
        for j=1:size(innerfolder,1)
            if size(dir([pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']];
                measurements = [measurements [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Detected_Filtered_Measurements.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\Channel_1_Flourescent_Intensities.csv']];
            measurements = [measurements [pathname,allfiles(i).name,'\Detected_Filtered_Measurements.csv']];
        end 
    end
end

numofexps = size(channel1,2);

disp(['There are ',num2str(numofexps),' files to analyse']);
%% Same photobleach for all dataset
SingleMolPhotoBleaching = 175;
umperpixel = 0.0866;

meantrace = [];
lengths = [];
for i=1:numofexps
    traces=csvread(channel1{i},1);
    meantrace = [meantrace;mean(traces,2)./SingleMolPhotoBleaching];
    
    d1 = csvread(measurements{i},1);
    lengths = [lengths;2.*d1(:,4).*umperpixel];
end

%%
fit  = robustfit(lengths,meantrace);
    bxout = 0:max(lengths);
    byout = fit(1)+fit(2)*bxout;

    disp(['Intensity of ' num2str(fit(2)) ' monomers per um']);

   figure
   hold on
   scatter(lengths,meantrace)
   plot(bxout,byout)
   xlabel('Length of tube (um)');
    ylabel('Fluorophore count')
   hold off
   
      %% 
figure
hold on
histogram2(lengths,meantrace,[0:0.06:3],[0:30:1500],'DisplayStyle','tile'); %you can change the number of mosaic tiles
plot(bxout,byout)
xlim([0 3])
ylim([0 1500])
xlabel('Length of tube (um)');
ylabel('Fluorophore count')
h = colorbar;
ylabel(h, 'Count');
hold off
figure
histogram(lengths,50)
xlabel('Length of tube (um)');
ylabel('Count');
figure
histogram(meantrace,50)
xlabel('Fluorophore count')
ylabel('Count');
%% Apply Threshold to select which subset of data to fit, lower threshold, more data
      threshold = 0.5;
figure
histdata = histogram2(lengths,meantrace,[0:0.06:3],[0:30:1500],'DisplayStyle','tile');
mycounts = histdata.BinCounts;
[highvalsx,highvalsy] = find(mycounts>threshold*max(max(mycounts)));
highcounts = mycounts(mycounts>threshold*max(max(mycounts)));
xvals = (histdata.XBinEdges(highvalsx)+histdata.XBinEdges(highvalsx))./2;
yvals = (histdata.YBinEdges(highvalsy)+histdata.YBinEdges(highvalsy))./2;

scatter(xvals,yvals)
xlim([0 3])
ylim([0 1500])

linearfit  = LinearModel.fit(xvals',yvals','Weights',highcounts);
fit = linearfit.Coefficients.Estimate;
    bxout = 0:max(lengths);
    byout = fit(1)+fit(2)*bxout;
    
   %%
figure
hold on
histogram2(lengths,meantrace,[0:0.06:3],[0:30:1500],'DisplayStyle','tile');
plot(bxout,byout,'LineWidth',2)
xlim([0 3])
ylim([0 1500])
xlabel('Length of tube (um)');
ylabel('Fluorophore count')
h = colorbar;
ylabel(h, 'Count');
hold off
 disp(['Intensity of ' num2str(fit(2)) ' monomers per um']);
 
 %%
 normlengths = lengths+fit(1)/fit(2);
 normmeantrace = meantrace(normlengths>0);
 normlengths = normlengths(normlengths>0);
 
 figure
 hold on
 histogram(normmeantrace./normlengths,0:10:1000)
 xlabel('Fluorophores per Length (1/um)');
 ylabel('Count')
plot([fit(2) fit(2)],ylim,'-r','LineWidth',2);
hold off

cd(strcat(pathname))
csvwrite('IntensitytoLengthratio.csv',intensitytolengthratio);
parametersforanalysis = {'Files analysed' num2str(numofexps); 'Photobleaching value of substrate used for analysis' num2str(SingleMolPhotoBleaching); 'Threshold used for fitting' num2str(threshold); 'Fluorophore per um (gradient)' num2str(fit(1)); 'y-intercept' num2str(fit(2))}; 
T = cell2table(parametersforanalysis);
T.Properties.VariableNames= {'Variable','Value'};
writetable(T, [pathname,'Parameters.csv']);