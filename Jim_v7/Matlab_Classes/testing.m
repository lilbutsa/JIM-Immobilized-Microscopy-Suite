myJim = JIM_Commands();
%%
myData = JIM_Data('G:\Group_Jim_Data\KM\may4-21-beads_2\may4-21-beads_2_MMStack_Pos0.ome\');

%%
figure
hold on
plot(median(myData.traces{1}))
plot(median(myData.traces{2}))
ylim([0 50000])
hold off
%% normalized
figure
hold on
toplot = median(myData.traces{1});
plot(toplot./max(toplot))
toplot = median(myData.traces{2});
plot(toplot./max(toplot))
ylim([0 1])
hold off

%%
stepfitIterations = 10000;
myData = myData.parseSingleStepData(myJim.singleStepfit(myData.traces{1},stepfitIterations));
%%
