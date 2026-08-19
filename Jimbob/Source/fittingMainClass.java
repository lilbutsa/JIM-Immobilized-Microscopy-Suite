package Jimbob;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.gui.GenericDialog;
import ij.gui.Plot;
import ij.gui.PlotWindow;
import ij.io.FileSaver;
import ij.plugin.MontageMaker;
import ij.process.ImageProcessor;

import java.awt.*;
import java.io.FileWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.stream.IntStream;

public class fittingMainClass {


    final static String[] fitTypeNames = {"---Fit All Traces---","Single Step Fit","Multi Step Fit","Bleach Correct NNLS","Piecewise Linear","Piecewise Exponential","Threshold","----Fit Mean Trace----","Linear","Quadratic","Exponential","Nuc Pol","Nuc Pol Input Bleach.","Nuc Pol Fit Bleach"};
    final static String[] normalizationTypeNames = {"None","Constant Intensity","Min","Max","Mean","First Frame","Last Frame","Each Frame","Normalize from 0 to 1"};
    final static String[] alignmentTypeNames = {"None","Wash In ","Single Step Fit","Piecewise Linear Joint","Piecewise Exponential Joint","Threshold"};
    final static String[] rangeNames = {"All","X Range Frames","X Range Time", "X Range Percent","Y Range Intensity","Y Range Percent"};


    //input with constructor

    String timePerFrameUnits = "",fileBase="";
    double timePerFrame=1;
    boolean saveTraces = false;

    //Fit Type
    int alignType,alignNormType,alignRangeType,fitNormType,fitRangeType, fitType;

    //fit Channel and Range
    int fitChannel;
    double fitMinRange,fitMaxRange;

    //Fit Normalization
    double fitNormConst = 1;
    int fitNormChannel = 0;


    //Fit Parameters

    boolean fitOverwrite = false;
    double fitThreshold = 3, fitStepfitMinSingleStepFraction = 0.75, fitStepfitMaxNoStepFraction = 0.5;//Stepfitting

    boolean fitBCBinding = true;//Bleach Correct
    double bleachFrame = 10,dissociationTime = 10;

    int fitDebounceNum = 3;//Thresholding
    boolean fitFirstThreshold = true,fitRisingThreshold = true;

    int minTraceCount = 10;//All mean trace fits

    //alignment Normalization Variables
    double alignNormConst = 1.0;
    int alignNormChannel = 0;

    //Alignment Variables

    int washinFrame = 0;
    int alignChannel = 0;
    double alignMinRange,alignMaxRange;//Range
    double  alignThreshold = 3, alignStepfitMinSingleStepFraction = 0.75, alignStepfitMaxNoStepFraction = 0.5;//Stepfitting
    boolean alignThresholdRising = true, alignFirstCrossing = true;
    int alignDebounceNum = 3;//for thresholds



    //Internal Variables
    String fitNameString = "",fitNameNoSpaces = "";
    String fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length";
    String resultString, csvNameString, csvFitString;
    final int firstMeanFit = 8;
    double alignStepfitStdDev = 0,fitStepfitStdDev = 0;
    double[] fitOverlay;
    int resultsColumns = 0;

    ArrayList<ArrayList<Double>> survivalCurveData = new ArrayList<>(), HistogramData= new ArrayList<>();
    ArrayList<String[]> survivalCurveNames= new ArrayList<>(), HistogramNames= new ArrayList<>();

    int pageNo = 1;

    fittingMainClass(){

    }

    fittingMainClass(fittingMainClass other){
        timePerFrameUnits = other.timePerFrameUnits;
        fileBase=other.fileBase;
        timePerFrame=other.timePerFrame;
        saveTraces=other.saveTraces;

        alignType = other.alignType;
        alignNormType = other.alignNormType;
        alignRangeType = other.alignRangeType;
        fitNormType = other.fitNormType;
        fitRangeType = other.fitRangeType;
        fitType = other.fitType;

        fitChannel = other.fitChannel;
        fitMinRange = other.fitMinRange;
        fitMaxRange = other.fitMaxRange;

        fitNormConst = other.fitNormConst;
        fitNormChannel = other.fitNormChannel;

        fitOverwrite = other.fitOverwrite;
        fitThreshold = other.fitThreshold;
        fitStepfitMinSingleStepFraction = other.fitStepfitMinSingleStepFraction;
        fitStepfitMaxNoStepFraction = other.fitStepfitMaxNoStepFraction;//Stepfitting

        fitBCBinding = other.fitBCBinding;//Bleach Correct
        bleachFrame = other.bleachFrame;
        dissociationTime = other.dissociationTime;

        fitDebounceNum = other.fitDebounceNum;//Thresholding
        fitFirstThreshold = other.fitFirstThreshold;
        fitRisingThreshold = other.fitRisingThreshold;

        minTraceCount = other.minTraceCount;//All mean trace fits

        alignNormConst = other.alignNormConst;
        alignNormChannel = other.alignNormChannel;

        washinFrame = other.washinFrame;
        alignChannel = other.alignChannel;
        alignMinRange = other.alignMinRange;
        alignMaxRange = other.alignMaxRange;//Range
        alignThreshold = other.alignThreshold;
        alignStepfitMinSingleStepFraction = other.alignStepfitMinSingleStepFraction;
        alignStepfitMaxNoStepFraction = other.alignStepfitMaxNoStepFraction;
        alignThresholdRising = other.alignThresholdRising;
        alignFirstCrossing = other.alignFirstCrossing;
        alignDebounceNum = other.alignDebounceNum;

        fitNameString = other.fitNameString;
        fitNameNoSpaces = other.fitNameNoSpaces;
        fitSummaryHeader = other.fitSummaryHeader;
        resultString = other.resultString;
        csvNameString = other.csvNameString;
        csvFitString = other.csvFitString;

        alignStepfitStdDev = other.alignStepfitStdDev;
        fitStepfitStdDev = other.fitStepfitStdDev;

        resultsColumns = other.resultsColumns;

        survivalCurveNames = new ArrayList<>(other.survivalCurveNames);
        HistogramNames = new ArrayList<>(other.HistogramNames);
        survivalCurveData = new ArrayList<>(other.survivalCurveData);
        HistogramData = new ArrayList<>(other.HistogramData);

        pageNo = other.pageNo;
    }

