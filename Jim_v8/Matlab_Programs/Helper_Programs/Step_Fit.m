%%Run First section of File Selector First

%%
sysConst.JIM = '"C:\Users\Jameswa\Documents\GitHub\JIM-Immobilized-Microscopy-Suite\Jim_v7\c++_Base_Programs\Windows\';
sysConst.fileEXE = '.exe"';

stepfitChannel = 1;
stepfitThreshold = 10;
for i=1:length(allData)
    workingDir = [fileparts(allData(i).intensityFileNames{stepFitChannel}),filesep];
    sysVar.cmd = [sysConst.JIM,'Step_Fitting',sysConst.fileEXE,' "',workingDir,'Channel_',num2str(stepfitChannel),'_Fluorescent_Intensities.csv','" "',workingDir,'Channel_',num2str(stepfitChannel),'" -TThreshold ',num2str(stepfitThreshold)];
    system(sysVar.cmd);
end

disp('Step fitting completed');