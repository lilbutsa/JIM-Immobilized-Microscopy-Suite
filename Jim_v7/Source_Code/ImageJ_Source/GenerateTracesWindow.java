import ij.ImagePlus;
import ij.gui.GenericDialog;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.util.*;

import ij.IJ;
import ij.gui.Plot;
import ij.io.OpenDialog;
import ij.plugin.ContrastEnhancer;
import ij.plugin.RGBStackMerge;
import ij.process.ImageConverter;
import java.awt.Color;
import java.util.List;

import ij.gui.PlotWindow;
import ij.plugin.MontageMaker;
import ij.io.DirectoryChooser;

public class GenerateTracesWindow extends javax.swing.JFrame{
    JPanel mainPanel;
    private JButton selectInputFileBT;
    private JButton splitChannelsBT;
    private JButton alignDriftCorrectBT;
    private JButton makeSubAverageBT;
    private JButton detectParticlesBT;
    private JButton additionalBackgroundBT;
    private JButton calculateTracesBT;
    private JButton viewTracesBT;
    private JButton importParametersBT;
    private JButton saveParametersBT;
    private JButton batchProcessBT;
    private JButton selectBatchFilesBT;
    private JButton expandRegionsBT;
    private JButton viewParamsBT;


    GenericDialog gd;

        String completeName;
        String workingDir;
        ArrayList<String> CMDList;
        ParametersClass params;


        java.util.List<String> results;

        private void setup_Jim_Programs(){
            params = new ParametersClass();

            workingDir = "";

            params.OS = System.getProperty("os.name", "generic").toLowerCase(Locale.ENGLISH);
            if ((params.OS.contains("mac")) || (params.OS.contains("darwin"))) {
                params.JIM = (new File("").getAbsolutePath())+"/plugins/c++_Base_Programs/Mac/";
                params.fileSep = "/";
                params.quote = "\\\"";
                params.fileEXE = "";
                params.newCMDWindowBefore = "tell application \"Terminal\"\n" + "activate\n" +"do script \"";
                params.newCMDWindowAfter = "\"\n" + "delay 1\n" + "repeat until busy of first window is false\n" +"delay 0.1\n" +
                        "end repeat\n" +"delay 1\n" +"close first window\n" +"end tell";
            } else if (params.OS.contains("win")) {
                params.JIM = (new File("").getAbsolutePath())+"\\plugins\\c++_Base_Programs\\Windows\\";
                params.fileSep = "\\";
                params.quote="\"";
                params.fileEXE = ".exe";
            }

            if(!new File(params.JIM).exists())
            {
                gd = new GenericDialog("Error Jim Folder not found", IJ.getInstance());
                gd.addMessage(params.JIM);
                gd.addMessage("The folder containing JIM analysis programs does not exist in the ImageJ plugin folder.");
                gd.addMessage("Copy the c++_Base_Programs folder fom the JIM distribution to : ");
                gd.addMessage((new File("").getAbsolutePath()));
                gd.setOKLabel("Close Analysis");
                gd.showDialog();
                return;
            }


        }

    void getInputFile(){
        gd = new GenericDialog("1) Select Input File", IJ.getInstance());
        gd.addNumericField("Additional Extensions to Remove ", params.additionalExtensionsToRemove, 0);
        gd.addCheckbox("Multiple Files Per Image Stack",params.multipleFilesPerImageStack);
        gd.showDialog();
        if (gd.wasCanceled())
            return;


        params.additionalExtensionsToRemove = (int) gd.getNextNumber();
        params.multipleFilesPerImageStack = gd.getNextBoolean();


        OpenDialog fileselector;

        fileselector = new OpenDialog("Select file for analysis");

        completeName = fileselector.getPath();

        if ("".equals(completeName)){
            return;
        }


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

    }



