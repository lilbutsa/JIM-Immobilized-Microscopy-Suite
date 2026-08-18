package Jimbob;

import ij.gui.GenericDialog;

import java.awt.*;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.ArrayList;
import java.util.Arrays;

public class paramsClass
{

    String folderName;
    String fileBase;

    int posNum= 0;

    //Alignment Info
    int[] C2CalignmentX,C2CalignmentY;
    Rectangle alignmentRectangle;

    //Detection parameters
    boolean driftCorrectOnlyDetect = true,displayAlignedStack,saveTraces;
    int alignMaxShift,alignROILength,detectStart,detectEnd,alignChannel,minCount,maxCount,minDFE;
    double cutoff,minEccentricity,maxEccentricity,timePerFrame,minSeparation,padROI,padBackground;
    String timePerFrameUnits;
    boolean bNormalizeTraces = false;


    //Fit parameters
    ArrayList<fittingMainClass> allFits = new ArrayList<>();
    int selectedFit = -1;

    //Internal params
    double LoGStdDev = 3,alignFilterStdDev = 10,measureAlignStdDev = 3;
    int initialSmallStackNum = 10;

    paramsClass(){
    }

    paramsClass(paramsClass other){
        folderName = other.folderName;
        fileBase = other.fileBase;
        posNum= other.posNum;
        C2CalignmentX = other.C2CalignmentX.clone();
        C2CalignmentY = other.C2CalignmentY.clone();
        alignmentRectangle = new Rectangle(other.alignmentRectangle);
        driftCorrectOnlyDetect = other.driftCorrectOnlyDetect;
        displayAlignedStack = other.displayAlignedStack;
        saveTraces = other.saveTraces;
        alignMaxShift = other.alignMaxShift;

        alignROILength = other.alignROILength;
        detectStart = other.detectStart;
        detectEnd = other.detectEnd;
        alignChannel = other.alignChannel;
        cutoff = other.cutoff;
        minCount = other.minCount;
        maxCount = other.maxCount;
        minDFE = other.minDFE;
        minEccentricity = other.minEccentricity;
        maxEccentricity = other.maxEccentricity;
        timePerFrame = other.timePerFrame;
        minSeparation = other.minSeparation;
        padBackground = other.padBackground;
        timePerFrameUnits = other.timePerFrameUnits;
        padROI = other.padROI;
        bNormalizeTraces = other.bNormalizeTraces;

        selectedFit = other.selectedFit;
        LoGStdDev = other.LoGStdDev;
        alignFilterStdDev = other.alignFilterStdDev;
        initialSmallStackNum = other.initialSmallStackNum;
        //Fit parameters

        allFits = new ArrayList<>();
        for(int i=0;i<other.allFits.size();i++)allFits.add(new fittingMainClass(other.allFits.get(i)));

    }

