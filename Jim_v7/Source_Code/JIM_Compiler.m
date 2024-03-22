
programNames = {'Align_Channels','Calculate_Traces','Change_Point_Analysis','Detect_Particles','Expand_Shapes','Exponential_Fit','Gaussian_Fit','Isolate_Particle','Make_Histogram','Mean_of_Frames','Tiff_Channel_Splitter'};
mklrequired = [true,false,false,false,false,true,true,true,false,true,false];
%%
inputBase = 'C:\Users\James_Walsh\Google Drive\Jim\c++_Projects\';
outputBase = 'C:\Users\James_Walsh\Documents\GitHub\JIM-Immobilized-Microscopy-Suite\Jim_v7\';

for i=1:size(programNames,2)

    
    source = [inputBase,programNames{i},'\x64\Release\',programNames{i},'.exe'];
    destination = [outputBase,'c++_Base_Programs\Windows\',programNames{i},'.exe'];
    copyfile(source,destination,'f');
    
    if exist([outputBase,'Source_Code\',programNames{i},'\'])==0
        mkdir([outputBase,'Source_Code\',programNames{i},'\']);
    end
    
    source = dir([inputBase,programNames{i},'\',programNames{i},'\*.cpp']);
    for j=1:length(source)
        copyfile([inputBase,programNames{i},'\',programNames{i},'\',source(j).name],[outputBase,'\Source_Code\',programNames{i},'\',source(j).name],'f');       
    end
    source = dir([inputBase,programNames{i},'\',programNames{i},'\*.hpp']);
    for j=1:length(source)
        copyfile([inputBase,programNames{i},'\',programNames{i},'\',source(j).name],[outputBase,'\Source_Code\',programNames{i},'\',source(j).name],'f');       
    end
end

if exist([outputBase,'Source_Code\Header_Libraries\'])==0
    mkdir([outputBase,'Source_Code\Header_Libraries\']);
end

source = dir([inputBase,'\Header_Libraries\*.h']);
for j=1:length(source)
    copyfile([inputBase,'\Header_Libraries\',source(j).name],[outputBase,'\Source_Code\Header_Libraries\',source(j).name],'f');       
end


%% Mac section
base = '/Users/james/Documents/GitHub/JIM-Immobilized-Microscopy-Suite/Jim_v7/';

IPPROOT = '/opt/intel/compilers_and_libraries_2020.2.258/mac/ipp';
IPPFILES = [' ',IPPROOT,'/lib/libippcore.a ',IPPROOT,'/lib/libippvm.a ', IPPROOT,'/lib/libipps.a ',IPPROOT,'/lib/libipps.a ',IPPROOT,'/lib/libippi.a ',IPPROOT,'/lib/libippcc.a ',IPPROOT,'/lib/libippcv.a '];
ALLIPPINCLUDE = [' -I ',IPPROOT,'/include '];

MKLROOT = '/opt/intel/compilers_and_libraries_2020.3.279/mac/mkl';
ALLMKLFILES = [' ',MKLROOT,'/lib/libmkl_intel_lp64.a ',MKLROOT,'/lib/libmkl_sequential.a ',MKLROOT,'/lib/libmkl_core.a '];
ALLMKLINCLUDE = [' -I ',MKLROOT,'/include/ '];

for i=1:size(programNames,2)
    disp(['compiling = ',num2str(i)]);
    allFiles = '';
    
    source = dir([base,'Source_Code/',programNames{i},'/*.cpp']);
    for j=1:length(source)
        allFiles = [allFiles,'"',base,'Source_Code/',programNames{i},'/',source(j).name,'" '];
    end
    
    if mklrequired(i)
        mklfilesin = ALLMKLFILES;
        mklincludein = ALLMKLINCLUDE;
    else
        mklfilesin = '';
        mklincludein = '';
    end
    
    cmd = ['clang++ ',allFiles,IPPFILES,mklfilesin,ALLIPPINCLUDE,mklincludein,' -I "',base,'Source_Code/Header_Libraries/" -std=c++17 -Os -stdlib=libc++ -lpthread -lm -ldl ',' -o "',base,'c++_Base_Programs/Mac/',programNames{i},'"'];
    system(cmd);

end
%% Make make executables
for i=1:size(programNames,2)
    cmd = ['chmod +x "',JIMbase,'/Jim_Compressed/Mac_Programs/',programNames{i},'"'];
    system(cmd);
end
%% Ubuntu section
IPPROOT = '/opt/intel/oneapi/ipp/2021.2.0/lib/intel64/';
IPPFILES = [' ',IPPROOT,'libippcore.a ',IPPROOT,'libippvm.a ', IPPROOT,'libipps.a ',IPPROOT,'libipps.a ',IPPROOT,'libippi.a ',IPPROOT,'libippcc.a ',IPPROOT,'libippcv.a ',IPPROOT,'libipps.a '];
ALLIPPINCLUDE = [' -I /opt/intel/oneapi/ipp/2021.2.0/include/ '];

MKLROOT = '/opt/intel/oneapi/mkl/2021.2.0/lib/intel64/';
ALLMKLFILES = [' ',MKLROOT,'libmkl_intel_lp64.a ',MKLROOT,'libmkl_sequential.a ',MKLROOT,'libmkl_core.a '];
ALLMKLINCLUDE = [' -I /opt/intel/oneapi/mkl/2021.2.0/include/ '];

for i=1:size(programNames,2)
    disp(['compiling = ',num2str(i)]);
    allFiles = '';
    
    source = dir([JIMbase,'/c++_Projects/',programNames{i},'/',programNames{i},'/*.cpp']);
    for j=1:size(source,1)
        allFiles = [allFiles,' "',JIMbase,'/c++_Projects/',programNames{i},'/',programNames{i},'/',source(j).name,'" '];
    end
    
    if mklrequired(i)
        mklfilesin = ALLMKLFILES;
        mklincludein = ALLMKLINCLUDE;
    else
        mklfilesin = '';
        mklincludein = '';
    end
    
    cmd = ['g++ -fuse-ld=lld ',allFiles,IPPFILES,mklfilesin,ALLIPPINCLUDE,mklincludein,' -I "',JIMbase,'/c++_Projects/Header_Libraries/" -std=c++17 -Os -lpthread -lm -ldl ',' -o"',JIMbase,'/Jim_Compressed/Linux_Programs/',programNames{i},'"'];
    system(cmd);

end
%% Make make executables
for i=1:size(programNames,2)
    cmd = ['chmod +x "',JIMbase,'/Jim_Compressed/Linux_Programs/',programNames{i},'"'];
    system(cmd);
end