    void splitFiles(){

        gd = new GenericDialog("2) Organise Channels", IJ.getInstance());

        gd.addNumericField("Number of Channels ", params.imStackNumberOfChannels, 0);
        gd.addCheckbox("Disable Metadata",params.imStackDisableMetadata);

        gd.addNumericField("Stack Start Frame ", params.imStackStartFrame, 0);
        gd.addNumericField("Stack End Frame ", params.imStackEndFrame, 0);

        gd.addMessage("Transform Channels:");
        gd.addStringField("Channels to Transform", params.imStackChannelsToTransform);

        gd.addStringField("Vertical Flip", params.imStackVerticalFlipChannel);

        gd.addStringField("Horizontal Flip", params.imStackHorizontalFlipChannel);

        gd.addStringField("Rotate", params.imStackRotateChannel);

        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#organise-channels");
        gd.showDialog();
        if (gd.wasCanceled())
            return;


        params.imStackNumberOfChannels = (int) gd.getNextNumber();
        params.imStackDisableMetadata = gd.getNextBoolean();
        params.imStackStartFrame = (int) gd.getNextNumber();
        params.imStackEndFrame = (int) gd.getNextNumber();
        params.imStackChannelsToTransform = gd.getNextString();
        params.imStackVerticalFlipChannel = gd.getNextString();
        params.imStackHorizontalFlipChannel = gd.getNextString();
        params.imStackRotateChannel = gd.getNextString();

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

        params.runCommand(true,CMDList);


    }



    void driftCorrectImage(){

        gd = new GenericDialog("3) Align Channels and Calculate Drifts", IJ.getInstance());

        gd.addNumericField("Iterations ", params.alignIterations, 0);
        gd.addNumericField("Alignment Start Frame", params.alignStartFrame, 0);
        gd.addNumericField("Alignment End Frame ", params.alignEndFrame, 0);
        gd.addNumericField("Max Shift ", params.alignMaxShift, 2);
        gd.addCheckbox("Save aligned stack",params.alignOutputStacks);
        gd.addMessage("");
        gd.addStringField("Alignment Max Int.", params.alignMaxInt);
        gd.addNumericField("Alignment SNR detectionCutoff", params.alignSNRdetectionCutoff, 2);
        gd.addMessage("");
        gd.addCheckbox("Align Manually",params.alignManually);
        gd.addStringField("X offset", params.alignXOffset);
        gd.addStringField("Y offset", params.alignYOffset);
        gd.addStringField("Rotation Angle", params.alignRotationAngle);
        gd.addStringField("Scaling Factor ", params.alignScalingFactor);

        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#align-channels-and-calculate-drifts");

        gd.showDialog();
        if (gd.wasCanceled())
            return;

        params.alignIterations = (int) gd.getNextNumber();
        params.alignStartFrame = (int) gd.getNextNumber();
        params.alignEndFrame = (int) gd.getNextNumber();
        params.alignMaxShift = gd.getNextNumber();
        params.alignOutputStacks = gd.getNextBoolean();

        params.alignMaxInt = gd.getNextString();
        params.alignSNRdetectionCutoff = gd.getNextNumber();

        params.alignManually = gd.getNextBoolean();
        params.alignXOffset = gd.getNextString();
        params.alignYOffset = gd.getNextString();
        params.alignRotationAngle = gd.getNextString();
        params.alignScalingFactor = gd.getNextString();


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
        if(params.alignOutputStacks)CMDList.add("-OutputAligned");


        params.runCommand(true,CMDList);

        ImagePlus rgbimage = IJ.openImage(workingDir +"Alignment_Full_Projection_Before.tiff");
        if(params.imStackNumberOfChannels>1)rgbimage.setDisplayMode(IJ.COMPOSITE);
        rgbimage.show();
        if(params.imStackNumberOfChannels>1)rgbimage.setTitle("Before Drift Correction. Ch1 - Red, Ch2 - Green, (Optional Ch3 - Blue)");
        else rgbimage.setTitle("Before Drift Correction");

        ImagePlus rgbimage2 = IJ.openImage(workingDir +"Alignment_Full_Projection_After.tiff");
        if(params.imStackNumberOfChannels>1)rgbimage2.setDisplayMode(IJ.COMPOSITE);
        rgbimage2.show();
        if(params.imStackNumberOfChannels>1)rgbimage2.setTitle("After Drift Correction. Ch1 - Red, Ch2 - Green, (Optional Ch3 - Blue)");
        else rgbimage2.setTitle("After Drift Correction");

    }

