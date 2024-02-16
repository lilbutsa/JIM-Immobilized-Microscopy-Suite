import ij.IJ;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

class batchClass {
    Thread batchThread;
    String completeName,workingDir;
    ArrayList<String> CMDList;
    ParametersClass params;

    public void analyseImageStack(String completeNameIn, ParametersClass paramsin){
        params = paramsin;
        completeName = completeNameIn;

        Runnable myrunnable = ()->{
            String[] filnamebaseandext = completeName.split("\\.(?=[^\\.]+$)");
            for(int i=0;i<params.additionalExtensionsToRemove;i++) filnamebaseandext = filnamebaseandext[0].split("\\.(?=[^\\.]+$)");
            workingDir = filnamebaseandext[0]+params.fileSep;

            if(!new File(workingDir).exists()) new File(workingDir).mkdirs();

            if(params.multipleFilesPerImageStack) {
                String pathname = new File(completeName).getParent();
                File[] files = new File(pathname).listFiles();
                List<String> allFiles = new ArrayList<>();
                ;
                //If this pathname does not denote a directory, then listFiles() returns null.
                for (File file : files) {
                    if (file.isFile()) {
                        filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                        if ("TIFF".equals(filnamebaseandext[1]) || "tiff".equals(filnamebaseandext[1]) || "TIF".equals(filnamebaseandext[1]) || "tif".equals(filnamebaseandext[1]) || "tf8".equals(filnamebaseandext[1]))
                            allFiles.add(file.getPath());
                    }
                }
                completeName = "";
                for (int i = 0; i < allFiles.size(); i++)
                    completeName = completeName + params.quote + allFiles.get(i) + params.quote + " ";
            }else
                completeName = params.quote+completeName+params.quote;
            if(batchThread.isInterrupted())return;
            //Organise files
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM + "TIFF_Channel_Splitter" + params.fileEXE);
            CMDList.add(params.quote + workingDir+ "Raw_Image_Stack" + params.quote);
            CMDList.add(completeName);
            CMDList.add("-NumberOfChannels");
            CMDList.add(IJ.d2s(params.imStackNumberOfChannels,0));
            CMDList.add("-StartFrame");
            CMDList.add(IJ.d2s(params.imStackStartFrame,0));
            CMDList.add("-EndFrame");
            CMDList.add(IJ.d2s(params.imStackEndFrame,0));

            if(params.imStackChannelsToTransform.length()>0){
                CMDList.add("-Transform");
                CMDList.add(params.quote + params.imStackChannelsToTransform + params.quote);
                CMDList.add(params.quote + params.imStackVerticalFlipChannel + params.quote);
                CMDList.add(params.quote + params.imStackHorizontalFlipChannel + params.quote);
                CMDList.add(params.quote + params.imStackRotateChannel + params.quote);
            }

            params.runCommand(false,CMDList);
            if(batchThread.isInterrupted())return;
            //Drift Correct
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM+"Align_Channels" + params.fileEXE);
            CMDList.add(params.quote+ workingDir + "Alignment"+params.quote);
            for(int i=0;i<params.imStackNumberOfChannels;i++)CMDList.add(params.quote + workingDir +
                    "Raw_Image_Stack_Channel_" + IJ.d2s(i+1,0) + ".tif"+params.quote);
            CMDList.add("-Start");
            CMDList.add(IJ.d2s(params.alignStartFrame,0));
            CMDList.add("-End");
            CMDList.add(IJ.d2s(params.alignEndFrame,0));
            CMDList.add("-Iterations");
            CMDList.add(IJ.d2s(params.alignIterations,0));
            CMDList.add("-MaxShift");
            CMDList.add(IJ.d2s(params.alignMaxShift,2));



            if (params.alignManually){
                CMDList.add("-Alignment");
                CMDList.add(params.quote + params.alignXOffset+ params.quote );
                CMDList.add(params.quote + params.alignYOffset+ params.quote );
                CMDList.add(params.quote + params.alignRotationAngle+ params.quote );
                CMDList.add(params.quote + params.alignScalingFactor+ params.quote );
            } else {
                CMDList.add("-MaxIntensities");
                CMDList.add(params.quote + params.alignMaxInt+ params.quote );
                CMDList.add("-SNRdetectionCutoff");
                CMDList.add(IJ.d2s(params.alignSNRdetectionCutoff,2));
            }