    int inputParametersFromGUI( ){

        GenericDialog gd1 = new GenericDialog("Input Fit", IJ.getInstance());

        gd1.addChoice(" Choose Fit:", fitTypeNames, fitTypeNames[fitType]);
        gd1.addToSameRow();
        gd1.addChoice(" In Range:", rangeNames, rangeNames[fitRangeType]);
        gd1.addToSameRow();
        gd1.addChoice(" Normalized By:", normalizationTypeNames, normalizationTypeNames[fitNormType]);

        gd1.addChoice(" Fit Aligned To:", alignmentTypeNames, alignmentTypeNames[alignType]);
        gd1.addToSameRow();
        gd1.addChoice(" In Range:", rangeNames, rangeNames[alignRangeType]);
        gd1.addToSameRow();
        gd1.addChoice(" Normalized By:", normalizationTypeNames, normalizationTypeNames[alignNormType]);


        gd1.showDialog();
        if (gd1.wasCanceled())return 1;


        fitType = gd1.getNextChoiceIndex();
        fitRangeType = gd1.getNextChoiceIndex();
        fitNormType = gd1.getNextChoiceIndex();
        alignType = gd1.getNextChoiceIndex();
        alignRangeType = gd1.getNextChoiceIndex();
        alignNormType = gd1.getNextChoiceIndex();

        if(fitType==0 ||fitType == firstMeanFit-1)return 2;


        GenericDialog gd = new GenericDialog("Input Parameters", IJ.getInstance());

        //Fit Info

        gd.addNumericField("Fit Channel = ", fitChannel+1);
        if(fitRangeType>0) {//Get channel and fit range

            String units = "";
            if(fitRangeType==1)units = " Frames ";
            else if(fitRangeType==2)units = " Time (" + timePerFrameUnits + ") ";
            else if(fitRangeType==3 || fitRangeType==5)units = " Percent ";
            else if(fitRangeType==4) units = " Intensity ";

            gd.addNumericField("Fit "+(fitRangeType<=3?"X":"Y")+" Range Min"+units+"= ", fitMinRange);
            gd.addNumericField("Fit "+(fitRangeType<=3?"X":"Y")+" Range Max"+units+"= ", fitMaxRange);
        }

        //fit parameters
        if(fitType==1) {    //SingleStep
            gd.addNumericField("Fit Stepfit Threshold = ", fitThreshold);
            gd.addNumericField("Fit Min % Loss for Single Step = ", fitStepfitMinSingleStepFraction);
            gd.addNumericField("Fit Max % Loss for No Step = ", fitStepfitMaxNoStepFraction);
            gd.addCheckbox("Overwrite trace data with fit",fitOverwrite);
        }else if(fitType==2) {    //multi step  fit
                gd.addNumericField("Fit Stepfit Threshold = ", fitThreshold);
                gd.addCheckbox("Overwrite trace data with fit",fitOverwrite);
        }else if(fitType==3) {    //Bleach Correct
            gd.addCheckbox("Binding Data",fitBCBinding);
            gd.addNumericField("Mean bleach Frame = ", bleachFrame);
            gd.addNumericField("Mean Dissociation Time ("+timePerFrameUnits+") = ", dissociationTime);
            gd.addCheckbox("Overwrite trace data with fit",fitOverwrite);
        } else if(fitType==6) {
            gd.addNumericField("Fit Threshold = ", fitThreshold);
            gd.addNumericField("Fit Threshold Debounce Frames = ", fitDebounceNum);
            gd.addCheckbox("Fit Rising Threshold",fitRisingThreshold);
            gd.addCheckbox("Fit First Crossing",fitFirstThreshold);
        } else if(fitType==12) {//Nuc plot with input bleaching
            gd.addNumericField("Mean bleach Frame = ", bleachFrame);
        }

        if(fitType>=firstMeanFit){
            gd.addNumericField("Min Trace number for Fit",minTraceCount);
        }

        //Fit Normalization!
        if(fitNormType==1){gd.addNumericField("Fit Normalization Constant = ", fitNormConst);
        }
        else if(fitNormType>1 && fitNormType<8 ){gd.addNumericField("Fit Normalization Channel = ", fitNormChannel+1);
        }

        gd.addMessage("Alignment Parameters");

        //Align Channel and range

        if(alignType==1) {//washing
            gd.addNumericField("Wash In Frame = ", washinFrame);
        }else if(alignType>1 && alignRangeType>0) {//Get channel and fit range
            gd.addNumericField("Alignment Channel = ", alignChannel+1);
            String units = "";
            if(alignRangeType==1)units = " Frames ";
            else if(alignRangeType==2)units = " Time (" + timePerFrameUnits + ") ";
            else if(alignRangeType==3 || alignRangeType==5)units = " Percent ";
            else if(alignRangeType==4) units = " Intensity ";

            gd.addNumericField("Alignment "+(alignRangeType<=3?"X":"Y")+" Range Min"+units+"= ", alignMinRange);
            gd.addNumericField("Alignment "+(alignRangeType<=3?"X":"Y")+" Range Max"+units+"= ", alignMaxRange);
        }

        //Align normalization parameters
        if(alignNormType==1 && alignType>1){gd.addNumericField("Alignment Normalization Constant = ", alignNormConst);
        }
        else if(alignNormType>1 && alignNormType<8 && alignType>1){gd.addNumericField("Alignment Normalization Channel = ", alignNormChannel+1);
        }

        //align fit
        if(alignType==2) {    //SingleStep
            gd.addNumericField("Alignment Stepfit Threshold = ", alignThreshold);
            gd.addNumericField("Align. Min % Loss for Single Step = ", alignStepfitMinSingleStepFraction);
            gd.addNumericField("Align. Max % Loss for No Step = ", alignStepfitMaxNoStepFraction);
        } else if(alignType==5) {
            gd.addNumericField("Alignment Threshold = ", alignThreshold);
            gd.addNumericField("Alignment Threshold Debounce Frames = ", alignDebounceNum);
            gd.addCheckbox("Align to Rising Threshold",alignThresholdRising);
            gd.addCheckbox("Align to First Crossing",alignFirstCrossing);
        }


        gd.showDialog();
        if (gd.wasCanceled()) return 3;

        //Read in parameters

        fitChannel = (int)gd.getNextNumber()-1;
        if(fitRangeType>0) {//Get channel and fit range
            fitMinRange = gd.getNextNumber();
            fitMaxRange = gd.getNextNumber();
        }

        //fit parameters
        if(fitType==1) {    //SingleStep
            fitThreshold = gd.getNextNumber();
            fitStepfitMinSingleStepFraction = gd.getNextNumber();
            fitStepfitMaxNoStepFraction = gd.getNextNumber();
            fitOverwrite = gd.getNextBoolean();
        }else if(fitType==2) {    //multi step  fit
            fitThreshold = gd.getNextNumber();
            fitOverwrite = gd.getNextBoolean();
        }else if(fitType==3) {    //Bleach Correct
            fitBCBinding = gd.getNextBoolean();
            bleachFrame = gd.getNextNumber();
            dissociationTime = gd.getNextNumber();
            fitOverwrite = gd.getNextBoolean();
        } else if(fitType==6) {
            fitThreshold = gd.getNextNumber();
            fitDebounceNum = (int)gd.getNextNumber();
            fitRisingThreshold = gd.getNextBoolean();
            fitFirstThreshold = gd.getNextBoolean();
        } else if(fitType==12) {//Nuc plot with input bleaching
            bleachFrame = gd.getNextNumber();
        }

        if(fitType>=firstMeanFit){
            minTraceCount = (int)gd.getNextNumber();
        }

        if(fitNormType==1){
            fitNormConst = gd.getNextNumber();
        }
        else if(fitNormType>1 && fitNormType<8){
            fitNormChannel = (int)gd.getNextNumber()-1;
        }

        //Align Channel and range
        if(alignType == 0){
            washinFrame = 1;
            alignChannel = 0;
        } else if(alignType==1) {//washing
            washinFrame = (int)gd.getNextNumber();
            alignChannel = 0;
        }else if(alignType>1 && alignRangeType>0) {//Get channel and fit range
            alignChannel = (int)gd.getNextNumber()-1;

            alignMinRange = gd.getNextNumber();
            alignMaxRange = gd.getNextNumber();
        } else {
            // Alignment enabled, but the range is "All".
            alignChannel = 0;
        }

        //Align normalization parameters
        if(alignNormType==1 && alignType>1)alignNormConst = gd.getNextNumber();
        else if(alignNormType>1 && alignNormType<8 && alignType>1) alignNormChannel = (int) gd.getNextNumber()-1;

        //align fit
        if(alignType==2) {    //SingleStep
            alignThreshold  = gd.getNextNumber();
            alignStepfitMinSingleStepFraction  = gd.getNextNumber();
            alignStepfitMaxNoStepFraction  = gd.getNextNumber();
        } else if(alignType==5) {
            alignThreshold  = gd.getNextNumber();
            alignDebounceNum  = (int)gd.getNextNumber();
            alignThresholdRising = gd.getNextBoolean();
            alignFirstCrossing = gd.getNextBoolean();
        }

        fitNameString = "Channel "+(fitChannel+1)+" "+fitTypeNames[fitType]+ " Aligned to "+
                (alignType>1?(" Channel "+(alignChannel+1)+" "+alignmentTypeNames[alignType]):" Frame "+washinFrame);
        fitNameNoSpaces = "Channel_"+(fitChannel+1)+"_"+fitTypeNames[fitType]+ "_Aligned_to_"+
                (alignType>1?("Channel_"+(alignChannel+1)+"_"+alignmentTypeNames[alignType]):"Frame_"+washinFrame);



        return 0;

    }