    void makeSubImage(){

        gd = new GenericDialog("5) Make Sub-Average", IJ.getInstance());
        gd.addMessage("Make a Sub-Average of the Image Stack for Detection");
        gd.addCheckbox("Use Max Projection",params.detectUsingMaxProjection);
        gd.addStringField("Detection Start Frames", params.detectionStartFrame);
        gd.addStringField("Detection End Frames", params.detectionEndFrame);
        gd.addStringField("Channel Weights", params.detectWeights);
        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#make-sub-average");
        gd.showDialog();
        if (gd.wasCanceled())
            return;

        params.detectUsingMaxProjection = gd.getNextBoolean();
        params.detectionStartFrame = gd.getNextString();
        params.detectionEndFrame = gd.getNextString();
        params.detectWeights = gd.getNextString();

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

        params.runCommand(true,CMDList);

        IJ.open(workingDir+"Image_For_Detection_Partial_Mean.tiff");

    }

    void detectParticles(){


        gd = new GenericDialog("6) Detect Particles", IJ.getInstance());
        gd.addMessage("Input particle detection parameters : ");

        gd.addNumericField("Threshold Cutoff", params.detectionCutoff, 2);
        gd.addMessage(" ");
        gd.addNumericField("Min. Distance From Left Edge", params.detectLeftEdge, 0);
        gd.addNumericField("Min. Distance From Right Edge", params.detectRightEdge, 0);
        gd.addNumericField("Min. Distance From Top Edge", params.detectTopEdge, 0);
        gd.addNumericField("Min. Distance From Bottom Edge", params.detectBottomEdge, 0);
        gd.addNumericField("Min. Pixel Count", params.detectMinCount, 0);
        gd.addNumericField("Max. Pixel Count", params.detectMaxCount, 0);
        gd.addNumericField("Min. Eccentricity", params.detectMinEccentricity, 2);
        gd.addNumericField("Max. Eccentricity", params.detectMaxEccentricity, 2);
        gd.addNumericField("Min. Length (Pixels)", params.detectMinLength, 1);
        gd.addNumericField("Max. Length (Pixels)", params.detectMaxLength, 1);
        gd.addNumericField("Max. Dist. From Linear", params.detectMaxDistFromLinear, 2);
        gd.addNumericField("Min. Separation", params.detectMinSeparation, 2);
        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#detect-particles");
        gd.showDialog();
        if (gd.wasCanceled())
            return;


        params.detectionCutoff =  gd.getNextNumber();
        params.detectLeftEdge =  (int) gd.getNextNumber();
        params.detectRightEdge =  (int) gd.getNextNumber();
        params.detectTopEdge =  (int) gd.getNextNumber();
        params.detectBottomEdge = (int) gd.getNextNumber();
        params.detectMinCount = (int) gd.getNextNumber();
        params.detectMaxCount = (int) gd.getNextNumber();
        params.detectMinEccentricity =  gd.getNextNumber();
        params.detectMaxEccentricity =  gd.getNextNumber();
        params.detectMinLength =  gd.getNextNumber();
        params.detectMaxLength =  gd.getNextNumber();
        params.detectMaxDistFromLinear =  gd.getNextNumber();
        params.detectMinSeparation =  gd.getNextNumber();


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

        params.runCommand(true,CMDList);

        ImagePlus channel1Im, channel2Im, channel3Im;

        channel1Im = IJ.openImage(workingDir+"Image_For_Detection_Partial_Mean.tiff");
        channel2Im = IJ.openImage(workingDir+"Detected_Regions.tif");
        channel3Im = IJ.openImage(workingDir+"Detected_Filtered_Regions.tif");

        ImageConverter ic = new ImageConverter(channel1Im);
        ic.convertToGray8();
        new ContrastEnhancer().equalize(channel1Im);

        ImagePlus[] rgbstack = {channel1Im,channel2Im,channel3Im};
        ImagePlus rgbimage = RGBStackMerge.mergeChannels(rgbstack, true);
        rgbimage.show();
        rgbimage.setTitle("Red - Original, Green - Thresholded Regions, Blue - Filtered Regions");

    }

