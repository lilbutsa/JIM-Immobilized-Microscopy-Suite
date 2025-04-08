%% 1) Select the input tiff file Create a Folder for results
additionalExtensionsToRemove = 0;

[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
%Convert to the file path for the C++ Jim Programs
fileEXE = '"';
fileSep = '';
if ismac
    JIM = ['"',fileparts(JIM),'/Mac_Programs/'];
    fileSep = '/';
elseif ispc
    JIM = ['"',fileparts(JIM),'\Jim_Programs\'];
    fileEXE = '.exe"';
    fileSep = '\';
else
    disp('Platform not supported')
end

[fileName,pathName] = uigetfile('*','Select the Image file');%Open the Dialog box to select the initial file to analyze

overlayColour1 = [1, 0, 0];
overlayColour2 = [0, 1, 0];
overlayColour3 = [0, 0, 1];

completeName = [pathName,fileName];
[fileNamein,name,~] = fileparts(completeName);%get the name of the tiff image
for j=1:additionalExtensionsToRemove
    workingDir = [fileNamein,fileSep,name];
    [fileNamein,name,~] = fileparts(workingDir);
end
workingDir = [fileNamein,fileSep,name];

%%
cmd = [JIM,'Picasso_Raw_Converter',fileEXE,' "',completeName,'" "',workingDir,'"'];
returnVal = system(cmd);

%%
if(exist([workingDir '_locs_undrift.hdf5'])>0)
    cmd = ['picasso render "' workingDir '_locs_undrift.hdf5" -o 1 -b none --scaling yes -c gray -s'];
    returnVal = system(cmd);
    Imin = imread([workingDir '_locs_undrift.png']);
else
    cmd = ['picasso render "' workingDir '_locs.hdf5" -o 1 -b none --scaling yes -c gray -s'];
    returnVal = system(cmd);
    Imin = imread([workingDir '_locs.png']);
end
Imin = cast(Imin(:, :, 1),'uint16').*255;
imshow(Imin)
imwrite(Imin,[workingDir '_picasso_out.tif'])
%%

%%
