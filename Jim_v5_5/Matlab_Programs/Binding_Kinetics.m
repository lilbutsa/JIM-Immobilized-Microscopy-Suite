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

%%  Importing wash-in or wash-out JIM outputs 
    exptocheck = 45;
    
    channel1reference = false;
    
    
    secperframe = 3; %change frame rate, how many sec do you wait before acquisition of next frame
    substrate_photobleaching = 1;
    binder_photobleaching = 1;
    substrate_partial_labelling = 1; %note that it is the factor that is considered here for label to unlabel ratio, it is a fraction
    binder_partial_labelling = 1; 
    
    d1=csvread(channel1{exptocheck},1);
    d2=csvread(channel2{exptocheck},1);
    b1=csvread(channel1b{exptocheck},1);
    b2=csvread(channel2b{exptocheck},1);

    numparticles = size(d1,1);
  
    
    if channel1reference  
        backgrounds = b2;
        intensitiesin = d2./d1.*substrate_photobleaching.*substrate_partial_labelling./binder_photobleaching./binder_partial_labelling;
        bindertosubstrateratio = d2./d1;
    else
         backgrounds = b1;
        intensitiesin = d1./d2.*substrate_photobleaching.*substrate_partial_labelling./binder_photobleaching./binder_partial_labelling;
        bindertosubstrateratio = d1./d2;
    end

    cd(strcat(pathname, allfiles(exptocheck).name));
    csvwrite('Bindertosubstrateratio.csv', bindertosubstrateratio);
    
%%  plot intensity ratio of all the particles in FOV
figure
hold on
for j=1:numparticles
    plot((1:size(d1,2))*secperframe,intensitiesin(j,:))
end
title('Plot of Intensity Ratio for All Particles in FOV');
xlabel('Time (sec)');
ylabel('Number of binder per substrate');
ylim([0 2.5*max(intensitiesin(j,:))]); %used 1.5x the max of y value
hold off

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
title('Comparison of binder (red) vs background signal (blue)');
xlabel('Time (sec)')
ylabel('Normalised intensity')

%% with offset - single exponential fitting
    medianint = median(intensitiesin);
    upperfitcutoff = 0.985;
    lowerfitcutoff = -0.075;
    bx = 1:size(medianint,2);
    byx = medianint;
       
    bx = bx(byx<upperfitcutoff*max(byx)&byx>lowerfitcutoff*max(byx));
    byx = byx(byx<upperfitcutoff*max(byx)&byx>lowerfitcutoff*max(byx));


    by = @(b,bx)( b(1)+b(2)*exp(-b(3)*bx));  
    OLS = @(b) sum((by(b,bx) - byx).^2);          % Ordinary Least Squares cost function
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    Bb = fminsearch(OLS, [medianint(end) medianint(1)-medianint(end) 3/size(medianint,2)], opts);
    
    disp(['Median rates (koff or kobs) calculates at ' num2str(Bb(3)./secperframe) ' per sec']);

%% Single exp fit

ricksavethis = median(intensitiesin)';

byout = by(Bb,bx);
figure
hold on
plot(1:size(d1,2),median(intensitiesin),'-g','LineWidth',2)
plot(bx,byx,'LineWidth',2);
plot(bx,byout,'-r','LineWidth',2);
hold off
title('Fitting of single exponential. Data not used (green), used (blue), fitted (red)')
xlabel('Time (frame)')
ylabel('Binder per substrate')

%% fit each particle separately
eachparticlefit = zeros(size(intensitiesin,1),1);

for i=1:size(intensitiesin,1)
    medianint = intensitiesin(i,:);
    
    bx = 1:size(medianint,2);
    byx = medianint;
       
    bx = bx(byx<upperfitcutoff.*max(byx)&byx>lowerfitcutoff.*max(byx));
    byx = byx(byx<upperfitcutoff.*max(byx)&byx>lowerfitcutoff.*max(byx));


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

%%
figure
hold on
histogram(eachparticlefit,0:0.005:0.1)
xlabel('Kobs (1/s)')
ylabel('Count')
plot([0.053 0.053],ylim,'-r')
hold off
%%
figure
plot(bx,byx)