    void parseParameters(Jimbob_Window Jim){
        //detection Image
        alignROILength = Integer.parseInt(Jim.AlignROISizeTextBox.getText());

        if(Jim.rawData!=null && Jim.rawData.imageWidth>0) {
            if (alignROILength > Jim.rawData.imageWidth || alignROILength > Jim.rawData.imageHeight || alignROILength < 8)
                alignROILength = Math.min(Jim.rawData.imageWidth, Jim.rawData.imageHeight);

            if ((alignROILength & -alignROILength) != alignROILength) {
                alignROILength = (int) (Math.log(alignROILength) / Math.log(2));
                alignROILength = (int) Math.round(Math.pow(2, alignROILength));
            }
            Jim.AlignROISizeTextBox.setText(String.valueOf(alignROILength));

            alignmentRectangle = new Rectangle(Jim.rawData.imageWidth / 2 - alignROILength / 2, Jim.rawData.imageHeight / 2 - alignROILength / 2, alignROILength, alignROILength);
        }

        alignMaxShift = Integer.parseInt(Jim.driftMaxShiftBox.getText());
        driftCorrectOnlyDetect = Jim.driftOnlyUsingDetectionChannelBox.isSelected();
        alignChannel = Integer.parseInt(Jim.Align_Channel_Select.getText());
        if(alignChannel<0||alignChannel>Jim.rawData.totChanNum){
            alignChannel = 0;
            Jim.Align_Channel_Select.setText("0");
        }


        detectStart = Integer.parseInt(Jim.detectStartFrameBox.getText())-1;
        detectEnd = Integer.parseInt(Jim.detectEndFrameBox.getText());
        if(detectEnd<0)detectEnd = Jim.rawData.totFrameNum+detectEnd+1;

        cutoff = Double.parseDouble(Jim.cutoffBox.getText());
        minDFE = Integer.parseInt(Jim.minDFEBox.getText());
        minEccentricity = Double.parseDouble(Jim.minEccentricityBox.getText());
        maxEccentricity = Double.parseDouble(Jim.maxEccentricityBox.getText());
        minCount = Integer.parseInt(Jim.minCountBox.getText());
        maxCount = Integer.parseInt(Jim.maxCountBox.getText());
        minSeparation = Double.parseDouble(Jim.minSeparationBox.getText());
        padROI = Double.parseDouble(Jim.ROIPaddingBox.getText());
        padBackground = Double.parseDouble(Jim.sBackgroundWidth.getText());

        saveTraces = Jim.saveTracesBox.isSelected();
        folderName = Jim.batchDirectoryBox.getText();
        fileBase = Jim.rawData.getFolderName(posNum,folderName,saveTraces);

        displayAlignedStack = Jim.displayAlignedStackBox.isSelected();

        timePerFrame = Double.parseDouble(Jim.timePerFrameBox.getText());
        timePerFrameUnits = Jim.timePerFrameUnitsBox.getText();

        selectedFit = Jim.allFitsDropdown.getSelectedIndex();

        bNormalizeTraces = Jim.bNormalizeTracesBox.isSelected();

        int pageNo = Integer.parseInt(Jim.pageNumberBox.getText());

        for(int i=0;i<allFits.size();i++){
            allFits.get(i).fileBase = fileBase+"Fit_"+(i+1)+allFits.get(i).fitNameNoSpaces+ File.separator;
            allFits.get(i).timePerFrameUnits = timePerFrameUnits;
            allFits.get(i).timePerFrame=timePerFrame;
            allFits.get(i).saveTraces = saveTraces;
            allFits.get(i).pageNo = pageNo;
        }
    }