    void fitMain(double[][] allTraces,double[][] allNormTraces,double[][] allAlignTraces,double[][] allAlignNormTraces, boolean outputDisplay){

        if(alignType==2)alignStepfitStdDev = myStepFitting.approxStdDev(allAlignTraces);
        if(fitType==1 || fitType==2 && fitStepfitStdDev<=0.000001)fitStepfitStdDev = myStepFitting.approxStdDev(allTraces);

        try {
            if (saveTraces) Files.createDirectories(Paths.get(fileBase));
        } catch (Exception e) {
                System.out.println(e);
                IJ.error(e.toString());
                return;
        }

        double[] xvals = new double[allTraces[0].length];


        double[] meanYVals  = new double[2*allTraces[0].length+1];
        int[] meanCounts  = new int[2*allTraces[0].length+1];
        int alignmentAnchor = allTraces[0].length - 1;
        double[] meanXVals  = new double[2*allTraces[0].length+1];
        for(int i=0;i<2*allTraces[0].length+1;i++)meanXVals[i] = (i-alignmentAnchor)*timePerFrame;

        ImageStack exampleTracePageStack = null;

        updateResultsSummaryInfo();
        double[][] fitSummary = new double[allTraces.length][3+resultsColumns];
        for (double[] row : fitSummary) {
            Arrays.fill(row, Double.NaN);
        }

        for(int i=0;i<xvals.length;i++)xvals[i] = i*timePerFrame;

        myPlot plot = new myPlot("Particle ", "Time (" + timePerFrameUnits + ")", "Intensity");


        for(int traceNum = 0;traceNum<allTraces.length;traceNum++){


            if(fitType<firstMeanFit && fitType>1 && (exampleTracePageStack == null || exampleTracePageStack.getSize() < 36) && traceNum>=36*(pageNo-1))plot = new myPlot("Particle " + String.valueOf(traceNum + 1), "Time (" + timePerFrameUnits + ")", "Intensity");

            double[] alignedNormedYVal = getNormalizedIntensity(alignNormType,allAlignTraces[traceNum],alignNormType==1?(new double[]{alignNormConst}):allAlignNormTraces[traceNum]);
            int[] alignFitRange = getRange(xvals, alignedNormedYVal,alignRangeType, 0,alignMinRange, alignMaxRange);
            if(alignFitRange[0]==-1  || alignFitRange[1]==-1) continue;

            int alignPos = findAlignments(Arrays.copyOfRange(alignedNormedYVal, alignFitRange[0], alignFitRange[0]+alignFitRange[1]));
            if(alignPos==-1) continue;
            alignPos = alignPos+alignFitRange[0];
            fitSummary[traceNum][0] = alignPos;

            double[] fitNormedYVal = getNormalizedIntensity(fitNormType,allTraces[traceNum],fitNormType==1?(new double[]{fitNormConst}):allNormTraces[traceNum]);

            int[] fitRange = getRange(xvals, fitNormedYVal,fitRangeType, alignPos,fitMinRange, fitMaxRange);
            fitSummary[traceNum][1] = fitRange[0];
            fitSummary[traceNum][2] = fitRange[1];

            if(fitRange[0]==-1  || fitRange[1]==-1) continue;

            if(fitType==1) {//"Single Step Fit"
                double[] result = singleStepFit(Arrays.copyOfRange(fitNormedYVal, fitRange[0],fitRange[0]+fitRange[1] ),fitStepfitStdDev, fitThreshold,fitStepfitMinSingleStepFraction,fitStepfitMaxNoStepFraction);
                for(int i=0;i<result.length;i++) fitSummary[traceNum][i+3] = result[i];
                if(exampleTracePageStack==null || exampleTracePageStack.getSize()<36 && traceNum>=36*(pageNo-1)) {
                    plot = new myPlot("Particle " + String.valueOf(traceNum + 1)+(result[0]==0?" Single Step":(result[0]==1?" No Step":" Other")) , "Time (" + timePerFrameUnits + ")", "Intensity");
                    plot.addLine(xvals, fitNormedYVal);
                    plot.overlay(Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]),fitOverlay.clone());
                    plot.setPlotLimitsWithYBuffer(true);
                    ImagePlus plotIm2 = plot.plot.makeHighResolution("Particle " + String.valueOf(traceNum + 1), 1.0f, true, false);
                    if(exampleTracePageStack==null)exampleTracePageStack = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
                    exampleTracePageStack.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                }


                if(result[0]==0) {
                    survivalCurveData.get(0).add(timePerFrame*result[1]);//Add to step rate survival curve
                    HistogramData.get(0).add(result[2]);//Add to step Height survival curve
                }

            } else if(fitType==2){//"Multi Step Fit"
                multiStepFit(Arrays.copyOfRange(fitNormedYVal, fitRange[0],fitRange[0]+fitRange[1] ),HistogramData.get(0),HistogramData.get(1),
                        survivalCurveData.get(0), survivalCurveData.get(1), survivalCurveData.get(2)
                        ,fitStepfitStdDev, fitThreshold);
                if((exampleTracePageStack==null || exampleTracePageStack.getSize()<36) && traceNum>=36*(pageNo-1)) {
                    plot.addLine(xvals, fitNormedYVal);
                    plot.overlay(Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]),fitOverlay.clone());
                    plot.setPlotLimitsWithYBuffer(true);
                    ImagePlus plotIm2 = plot.plot.makeHighResolution("Particle " + String.valueOf(traceNum + 1), 1.0f, true, false);
                    if(exampleTracePageStack==null)exampleTracePageStack = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
                    exampleTracePageStack.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                }

            } else if(fitType==3){//"Bleach Correct NNLS"
                double[] traceRange = Arrays.copyOfRange(fitNormedYVal, fitRange[0], fitRange[0] + fitRange[1]);

                myBleachCorrect bleachCorrect = new myBleachCorrect(traceRange.length, bleachFrame, fitBCBinding);
                bleachCorrect.Bleach_Correct(traceRange);

                for (double intervalFrames : bleachCorrect.stepFrames) survivalCurveData.get(0).add(intervalFrames * timePerFrame);
                for (double stepHeight : bleachCorrect.stepHeights) HistogramData.get(0).add(stepHeight);

                if((exampleTracePageStack==null || exampleTracePageStack.getSize()<36)  && traceNum>=36*(pageNo-1)) {
                    plot.addLine(xvals, fitNormedYVal);
                    plot.overlay(Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]), bleachCorrect.bleachCorrected);
                    plot.overlay(Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]), bleachCorrect.bleachFit);
                    plot.setPlotLimitsWithYBuffer(true);
                    ImagePlus plotIm2 = plot.plot.makeHighResolution("Particle " + String.valueOf(traceNum + 1), 1.0f, true, false);
                    if(exampleTracePageStack==null)exampleTracePageStack = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
                    exampleTracePageStack.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                }

            } else if(fitType==4){//"Piecewise Linear"
                double[] fitX = Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]);
                double[] fitY = Arrays.copyOfRange(fitNormedYVal, fitRange[0], fitRange[0] + fitRange[1]);
                double[] result = myLeastSquare.fitPiecewiseConstantLinear(fitX, fitY);

                for (int i = 0; i < result.length; i++) fitSummary[traceNum][i + 3] = result[i];

                HistogramData.get(0).add(result[0]);
                HistogramData.get(1).add(result[1]);
                survivalCurveData.get(0).add(result[2]);

                if ((exampleTracePageStack == null || exampleTracePageStack.getSize() < 36) && traceNum>=36*(pageNo-1)) {

                    // y = a before c; y = a + b(x-c) from c onward
                    double[] overlay = new double[fitX.length];
                    for (int i = 0; i < fitX.length; i++) {
                        double xAfterTransition = Math.max(0.0, fitX[i] - result[2]);
                        overlay[i] = result[0] + result[1] * xAfterTransition;
                    }
                    plot.addLine(xvals, fitNormedYVal);
                    plot.overlay(fitX, overlay);
                    plot.setPlotLimitsWithYBuffer(true);
                    ImagePlus plotImage = plot.plot.makeHighResolution("Particle " + (traceNum + 1), 1.0f, true, false);
                    if (exampleTracePageStack == null) exampleTracePageStack = new ImageStack(plotImage.getWidth(), plotImage.getHeight());
                    exampleTracePageStack.addSlice((ImageProcessor) plotImage.getProcessor().clone());
                }



            } else if(fitType==5){//"Piecewise Exponential"

                double[] fitX = Arrays.copyOfRange(xvals, fitRange[0], fitRange[0] + fitRange[1]);
                double[] fitY = Arrays.copyOfRange(fitNormedYVal, fitRange[0], fitRange[0] + fitRange[1]);
                double[] result = myLeastSquare.fitPiecewiseConstantExp(fitX, fitY);

                for (int i = 0; i < result.length; i++) fitSummary[traceNum][i + 3] = result[i];

                HistogramData.get(0).add(result[0]);
                HistogramData.get(1).add(result[1]);
                HistogramData.get(2).add(result[3]);
                survivalCurveData.get(0).add(result[2]);

                if ((exampleTracePageStack == null || exampleTracePageStack.getSize() < 36)  && traceNum>=36*(pageNo-1)){
                    double[] overlay = new double[fitX.length];// y = a before c; y = a + b(1 - exp(-d(x-c))) from c onward
                    for (int i = 0; i < fitX.length; i++) {
                        double xAfterTransition = Math.max(0.0, fitX[i] - result[2]);
                        overlay[i] = result[0] + result[1] * (1.0 - Math.exp(-result[3] * xAfterTransition));
                    }

                    plot.addLine(xvals, fitNormedYVal);
                    plot.overlay(fitX, overlay);
                    plot.setPlotLimitsWithYBuffer(true);
                    ImagePlus plotImage = plot.plot.makeHighResolution("Particle " + (traceNum + 1), 1.0f, true, false);
                    if (exampleTracePageStack == null) exampleTracePageStack = new ImageStack(plotImage.getWidth(), plotImage.getHeight());
                    exampleTracePageStack.addSlice((ImageProcessor) plotImage.getProcessor().clone());
                }

            } else if(fitType==6){//"Threshold"
                double[] thresholdData = Arrays.copyOfRange(fitNormedYVal, fitRange[0], fitRange[0] + fitRange[1]);

                int thresholdPos = fitFirstThreshold ?
                        myThreshold.singleFirstThreshold(thresholdData, fitRisingThreshold, fitThreshold, fitDebounceNum, false)
                        : myThreshold.singleLastThreshold(thresholdData, fitRisingThreshold, fitThreshold, fitDebounceNum, false);

                if (thresholdPos >= 0) {
                    int absoluteThresholdPos = fitRange[0] + thresholdPos;
                    fitSummary[traceNum][3] = absoluteThresholdPos;
                    survivalCurveData.get(0).add(timePerFrame*( thresholdPos));

                    if ((exampleTracePageStack == null || exampleTracePageStack.getSize() < 36) && traceNum>=36*(pageNo-1)) {
                        plot.addLine(xvals, fitNormedYVal);

                        double thresholdTime = xvals[absoluteThresholdPos];
                        double minY = Arrays.stream(fitNormedYVal).min().orElse(0.0);
                        double maxY = Arrays.stream(fitNormedYVal).max().orElse(1.0);

                        // Vertical line at the detected threshold frame
                        plot.overlay(new double[]{thresholdTime, thresholdTime}, new double[]{minY, maxY});
                        plot.setPlotLimitsWithYBuffer(true);
                        ImagePlus plotImage = plot.plot.makeHighResolution("Particle " + (traceNum + 1), 1.0f, true, false);
                        if (exampleTracePageStack == null) exampleTracePageStack = new ImageStack(plotImage.getWidth(), plotImage.getHeight());
                        exampleTracePageStack.addSlice((ImageProcessor) plotImage.getProcessor().clone());
                    }

                }
            } else if(fitType>=firstMeanFit)
                for(int i=0;i<fitRange[1];i++){
                    meanCounts[alignmentAnchor-alignPos+fitRange[0]+i]++;
                    meanYVals[alignmentAnchor-alignPos+fitRange[0]+i] = meanYVals[alignmentAnchor-alignPos+fitRange[0]+i]+fitNormedYVal[fitRange[0] + i];
            };
        }

        if(fitType<firstMeanFit) {
            //Plot analysis curves
            for(int i=0;i<HistogramData.size();i++){
                double[] toplot = HistogramData.get(i).stream().mapToDouble(Double::doubleValue).toArray();
                intensityDistribution(toplot,0.05,0.95,HistogramNames.get(i)[0],HistogramNames.get(i)[1],HistogramNames.get(i)[2],outputDisplay);
            }
            for(int i=0;i<survivalCurveData.size();i++){
                double[] toplot = survivalCurveData.get(i).stream().mapToDouble(Double::doubleValue).toArray();
                survivalCurve(toplot,timePerFrame,0.0
                        ,survivalCurveNames.get(i)[0],survivalCurveNames.get(i)[1],survivalCurveNames.get(i)[2],survivalCurveNames.get(i)[3],outputDisplay);
            }

            if(exampleTracePageStack!=null && exampleTracePageStack.size()>0){
                ImagePlus outputImStack = new ImagePlus("Trace Fit Overlays", exampleTracePageStack);
                MontageMaker myMaker = new MontageMaker();
                ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, exampleTracePageStack.size(), 1, 0, false);
                //if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                if(saveTraces) new FileSaver(outputMontage).saveAsPng(fileBase+"Example_Trace_Page_"+pageNo+".png");
                if(outputDisplay)outputMontage.show();
            }

        }else{
            //find range
            int start = 0,end;
            for(start = 0;start< meanCounts.length && meanCounts[start]<minTraceCount;start++);
            for(end = meanCounts.length-1;end>=0 && meanCounts[end]<minTraceCount;end--);
            end++;

            if(end-start<3) {
                GenericDialog gd = new GenericDialog("Error - Insufficient Traces remaining after alignment");
                gd.addMessage("No frame has more than the minimum number of traces ("+minTraceCount+") after alignment");
                gd.showDialog();
                return;
            }
            for(int i=start;i<end;i++)meanYVals[i] = meanCounts[i]>0?meanYVals[i]/meanCounts[i]:0;

            meanFit(Arrays.copyOfRange(meanXVals, start, end),Arrays.copyOfRange(meanYVals, start, end),Arrays.copyOfRange(meanCounts, start, end),timePerFrame,outputDisplay,saveTraces);
        }

        if(saveTraces)ShapeFunctions.writeCSV(fileBase+"Fit_Summary.csv",fitSummary,fitSummaryHeader,false);

    }

    void updateResultsSummaryInfo(){


        resultsColumns = 0;
        fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length";

        HistogramData.clear();
        HistogramNames.clear();
        survivalCurveData.clear();
        survivalCurveNames.clear();


        if(fitType==1){//Single Step
            resultsColumns = 7;
            fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length,Trace Class, Step Frame,Step Height, Max Intensity,Min Intensity, Intensity Before, Intensity After";
            HistogramData.add(new ArrayList<>());
            HistogramNames.add(new String[]{"Single Step Height","Intensity",fileBase+"StepHeight_Distribution"});

            survivalCurveData.add(new ArrayList<>());
            survivalCurveNames.add(new String[]{"Single Step Times","Time ("+timePerFrameUnits+")","Remaining Particles",fileBase+"StepTime_Distribution"});

        }else if (fitType==2){
            resultsColumns = 0;
            HistogramData.add(new ArrayList<>()); // Positive step heights
            HistogramData.add(new ArrayList<>()); // Negative step heights

            HistogramNames.add(new String[]{"Positive Step Heights", "Intensity", fileBase + "Positive_Step_Height_Distribution"});
            HistogramNames.add(new String[]{"Negative Step Heights", "Intensity", fileBase + "Negative_Step_Height_Distribution"});

            survivalCurveData.add(new ArrayList<>()); // All intervals
            survivalCurveData.add(new ArrayList<>()); // Positive-step intervals
            survivalCurveData.add(new ArrayList<>()); // Negative-step intervals

            survivalCurveNames.add(new String[]{"All Step Intervals", "Time (" + timePerFrameUnits + ")", "Remaining Intervals", fileBase + "All_Step_Interval_Distribution"});
            survivalCurveNames.add(new String[]{"Positive Step Intervals", "Time (" + timePerFrameUnits + ")", "Remaining Intervals", fileBase + "Positive_Step_Interval_Distribution"});
            survivalCurveNames.add(new String[]{"Negative Step Intervals", "Time (" + timePerFrameUnits + ")", "Remaining Intervals", fileBase + "Negative_Step_Interval_Distribution"});

        }else if (fitType==3){//NNLS
            resultsColumns = 0;
            HistogramData.add(new ArrayList<>()); // tep heights
            HistogramNames.add(new String[]{"Step Heights", "Intensity", fileBase + "Positive_Step_Height_Distribution"});

            survivalCurveData.add(new ArrayList<>()); // All intervals
            survivalCurveNames.add(new String[]{"All Step Intervals", "Time (" + timePerFrameUnits + ")", "Remaining Intervals", fileBase + "All_Step_Interval_Distribution"});
        }else if (fitType==4){// Piecewise Constant/Linear
            resultsColumns = 3;
            fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length, Initial Constant Intensity, Second Section Gradient, Transition Time";
            HistogramData.add(new ArrayList<>()); // Initial intensity
            HistogramData.add(new ArrayList<>()); // Gradient

            HistogramNames.add(new String[]{"Initial Constant Intensities", "Intensity", fileBase + "Piecewise_Linear_Initial_Intensity_Distribution"});
            HistogramNames.add(new String[]{"Second Section Gradients", "Intensity / " + timePerFrameUnits, fileBase + "Piecewise_Linear_Gradient_Distribution"});

            survivalCurveData.add(new ArrayList<>()); // Transition time
            survivalCurveNames.add(new String[]{"Piecewise Linear Transition Times", "Time (" + timePerFrameUnits + ")", "Remaining Particles", fileBase + "Piecewise_Linear_Transition_Time_Distribution"});

        }else if (fitType==5){// Piecewise Constant/Exponential
            resultsColumns = 4;
            fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length, Initial Constant Intensity, Exponential Intensity, Transition Time, Exponential Exponent";

            HistogramData.add(new ArrayList<>()); // Initial intensity
            HistogramData.add(new ArrayList<>()); // Exponential amplitude
            HistogramData.add(new ArrayList<>()); // Exponent

            HistogramNames.add(new String[]{"Initial Constant Intensities", "Intensity", fileBase + "Piecewise_Exponential_Initial_Intensity_Distribution"});
            HistogramNames.add(new String[]{"Exponential Intensities", "Intensity", fileBase + "Piecewise_Exponential_Intensity_Distribution"});
            HistogramNames.add(new String[]{"Exponential Exponents", "1 / " + timePerFrameUnits, fileBase + "Piecewise_Exponential_Exponent_Distribution"});

            survivalCurveData.add(new ArrayList<>()); // Transition time
            survivalCurveNames.add(new String[]{"Piecewise Exponential Transition Times", "Time (" + timePerFrameUnits + ")", "Remaining Particles", fileBase + "Piecewise_Exponential_Transition_Time_Distribution"
            });
        }else if (fitType==6){
            resultsColumns = 1;
            fitSummaryHeader = "Align Frame, Fit Range Start Frame, Fit Range Length, Threshold Position";

            survivalCurveData.add(new ArrayList<>());
            survivalCurveNames.add(new String[]{"Threshold Crossing Times", "Time (" + timePerFrameUnits + ")", "Remaining Particles", fileBase + "Threshold_Crossing_Time_Distribution"});
        }


    }

    void meanFit(double[] xIn,double[] yIn,int[] meanCounts,double timePerFrame,boolean outputDisplay,boolean saveTraces){
        myLeastSquare myLS = new myLeastSquare();
        double[] result;
        double[] yFit = new double[yIn.length];
        if(fitType==firstMeanFit){
            result = myLS.fitLinear(xIn,yIn);
            for( int i=0;i<xIn.length;i++)yFit[i] = result[0]+result[1]*xIn[i];
            resultString = "Linear Fit = "+ IJ.d2s(result[0],2)+(result[1]>0?"+":"")+IJ.d2s(result[1],2)+"x";
            csvNameString = "Linear_Fit";
            csvFitString = "Fit Equation : y=a+bt, a =,"+result[0]+",b =,"+result[1]+"\n";
        }
        else if(fitType==firstMeanFit+1){
            result = myLS.fitQuadratic(xIn,yIn);
            for( int i=0;i<xIn.length;i++)yFit[i] = result[0]+result[1]*xIn[i]+result[2]*xIn[i]*xIn[i];
            resultString = "Quadratic Fit="+IJ.d2s(result[0],2)+(result[1]>0?"+":"")+IJ.d2s(result[1],2)+"x+"+IJ.d2s(result[2],3)+"x^2";
            csvNameString = "Quadratic_Fit";
            csvFitString = "Fit Equation : y=a+b*t+c*t^2, a =,"+result[0]+",b =,"+result[1]+",c =,"+result[2]+"\n";
        }
        else if(fitType==firstMeanFit+2){
            result = myLS.fitExp(xIn,yIn);
            for( int i=0;i<xIn.length;i++)yFit[i] = result[0]+result[1]*Math.exp(-result[2]*xIn[i]);
            resultString = "Exp Fit="+IJ.d2s(result[0],2)+(result[1]>0?"+":"")+IJ.d2s(result[1],2)+"exp(-"+IJ.d2s(result[2],3)+"x)";
            csvNameString = "Exp_Fit";
            csvFitString = "Fit Equation : y=a+b*exp(-c*t), a =,"+result[0]+",b =,"+result[1]+",c =,"+result[2]+"\n";
        }
        else if(fitType==firstMeanFit+3){
            result = myLS.fitNucPolNoBleach(xIn,yIn);
            for( int i=0;i<xIn.length;i++)yFit[i] = result[0]*xIn[i]-result[0]/result[1]*(1-Math.exp(-result[1] * xIn[i]));
            resultString = "Polymerisation Rate="+ IJ.d2s(result[0],3)+"Int per "+timePerFrameUnits
                    +" Nucleation Frame="+IJ.d2s(1/result[1],3)+" "+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +" Frames";
            csvNameString = "Nuc_Pol_no_bleaching";
            csvFitString = "Fit Equation : y=p/n*(exp(-nt)+nt-1), p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+"\n";
        }
        else if(fitType==firstMeanFit+4){
            result = myLS.fitNucPolGivenBleach(xIn,yIn,1.0/(bleachFrame*timePerFrame));
            double p = result[0];
            double n = result[1];
            double b = 1.0/(bleachFrame*timePerFrame);
            for( int i=0;i<xIn.length;i++)yFit[i] =  p * (1-Math.exp(-n * xIn[i])+n/b*(Math.exp(-b * xIn[i])-1))/(b-n);
            resultString = "Polymerisation_Rate="+ IJ.d2s(result[0],3)+"_Int_per_"+timePerFrameUnits
                    +"_Nucleation_Frame="+IJ.d2s(1/result[1],3)+"_"+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +"_Frames";
            csvNameString = "Nuc_Pol_given_bleaching";
            csvFitString = "Fit Equation : y=p * (1-exp(-nt)+n/b*(exp(-bt)-1))/(b-n);, p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+",b (Bleach Rate(1/"+timePerFrameUnits+")) =,"+b+"\n";

        }
        else if(fitType==firstMeanFit+5){
            result = myLS.fitNucPolFitBleach(xIn,yIn);
            double p = result[0];
            double n = result[1];
            double b = result[2];
            for( int i=0;i<xIn.length;i++)yFit[i] =  p * (1-Math.exp(-n * xIn[i])+n/b*(Math.exp(-b * xIn[i])-1))/(b-n);
            resultString = "Polymerisation_Rate="+ IJ.d2s(result[0],3)+"_Int_per_"+timePerFrameUnits
                    +"_Nucleation_Frame="+IJ.d2s(1/result[1],3)+"_"+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +"_Frames__Fit_Bleach_Frame="+ IJ.d2s(1.0/(result[2]*timePerFrame),3);
            csvNameString = "Nuc_Pol_fit_bleaching";
            csvFitString = "Fit Equation : y=p * (1-exp(-nt)+n/b*(exp(-bt)-1))/(b-n);, p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+",b (Bleach Rate(1/"+timePerFrameUnits+")) =,"+b+"\n";
        }


        myPlot plot = new myPlot(resultString, "Time ("+timePerFrameUnits+")", "Intensity");
        plot.addLine(xIn,yIn);
        plot.overlay(xIn,yFit);
        plot.saveAndDisplay(saveTraces, fileBase + "_" + csvNameString+".png",true, outputDisplay);



        if(saveTraces) {

            //write out csv
            try {
                FileWriter myOutput = new FileWriter(fileBase  + "_" + csvNameString + ".csv");
                myOutput.write(csvFitString);
                myOutput.write("All Mean Data Time("+timePerFrameUnits+"),Mean Intensity,Fit Intensity\n");

                String myLine;
                for (int i = 0; i < xIn.length; i++) {
                    myLine = xIn[i]+","+meanCounts[i]+","+yIn[i]+","+yFit[i]+"\n";
                    myOutput.write(myLine);
                }
                myOutput.close();

            } catch (Exception e) {
                System.out.println(e);
                IJ.error(e.toString());
            }
        }

    }

    int[] getRange(double[] xvals, double[] yvals,int rangeType, int alignFrame,double minRange, double maxRange){
        int start = -1;
        int length = -1;

        if(rangeType == 0)return new int[]{0,yvals.length};

        double minFraction = minRange / 100.0;
        double maxFraction = maxRange / 100.0;

        //All values
        if(maxRange<minRange || yvals==null||yvals.length==0 || alignFrame<0 || alignFrame>= yvals.length || alignDebounceNum<=0 )return new int[]{start,length};

        if (rangeType == 1 ||rangeType == 2||rangeType == 3) {//Fixed x range
            if(rangeType == 2) {
                minRange = minRange/timePerFrame;
                maxRange = maxRange/timePerFrame;
            }else if(rangeType == 3){//Fixed x range percent
                if(minRange>100 || maxRange<0)return new int[]{start,length};

                // X percentage:
                minRange = minFraction * (yvals.length - 1);
                maxRange = maxFraction * (yvals.length - 1);

            }
            if(maxRange<0 || minRange>yvals.length-1)return new int[]{start,length};
            start = Math.max(alignFrame+(int)Math.round(minRange),0);
            int end = Math.min(alignFrame+(int)Math.round(maxRange),yvals.length);
            if(start<end)length = end-start;
            else start = -1;
        }else if (rangeType == 4 ||rangeType == 5) {//Y Range or percent
            if(rangeType == 5){//Fixed y range percent
                double min = Arrays.stream(yvals).min().getAsDouble();
                double max = Arrays.stream(yvals).max().getAsDouble();
                minRange = min + minFraction * (max - min);
                maxRange = min + maxFraction * (max - min);
            }
            start = 0;
            for(int i=alignFrame;i>=alignDebounceNum-1;i--) {
                boolean allFalse = true;
                for(int j=0;j<alignDebounceNum;j++)if (yvals[i-j]<maxRange && yvals[i-j]>minRange){
                    allFalse = false;
                    break;
                }
                if(allFalse){
                    start = i+1;
                    break;
                }
            }

            int end = yvals.length;
            for(int i=alignFrame;i<yvals.length-alignDebounceNum+1;i++) {
                boolean allFalse = true;
                for(int j=0;j<alignDebounceNum;j++)if (yvals[i+j]<maxRange && yvals[i+j]>minRange){
                    allFalse = false;
                    break;
                }
                if(allFalse){
                    end = i;
                    break;
                }
            }
            return new int[]{start,end-start};

        }
        return new int[]{start,length};
    }

    double[] getNormalizedIntensity(int normType,double[] yVal,double[] yNormVal){
        double normVal = 1;
        double[] normedTrace = new double[yVal.length];


        if(normType==0)normVal = 1;//None
        else if (normType == 1)normVal = yNormVal[0];//Constant
        else if (normType == 2)normVal = Arrays.stream(yNormVal).min().getAsDouble();//min
        else if (normType == 3)normVal = Arrays.stream(yNormVal).max().getAsDouble();//max
        else if (normType == 4) normVal = Arrays.stream(yNormVal).average().getAsDouble();//mean
        else if (normType == 5) normVal = yNormVal[0];//first
        else if (normType == 6)normVal = yNormVal[yNormVal.length-1];//last
        else if (normType == 7)for(int i=0;i<yVal.length;i++)normedTrace[i] = yVal[i]/yNormVal[i];//each frame
        else if (normType == 8){
            double min = Arrays.stream(yNormVal).min().getAsDouble();
            double max = Arrays.stream(yNormVal).max().getAsDouble();
            for(int i=0;i<yVal.length;i++)normedTrace[i] = (max-min)==0?0:(yVal[i]-min)/(max-min);//Norm from 0 to 1
        }

        if (normType < 7)for(int i=0;i<yVal.length;i++)normedTrace[i] = yVal[i]/normVal;

        return normedTrace;

    }

    int findAlignments(double[] yVals){

        double[] fitResult;

        if(alignType==0)return 0;
        else if(alignType==1 ){//none or wash in frame
            return washinFrame-1;
        } else if(alignType==2) {//step fit
            fitResult = singleStepFit(yVals,alignStepfitStdDev, alignThreshold,alignStepfitMinSingleStepFraction,alignStepfitMaxNoStepFraction);
            if(fitResult[0]==0)return (int) fitResult[1];
            else return -1;
        }else if(alignType==3 || alignType==4){
            double[] xVals = new double[yVals.length];
            Arrays.setAll(xVals, i -> i * 1.0);
            if(alignType==3)fitResult = myLeastSquare.fitPiecewiseConstantLinear(xVals, yVals);
            else fitResult = myLeastSquare.fitPiecewiseConstantExp(xVals, yVals);
            int intResult = (int)Math.round(fitResult[2]);
            if(intResult>=0 && intResult<yVals.length)
                return intResult;
            else return -1;
        }else if(alignType==5 ){
            int pos;
            if(alignFirstCrossing)pos = myThreshold.singleFirstThreshold(yVals,alignThresholdRising,alignThreshold , alignDebounceNum,false);
            else pos = myThreshold.singleLastThreshold(yVals,alignThresholdRising,alignThreshold , alignDebounceNum,false);
            if(pos>=0)return pos;
            else return -1;
        }
        return -1;

    }

    double[] singleStepFit(double[] yVals,double dataStdDev, double threshold,double minSingleStepFraction,double maxNoStepFraction){

        if(dataStdDev<=0){
            double[][] allData = new double[1][yVals.length];
            allData[0] = yVals.clone();
            dataStdDev = myStepFitting.approxStdDev(allData);
        }

        double stepPenalty = threshold * threshold * dataStdDev * dataStdDev;

        ArrayList<Integer> fitPoints = new ArrayList<>();
        ArrayList<Double> fitMeans = new ArrayList<>();

        myStepFitting.Aggarwal(yVals,stepPenalty, 10, fitPoints, fitMeans);

        double[] stepSummary = new double[]{0,0,-Double.MAX_VALUE,-Double.MAX_VALUE,Double.MAX_VALUE,0,0};//"Trace Class, Step Frame,Step Height, Max Intensity,Min Intensity, Intensity Before, Intensity After";
        int noStepCount =0;


        for(int j=0;j<fitMeans.size();j++){
            if(fitMeans.get(j)>stepSummary[3])stepSummary[3] = fitMeans.get(j);
            if(fitMeans.get(j)<stepSummary[4])stepSummary[4] = fitMeans.get(j);
            if(j>0 && fitMeans.get(j-1)-fitMeans.get(j)>stepSummary[2]){
                stepSummary[2] = fitMeans.get(j-1)-fitMeans.get(j);
                stepSummary[1] = fitPoints.get(j);
                stepSummary[5] = fitMeans.get(j-1);
                stepSummary[6] = fitMeans.get(j);

            }
        }


        if((stepSummary[3]-Math.min(0,stepSummary[4]))*minSingleStepFraction<stepSummary[2])stepSummary[0] = 0;//Single Step
        else if((stepSummary[3]-stepSummary[4])<maxNoStepFraction*stepSummary[3])stepSummary[0] = 1;//No Step
        else stepSummary[0] = 2;

        fitOverlay = myStepFitting.makeFitTrace(fitPoints,fitMeans,yVals.length);

        return stepSummary;

    }

    void multiStepFit(double[] yVals,ArrayList<Double> positiveStepHeights,ArrayList<Double> negativeStepHeights, ArrayList<Double> allIntervals, ArrayList<Double> positiveStepInterval, ArrayList<Double> negativeStepInterval,double dataStdDev, double threshold){

        double stepPenalty = threshold * threshold * dataStdDev * dataStdDev;
        ArrayList<Integer> fitPoints = new ArrayList<>();
        ArrayList<Double> fitMeans = new ArrayList<>();

        myStepFitting.Aggarwal(yVals,stepPenalty, 10, fitPoints, fitMeans);

        double lastNegativeStepFrame = -1,lastPositiveStepFrame = -1,lastStepFrame = -1;
        for(int j=1;j<fitMeans.size();j++){
            double stepHeight = fitMeans.get(j)-fitMeans.get(j-1);
            if(stepHeight>=0){
                positiveStepHeights.add(stepHeight);
                if(lastPositiveStepFrame>=0)positiveStepInterval.add(timePerFrame*(fitPoints.get(j)-lastPositiveStepFrame));
                lastPositiveStepFrame = (double)fitPoints.get(j);
            } else{
                negativeStepHeights.add(-stepHeight);
                if(lastNegativeStepFrame>=0)negativeStepInterval.add(timePerFrame*(fitPoints.get(j)-lastNegativeStepFrame));
                lastNegativeStepFrame = (double)fitPoints.get(j);
            }
            if(lastStepFrame>=0)allIntervals.add(timePerFrame*(fitPoints.get(j)-lastStepFrame));
            lastStepFrame = (double)fitPoints.get(j);
        }

        fitOverlay = myStepFitting.makeFitTrace(fitPoints,fitMeans,yVals.length);

    }

    void plotPageOfTraces(ArrayList<double[]> yvals,ArrayList<double[]> fit, String name,paramsClass params){

        double[] frames = new double[yvals.get(0).length];
        for (int frameNum = 0; frameNum < yvals.get(0).length; frameNum++)frames[frameNum] = frameNum*params.timePerFrame;

        ImageStack imstackin = null;
        for (int partNum = 0; partNum < Math.min(yvals.size(), 36); partNum++) {
            myPlot plot = new myPlot("Particle " + String.valueOf(partNum + 1), "Time (" + params.timePerFrameUnits + ")", "Intensity");
            plot.addLine(frames,yvals.get(partNum));
            plot.overlay(frames,fit.get(partNum));
            plot.setPlotLimitsWithYBuffer(true);
            ImagePlus plotIm2 = plot.plot.makeHighResolution("Particle " + String.valueOf(partNum + 1), 1.0f, true, false);
            if(imstackin==null)imstackin = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
            imstackin.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
        }

        if(imstackin!=null && imstackin.size()>0) {
            ImagePlus outputImStack = new ImagePlus(name, imstackin);
            MontageMaker myMaker = new MontageMaker();
            ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, imstackin.size(), 1, 0, false);
            //if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
            if(params.saveTraces) new FileSaver(outputMontage).saveAsPng(params.fileBase+name+".png");
            outputMontage.show();
        }
    }

    void survivalCurve(double[] data,double delta, double offset,String name,String xAxis,String yAxis,String fileName,boolean displayOutput){

        if(data.length==0 || delta<0)return;

        Arrays.sort(data);

        double minPoint = Math.min(0.0,data[0]);
        int NOP = (int)Math.ceil((data[data.length-1]-minPoint)/delta)+1;

        double[][] survivalCurves = new double[3][NOP];//x, y, yfit

        for(int i=0;i<NOP;i++)survivalCurves[0][i] = minPoint+i*delta;

        int partCount = 0;
        for(int i=0;i<NOP;i++){
            while(partCount+1<data.length && data[partCount]-0.00001<survivalCurves[0][i])partCount++;
            survivalCurves[1][i] = data.length-partCount+offset;
        }

        //Fit with exponential
        myLeastSquare myLS = new myLeastSquare();
        double[] expFit = myLS.fitExp(survivalCurves[0],survivalCurves[1]);
        for(int i=0;i<NOP;i++)survivalCurves[2][i] = expFit[0]+expFit[1]*Math.exp(-1.0*expFit[2]*survivalCurves[0][i]);

        //plot result
        myPlot plot = new myPlot(name+" Mean = "+ IJ.d2s(1/expFit[2],2), xAxis, yAxis);
        plot.addLine(survivalCurves[0],survivalCurves[1]);
        plot.overlay(survivalCurves[0],survivalCurves[2]);

        plot.saveAndDisplay(saveTraces, fileName,true, displayOutput);


        // save csv

        String summaryHeader ="Fit Equation = ,a+b exp(-c x),a = "+expFit[0]+",b = ,"+expFit[1]+",c = ,"+expFit[2]+
                "\nFit Mean = ,"+IJ.d2s(1/expFit[2],2)+", Percent Observed = ,"+IJ.d2s(100-100*Math.exp(-1.0*expFit[2]*(NOP-1)),0)+"\n";
        summaryHeader =summaryHeader +xAxis+","+yAxis+", y Fit\n";
        if(saveTraces) ShapeFunctions.writeCSV(fileName+"_Data.csv", survivalCurves,summaryHeader,true);

    }

    void intensityDistribution(double[] data, double minFitPercentage, double maxFitPercentage,String name,String xAxis,String fileName, boolean displayOutput){


        Arrays.sort(data);

        int start = (int) (data.length * minFitPercentage);
        while(start<data.length && data[start]<=0)start++;
        int end = (int) (data.length * maxFitPercentage);
        int NOP = end-start;

        if(NOP<3)return;

        double[][] cdfData = new double[2][NOP];//x, y, yfit

        cdfData[0] = java.util.Arrays.copyOfRange(data, start, end);
        cdfData[1] = IntStream.range(start, end).asDoubleStream().toArray();

        //Fit with exponential
        myLeastSquare myLS = new myLeastSquare();
        double[] normFit = myLS.fitNormalCDF(cdfData[0],cdfData[1]);
        double[] logNormFit = myLS.fitLogNormalCDF(cdfData[0],cdfData[1]);


        double binWidth = 2.0*(data[(int) (data.length * 0.75)]-data[(int) (data.length * 0.25)]) / (Math.pow(1.0*data.length, 0.3333333)); //Using the Freedman–Diaconis rule

        if(binWidth==0)return;

        int binCount = (int)Math.ceil(data[end]/binWidth)+1;

        double[][] histFits = new double[4][binCount];
        for(int i=0;i<binCount;i++)histFits[0][i] = binWidth*i;
        for(int i=0;i<data.length;i++){
            int toAdd = (int)(data[i]/binWidth+0.5);
            if(toAdd>=0 && toAdd<binCount)histFits[1][toAdd] = histFits[1][toAdd]+1;
        }
        for(int i=0;i<binCount;i++)histFits[1][i] = histFits[1][i]/(data.length*binWidth);

        for(int i=0;i<binCount;i++){
            histFits[2][i] =1.0 / (normFit[3] * Math.sqrt(2*Math.PI)) * Math.exp(-(histFits[0][i] - normFit[2])*(histFits[0][i] - normFit[2]) / (2*normFit[3]*normFit[3]));
            histFits[3][i] =histFits[0][i]<=0?0:1.0 / (histFits[0][i]*logNormFit[3] * Math.sqrt(2*Math.PI)) * Math.exp(-(Math.log(histFits[0][i]) - logNormFit[2])*(Math.log(histFits[0][i]) - logNormFit[2]) / (2*logNormFit[3]*logNormFit[3]));
        }

        double mean = Arrays.stream(data).average().orElse(0.0);

        //plot result
        myPlot plot = new myPlot(name+" Raw Data Mean = "+ IJ.d2s(mean,2), xAxis, "Probability Density");
        plot.addLine(histFits[0],histFits[1]);
        plot.overlay(histFits[0],histFits[2]);
        plot.overlay(histFits[0],histFits[3]);

        plot.saveAndDisplay(saveTraces, fileName,true, displayOutput);
        // save csv

        String summaryHeader ="Normal Fit Equation = ,1 / (sigma*sqrt(2*pi)) * exp(-(x-mu)^2 / (2*sigma^2),mu = "+normFit[2]+",sigma = ,"+normFit[3]+"\n"+
                "Log Normal Fit Equation = ,1 / (x*sigma*sqrt(2*pi)) * exp(-(ln(x)-mu)^2 / (2*sigma^2),mu = "+logNormFit[2]+",sigma = ,"+logNormFit[3]+"\n";
        summaryHeader =summaryHeader +xAxis+","+"Probability Density"+", Normal Fit, Log Normal Fit\n";
        if(saveTraces) ShapeFunctions.writeCSV(fileName+"_Data.csv", histFits,summaryHeader,true);

    }

}

