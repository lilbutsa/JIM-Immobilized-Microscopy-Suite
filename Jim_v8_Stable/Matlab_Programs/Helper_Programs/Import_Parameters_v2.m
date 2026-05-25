%%
sysVar.stackName = [workingDir,'Examples\Example_Trace_' num2str(montage.traceNo) '_Channel_1.tiff'];

fig = uifigure('Position',[100 100 400 400]);

hold on

ax = uiaxes(fig,'Position',[50 50 300 300]);
imshow(imread(sysVar.stackName,1),'Parent',ax);

sld = uislider(fig,'Position',[100 30 200 3],'ValueChangedFcn',@(sld,event) updateImage(sld,sld.Value,sysVar.stackName,ax));
next_but   = uibutton(fig,'push', 'Text','Next', 'Position', [315 15 50 20], 'ButtonPushedFcn',  @(next_but,event)  updateImage(sld , sld.Value+1,sysVar.stackName,ax));
prev_but   = uibutton(fig,'push', 'Text','Prev', 'Position', [35 15 50 20], 'ButtonPushedFcn',  @(prev_but,event)  updateImage(sld , sld.Value-1,sysVar.stackName,ax));

sld.Limits = [1 30];

sld.Value = 1;
hold off

%%
% Create ValueChangedFcn callback
function updateImage(sld,newval,imagename,imageaxis)
%cg.Value = sld.Value;
sld.Value = round(newval);
disp(sld.Value);
imshow(imread(imagename,sld.Value),'Parent',imageaxis);
end