    void additionalBackgroundDetection(){
        gd = new GenericDialog("7) Additional Background Detection", IJ.getInstance());
        gd.addMessage("Detect extra particles not in the detection image");
        gd.addCheckbox("Detect Additional Background",params.additionBackgroundDetect);
        gd.addCheckbox("Use Max Projection",params.additionBackgroundUseMaxProjection);
        gd.addStringField("Detection Start Frames", params.additionalBackgroundStartFrame);
        gd.addStringField("Detection End Frames", params.additionalBackgroundEndFrame);
        gd.addStringField("Channel Weights", params.additionalBackgroundWeights);
        gd.addNumericField("Threshold Cutoff", params.additionBackgroundCutoff, 2);
        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#additional-background-detection");

        gd.showDialog();
        if (gd.wasCanceled())
            return;

        params.additionBackgroundDetect = gd.getNextBoolean();
        params.additionBackgroundUseMaxProjection = gd.getNextBoolean();
        params.additionalBackgroundStartFrame = gd.getNextString();
        params.additionalBackgroundEndFrame = gd.getNextString();
        params.additionalBackgroundWeights = gd.getNextString();
        params.additionBackgroundCutoff =  gd.getNextNumber();

        if(!params.additionBackgroundDetect)return;

        CMDList = new ArrayList<>();
        CMDList.add(params.JIM+"Mean_of_Frames" + params.fileEXE);
        CMDList.add(params.quote +workingDir+"Alignment_Channel_To_Channel_Alignment.csv"+ params.quote);
        CMDList.add(params.quote + workingDir + "Alignment_Combined_Drift.csv"+ params.quote);
        CMDList.add(params.quote + workingDir + "Background"+ params.quote);
        for(int i=0;i<params.imStackNumberOfChannels;i++)CMDList.add(params.quote + workingDir +
                "Raw_Image_Stack_Channel_" + IJ.d2s(i+1,0) + ".tif"+params.quote);
        CMDList.add("-Start");CMDList.add(params.quote + params.additionalBackgroundStartFrame+ params.quote);
        CMDList.add("-End");CMDList.add(params.quote + params.additionalBackgroundEndFrame+ params.quote);
        CMDList.add("-Weights");CMDList.add(params.quote + params.additionalBackgroundWeights+ params.quote);
        if(params.additionBackgroundUseMaxProjection)CMDList.add("-MaxProjection");

        params.runCommand(true,CMDList);

        CMDList = new ArrayList<>();
        CMDList.add(params.JIM+"Detect_Particles" + params.fileEXE);
        CMDList.add(params.quote +workingDir+"Background_Partial_Mean.tiff"+ params.quote);
        CMDList.add(params.quote + workingDir + "Background_Detected"+ params.quote);
        CMDList.add("-BinarizeCutoff");CMDList.add(IJ.d2s(params.additionBackgroundCutoff,2));

        params.runCommand(true,CMDList);

        ImagePlus channel1Im, channel2Im;

        channel1Im = IJ.openImage(workingDir+"Image_For_Detection_Partial_Mean.tiff");
        channel2Im = IJ.openImage(workingDir+"Detected_Regions.tif");

        ImageConverter ic = new ImageConverter(channel1Im);
        ic.convertToGray8();
        new ContrastEnhancer().equalize(channel1Im);

        ImagePlus[] rgbstack = {channel1Im,channel2Im};
        ImagePlus rgbimage = RGBStackMerge.mergeChannels(rgbstack, true);
        rgbimage.show();
        rgbimage.setTitle("Red - Original, Green - Thresholded Regions");

    }