            params.runCommand(false,CMDList);
            if(batchThread.isInterrupted())return;
            //make subimage
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM+"Mean_of_Frames" + params.fileEXE);
            CMDList.add(params.quote +workingDir+"Alignment_Channel_To_Channel_Alignment.csv"+ params.quote);
            CMDList.add(params.quote + workingDir + "Alignment_Channel_1.csv"+ params.quote);
            CMDList.add(params.quote + workingDir + "Image_For_Detection"+ params.quote);
            for(int i=0;i<params.imStackNumberOfChannels;i++)CMDList.add(params.quote + workingDir +
                    "Raw_Image_Stack_Channel_" + IJ.d2s(i+1,0) + ".tif"+params.quote);
            CMDList.add("-Start");CMDList.add(params.quote + params.detectionStartFrame+ params.quote);
            CMDList.add("-End");CMDList.add(params.quote + params.detectionEndFrame+ params.quote);
            CMDList.add("-Weights");CMDList.add(params.quote + params.detectWeights+ params.quote);
            if(params.detectUsingMaxProjection)CMDList.add("-MaxProjection");

            params.runCommand(false,CMDList);
            if(batchThread.isInterrupted())return;
            //Detect
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM+"Detect_Particles" + params.fileEXE);
            CMDList.add(params.quote +workingDir+"Image_For_Detection_Partial_Mean.tiff"+ params.quote);
            CMDList.add(params.quote + workingDir + "Detected"+ params.quote);
            CMDList.add("-BinarizeCutoff");CMDList.add(IJ.d2s(params.detectionCutoff,2));
            CMDList.add("-left");CMDList.add(IJ.d2s(params.detectLeftEdge,0));
            CMDList.add("-right");CMDList.add(IJ.d2s(params.detectRightEdge,0));
            CMDList.add("-top");CMDList.add(IJ.d2s(params.detectTopEdge,0));
            CMDList.add("-bottom");CMDList.add(IJ.d2s(params.detectBottomEdge,0));
            CMDList.add("-minCount");CMDList.add(IJ.d2s(params.detectMinCount,0));
            CMDList.add("-maxCount");CMDList.add(IJ.d2s(params.detectMaxCount,0));
            CMDList.add("-minEccentricity");CMDList.add(IJ.d2s(params.detectMinEccentricity,2));
            CMDList.add("-maxEccentricity");CMDList.add(IJ.d2s(params.detectMaxEccentricity,2));
            CMDList.add("-minLength");CMDList.add(IJ.d2s(params.detectMinLength,2));
            CMDList.add("-maxLength");CMDList.add(IJ.d2s(params.detectMaxLength,2));
            CMDList.add("-maxDistFromLinear");CMDList.add(IJ.d2s(params.detectMaxDistFromLinear,2));
            CMDList.add("-minSeparation");CMDList.add(IJ.d2s(params.detectMinSeparation,2));

            params.runCommand(false,CMDList);

            if(params.additionBackgroundDetect) {
                CMDList = new ArrayList<>();
                CMDList.add(params.JIM + "Mean_of_Frames" + params.fileEXE);
                CMDList.add(params.quote + workingDir + "Alignment_Channel_To_Channel_Alignment.csv" + params.quote);
                CMDList.add(params.quote + workingDir + "Alignment_Combined_Drift.csv" + params.quote);
                CMDList.add(params.quote + workingDir + "Background" + params.quote);
                for (int i = 0; i < params.imStackNumberOfChannels; i++)
                    CMDList.add(params.quote + workingDir +
                            "Raw_Image_Stack_Channel_" + IJ.d2s(i + 1, 0) + ".tif" + params.quote);
                CMDList.add("-Start");
                CMDList.add(params.quote + params.additionalBackgroundStartFrame + params.quote);
                CMDList.add("-End");
                CMDList.add(params.quote + params.additionalBackgroundEndFrame + params.quote);
                CMDList.add("-Weights");
                CMDList.add(params.quote + params.additionalBackgroundWeights + params.quote);
                if (params.additionBackgroundUseMaxProjection) CMDList.add("-MaxProjection");

                params.runCommand(false, CMDList);

                CMDList = new ArrayList<>();
                CMDList.add(params.JIM + "Detect_Particles" + params.fileEXE);
                CMDList.add(params.quote + workingDir + "Background_Partial_Mean.tiff" + params.quote);
                CMDList.add(params.quote + workingDir + "Background_Detected" + params.quote);
                CMDList.add("-BinarizeCutoff");
                CMDList.add(IJ.d2s(params.additionBackgroundCutoff, 2));

                params.runCommand(false, CMDList);
            }
            if(batchThread.isInterrupted())return;
            //Expand
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM+"Expand_Shapes" + params.fileEXE);
            CMDList.add(params.quote +workingDir+"Detected_Filtered_Positions.csv"+ params.quote);
            CMDList.add(params.quote +workingDir+"Detected_Positions.csv"+ params.quote);
            CMDList.add(params.quote + workingDir + "Expanded"+ params.quote);
            CMDList.add("-boundaryDist");CMDList.add(IJ.d2s(params.expandForegroundDist,2));
            CMDList.add("-backgroundDist");CMDList.add(IJ.d2s(params.expandBackOuterDist,2));
            CMDList.add("-backInnerRadius");CMDList.add(IJ.d2s(params.expandBackInnerDist,2));
            if(params.additionBackgroundDetect){CMDList.add("-extraBackgroundFile");CMDList.add(params.quote +workingDir+"Background_Detected_Positions.csv"+ params.quote);}
            if (params.imStackNumberOfChannels>1){CMDList.add("-channelAlignment");CMDList.add(params.quote +workingDir+"Alignment_Channel_To_Channel_Alignment.csv"+ params.quote);}

            params.runCommand(false,CMDList);
            if(batchThread.isInterrupted())return;
            //Generate Traces
            for(int chanCount = 0;chanCount<params.imStackNumberOfChannels;chanCount++){
                CMDList = new ArrayList<>();
                CMDList.add(params.JIM+"Calculate_Traces" + params.fileEXE);
                CMDList.add(params.quote +workingDir+"Raw_Image_Stack_Channel_"+IJ.d2s(chanCount+1,0)+".tif"+ params.quote);
                CMDList.add(params.quote +workingDir+"Expanded_ROI_Positions_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
                CMDList.add(params.quote +workingDir+"Expanded_Background_Positions_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
                CMDList.add(params.quote +workingDir+"Channel_"+IJ.d2s(chanCount+1,0)+ params.quote);
                CMDList.add("-Drift");CMDList.add(params.quote +workingDir+"Alignment_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
                if(params.verboseOutput)CMDList.add("-Verbose");
                params.runCommand(false,CMDList);

            }
            if(batchThread.isInterrupted())return;
            params.saveParameters(false,workingDir);

        };

        batchThread = new Thread(myrunnable);
        batchThread.start();

    }
}
