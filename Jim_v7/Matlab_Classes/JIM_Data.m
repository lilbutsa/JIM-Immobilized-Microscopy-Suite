classdef JIM_Data
    properties
        numOfChannels;
        traces;
        backgrounds;
        measurements;
        driftCorrections;
        stepData;
        channelsName;
        backgroundNames;
        folderName;
        selected;
        formerPos;
        
        
    end
    
    methods
        function obj = JIM_Data(folderName,toSelect)
            
            if nargin==1
                obj.folderName = folderName;
                obj.numOfChannels = 1;
                allFiles = arrayfun(@(x)[folderName,x.name],dir(folderName)','UniformOutput',false);
                found = allFiles(contains(allFiles,['Channel_',num2str(obj.numOfChannels),'_Fluorescent_Intensities.csv'],'IgnoreCase',true));
                backfound = allFiles(contains(allFiles,['Channel_',num2str(obj.numOfChannels),'_Fluorescent_Intensities.csv'],'IgnoreCase',true));
                measuresfound = allFiles(contains(allFiles,['Detected_Filtered_Measurements.csv'],'IgnoreCase',true));
                driftsfound = allFiles(contains(allFiles,['Aligned_Drifts.csv'],'IgnoreCase',true));

                obj.channelsName = {};
                obj.backgroundNames = {};
                while size(found,2)>0 && size(backfound,2)>0
                    obj.channelsName{obj.numOfChannels} = found{1};
                    obj.backgroundNames{obj.numOfChannels} = backfound{1};
                    obj.traces{obj.numOfChannels} = csvread(found{1},1);
                    obj.backgrounds{obj.numOfChannels} = csvread(backfound{1},1);

                    if size(measuresfound,2)>0
                        obj.measurements{obj.numOfChannels} = csvread(measuresfound{1},1);
                    end

                    if size(driftsfound,2)>0
                        obj.driftCorrections{obj.numOfChannels} = csvread(driftsfound{1},1);
                    end

                    obj.numOfChannels = obj.numOfChannels+1;
                    found = allFiles(contains(allFiles,['Channel_',num2str(obj.numOfChannels),'_Fluorescent_Intensities.csv'],'IgnoreCase',true));
                    backfound = allFiles(contains(allFiles,['Channel_',num2str(obj.numOfChannels),'_Fluorescent_Intensities.csv'],'IgnoreCase',true));
                    measuresfound = allFiles(contains(allFiles,['Detected_Filtered_Measurements_Channel_',num2str(obj.numOfChannels),'.csv'],'IgnoreCase',true));
                    driftsfound = allFiles(contains(allFiles,['Detected_Filtered_Drifts_Channel_',num2str(obj.numOfChannels),'.csv'],'IgnoreCase',true));
                end
                obj.numOfChannels = obj.numOfChannels-1;
                
            elseif nargin ==2
                    obj.selected = toSelect;
                    obj.formerPos = find(toSelect);
                    
                    obj.folderName = folderName.folderName;
                    obj.numOfChannels = folderName.numOfChannels;
                    obj.channelsName= folderName.channelsName;
                    obj.backgroundNames= folderName.backgroundNames;
                    obj.driftCorrections = folderName.driftCorrections;
                    for i=1:obj.numOfChannels
                        obj.traces{i} = folderName.traces{i}(toSelect,:);
                        if min(size(folderName.backgrounds{i}))>0
                            obj.backgrounds{i} = folderName.backgrounds{i}(toSelect,:);
                        end
                        if min(size(folderName.measurements{i}))>0
                            obj.measurements{i} = folderName.measurements{i}(toSelect,:);
                        end

                    end

                    if isstruct(folderName.stepData)
                        obj.stepData.noStepMean = folderName.stepData.noStepMean(toSelect);
                        obj.stepData.noStepProb = folderName.stepData.noStepProb(toSelect);
                        obj.stepData.stepTimes = folderName.stepData.stepTimes(toSelect);
                        obj.stepData.preHeight = folderName.stepData.preHeight(toSelect);
                        obj.stepData.postHeight = folderName.stepData.postHeight(toSelect);
                        obj.stepData.stepHeights= folderName.stepData.stepHeights(toSelect);
                        obj.stepData.moreStepProb = folderName.stepData.moreStepProb(toSelect);
                        obj.stepData.residualStdDev = folderName.stepData.residualStdDev(toSelect);
                        
                        %obj.stepData.stepTraces = folderName.stepData.stepTraces(toSelect,:);
                    end
            end
            
        end
        
        function obj = parseSingleStepData(obj,stepDataIn)
                obj.stepData.noStepMean = stepDataIn(:,2);
                %disp(obj.stepData.noStepMean);
                obj.stepData.noStepProb = stepDataIn(:,3);
                obj.stepData.stepTimes = stepDataIn(:,4);
                obj.stepData.preHeight = stepDataIn(:,5);
                obj.stepData.postHeight = stepDataIn(:,6);
                obj.stepData.stepHeights= obj.stepData.postHeight-obj.stepData.preHeight;
                obj.stepData.moreStepProb = stepDataIn(:,7);
                obj.stepData.residualStdDev = stepDataIn(:,8);
                
                %obj.stepData.stepTraces
        end
    end
    
end