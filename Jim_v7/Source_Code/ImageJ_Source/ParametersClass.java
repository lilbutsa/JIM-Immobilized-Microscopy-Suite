import ij.IJ;
import ij.gui.GenericDialog;
import ij.io.OpenDialog;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.ArrayList;
import java.util.Scanner;

class ParametersClass {
    //File strings
    String OS;
    String JIM;
    String fileSep;
    String fileEXE;
    String quote;
    String newCMDWindowBefore,newCMDWindowAfter;


    //1 File Input
    int additionalExtensionsToRemove;
    boolean multipleFilesPerImageStack;

    //2 - Split Channels
    int imStackNumberOfChannels;

    String imStackChannelsToTransform;
    String imStackVerticalFlipChannel;
    String imStackHorizontalFlipChannel;
    String imStackRotateChannel;

    boolean imStackDisableMetadata;

    int imStackStartFrame;
    int imStackEndFrame;


    // 2 - Drift Correct Parameters
    int alignIterations;
    int alignStartFrame;
    int alignEndFrame;
    double alignMaxShift;

    boolean alignManually;
    String alignRotationAngle,alignScalingFactor,alignXOffset,alignYOffset,alignMaxInt;
    double alignSNRdetectionCutoff;
    boolean alignOutputStacks;


    // 3 - Make a SubAverage of the Image Stack for Detection Parameters
    boolean detectUsingMaxProjection;
    String detectionStartFrame, detectionEndFrame, detectWeights;

    // 4 - Detect Particles Parameters
    double detectionCutoff;

    int detectLeftEdge;
    int detectRightEdge;
    int detectTopEdge;
    int detectBottomEdge;
    int detectMinCount;
    int detectMaxCount;
    double detectMinEccentricity;
    double detectMaxEccentricity;
    double detectMinLength;
    double detectMaxLength;
    double detectMaxDistFromLinear;
    double detectMinSeparation;

    //Detect Additional Background
    boolean additionBackgroundDetect,additionBackgroundUseMaxProjection;
    double additionBackgroundCutoff;
    String additionalBackgroundStartFrame,additionalBackgroundEndFrame,additionalBackgroundWeights;

    // 5 - Expand Regions Parameters

    double expandForegroundDist;
    double expandBackInnerDist;
    double expandBackOuterDist;

    // 6 - Calculate Traces Parameter
    boolean verboseOutput;

    // 7 - View Traces Parameter
    int pageNumber;

    // 8 - Detect files for batch
    boolean filesInSubFolders;

    // 9 - Batch Analysis
    boolean overwritePreviouslyAnalysed;

    public ParametersClass(){
        //1 - file selection
        additionalExtensionsToRemove = 0;
        multipleFilesPerImageStack = false;

        //2 - Arrange Channels
        imStackNumberOfChannels = 1;

        imStackChannelsToTransform = "";
        imStackVerticalFlipChannel = "1";
        imStackHorizontalFlipChannel = "0";
        imStackRotateChannel = "0";

        imStackDisableMetadata = false;

        imStackStartFrame = 1;
        imStackEndFrame = -1;


        // 2 - Drift Correct Parameters
        alignIterations = 1;
        alignStartFrame = 1;
        alignEndFrame = 5;

        alignManually = false;
        alignRotationAngle = "0";
        alignScalingFactor = "1";
        alignXOffset = "0";
        alignYOffset = "0";
        alignMaxInt = "65000 65000";
        alignSNRdetectionCutoff = 1;

        alignMaxShift = 10000;

        // 3 - Make a SubAverage of the Image Stack for Detection Parameters
        detectUsingMaxProjection = false;
        detectionStartFrame = "1 1";
        detectionEndFrame = "10 10";
        detectWeights = "1 1";

        // 4 - Detect Particles Parameters
        detectionCutoff = 0.5;

        detectLeftEdge = 25;
        detectRightEdge = 25;
        detectTopEdge = 25;
        detectBottomEdge = 25;

        detectMinCount = 0;
        detectMaxCount = 10000;

        detectMinEccentricity = -0.1;
        detectMaxEccentricity = 1.1;

        detectMinLength = 0;
        detectMaxLength = 10000;

        detectMaxDistFromLinear = 10000;

        detectMinSeparation = -1000;

        //Additional Background
        additionBackgroundDetect = false;
        additionBackgroundUseMaxProjection = true;
        additionBackgroundCutoff = 1;
        additionalBackgroundStartFrame = "1 1";
        additionalBackgroundEndFrame = "-1 -1";
        additionalBackgroundWeights = "1 1";

        // 5 - Expand Regions Parameters

        expandForegroundDist = 4.1;
        expandBackInnerDist = 4.1;
        expandBackOuterDist = 20;

        // 6 - Calculate Traces Parameter
        verboseOutput = false;

        // 7 - View Traces Parameter
        pageNumber = 1;

        // 8 - Detect files for batch
        filesInSubFolders = true;

        // 9 - Batch Analysis
        overwritePreviouslyAnalysed = true;

    }

