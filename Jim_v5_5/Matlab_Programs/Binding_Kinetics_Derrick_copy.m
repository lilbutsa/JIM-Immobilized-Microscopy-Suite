clear
%% 1) get the working folder
pathname = uigetdir();
pathname=[pathname,'\'];

%% 2) Find all traces
insubfolders = true;

channel1 = {};
channel2 = {};
channel1b = {};
channel2b = {};

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
                channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']];
                channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Flourescent_Intensities.csv']];
                channel1b = [channel1b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Backgrounds.csv']];
                channel2b = [channel2b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Flourescent_Backgrounds.csv']];
            end
        end
    end
else
    for i=1:size(allfiles,1)
        if size(dir([pathname,allfiles(i).name,'\Channel_1_traces.csv']),1)==1
            channel1 = [channel1 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Intensities.csv']];
            channel2 = [channel2 [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Flourescent_Intensities.csv']];
            channel1b = [channel1b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_1_Flourescent_Backgrounds.csv']];
            channel2b = [channel2b [pathname,allfiles(i).name,'\',innerfolder(j).name,'\Channel_2_Flourescent_Backgrounds.csv']];
        end 
    end
end

numofexps = size(channel1,2);
disp(['There are ' num2str(numofexps) ' files to analyse']);

%%  Importing wash-in or wash-out JIM outputs 
    exptocheck = 17;
    
    channel1reference = false;
    
    secperframe = 3; %change frame rate, how many sec do you wait before acquisition of next frame
    substrate_photobleaching = 1;
    binder_photobleaching = 1;
    substrate_partial_labelling = 1; %note that it is the fraction/factor that is considered here for label to unlabel ratio
    binder_partial_labelling = 1; 
    
    d1=csvread(channel1{exptocheck},1);
    d2=csvread(channel2{exptocheck},1);
    b1=csvread(channel1b{exptocheck},1);
    b2=csvread(channel2b{exptocheck},1);

    numparticles = size(d1,1);
  
    
    if channel1reference  
        backgrounds = b1; %if spiked in the dye reference channel; you can b1, otherwise use b2 (default)
        intensitiesin = d2./d1.*substrate_photobleaching.*substrate_partial_labelling./binder_photobleaching./binder_partial_labelling;
        bindertosubstrateratio = d2./d1;
    else
         backgrounds = b2; %if spiked in the dye reference channel; you can b2, otherwise use b1 (default)
        intensitiesin = d1./d2.*substrate_photobleaching.*substrate_partial_labelling./binder_photobleaching./binder_partial_labelling;
        bindertosubstrateratio = d1./d2;
    end

    cd(strcat(pathname, allfiles(exptocheck).name));
    csvwrite('Bindertosubstrateratio_allparticle.csv', bindertosubstrateratio);
    
%%  Plot intensity ratio of all the particles in FOV
figure
hold on
for j=1:numparticles
    plot((1:size(d1,2))*secperframe,intensitiesin(j,:))
end
title('Plot of Intensity Ratio for All Particles in FOV');
xlabel('Time (sec)');
% ylabel('Number of binder per substrate');
ylabel('Binder to CA intensity ratio');
ylim([0 2.5*max(intensitiesin(j,:))]); %used 1.5x the max of y value
hold off
savefig('Allparticles_bindingintensity.fig');

%% Plotting background of the binder channel
figure
hold on
for j=1:numparticles
    plot(secperframe*(1:size(d1,2)),backgrounds(j,:))
end
title('Background of binder channel');
xlabel('Time (sec)');
ylabel('Intensity of background');
hold off

%% Plotting of signal (red) vs background (blue) so we can compare
backmedian = median(backgrounds); %fetch median background intensity for every frame amongst all particles; this gives a X number of values where X is the number of frames
backmedian = (backmedian-min(backmedian))./(max(backmedian)-min(backmedian)); %normalising the background using the difference between max median and min median value as denominator. Using min median value takes care of background
medianint = median(intensitiesin);
medianint = (medianint-min(medianint))./(max(medianint)-min(medianint));
xvalueplot1 = secperframe*(1:size(d1,2));
transx1 = xvalueplot1';
figure
hold on
plot(xvalueplot1,backmedian,'LineWidth',2)
plot(xvalueplot1,medianint,'LineWidth',2)
hold off
title('Comparison of binder (red) vs background signal AF647 (blue)');
xlabel('Time (sec)')
ylabel('Normalised intensity')
savefig('Bkg_vs_binder.fig');
saveas(gcf,'Bkg_vs_binder.png');
medianint = median(intensitiesin);
csvwrite('Median_intensity_binder_ratio.csv',medianint');

%% with offset - single exponential fitting
    medianint = median(intensitiesin);
    upperfitcutoff = 1.1; %set the upper cutoff of the data you want to fit based on max value
    lowerfitcutoff = -0.075; %set the lower cutoff of the data you want to fit based on  max value
    framemin = [21,240]; %input first and last timepoint to fit
    
    bx = xvalueplot1; %1:size(medianint,2);
    byx = medianint;
    
    
    toselect = bx>=framemin(1) & bx<=framemin(2);%& byx<upperfitcutoff*max(byx) & byx>lowerfitcutoff*max(byx)
    bx = bx(toselect);
    byx = byx(toselect);


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));  
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [medianint(end) medianint(1)-medianint(end) 3/size(medianint,2)], opts);
    
    disp(['Median rates (koff or kobs) calculates at ' num2str(Bb(3)) ' per sec']);
    medianrate = Bb(3);
    csvwrite('Median_k_rate.txt',medianrate);
    allmedianrates = Bb;
    allmedianrates(3) = Bb(3);
    csvwrite('Frame_to_start_fit.txt',framemin);
    
%% Single exp fit

ricksavethis = median(intensitiesin)';

%byout = by(Bb,bx);
byout = by(Bb,framemin:secperframe:secperframe*size(d1,2));
figure
hold on
plot(secperframe:secperframe:secperframe*size(d1,2),median(intensitiesin),'-g','LineWidth',2)
plot(bx,byx,'LineWidth',2);
%plot(bx,byout,'-r','LineWidth',2);
plot(framemin:secperframe:secperframe*size(d1,2),byout,'-r','LineWidth',2);
hold off
title('Fitting of single exponential. Data not used (green), used (blue), fitted (red)')
xlabel('Time (sec)')
% ylabel('Binder per substrate')
ylabel('Binder to CA intensity ratio')
xlim([0,secperframe*size(medianint,2)])
savefig('Single_exp_fit.fig');
saveas(gcf,'Single_exp_fit.png');

%% fit each particle separately - optional
eachparticlefit = zeros(size(intensitiesin,1),1);

for i=1:size(intensitiesin,1)
    medianint = intensitiesin(i,:);
    
    bx = 1:size(medianint,2);
    byx = medianint;
       
    toselect = byx<upperfitcutoff*max(byx)&byx>lowerfitcutoff*max(byx)&bx>=framemin(1)&bx<=framemin(2);
    bx = bx(toselect);
    byx = byx(toselect);


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));  
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [medianint(end) medianint(1)-medianint(end) 3/size(medianint,2)], opts);
    
    eachparticlefit(i) = Bb(3)./secperframe;
end

cd(strcat(pathname, allfiles(exptocheck).name));
csvwrite('Fitted_rates_all_particles.csv',eachparticlefit);
csvwrite('upperthresholdfit.txt',upperfitcutoff);
csvwrite('lowerthresholdfit.txt',lowerfitcutoff);

%% Make a histogram of fitting every kobs/koff of every particles in a FOV
figure
hold on
histogram(eachparticlefit,0:0.002:0.1)
xlabel('koff (1/s)')
ylabel('Count')
plot([medianrate medianrate],ylim,'-r','linewidth',2)
hold off
%% Flattening process to make into a heatmap step 1; Must not used PB corrected values
flatintsin = reshape(intensitiesin,[],1);
timein = reshape(repmat(0:secperframe:secperframe*(size(intensitiesin,2)-1),size(intensitiesin,1),1),[],1);
%% Making the heatmap of binding step 2
by = @(b,bx)( b(1)+b(2)*exp(-b(3)*(bx+secperframe)));
bxout = 10:(secperframe*size(medianint,2))-0.5*secperframe;
byout = by(allmedianrates,bxout);
figure
hold on
histogram2(timein,flatintsin,[-0.5*secperframe:secperframe:secperframe*(size(intensitiesin,2)-0.5)],[-0.2:0.01*1.2:2.5],'DisplayStyle','tile');
plot(0:secperframe:secperframe*(size(intensitiesin,2)-1),median(intensitiesin)','-black','LineWidth',1)
plot(bxout,byout,'-r','LineWidth',1)
ylim([-0.2,2.0]);
xlim([0 150]);
xlabel('Time (s)');
ylabel('Intensity ratio (CPSF6:CA)');
hold off

%% Heatmap background of channel2
medianb2 = median(b2);
flatintsinb = reshape(b2,[],1);
timein = reshape(repmat(0:secperframe:secperframe*(size(intensitiesin,2)-1),size(intensitiesin,1),1),[],1);
figure
hold on
%histogram2(timein,flatintsinb,[-0.5*secperframe:secperframe:secperframe*(size(intensitiesin,2)-0.5)],[480:1:600],'DisplayStyle','tile');
plot(0:secperframe:secperframe*(size(intensitiesin,2)-1),median(b2)','-black','LineWidth',2)
xlim([0 150]);
xlabel('Time (s)');
ylabel('AF647 signal (a.u.)');
hold off