    void readUsedParametersCSV(String filePath,Jimbob_Window Jim) {
        String line = "";
        try(BufferedReader br = new BufferedReader(new FileReader(filePath));) {

            allFits = new ArrayList<>();

            while ((line = br.readLine()) != null) {
                String[] values = line.split(",", 2);
                if (values.length < 2) continue;
                if (values[0].equalsIgnoreCase("alignROILength")) Jim.AlignROISizeTextBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("alignMaxShift")) Jim.driftMaxShiftBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("driftCorrectOnlyDetect"))
                    Jim.driftOnlyUsingDetectionChannelBox.setSelected(values[1].equalsIgnoreCase("True"));
                else if (values[0].equalsIgnoreCase("alignChannel")) Jim.Align_Channel_Select.setText(values[1]);
                else if (values[0].equalsIgnoreCase("detectStart")) Jim.detectStartFrameBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("detectEnd")) Jim.detectEndFrameBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("threshold")) Jim.cutoffBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("minDistanceFromEdge")) Jim.minDFEBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("minEccentricity")) Jim.minEccentricityBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("maxEccentricity")) Jim.maxEccentricityBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("minCount")) Jim.minCountBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("maxCount")) Jim.maxCountBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("minSeparation")) Jim.minSeparationBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("padROI")) Jim.ROIPaddingBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("padBackground")) Jim.sBackgroundWidth.setText(values[1]);
                else if (values[0].equalsIgnoreCase("displayAlignedStack"))
                    Jim.displayAlignedStackBox.setSelected(values[1].equalsIgnoreCase("True"));
                else if (values[0].equalsIgnoreCase("saveTraces"))
                    Jim.saveTracesBox.setSelected(values[1].equalsIgnoreCase("True"));
                else if (values[0].equalsIgnoreCase("timePerFrame")) Jim.timePerFrameBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("timePerFrameUnits")) Jim.timePerFrameUnitsBox.setText(values[1]);
                else if (values[0].equalsIgnoreCase("normalizeTraces"))
                    Jim.bNormalizeTracesBox.setSelected(values[1].equalsIgnoreCase("True"));
                else if (values[0].length() > 20 && values[0].substring(0, 20).equalsIgnoreCase("X_Alignment_Channel_")) {
                    int numIn = Integer.parseInt(values[0].substring(20)) - 2;
                    if (C2CalignmentX.length < numIn + 1) {
                        C2CalignmentX = Arrays.copyOf(C2CalignmentX, numIn + 1);
                        C2CalignmentY = Arrays.copyOf(C2CalignmentY, numIn + 1);
                    }
                    C2CalignmentX[numIn] = Integer.parseInt(values[1]);
                } else if (values[0].length() > 20 && values[0].substring(0, 20).equalsIgnoreCase("Y_Alignment_Channel_")) {
                    int numIn = Integer.parseInt(values[0].substring(20)) - 2;
                    if (C2CalignmentX.length < numIn + 1) {
                        C2CalignmentX = Arrays.copyOf(C2CalignmentX, numIn + 1);
                        C2CalignmentY = Arrays.copyOf(C2CalignmentY, numIn + 1);
                    }
                    C2CalignmentY[numIn] = Integer.parseInt(values[1]);
                } else if (values[0].startsWith("Fit_Type_Fit_")) {//Fit parameters
                    int numIn = Integer.parseInt(values[0].substring("Fit_Type_Fit_".length())) - 1;
                    if (allFits.size() < numIn + 1)
                        for (int i = allFits.size(); i < numIn + 1; i++) allFits.add(new fittingMainClass());
                    allFits.get(numIn).fitType = Arrays.asList(fittingMainClass.fitTypeNames).indexOf(values[1]);
                } else if(values[0].startsWith("Fit_Range_Type_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Range_Type_Fit_".length()))-1).fitRangeType =
                            Arrays.asList(fittingMainClass.rangeNames).indexOf(values[1]);
                else if(values[0].startsWith("Fit_Normalization_Type_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Normalization_Type_Fit_".length()))-1).fitNormType =
                            Arrays.asList(fittingMainClass.normalizationTypeNames).indexOf(values[1]);
                else if(values[0].startsWith("Align_Type_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Type_Fit_".length()))-1).alignType =
                            Arrays.asList(fittingMainClass.alignmentTypeNames).indexOf(values[1]);
                else if(values[0].startsWith("Align_Range_Type_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Range_Type_Fit_".length()))-1).alignRangeType =
                            Arrays.asList(fittingMainClass.rangeNames).indexOf(values[1]);
                else if(values[0].startsWith("Align_Normalization_Type_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Normalization_Type_Fit_".length()))-1).alignNormType =
                            Arrays.asList(fittingMainClass.normalizationTypeNames).indexOf(values[1]);
                else if(values[0].startsWith("Fit_Channel_Fit_")) {
                    int numIn = Integer.parseInt(values[0].substring("Fit_Channel_Fit_".length())) - 1;
                    if (allFits.size() < numIn + 1)
                        for (int i = allFits.size(); i < numIn + 1; i++) allFits.add(new fittingMainClass());
                    allFits.get(numIn).fitChannel = Integer.parseInt(values[1])-1;
                }else if(values[0].startsWith("Fit_Range_Min_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Range_Min_Fit_".length()))-1).fitMinRange = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Range_Max_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Range_Max_Fit_".length()))-1).fitMaxRange = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Normalization_Const_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Normalization_Const_Fit_".length()))-1).fitNormConst = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Normalization_Channel_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Normalization_Channel_Fit_".length()))-1).fitNormChannel = Integer.parseInt(values[1])-1;
                else if(values[0].startsWith("Fit_Threshold_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Threshold_Fit_".length()))-1).fitThreshold = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Min_Loss_for_Single_Step_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Min_Loss_for_Single_Step_Fit_".length()))-1).fitStepfitMinSingleStepFraction = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Max_Loss_for_No_Step_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Max_Loss_for_No_Step_Fit_".length()))-1).fitStepfitMaxNoStepFraction = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Overwrite_Trace_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Overwrite_Trace_Fit_".length()))-1).fitOverwrite = values[1].equalsIgnoreCase("True");
                else if(values[0].startsWith("Fit_Binding_Data_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Binding_Data_Fit_".length()))-1).fitBCBinding = values[1].equalsIgnoreCase("True");
                else if(values[0].startsWith("Fit_Bleach_Frame_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Bleach_Frame_Fit_".length()))-1).bleachFrame = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Dissociation_Rate_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Dissociation_Rate_Fit_".length()))-1).dissociationTime = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Fit_Debounce_Num_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Debounce_Num_Fit_".length()))-1).fitDebounceNum = Integer.parseInt(values[1]);
                else if(values[0].startsWith("Fit_Rising_Threshold_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Rising_Threshold_Fit_".length()))-1).fitRisingThreshold = values[1].equalsIgnoreCase("True");
                else if(values[0].startsWith("Fit_First_Crossing_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_First_Crossing_Fit_".length()))-1).fitFirstThreshold = values[1].equalsIgnoreCase("True");
                else if(values[0].startsWith("Fit_Min_Trace_Count_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Fit_Min_Trace_Count_Fit_".length()))-1).minTraceCount = Integer.parseInt(values[1]);
                else if(values[0].startsWith("Align_Wash_In_Frame_Fit_"))//Align Parameters
                    allFits.get(Integer.parseInt(values[0].substring("Align_Wash_In_Frame_Fit_".length()))-1).washinFrame = Integer.parseInt(values[1]);
                else if(values[0].startsWith("Align_Channel_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Channel_Fit_".length()))-1).alignChannel = Integer.parseInt(values[1])-1;
                else if(values[0].startsWith("Align_Range_Min_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Range_Min_Fit_".length()))-1).alignMinRange = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Range_Max_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Range_Max_Fit_".length()))-1).alignMaxRange = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Normalization_Const_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Normalization_Const_Fit_".length()))-1).alignNormConst = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Normalization_Channel_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Normalization_Channel_Fit_".length()))-1).alignNormChannel = Integer.parseInt(values[1])-1;
                else if(values[0].startsWith("Align_Threshold_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Threshold_Fit_".length()))-1).alignThreshold = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Min_Loss_for_Single_Step_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Min_Loss_for_Single_Step_Fit_".length()))-1).alignStepfitMinSingleStepFraction = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Max_Loss_for_No_Step_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Max_Loss_for_No_Step_Fit_".length()))-1).alignStepfitMaxNoStepFraction = Double.parseDouble(values[1]);
                else if(values[0].startsWith("Align_Debounce_Num_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Debounce_Num_Fit_".length()))-1).alignDebounceNum = Integer.parseInt(values[1]);
                else if(values[0].startsWith("Align_Rising_Threshold_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_Rising_Threshold_Fit_".length()))-1).alignThresholdRising = values[1].equalsIgnoreCase("True");
                else if(values[0].startsWith("Align_First_Crossing_Fit_"))
                    allFits.get(Integer.parseInt(values[0].substring("Align_First_Crossing_Fit_".length()))-1).alignFirstCrossing = values[1].equalsIgnoreCase("True");


            }
        }catch (Exception e) {
            System.out.println("Could not read parameters CSV: Error with line "+line+ e);
            GenericDialog gd = new GenericDialog("Error - Could not read parameters");
            gd.addMessage("Error with line "+line);
            gd.showDialog();

        }

    }


    void writeUsedParametersCSV(String filePath) {

        try(FileWriter myOutput = new FileWriter(filePath);) {


            myOutput.write("Parameter,Value\n");
            myOutput.write("alignROILength," + alignROILength + "\n");
            myOutput.write("alignMaxShift," + alignMaxShift + "\n");
            myOutput.write("driftCorrectOnlyDetect," + (driftCorrectOnlyDetect ? "True" : "False") + "\n");
            myOutput.write("alignChannel," + alignChannel + "\n");
            myOutput.write("detectStart," + (detectStart + 1) + "\n");
            myOutput.write("detectEnd," + detectEnd + "\n");
            myOutput.write("threshold," + cutoff + "\n");
            myOutput.write("minDistanceFromEdge," + minDFE + "\n");
            myOutput.write("minEccentricity," + minEccentricity + "\n");
            myOutput.write("maxEccentricity," + maxEccentricity + "\n");
            myOutput.write("minCount," + minCount + "\n");
            myOutput.write("maxCount," + maxCount + "\n");
            myOutput.write("minSeparation," + minSeparation + "\n");
            myOutput.write("padROI," + padROI + "\n");
            myOutput.write("padBackground," + padBackground + "\n");
            myOutput.write("displayAlignedStack," + (displayAlignedStack ? "True" : "False") + "\n");
            myOutput.write("normalizeTraces," + (bNormalizeTraces ? "True" : "False") + "\n");
            myOutput.write("saveTraces," + (saveTraces ? "True" : "False") + "\n");
            myOutput.write("timePerFrame," + timePerFrame + "\n");
            myOutput.write("timePerFrameUnits," + timePerFrameUnits + "\n");
            for (int i = 0; i < C2CalignmentX.length; i++) {
                myOutput.write("X_Alignment_Channel_" + (i + 2) + "," + C2CalignmentX[i] + "\n");
                myOutput.write("Y_Alignment_Channel_" + (i + 2) + "," + C2CalignmentY[i] + "\n");
            }
            for (int i = 0; i < allFits.size(); i++) {
                myOutput.write("Fit_Type_Fit_" + (i + 1) + "," + fittingMainClass.fitTypeNames[allFits.get(i).fitType] + "\n");
                myOutput.write("Fit_Range_Type_Fit_" + (i + 1) + "," + fittingMainClass.rangeNames[allFits.get(i).fitRangeType] + "\n");
                myOutput.write("Fit_Normalization_Type_Fit_" + (i + 1) + "," + fittingMainClass.normalizationTypeNames[allFits.get(i).fitNormType] + "\n");
                myOutput.write("Fit_Channel_Fit_" + (i + 1) + "," + (allFits.get(i).fitChannel+1)+ "\n");

                myOutput.write("Align_Type_Fit_" + (i + 1) + "," + fittingMainClass.alignmentTypeNames[allFits.get(i).alignType] + "\n");
                myOutput.write("Align_Range_Type_Fit_" + (i + 1) + "," + fittingMainClass.rangeNames[allFits.get(i).alignRangeType] + "\n");
                myOutput.write("Align_Normalization_Type_Fit_" + (i + 1) + "," + fittingMainClass.normalizationTypeNames[allFits.get(i).alignNormType] + "\n");

                if(allFits.get(i).fitRangeType>0) {//Get channel and fit range
                    myOutput.write("Fit_Range_Min_Fit_" + (i + 1) + "," + allFits.get(i).fitMinRange + "\n");
                    myOutput.write("Fit_Range_Max_Fit_" + (i + 1) + "," + allFits.get(i).fitMaxRange + "\n");
                }

                if(allFits.get(i).fitNormType==1){myOutput.write("Fit_Normalization_Const_Fit_" + (i + 1) + "," + allFits.get(i).fitNormConst + "\n");
                }
                else if(allFits.get(i).fitNormType>1 && allFits.get(i).fitNormType<8 ){
                    myOutput.write("Fit_Normalization_Channel_Fit_" + (i + 1) + "," + (allFits.get(i).fitNormChannel+1) + "\n");
                }


                //fit parameters
                if(allFits.get(i).fitType==1) {    //SingleStep
                    myOutput.write("Fit_Threshold_Fit_" + (i + 1) + "," + allFits.get(i).fitThreshold + "\n");
                    myOutput.write("Fit_Min_Loss_for_Single_Step_Fit_" + (i + 1) + "," + allFits.get(i).fitStepfitMinSingleStepFraction + "\n");
                    myOutput.write("Fit_Max_Loss_for_No_Step_Fit_" + (i + 1) + "," + allFits.get(i).fitStepfitMaxNoStepFraction + "\n");
                    myOutput.write("Fit_Overwrite_Trace_Fit_" + (i + 1) + "," + (allFits.get(i).fitOverwrite ? "True" : "False") + "\n");
                }else if(allFits.get(i).fitType==2) {    //multi step  fit
                    myOutput.write("Fit_Threshold_Fit_" + (i + 1) + "," + allFits.get(i).fitThreshold + "\n");
                    myOutput.write("Fit_Overwrite_Trace_Fit_" + (i + 1) + "," + (allFits.get(i).fitOverwrite ? "True" : "False") + "\n");
                }else if(allFits.get(i).fitType==3) {    //Bleach Correct
                    myOutput.write("Fit_Binding_Data_Fit_" + (i + 1) + "," + (allFits.get(i).fitBCBinding ? "True" : "False") + "\n");
                    myOutput.write("Fit_Bleach_Frame_Fit_" + (i + 1) + "," + allFits.get(i).bleachFrame + "\n");
                    myOutput.write("Fit_Dissociation_Rate_Fit_" + (i + 1) + "," + allFits.get(i).dissociationTime + "\n");
                    myOutput.write("Fit_Overwrite_Trace_Fit_" + (i + 1) + "," + (allFits.get(i).fitOverwrite ? "True" : "False") + "\n");
                } else if(allFits.get(i).fitType==6) {
                    myOutput.write("Fit_Threshold_Fit_" + (i + 1) + "," + allFits.get(i).fitThreshold + "\n");
                    myOutput.write("Fit_Debounce_Num_Fit_" + (i + 1) + "," + allFits.get(i).fitDebounceNum + "\n");
                    myOutput.write("Fit_Rising_Threshold_Fit_" + (i + 1) + "," + (allFits.get(i).fitRisingThreshold ? "True" : "False") + "\n");
                    myOutput.write("Fit_First_Crossing_Fit_" + (i + 1) + "," + (allFits.get(i).fitFirstThreshold ? "True" : "False") + "\n");
                } else if(allFits.get(i).fitType==12) {//Nuc plot with input bleaching
                    myOutput.write("Fit_Bleach_Frame_Fit_" + (i + 1) + "," + allFits.get(i).bleachFrame + "\n");
                }

                if(allFits.get(i).fitType>=allFits.get(i).firstMeanFit){
                    myOutput.write("Fit_Min_Trace_Count_Fit_" + (i + 1) + "," + allFits.get(i).minTraceCount + "\n");
                }


                //Align Channel and range

                if(allFits.get(i).alignType==1) {//washing
                    myOutput.write("Align_Wash_In_Frame_Fit_" + (i + 1) + "," + allFits.get(i).washinFrame + "\n");
                }else if(allFits.get(i).alignType>1 && allFits.get(i).alignRangeType>0) {//Get channel and fit range
                    myOutput.write("Align_Channel_Fit_" + (i + 1) + "," + (allFits.get(i).alignChannel+1) + "\n");

                    myOutput.write("Align_Range_Min_Fit_" + (i + 1) + "," + allFits.get(i).alignMinRange + "\n");
                    myOutput.write("Align_Range_Max_Fit_" + (i + 1) + "," + allFits.get(i).alignMaxRange + "\n");

                }

                //Align normalization parameters
                if(allFits.get(i).alignNormType==1 && allFits.get(i).alignType>1){
                    myOutput.write("Align_Normalization_Const_Fit_" + (i + 1) + "," + allFits.get(i).alignNormConst + "\n");
                }
                else if(allFits.get(i).alignNormType>1 && allFits.get(i).alignNormType<8 && allFits.get(i).alignType>1){
                    myOutput.write("Align_Normalization_Channel_Fit_" + (i + 1) + "," + (allFits.get(i).alignNormChannel+1) + "\n");
                }

                //align fit
                if(allFits.get(i).alignType==2) {    //SingleStep
                    myOutput.write("Align_Threshold_Fit_" + (i + 1) + "," + allFits.get(i).alignThreshold + "\n");
                    myOutput.write("Align_Min_Loss_for_Single_Step_Fit_" + (i + 1) + "," + allFits.get(i).alignStepfitMinSingleStepFraction + "\n");
                    myOutput.write("Align_Max_Loss_for_No_Step_Fit_" + (i + 1) + "," + allFits.get(i).alignStepfitMaxNoStepFraction + "\n");
                } else if(allFits.get(i).alignType==5) {
                    myOutput.write("Align_Threshold_Fit_" + (i + 1) + "," + allFits.get(i).alignThreshold + "\n");
                    myOutput.write("Align_Debounce_Num_Fit_" + (i + 1) + "," + allFits.get(i).alignDebounceNum + "\n");
                    myOutput.write("Align_Rising_Threshold_Fit_" + (i + 1) + "," + (allFits.get(i).alignThresholdRising ? "True" : "False") + "\n");
                    myOutput.write("Align_First_Crossing_Fit_" + (i + 1) + "," + (allFits.get(i).alignFirstCrossing ? "True" : "False") + "\n");
                }

            }


        } catch (Exception e) {
            System.out.println("Could not write used parameters CSV: " + e);
            GenericDialog gd = new GenericDialog("Error - Could not write parameters");
            gd.addMessage("Error with Writing Parameters");
            gd.showDialog();
        }
    }

}