    void runCommand(boolean verbose,ArrayList<String> CMDList){
        try {

            if ((OS.contains("mac")) || (OS.contains("darwin"))){
                Runtime runtime= Runtime.getRuntime();
                String CMD = CMDList.get(0);
                for(int i=1;i<CMDList.size();i++)CMD = CMD + " " + CMDList.get(i);
                String[] args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                Process process = runtime.exec(args);
                process.waitFor();
            }
            else if (OS.contains("win")){
                ProcessBuilder builder = new ProcessBuilder(CMDList);
                builder.redirectErrorStream(true);
                Process process = builder.start();
                process.waitFor();

                if(verbose) {
                    Scanner s = new Scanner(process.getInputStream()).useDelimiter("\\A");
                    String result = s.hasNext() ? s.next() : "";
                    GenericDialog gd = new GenericDialog("Finished running", IJ.getInstance());
                    gd.addMessage(result);
                    gd.showDialog();
                }
            }



        }catch(Exception e)
        {
            GenericDialog gd = new GenericDialog("Error while running program", IJ.getInstance());
            gd.addMessage(CMDList.get(0));
            gd.addMessage(e.getMessage());
            gd.showDialog();
        }

    }



    void UpdateParameters(){


        GenericDialog gd = new GenericDialog("Update Parameters", IJ.getInstance());
        gd.addMessage("1) Select File");
        gd.addNumericField("Additional Extensions to Remove ", additionalExtensionsToRemove, 0);
        gd.addToSameRow();
        gd.addCheckbox("Multiple Files Per Image Stack",multipleFilesPerImageStack);

        gd.addMessage("2) Organise Channels");
        gd.addNumericField("Number of Channels ", imStackNumberOfChannels, 0);
        gd.addToSameRow();
        gd.addCheckbox("Disable Metadata",imStackDisableMetadata);

        gd.addNumericField("Stack Start Frame ", imStackStartFrame, 0);
        gd.addToSameRow();
        gd.addNumericField("Stack End Frame ", imStackEndFrame, 0);
        gd.addToSameRow();
        gd.addStringField("Channels to Transform", imStackChannelsToTransform);
        gd.addStringField("Vertical Flip", imStackVerticalFlipChannel);
        gd.addToSameRow();
        gd.addStringField("Horizontal Flip", imStackHorizontalFlipChannel);
        gd.addToSameRow();
        gd.addStringField("Rotate", imStackRotateChannel);

        gd.addMessage("3) Align Channels and Calculate Drifts");
        gd.addNumericField("Iterations ", alignIterations, 0);
        gd.addToSameRow();
        gd.addNumericField("Alignment Start Frame", alignStartFrame, 0);
        gd.addToSameRow();
        gd.addNumericField("Alignment End Frame ", alignEndFrame, 0);
        gd.addNumericField("Max Shift ", alignMaxShift, 2);
        gd.addToSameRow();
        gd.addCheckbox("Save aligned stack",alignOutputStacks);

        gd.addStringField("Alignment Max Int.", alignMaxInt);
        gd.addToSameRow();
        gd.addNumericField("Alignment SNR detectionCutoff", alignSNRdetectionCutoff, 2);
        gd.addCheckbox("Align Manually",alignManually);
        gd.addToSameRow();
        gd.addStringField("X offset", alignXOffset);
        gd.addToSameRow();
        gd.addStringField("Y offset", alignYOffset);
        gd.addStringField("Rotation Angle", alignRotationAngle);
        gd.addToSameRow();
        gd.addStringField("Scaling Factor ", alignScalingFactor);


        gd.addMessage("5) Make Sub-Average");
        gd.addCheckbox("Use Max Projection",detectUsingMaxProjection);
        gd.addStringField("Detection Start Frames", detectionStartFrame);
        gd.addToSameRow();
        gd.addStringField("Detection End Frames", detectionEndFrame);
        gd.addToSameRow();
        gd.addStringField("Channel Weights", detectWeights);

        gd.addMessage("6) Detect Particles");
        gd.addNumericField("Threshold Cutoff", detectionCutoff, 2);
        gd.addToSameRow();
        gd.addNumericField("Min. Distance From Left Edge", detectLeftEdge, 0);
        gd.addToSameRow();
        gd.addNumericField("Min. Distance From Right Edge", detectRightEdge, 0);
        gd.addNumericField("Min. Distance From Top Edge", detectTopEdge, 0);
        gd.addToSameRow();
        gd.addNumericField("Min. Distance From Bottom Edge", detectBottomEdge, 0);
        gd.addNumericField("Min. Pixel Count", detectMinCount, 0);
        gd.addToSameRow();
        gd.addNumericField("Max. Pixel Count", detectMaxCount, 0);
        gd.addNumericField("Min. Eccentricity", detectMinEccentricity, 2);
        gd.addToSameRow();
        gd.addNumericField("Max. Eccentricity", detectMaxEccentricity, 2);
        gd.addNumericField("Min. Length (Pixels)", detectMinLength, 1);
        gd.addToSameRow();
        gd.addNumericField("Max. Length (Pixels)", detectMaxLength, 1);
        gd.addNumericField("Max. Dist. From Linear", detectMaxDistFromLinear, 2);
        gd.addToSameRow();
        gd.addNumericField("Min. Separation", detectMinSeparation, 2);

        gd.addMessage("7) Additional Background Detection");
        gd.addCheckbox("Detect Additional Background",additionBackgroundDetect);
        gd.addToSameRow();
        gd.addCheckbox("Use Max Projection",additionBackgroundUseMaxProjection);
        gd.addStringField("Detection Start Frames", additionalBackgroundStartFrame);
        gd.addToSameRow();
        gd.addStringField("Detection End Frames", additionalBackgroundEndFrame);
        gd.addStringField("Channel Weights", additionalBackgroundWeights);
        gd.addToSameRow();
        gd.addNumericField("Threshold Cutoff", additionBackgroundCutoff, 2);

        gd.addMessage("8) Expand Regions");
        gd.addNumericField("Foreground Distance", expandForegroundDist, 2);
        gd.addToSameRow();
        gd.addNumericField("Background Inner Distance", expandBackInnerDist, 2);
        gd.addToSameRow();
        gd.addNumericField("Background Outer Distance", expandBackOuterDist, 2);


        gd.addMessage("9) Calculate Traces");
        gd.addCheckbox("Verbose Output",verboseOutput);

        gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/begin_here_generate_traces.html");
        gd.showDialog();

        if (gd.wasCanceled())
            return;



        additionalExtensionsToRemove = (int) gd.getNextNumber();
        multipleFilesPerImageStack = gd.getNextBoolean();

        imStackNumberOfChannels = (int) gd.getNextNumber();
        imStackDisableMetadata = gd.getNextBoolean();
        imStackStartFrame = (int) gd.getNextNumber();
        imStackEndFrame = (int) gd.getNextNumber();
        imStackChannelsToTransform = gd.getNextString();
        imStackVerticalFlipChannel = gd.getNextString();
        imStackHorizontalFlipChannel = gd.getNextString();
        imStackRotateChannel = gd.getNextString();


        alignIterations = (int) gd.getNextNumber();
        alignStartFrame = (int) gd.getNextNumber();
        alignEndFrame = (int) gd.getNextNumber();
        alignMaxShift = gd.getNextNumber();
        alignOutputStacks = gd.getNextBoolean();

        alignMaxInt = gd.getNextString();
        alignSNRdetectionCutoff = gd.getNextNumber();
        alignManually = gd.getNextBoolean();
        alignXOffset = gd.getNextString();
        alignYOffset = gd.getNextString();
        alignRotationAngle = gd.getNextString();
        alignScalingFactor = gd.getNextString();


        detectUsingMaxProjection = gd.getNextBoolean();
        detectionStartFrame = gd.getNextString();
        detectionEndFrame = gd.getNextString();
        detectWeights = gd.getNextString();


        detectionCutoff =  gd.getNextNumber();
        detectLeftEdge =  (int) gd.getNextNumber();
        detectRightEdge =  (int) gd.getNextNumber();
        detectTopEdge =  (int) gd.getNextNumber();
        detectBottomEdge = (int) gd.getNextNumber();
        detectMinCount = (int) gd.getNextNumber();
        detectMaxCount = (int) gd.getNextNumber();
        detectMinEccentricity =  gd.getNextNumber();
        detectMaxEccentricity =  gd.getNextNumber();
        detectMinLength =  gd.getNextNumber();
        detectMaxLength =  gd.getNextNumber();
        detectMaxDistFromLinear =  gd.getNextNumber();
        detectMinSeparation =  gd.getNextNumber();

        additionBackgroundDetect = gd.getNextBoolean();
        additionBackgroundUseMaxProjection = gd.getNextBoolean();
        additionalBackgroundStartFrame = gd.getNextString();
        additionalBackgroundEndFrame = gd.getNextString();
        additionalBackgroundWeights = gd.getNextString();
        additionBackgroundCutoff =  gd.getNextNumber();

        expandForegroundDist =  gd.getNextNumber();
        expandBackInnerDist =  gd.getNextNumber();
        expandBackOuterDist =  gd.getNextNumber();

        verboseOutput = gd.getNextBoolean();
    }

