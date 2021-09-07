%Select Parameters File

[fileName,pathName] = uigetfile('*','Select the Parameter File');

generateTracesFileName = '\Begin_Here_Generate_Traces.m';

completeName = [pathName,fileName];
paramtab = readtable(completeName,'Format','%s%s');
paramtab = paramtab(2:end,2);
paramtab = table2cell(paramtab);
falsetrue = ['false;';'true; '];
[JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);
line = splitlines(fileread([JIM,generateTracesFileName]));
%% Import the paramaters to the file
toreplace = find(contains(line,'additionalExtensionsToRemove','IgnoreCase',true),1);
line{toreplace} = ['additionalExtensionsToRemove = ',paramtab{1},';'];

toreplace = find(contains(line,'multipleFilesPerImageStack','IgnoreCase',true),1);
line{toreplace} = ['multipleFilesPerImageStack = ',falsetrue((paramtab{2}=='1')+1,:),''];

toreplace = find(contains(line,'useMetadataFile','IgnoreCase',true),1);
line{toreplace} = ['useMetadataFile = ',falsetrue((paramtab{3}=='1')+1,:),''];

toreplace = find(contains(line,'numberOfChannels','IgnoreCase',true),1);
line{toreplace} = ['numberOfChannels = ',paramtab{4},';'];

toreplace = find(contains(line,'invertChannel','IgnoreCase',true),1);
line{toreplace} = ['invertChannel = ',falsetrue((paramtab{5}=='1')+1,:)];

toreplace = find(contains(line,'channelToInvert','IgnoreCase',true),1);
line{toreplace} = ['channelToInvert = ',paramtab{6},';'];

toreplace = find(contains(line,'iterations','IgnoreCase',true),1);
line{toreplace} = ['iterations = ',paramtab{7},';'];

toreplace = find(contains(line,'alignStartFrame','IgnoreCase',true),1);
line{toreplace} = ['alignStartFrame = ',paramtab{8},';'];

toreplace = find(contains(line,'alignEndFrame','IgnoreCase',true),1);
line{toreplace} = ['alignEndFrame = ',paramtab{9},';'];

toreplace = find(contains(line,'manualAlignment','IgnoreCase',true),1);
line{toreplace} = ['manualAlignment = ',falsetrue((paramtab{10}=='1')+1,:)];

toreplace = find(contains(line,'rotationAngle','IgnoreCase',true),1);
line{toreplace} = ['rotationAngle = ',paramtab{11},';'];

toreplace = find(contains(line,'scalingFactor','IgnoreCase',true),1);
line{toreplace} = ['scalingFactor = ',paramtab{12},';'];

toreplace = find(contains(line,'xoffset','IgnoreCase',true),1);
line{toreplace} = ['xoffset = ',paramtab{13},';'];

toreplace = find(contains(line,'yoffset','IgnoreCase',true),1);
line{toreplace} = ['yoffset = ',paramtab{14},';'];

toreplace = find(contains(line,'maxShift','IgnoreCase',true),1);
line{toreplace} = ['maxShift = ',paramtab{15},';'];

toreplace = find(contains(line,'maxIntesities','IgnoreCase',true),1);
line{toreplace} = ['maxIntesities = ''',paramtab{16},''';'];

toreplace = find(contains(line,'SNRCutoff','IgnoreCase',true),1);
line{toreplace} = ['SNRCutoff = ',paramtab{17},';'];

toreplace = find(contains(line,'useMaxProjection','IgnoreCase',true),1);
line{toreplace} = ['useMaxProjection = ',falsetrue((paramtab{18}=='1')+1,:)];

toreplace = find(contains(line,'detectionStartFrame','IgnoreCase',true),1);
line{toreplace} = ['detectionStartFrame = ''',paramtab{19},''';'];

toreplace = find(contains(line,'detectionEndFrame','IgnoreCase',true),1);
line{toreplace} = ['detectionEndFrame = ''',paramtab{20},''';'];
 
toreplace = find(contains(line,'cutoff','IgnoreCase',true),4);
line{toreplace(end)} = ['cutoff = ',paramtab{21},';'];

toreplace = find(contains(line,'leftEdge','IgnoreCase',true),1);
line{toreplace} = ['leftEdge = ',paramtab{22},';'];

toreplace = find(contains(line,'rightEdge','IgnoreCase',true),1);
line{toreplace} = ['rightEdge = ',paramtab{23},';'];

toreplace = find(contains(line,'topEdge','IgnoreCase',true),1);
line{toreplace} = ['topEdge = ',paramtab{24},';'];

toreplace = find(contains(line,'bottomEdge','IgnoreCase',true),1);
line{toreplace} = ['bottomEdge = ',paramtab{25},';'];

toreplace = find(contains(line,'minCount','IgnoreCase',true),1);
line{toreplace} = ['minCount = ',paramtab{26},';'];

toreplace = find(contains(line,'maxCount','IgnoreCase',true),1);
line{toreplace} = ['maxCount = ',paramtab{27},';'];

toreplace = find(contains(line,'minEccentricity','IgnoreCase',true),1);
line{toreplace} = ['minEccentricity = ',paramtab{28},';'];

toreplace = find(contains(line,'maxEccentricity','IgnoreCase',true),1);
line{toreplace} = ['maxEccentricity = ',paramtab{29},';'];

toreplace = find(contains(line,'minLength','IgnoreCase',true),1);
line{toreplace} = ['minLength = ',paramtab{30},';'];

toreplace = find(contains(line,'maxLength','IgnoreCase',true),1);
line{toreplace} = ['maxLength = ',paramtab{31},';'];

toreplace = find(contains(line,'maxDistFromLinear','IgnoreCase',true),1);
line{toreplace} = ['maxDistFromLinear = ',paramtab{32},';'];

toreplace = find(contains(line,'minSeparation','IgnoreCase',true),1);
line{toreplace} = ['minSeparation = ',paramtab{33},';'];

toreplace = find(contains(line,'foregroundDist','IgnoreCase',true),1);
line{toreplace} = ['foregroundDist = ',paramtab{34},';'];

toreplace = find(contains(line,'backInnerDist','IgnoreCase',true),1);
line{toreplace} = ['backInnerDist = ',paramtab{35},';'];

toreplace = find(contains(line,'backOuterDist','IgnoreCase',true),1);
line{toreplace} = ['backOuterDist = ',paramtab{36},';'];

toreplace = find(contains(line,'verboseOutput','IgnoreCase',true),1);
line{toreplace} = ['verboseOutput = ',falsetrue((paramtab{37}=='1')+1,:)];


fid = fopen([JIM,generateTracesFileName],'w');
for i=1:size(line,1)
    fprintf(fid,'%s\n',line{i});
end
fclose(fid);