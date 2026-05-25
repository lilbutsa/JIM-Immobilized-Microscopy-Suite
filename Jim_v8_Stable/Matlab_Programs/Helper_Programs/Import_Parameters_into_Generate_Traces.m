%Select Parameters File

[sysVar.fileName,sysVar.pathName] = uigetfile('*','Select the Parameter File');
completeName = [sysVar.pathName,sysVar.fileName];
sysVar.paramtab = readtable(completeName,'Format','%s%s');
sysVar.paramtab = sysVar.paramtab(2:end,:);
sysVar.paramtab = table2cell(sysVar.paramtab);
[sysConst.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)
sysVar.line = splitsysVar.lines(fileread([JIM,'\Begin_Here_Generate_Traces.m']));

for i=1:length(sysVar.paramtab)
    sysVar.toreplace = find(contains(sysVar.line,sysVar.paramtab{i,1},'IgnoreCase',true),1);
    sysVar.sysVar.linein = sysVar.line{sysVar.toreplace};
    sysVar.line{sysVar.toreplace} = [sysVar.sysVar.linein(1:strfind(sysVar.sysVar.linein,'=')) ' ' sysVar.paramtab{i,2} sysVar.sysVar.linein(strfind(sysVar.sysVar.linein,';'):end)];
end
sysVar.fid = fopen([JIM,'\Begin_Here_Generate_Traces.m'],'w');
for i=1:size(sysVar.line,1)
    fprintf(sysVar.fid,'%s\n',sysVar.line{i});
end
fclose(sysVar.fid);