    void importParameters(){

        OpenDialog fileselector;

        fileselector = new OpenDialog("Open Parameters CSV");

        String saveName = fileselector.getPath();
        String row;
        try{
            BufferedReader csvReader = new BufferedReader(new FileReader(saveName));

            int count = 0;
            while ((row = csvReader.readLine()) != null) {
                String[] data = row.split(",");
                if(count == 1)additionalExtensionsToRemove = Integer.parseInt(data[1]);
                if(count == 2)multipleFilesPerImageStack = Boolean.parseBoolean(data[1]);

                if(count == 3)imStackNumberOfChannels = Integer.parseInt(data[1]);
                if(count == 4)imStackDisableMetadata = Boolean.parseBoolean(data[1]);
                if(count == 5)imStackStartFrame = Integer.parseInt(data[1]);
                if(count == 6)imStackEndFrame = Integer.parseInt(data[1]);
                if(count == 7)imStackChannelsToTransform = data[1];
                if(count == 8)imStackVerticalFlipChannel = data[1];
                if(count == 9)imStackHorizontalFlipChannel = data[1];
                if(count == 10)imStackRotateChannel = data[1];


                if(count == 11)alignIterations = Integer.parseInt(data[1]);
                if(count == 12)alignStartFrame = Integer.parseInt(data[1]);
                if(count == 13)alignEndFrame = Integer.parseInt(data[1]);
                if(count == 14)alignMaxShift = Double.parseDouble(data[1]);
                if(count == 15)alignOutputStacks = Boolean.parseBoolean(data[1]);
                if(count == 16)alignMaxInt = data[1];
                if(count == 17)alignSNRdetectionCutoff = Double.parseDouble(data[1]);
                if(count == 18)alignManually = Boolean.parseBoolean(data[1]);
                if(count == 19)alignXOffset = data[1];
                if(count == 20)alignYOffset = data[1];
                if(count == 21)alignRotationAngle = data[1];
                if(count == 22)alignScalingFactor = data[1];


                if(count == 23)detectUsingMaxProjection = Boolean.parseBoolean(data[1]);
                if(count == 24)detectionStartFrame = data[1];
                if(count == 25)detectionEndFrame = data[1];
                if(count == 26)detectWeights = data[1];


                if(count == 27)detectionCutoff =  Double.parseDouble(data[1]);
                if(count == 28)detectLeftEdge =  Integer.parseInt(data[1]);
                if(count == 29)detectRightEdge =  Integer.parseInt(data[1]);
                if(count == 30)detectTopEdge =  Integer.parseInt(data[1]);
                if(count == 31)detectBottomEdge = Integer.parseInt(data[1]);
                if(count == 32)detectMinCount = Integer.parseInt(data[1]);
                if(count == 33)detectMaxCount = Integer.parseInt(data[1]);
                if(count == 34)detectMinEccentricity =  Double.parseDouble(data[1]);
                if(count == 35)detectMaxEccentricity =  Double.parseDouble(data[1]);
                if(count == 36)detectMinLength =  Double.parseDouble(data[1]);
                if(count == 37)detectMaxLength =  Double.parseDouble(data[1]);
                if(count == 38)detectMaxDistFromLinear =  Double.parseDouble(data[1]);
                if(count == 39)detectMinSeparation =  Double.parseDouble(data[1]);

                if(count == 40)additionBackgroundDetect = Boolean.parseBoolean(data[1]);
                if(count == 41)additionBackgroundUseMaxProjection = Boolean.parseBoolean(data[1]);
                if(count == 42)additionalBackgroundStartFrame = data[1];
                if(count == 43)additionalBackgroundEndFrame = data[1];
                if(count == 44)additionalBackgroundWeights = data[1];
                if(count == 45)additionBackgroundCutoff =  Double.parseDouble(data[1]);

                if(count == 46)expandForegroundDist =  Double.parseDouble(data[1]);
                if(count == 47)expandBackInnerDist =  Double.parseDouble(data[1]);
                if(count == 48)expandBackOuterDist =  Double.parseDouble(data[1]);

                if(count == 49)verboseOutput = Boolean.parseBoolean(data[1]);


                count++;
            }
            csvReader.close();
        }catch(Exception e)
        {
            GenericDialog gd = new GenericDialog("Error", IJ.getInstance());
            gd.addMessage("Error During Parameter Import... ");
            gd.addMessage(e.getMessage());
            gd.addMessage(e.getLocalizedMessage());
            gd.addMessage(e.toString());
            gd.showDialog();
        }


    }