    void expandROIs(){
        gd = new GenericDialog("8) Expand Regions", IJ.getInstance());
        gd.addMessage("Input Expansion Distances : ");
        gd.addNumericField("Foreground Distance", params.expandForegroundDist, 2);
        gd.addNumericField("Background Inner Distance", params.expandBackInnerDist, 2);
        gd.addNumericField("Background Outer Distance", params.expandBackOuterDist, 2);
        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#expand-regions");
        gd.showDialog();
        if (gd.wasCanceled())
            return;

        params.expandForegroundDist =  gd.getNextNumber();
        params.expandBackInnerDist =  gd.getNextNumber();
        params.expandBackOuterDist =  gd.getNextNumber();


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

        params.runCommand(true,CMDList);

        ImagePlus rgbimage;
        ImagePlus[] rgbstack = {new ImagePlus(), new ImagePlus(), new ImagePlus()};
        rgbstack[0] = IJ.openImage(workingDir+"Image_For_Detection_Partial_Mean.tiff");
        rgbstack[1] = IJ.openImage(workingDir+"Expanded_ROIs.tif");
        rgbstack[2] = IJ.openImage(workingDir+"Expanded_Background_Regions.tif");

        ImageConverter ic2 = new ImageConverter(rgbstack[0]);
        ic2.convertToGray8();
        new ContrastEnhancer().equalize(rgbstack[0]);

        rgbimage = RGBStackMerge.mergeChannels(rgbstack, true);
        rgbimage.show();
        rgbimage.setTitle("Detected Particles - Red Original Image - Green ROIs - Blue Background Regions");


    }

