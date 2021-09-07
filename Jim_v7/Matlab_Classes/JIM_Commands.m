classdef JIM_Commands
    properties
        fileEXE;
        fileSep;
        JIM;
    end
    
    methods
        function obj = JIM_Commands()
            [obj.JIM,~,~] = fileparts(matlab.desktop.editor.getActiveFilename);%Find the location of this script (should be in Jim\Matlab_Programs)

            obj.fileEXE = '"';
            obj.fileSep = '';
            if ismac
                obj.JIM = [fileparts(obj.JIM),'/Mac_Programs/'];
                obj.fileSep = '/';
            elseif isunix
                obj.JIM = [fileparts(obj.JIM),'/Linux_Programs/'];
                obj.fileSep = '/';
            elseif ispc
                if strcmp(computer('arch'),'win64')
                    obj.JIM = [fileparts(obj.JIM),'\Jim_Programs\'];
                else
                    obj.JIM = [fileparts(obj.JIM),'\Jim_Programs_32bit\'];
                end
                obj.fileEXE = '.exe"';
                obj.fileSep = '\';
            else
                disp('Platform not supported')
            end
        end
        
        function stepsdata = singleStepfit(obj,dataToFit,stepfitIterations)
                    
                    fileout = [obj.JIM,'dataToFit.csv']; 
                    fid = fopen(fileout,'w'); 
                    fprintf(fid,'%s\n','Each row is a particle. Each column is a Frame');
                    fclose(fid);
                    if iscell(dataToFit)
                        for i=1:max(size(dataToFit))
                            dlmwrite(fileout,dataToFit{i},'-append');
                        end
                    else
                        dlmwrite(fileout,dataToFit,'-append');
                    end
                    cmd = ['"',obj.JIM,'Change_Point_Analysis',obj.fileEXE,' "',fileout,'" "',obj.JIM,'Stepfit" -FitSingleSteps -Iterations ',num2str(stepfitIterations)];
                    system(cmd);
                    stepsdata = csvread([obj.JIM,'Stepfit_Single_Step_Fits.csv'],1);
                    delete(fileout);
                    delete([obj.JIM,'Stepfit_Single_Step_Fits.csv']);
        end
    end
    
end