    void saveParameters(boolean selectFile, String workingDir){
        try{
            String saveName = workingDir+"Trace_Generation_Variables.csv";
            if(selectFile) {
                OpenDialog fileselector;
                fileselector = new OpenDialog("Save Parameters CSV");
                saveName = fileselector.getPath();
            }
            String currentDate = java.time.LocalDate.now().toString();

            String variablesString = ("Date, " + currentDate +
                    "\nadditionalExtensionsToRemove,"+ IJ.d2s(additionalExtensionsToRemove,0)+
                    "\nmultipleFilesPerImageStack," + (multipleFilesPerImageStack?"true ":"false ") +

                    "\nimStackNumberOfChannels," + IJ.d2s(imStackNumberOfChannels,0) +
                    "\nimStackDisableMetadata," + (imStackDisableMetadata?"true ":"false ") +
                    "\nimStackStartFrame,"+ IJ.d2s(imStackStartFrame ,0)+
                    "\nimStackEndFrame,"+ IJ.d2s(imStackEndFrame ,0)+
                    "\nimStackChannelsToTransform ,"+imStackChannelsToTransform +
                    "\nimStackVerticalFlipChannel ,"+imStackVerticalFlipChannel +
                    "\nimStackHorizontalFlipChannel ,"+imStackHorizontalFlipChannel +
                    "\nimStackRotateChannel ,"+imStackRotateChannel +

                    "\nalignIterations," + IJ.d2s(alignIterations,0) +
                    "\nalignStartFrame," + IJ.d2s(alignStartFrame,0) +
                    "\nalignEndFrame," + IJ.d2s(alignEndFrame,0) +
                    "\nalignMaxShift," + IJ.d2s(alignMaxShift,2) +
                    "\nalignOutputStacks," + (alignOutputStacks?"true ":"false ")  +

                    "\nalignMaxInt,"+alignMaxInt  +
                    "\nalignSNRdetectionCutoff," + IJ.d2s(alignSNRdetectionCutoff ,2) +
                    "\nalignManually," + (alignManually?"true ":"false ") +
                    "\nalignXOffset,"+alignXOffset+
                    "\nalignYOffset," +alignYOffset+
                    "\nalignRotationAngle," + alignRotationAngle +
                    "\nalignScalingFactor," +alignScalingFactor+


                    "\ndetectUsingMaxProjection," + (detectUsingMaxProjection?"true ":"false ") +
                    "\ndetectionStartFrame," + detectionStartFrame +
                    "\ndetectionEndFrame," + detectionEndFrame +
                    "\ndetectWeights ," + detectWeights  +

                    "\ndetectionCutoff," + IJ.d2s(detectionCutoff,2) +
                    "\ndetectLeftEdge," + IJ.d2s(detectLeftEdge,0) +
                    "\ndetectRightEdge," + IJ.d2s(detectRightEdge,0) +
                    "\ndetectTopEdge," + IJ.d2s(detectTopEdge,0) +
                    "\ndetectBottomEdge," + IJ.d2s(detectBottomEdge,0) +
                    "\ndetectMinCount," + IJ.d2s(detectMinCount,0) +
                    "\ndetectMaxCount," + IJ.d2s(detectMaxCount,0) +
                    "\ndetectMinEccentricity," +IJ.d2s(detectMinEccentricity) +
                    "\ndetectMaxEccentricity," + IJ.d2s(detectMaxEccentricity) +
                    "\ndetectMinLength," + IJ.d2s(detectMinLength,2) +
                    "\ndetectMaxLength," + IJ.d2s(detectMaxLength,2) +
                    "\ndetectMaxDistFromLinear," + IJ.d2s(detectMaxDistFromLinear,2) +
                    "\ndetectMinSeparation," + IJ.d2s(detectMinSeparation,2) +

                    "\nadditionBackgroundDetect ," + (additionBackgroundDetect?"true ":"false ") +
                    "\nadditionBackgroundUseMaxProjection ," + (additionBackgroundUseMaxProjection?"true ":"false ") +
                    "\nadditionalBackgroundStartFrame ," + additionalBackgroundStartFrame  +
                    "\nadditionalBackgroundEndFrame ," + additionalBackgroundEndFrame  +
                    "\nadditionalBackgroundWeights  ," + additionalBackgroundWeights   +
                    "\nadditionBackgroundCutoff ," + IJ.d2s(additionBackgroundCutoff ,2) +

                    "\nexpandForegroundDist," + IJ.d2s(expandForegroundDist,2) +
                    "\nexpandBackInnerDist," + IJ.d2s(expandBackInnerDist,2) +
                    "\nexpandBackOuterDist," + IJ.d2s(expandBackOuterDist,2) +

                    "\nverboseOutput," + (verboseOutput?"true ":"false "));
            FileWriter fw=new FileWriter(saveName);
            fw.write(variablesString);
            fw.close();
        }catch(Exception e)
        {
            GenericDialog gd = new GenericDialog("Error", IJ.getInstance());
            gd.addMessage("Error During Batch Process1ing... ");
            gd.showDialog();
        }
    }
}