    void measureTraces(){

        gd = new GenericDialog("9) Calculate Traces", IJ.getInstance());
        gd.addMessage("Measure Fluorescent Intensity for each region in each frame");
        gd.addCheckbox("Verbose Output",params.verboseOutput);
        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html#calculate-traces");
        gd.showDialog();
        if (gd.wasCanceled())
            return;

        params.verboseOutput = gd.getNextBoolean();

        for(int chanCount = 0;chanCount<params.imStackNumberOfChannels;chanCount++){
            CMDList = new ArrayList<>();
            CMDList.add(params.JIM+"Calculate_Traces" + params.fileEXE);
            CMDList.add(params.quote +workingDir+"Raw_Image_Stack_Channel_"+IJ.d2s(chanCount+1,0)+".tif"+ params.quote);
            CMDList.add(params.quote +workingDir+"Expanded_ROI_Positions_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
            CMDList.add(params.quote +workingDir+"Expanded_Background_Positions_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
            CMDList.add(params.quote +workingDir+"Channel_"+IJ.d2s(chanCount+1,0)+ params.quote);
            CMDList.add("-Drift");CMDList.add(params.quote +workingDir+"Alignment_Channel_"+IJ.d2s(chanCount+1,0)+".csv"+ params.quote);
            if(params.verboseOutput)CMDList.add("-Verbose");
            params.runCommand(true,CMDList);

        }

        params.saveParameters(false,workingDir);
    }

    void viewTraces(){
        try{
            gd = new GenericDialog("10) View Traces", IJ.getInstance());
            gd.addNumericField("Page Number",params.pageNumber,0);
            gd.showDialog();
            if (gd.wasCanceled())
                return;

            params.pageNumber =  (int) gd.getNextNumber();

            String row;
            int count;
            String[] data;
            BufferedReader csvReader;

            ArrayList<ArrayList<ArrayList<Double>>> traces = new ArrayList<>();
            ArrayList<ArrayList<Double>> measures = new ArrayList<>();

            for(int channelcount = 0;channelcount<params.imStackNumberOfChannels;channelcount++){
                traces.add(new ArrayList<>());
                csvReader = new BufferedReader(new FileReader((workingDir+"Channel_"+IJ.d2s(channelcount+1,0)+"_Fluorescent_Intensities.csv")));
                csvReader.readLine();
                count=0;
                while ((row = csvReader.readLine()) != null) {
                    traces.get(channelcount).add(new ArrayList<>());
                    data = row.split(",");
                    for (int i = 0; i < data.length; i++) {
                        (traces.get(channelcount).get(count)).add(Double.parseDouble(data[i]));
                    }

                    if (params.imStackNumberOfChannels > 1) {
                        double max = Collections.max(traces.get(channelcount).get(count));
                        for (int i = 0; i < data.length; i++) {
                            traces.get(channelcount).get(count).set(i, traces.get(channelcount).get(count).get(i) / max);
                        }
                    }

                    count++;
                }
                csvReader.close();

            }

            csvReader = new BufferedReader(new FileReader((workingDir+"Detected_Filtered_Measurements.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                measures.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));
                count++;
            }
            csvReader.close();

            double[] frameNumber = new double[traces.get(0).size()];
            double[] axisZero = new double[traces.get(0).size()];
            for(int i=0;i<traces.get(0).size();i++){
                frameNumber[i] = (i+1.0);
                axisZero[i] = (0.0);
            }

            IJ.open(workingDir+"Detected_Filtered_Region_Numbers.tif");

            Plot plot = new Plot("PageNumber "+IJ.d2s(params.pageNumber,0),"Frames","Intensity");

            // ImagePlus myStack = IJ.createHyperStack("Plot Stack",imp.getWidth(),imp.getHeight(),1,1,36,24);
            List <Color> mycolour = Arrays.asList(Color.red, Color.blue, Color.green,Color.orange,Color.MAGENTA,Color.PINK,Color.CYAN,Color.GRAY);
            count = 0;
            for(int particleCount = 0;particleCount<36;particleCount++){
                int abPartCount = particleCount+36*(params.pageNumber-1);
                if(abPartCount>= traces.get(0).size())break;
                count++;
                plot.setFrameSize(400, 250);
                PlotWindow.noGridLines = false; // draw grid lines
                plot.setAxisLabelFont(Font.BOLD, 40);
                plot.setFont(Font.BOLD, 40);

                if(params.imStackNumberOfChannels==1) {
                    plot.setLimits(1, traces.get(0).get(abPartCount).size(), Collections.min(traces.get(0).get(abPartCount)), Collections.max(traces.get(0).get(abPartCount)));
                } else plot.setLimits(1, traces.get(0).get(abPartCount).size(), -0.1, 1);

                plot.setLineWidth(6);
                plot.setColor(Color.black);
                plot.add("line",frameNumber, axisZero);
                for(int channelcount = 0;channelcount<params.imStackNumberOfChannels;channelcount++){
                    plot.setColor(mycolour.get(channelcount));
                    double[] detectTopEdgelot = (traces.get(channelcount).get(abPartCount)).stream().mapToDouble(d -> d).toArray();
                    plot.add("line",frameNumber, detectTopEdgelot);
                }
                plot.setColor(Color.black);
                plot.addLabel( 0.25, 0,"Particle "+IJ.d2s(abPartCount+1,0)+" x "+IJ.d2s(measures.get(abPartCount).get(0),0)+" y "+IJ.d2s(measures.get(abPartCount).get(1),0));
                plot.appendToStack();
            }

            plot.show();

            ImagePlus imp = IJ.getImage();

            MontageMaker mymontage = new MontageMaker();
            mymontage.makeMontage(imp, 6, 6, 1, 1, count, 1, 5, false);
            imp.close();

        }catch(Exception e)
        {
            gd = new GenericDialog("Error", IJ.getInstance());
            gd.addMessage("Error Plotting Trace... ");
            gd.addMessage(e.getMessage());
            gd.addMessage(e.getLocalizedMessage());
            gd.addMessage(e.toString());
            gd.showDialog();
        }
    }

    void getBatchFiles(){


        java.util.List<String> subfolderlist;

        gd = new GenericDialog("8) Select Batch Files", IJ.getInstance());
        gd.addMessage("Select the folder that contains all image files to analyse");
        gd.addCheckbox("Image Files in subfolders",true);

        gd.setOKLabel("Select Folder");
        gd.showDialog();
        if (gd.wasCanceled())
            return;

        boolean filesInSubFolders = gd.getNextBoolean();

        DirectoryChooser dir = new DirectoryChooser("Select Folder containg all image stacks");

        String pathname = dir.getDirectory();

        results = new ArrayList<>();
        subfolderlist = new ArrayList<>();

        File[] files = new File(pathname).listFiles();
        //If this pathname does not denote a directory, then listFiles() returns null.
        if(files==null)return;
        for (File file : files) {
            if (file.isFile() && !filesInSubFolders) {
                String[] filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1])) {
                    results.add(file.getPath());
                    if(params.multipleFilesPerImageStack)break;
                }
            }
            else if(!file.isFile() && filesInSubFolders){
                subfolderlist.add(file.getPath());
            }
        }
        if (filesInSubFolders)
            for(String folderin:subfolderlist){
                files = new File(folderin).listFiles();

                for (File file : files) {
                    if (file.isFile()){
                        String[] filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                        if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1])) {
                            results.add(file.getPath());
                            if(params.multipleFilesPerImageStack)break;
                        }
                    }
                }
            }
        gd = new GenericDialog("8) Select Files for Batch analyse", IJ.getInstance());
        gd.addMessage("Detected Files : ");
        for (String result : results) gd.addMessage(result);
        gd.setOKLabel("Continue");
        gd.showDialog();
    }


    void runBatchFiles(){
        JFrame progressWindow = new JFrame("Progress");
        progressBar myProgressWindow = new progressBar();
        myProgressWindow.progressBar.setValue(0);
        myProgressWindow.Ratio.setText("0/" + Integer.toString(results.size()));
        progressWindow.setContentPane(myProgressWindow.MainPanel);
        progressWindow.setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);
        progressWindow.pack();
        progressWindow.setVisible(true);

        Runnable myrunnable = ()-> {
            int error = 1;

            try {
                int cores = Runtime.getRuntime().availableProcessors() - 2;
                if (cores < 1) cores = 1;
                ArrayList<batchClass> threadList = new ArrayList<>();
                for (int i = 0; i < cores; i++) threadList.add(new batchClass());

                error = 3;
                int filesSent = 0;
                while (filesSent < results.size() && !myProgressWindow.cancelbuttonpushed) {
                    for (int i = 0; i < cores; i++) {
                        if (threadList.get(i).batchThread == null || !threadList.get(i).batchThread.isAlive()) {
                            threadList.get(i).analyseImageStack(results.get(filesSent), params);
                            filesSent++;
                            int progressInt = Math.max(filesSent - cores, 0);
                            myProgressWindow.progressBar.setValue(100 * progressInt / results.size());
                            myProgressWindow.Ratio.setText(Integer.toString(progressInt) + "/" + Integer.toString(results.size()));
                            if (filesSent == results.size()) break;
                        }
                    }
                    Thread.sleep(1000);
                }
                error = 4;
                if (myProgressWindow.cancelbuttonpushed) {
                    for (int i = 0; i < cores; i++)
                        if (threadList.get(i).batchThread != null && threadList.get(i).batchThread.isAlive())
                            threadList.get(i).batchThread.interrupt();
                    return;
                }

                error = 5;
                for (int i = 0; i < cores; i++)
                    if (threadList.get(i).batchThread != null && threadList.get(i).batchThread.isAlive())
                        threadList.get(i).batchThread.join();
                error = 6;
                myProgressWindow.progressBar.setValue(100);
                myProgressWindow.Ratio.setText(Integer.toString(results.size()) + "/" + Integer.toString(results.size()));


            } catch (Exception e) {
                gd = new GenericDialog("Error", IJ.getInstance());
                gd.addMessage("Error During Batch Processing... ");
                gd.addMessage("errorVal = " + Integer.toString(error));
                gd.showDialog();
                return;
            }
        };
        Thread masterthread = new Thread(myrunnable);
        masterthread.start();
        try {
            masterthread.join();
        }catch (Exception e) {
            gd = new GenericDialog("Error", IJ.getInstance());
            gd.addMessage("Error joining master thread");
            gd.showDialog();
            return;
        }

        progressWindow.dispose();

        gd = new GenericDialog("Batch Complete", IJ.getInstance());
        gd.addMessage("Batch Processsing is complete!");
        gd.showDialog();
        return;

    }





    public GenerateTracesWindow() {

        setup_Jim_Programs();

        selectInputFileBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                getInputFile();
            }
        });
        splitChannelsBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                splitFiles();
            }
        });
        alignDriftCorrectBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                driftCorrectImage();
            }
        });
        makeSubAverageBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                makeSubImage();
            }
        });
        detectParticlesBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                detectParticles();
            }
        });
        additionalBackgroundBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                additionalBackgroundDetection();
            }
        });
        expandRegionsBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                expandROIs();
            }
        });
        calculateTracesBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                measureTraces();
            }
        });
        viewTracesBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                viewTraces();
            }
        });
        viewParamsBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                params.UpdateParameters();
            }
        });
        importParametersBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                params.importParameters();
            }
        });
        saveParametersBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                params.saveParameters(true, workingDir);
            }
        });
        selectBatchFilesBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                getBatchFiles();
            }
        });
        batchProcessBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                runBatchFiles();
            }
        });
    }
}
