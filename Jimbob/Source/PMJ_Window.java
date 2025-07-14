package org.micromanager.plugins.Poor_Mans_JIM;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.Prefs;
import ij.gui.*;
import ij.io.FileSaver;
import ij.measure.Measurements;
import ij.measure.ResultsTable;
import ij.plugin.HyperStackConverter;
import ij.plugin.MontageMaker;
import ij.plugin.filter.ParticleAnalyzer;
import ij.process.ByteProcessor;
import ij.process.FloatProcessor;
import ij.process.ImageProcessor;
import ij.process.ShortProcessor;
import org.micromanager.Studio;
import org.micromanager.data.Coords;
import org.micromanager.data.DataProvider;
import org.micromanager.data.Metadata;
import org.micromanager.display.DisplayManager;
import org.micromanager.display.DataViewer;


import javax.swing.*;
import javax.swing.event.PopupMenuEvent;
import javax.swing.event.PopupMenuListener;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.io.FileWriter;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class PMJ_Window {
    PMJ_Window mainWindow;



    JPanel MainPanel;
    private JButton detectionImageButton;
    private JTextField AlignROISizeTextBox;
    private JTextField sBackgroundWidth;
    private JCheckBox bNormalizeTracesBox;
    private JButton detectParticlesButton;
    private JTextField detectStartFrameBox;
    private JTextField detectEndFrameBox;
    private JTextField cutoffBox;
    private JTextField ROIPaddingBox;
    private JTextField minEccentricityBox;
    private JTextField maxEccentricityBox;
    private JTextField minCountBox;
    private JTextField maxCountBox;
    private JTextField minDFEBox;
    private JButton GenerateTracesButton;
    private JTextField pageNumberBox;
    private JButton stepFitButton;
    private JTextField channelToFitBox;
    private JButton batchButton;
    private JTextField batchDirectoryBox;
    private JButton browseButton;
    private JComboBox filesDropDownMenu;
    private JLabel statusText;
    private JTextField driftMaxShiftBox;
    private JCheckBox driftCorrectDetectBox;
    private JCheckBox displayAlignedStackBox;
    private JCheckBox driftCorrectTraceBox;
    private JCheckBox saveTracesBox;
    private JCheckBox batchStepFitBox;
    private JTextField Align_Channel_Select;
    private JButton helpButton;
    private JTextField timePerFrameBox;
    private JTextField timePerFrameUnitsBox;


    DisplayManager myDisplayManager;
    DataViewer  myDataViewer;
    DataProvider myDataProvider;
    Coords.Builder newcoordsBuilder ;

    int totChanNum,totFrameNum,totPosNum;
    int currentFrame, currentPos;
    int totPartNum;
    int totImageWidth,totImageHeight,totNOP;

    int[][] allDrifts;
    double[][][] traces=new double[0][0][0];
    double[][][] backTraces=new double[0][0][0];

    double[][] stepfits;


    ArrayList<Rectangle> filteredROIs = new ArrayList<>();

    int plotWidth = 0;
    int plotHeight = 0;

    final List<Color> mycolour = Arrays.asList(Color.MAGENTA, Color.CYAN, Color.BLUE, Color.BLACK, Color.PINK);

    short[] rawImage16;

    byte[] backgroundMask;

    float[] imageForDetection;
    int[] imageForAlignment;

    Rectangle fullImageRec, alignmentRectangle;

    Runnable imageForDetectRunnable,detectRunnable,measureTracesRunnable,stepFitRunnbale;

    int posNum;
    boolean outputDisplay;



    //parameters
    boolean driftCorrectDetect, driftCorrectTrace,displayAlignedStack,saveTraces,batchStepFit;
    int alignMaxShift,alignROILength,detectStart,detectEnd,alignChannel,minCount,maxCount,minDFE,padROI,backgroundWidth,channelToStepFit;
    double cutoff,minEccentricity,maxEccentricity,timePerFrame;
    String timePerFrameUnits;
    void parseParameters(){
        //detection Image
        alignROILength = Integer.parseInt(AlignROISizeTextBox.getText());
        if(alignROILength>totImageWidth || alignROILength>totImageHeight || alignROILength<8)alignROILength = Math.min(totImageWidth,totImageHeight);
        if ((alignROILength & -alignROILength) != alignROILength){
            alignROILength = (int)(Math.log(alignROILength)/Math.log(2));
            alignROILength = (int)Math.round(Math.pow(2,alignROILength));
        }
        AlignROISizeTextBox.setText(String.valueOf(alignROILength));

        alignmentRectangle = new Rectangle(totImageWidth/2-alignROILength/2,totImageHeight/2-alignROILength/2,alignROILength,alignROILength);

        alignMaxShift = Integer.parseInt(driftMaxShiftBox.getText());
        driftCorrectDetect = driftCorrectDetectBox.isSelected();
        alignChannel = Integer.parseInt(Align_Channel_Select.getText());


        detectStart = Integer.parseInt(detectStartFrameBox.getText())-1;
        detectEnd = Integer.parseInt(detectEndFrameBox.getText());
        if(detectEnd<0)detectEnd = totFrameNum;

        cutoff = Double.parseDouble(cutoffBox.getText());
        minEccentricity = Double.parseDouble(minEccentricityBox.getText());
        maxEccentricity = Double.parseDouble(maxEccentricityBox.getText());
        minCount = Integer.parseInt(minCountBox.getText());
        maxCount = Integer.parseInt(maxCountBox.getText());
        minDFE = Integer.parseInt(minDFEBox.getText());
        padROI = Integer.parseInt(ROIPaddingBox.getText());
        backgroundWidth = Integer.parseInt(sBackgroundWidth.getText());

        driftCorrectTrace = driftCorrectTraceBox.isSelected();
        displayAlignedStack = displayAlignedStackBox.isSelected();
        saveTraces = saveTracesBox.isSelected();
        timePerFrame = Double.parseDouble(timePerFrameBox.getText());
        timePerFrameUnits = timePerFrameUnitsBox.getText();

        batchStepFit = batchStepFitBox.isSelected();
        channelToStepFit = Integer.parseInt(channelToFitBox.getText())-1;
    }

    void getImage(int chanNum, int frameNum,int posNum){
        try {
            newcoordsBuilder = newcoordsBuilder.t(frameNum);
            newcoordsBuilder = newcoordsBuilder.c(chanNum);
            newcoordsBuilder = newcoordsBuilder.p(posNum);
            Coords nextCoords = newcoordsBuilder.build();
            totImageWidth = myDataProvider.getImage(nextCoords).getWidth();
            totImageHeight = myDataProvider.getImage(nextCoords).getHeight();
            totNOP = totImageWidth*totImageHeight;

            rawImage16 = (short[])myDataProvider.getImage(nextCoords).getRawPixels();


        } catch (java.io.IOException e1) {
            System.out.println(e1);
            statusText.setText(e1.toString());
        }
    }

    String getFolderName(){
        try{
            newcoordsBuilder = newcoordsBuilder.t(0);
            newcoordsBuilder = newcoordsBuilder.c(0);
            newcoordsBuilder = newcoordsBuilder.p(posNum);
            Coords nextCoords = newcoordsBuilder.build();

            Metadata myMetadata= myDataProvider.getImage(nextCoords).getMetadata();
            String folderName = batchDirectoryBox.getText();
            String fileName = myMetadata.getFileName();

            System.out.println(fileName);
            fileName = folderName+File.separator+fileName.substring(0, fileName.length() - 8)+File.separator;
            System.out.println(fileName);

            Files.createDirectories(Paths.get(fileName));

            return  fileName;
        } catch (java.io.IOException e1) {
            return "";
        }

    }


    void getROIImageFloat(int[] imageIn,float[] roiImageFloat, Rectangle ROI,int driftX, int driftY,boolean add){
        if(roiImageFloat==null || roiImageFloat.length != ROI.width * ROI.height){
            if(add)System.out.println("WARNING Imaging reset when adding!!!");
            roiImageFloat = new float[ROI.width * ROI.height];
        }
        for (int i = 0; i < ROI.width; i++)
            for (int j = 0; j < ROI.height; j++) {
                int xIn = (i + ROI.x + driftX);
                if(xIn<0)xIn=0;
                if(xIn>=totImageWidth)xIn = totImageWidth-1;
                int yIn = (j + ROI.y + driftY);
                if(yIn<0)yIn=0;
                if(yIn>=totImageHeight)yIn = totImageHeight-1;

                if(add) roiImageFloat[i + j * ROI.width] = roiImageFloat[i + j * ROI.width]+imageIn[(xIn + yIn * totImageWidth)];
                else roiImageFloat[i + j * ROI.width] = imageIn[(xIn + yIn * totImageWidth)];
            }
    }

    void getROIImageForAlign(int[] imageIn,int[] roiImageForAlign, Rectangle ROI,int driftX, int driftY,boolean add){
        if(roiImageForAlign==null || roiImageForAlign.length != ROI.width * ROI.height){
            roiImageForAlign = new int[ROI.width * ROI.height];
        }
        for (int i = 0; i < ROI.width; i++)
            for (int j = 0; j < ROI.height; j++) {
                int xIn = (i + ROI.x + driftX);
                if(xIn<0)xIn=0;
                if(xIn>=totImageWidth)xIn = totImageWidth-1;
                int yIn = (j + ROI.y + driftY);
                if(yIn<0)yIn=0;
                if(yIn>=totImageHeight)yIn = totImageHeight-1;

                if(add) roiImageForAlign[i + j * ROI.width] = roiImageForAlign[i + j * ROI.width]+imageIn[(xIn + yIn * totImageWidth)];
                else roiImageForAlign[i + j * ROI.width] = imageIn[(xIn + yIn * totImageWidth)];

            }
    }

    void getROIImageShort(short[] imageIn,short[] roiImageForAlign, Rectangle ROI,int driftX, int driftY){
        if(roiImageForAlign==null || roiImageForAlign.length != ROI.width * ROI.height){
            roiImageForAlign = new short[ROI.width * ROI.height];
        }
        for (int i = 0; i < ROI.width; i++)
            for (int j = 0; j < ROI.height; j++) {
                int xIn = (i + ROI.x + driftX);
                if(xIn<0)xIn=0;
                if(xIn>=totImageWidth)xIn = totImageWidth-1;
                int yIn = (j + ROI.y + driftY);
                if(yIn<0)yIn=0;
                if(yIn>=totImageHeight)yIn = totImageHeight-1;

                roiImageForAlign[i + j * ROI.width] = imageIn[(xIn + yIn * totImageWidth)];

            }
    }



    public PMJ_Window(Studio studioin) {
        myDisplayManager = studioin.getDisplayManager();
        myDataViewer=null;

        mainWindow = this;

        imageForDetectRunnable = ()->{
            if(outputDisplay){
                statusText.setText("Summing Frame ");
            }
            getImage(0, 0, posNum);
            myFFT aligner = new myFFT(alignROILength);

            //Declare summed image sizes

            int[] tempImageForAlign = new int[alignROILength*alignROILength];
            imageForAlignment = new int[alignROILength*alignROILength];
            imageForDetection = new float[totNOP];

            //set the bounds for channels that are used for detection and alignment
            int chanStart = 0,chanEnd = totChanNum;
            if(alignChannel>0){
                chanStart = alignChannel-1;
                chanEnd = alignChannel;
            }

            int[] chanSum = new int[totNOP];

            for (int frameNum = detectStart; frameNum < detectEnd; frameNum++) {
                if(outputDisplay)statusText.setText("Summing Frame "+String.valueOf(detectStart+1));
                chanSum = new int[totNOP];
                //get sum of channels
                for (int chanNum = chanStart; chanNum < chanEnd; chanNum++) {
                    getImage(chanNum, frameNum, posNum);
                    for(int i=0;i<totNOP;i++)chanSum[i] += (int)rawImage16[i];
                }
                //align image
                int xDrift = 0, yDrift = 0;
                if(frameNum==detectStart && driftCorrectDetect) {
                    getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
                    aligner.set_Reference(tempImageForAlign);
                } else if(driftCorrectDetect) {
                    getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
                    aligner.align(tempImageForAlign, alignMaxShift);
                    xDrift = aligner.maxXPos;
                    yDrift = aligner.maxYPos;
                }
                //add aligned images to stack
                getROIImageForAlign(chanSum, imageForAlignment, alignmentRectangle, xDrift, yDrift, true);
                getROIImageFloat(chanSum, imageForDetection, fullImageRec,  xDrift, yDrift, true);
            }

            //Debugging
            getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
            aligner.set_Reference(tempImageForAlign);
            for(int i=-3;i<3;i++)for(int j=-3;j<3;j++){
                getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, i, j, false);
                aligner.align(tempImageForAlign,100);
                System.out.println("i,j,iout,jout = "+i+","+j+","+(-aligner.maxXPos)+","+(-aligner.maxYPos));
            }

            if(outputDisplay){
               new ImagePlus("Detection Image",new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone())).show();
            }
        };


        detectRunnable = () -> {
            if(outputDisplay){
                statusText.setText("Detecting ROIs");
            }

            ImageStack imstackin = new ImageStack(totImageWidth, totImageHeight);


            if(outputDisplay)imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone()));
            FloatProcessor meanFP = new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone());
            LapOfGauss logClass = new LapOfGauss(10);

            FloatProcessor logim = logClass.run(meanFP,true);
            float[] flogim = (float[])logim.getPixels();

            float mean = 0;
            for (float i : flogim) {
                mean += i;
            }
            mean = mean / flogim.length;

            float stddev = 0;
            for (float num : flogim) {
                stddev += Math.pow(num - mean, 2);
            }
            stddev =  (float)Math.sqrt(stddev / flogim.length);

            byte background,foreground;
            if(Prefs.blackBackground){
                background = 0;
                foreground = (byte)255;
            }else{
                background = (byte)255;
                foreground = 0;
            }

            //if(outputDisplay)imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, flogim.clone()));

            float threshold = (float) (mean+cutoff*stddev);
            byte[] detectIm = new byte[totNOP];
            float[] roiImageFloat = new float[totNOP];
            for(int i=0;i<flogim.length;i++)
                if(flogim[i]>threshold){
                    detectIm[i]=foreground;
                    roiImageFloat[i]=threshold;
                }
                else {detectIm[i]=background;
                    roiImageFloat[i] = 0;
                }

            if(outputDisplay)imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, roiImageFloat.clone()));

            ByteProcessor BP = new ByteProcessor(totImageWidth, totImageHeight, detectIm.clone());

            ImagePlus detected = new ImagePlus("Detected ",BP);
            ResultsTable myRT = new ResultsTable();
            int toMeasure = Measurements.CIRCULARITY+Measurements.AREA+Measurements.RECT+Measurements.CENTROID;
            ParticleAnalyzer myPartAnal = new ParticleAnalyzer(ParticleAnalyzer.SHOW_NONE,toMeasure,myRT,3,1000);
            if(myPartAnal.analyze(detected)==false){
                System.out.println("Error With particle analyzer");
            }

            double[][] myResults = new double[myRT.size()][9]; //Area, x,y,width,height, eccentricity, nearest neighbour


            for(int i=0;i<myRT.size();i++){
                myResults[i][0] = myRT.getValue("Area",i);
                myResults[i][1] = myRT.getValue("BX",i)-padROI;
                myResults[i][2] = myRT.getValue("BY",i)-padROI;
                myResults[i][3] = myRT.getValue("Width",i)+2*padROI;
                myResults[i][4] = myRT.getValue("Height",i)+2*padROI;
                myResults[i][5] = 1-myRT.getValue("Circ.",i);
                myResults[i][6] = myRT.getValue("X",i);
                myResults[i][7] = myRT.getValue("Y",i);
                myResults[i][8] = 100000;//min dist
            }
            // find min separation
            for(int i=0;i<myRT.size();i++)
                for(int j=0;j<myResults.length;j++){
                    double xdist = Math.abs(myResults[i][6]-myResults[j][6])-myResults[i][3]/2-myResults[j][3]/2;
                    double ydist = Math.abs(myResults[i][7]-myResults[j][7])-myResults[i][4]/2-myResults[j][4]/2;
                    if(i!=j && Math.max(xdist,ydist)<myResults[i][8])myResults[i][8] = Math.max(xdist,ydist);
                }

            filteredROIs = new ArrayList<>();
            for(int i=0;i<myRT.size();i++){
                if(myResults[i][0]>=minCount && myResults[i][0]<=maxCount && myResults[i][5]>=minEccentricity-0.01 && myResults[i][5]<=maxEccentricity+0.01
                        && myResults[i][6]>(minDFE) && myResults[i][6]<totImageWidth - (minDFE) && myResults[i][7]>(minDFE) && myResults[i][7]<totImageHeight - (minDFE) &&
                        myResults[i][8] > 2)filteredROIs.add(new Rectangle((int)myResults[i][1],(int)myResults[i][2],(int)myResults[i][3],(int)myResults[i][4]));
            }

            backgroundMask = new byte[totImageHeight*totImageWidth];
            for(int partNum=0;partNum<totPartNum;partNum++)
                for(int i=0;i<filteredROIs.get(i).width;i++)
                    for(int j=0;j<filteredROIs.get(i).height;j++)backgroundMask[(i+filteredROIs.get(i).x)+(j+filteredROIs.get(i).y)*totImageWidth] = 1;

            totPartNum = filteredROIs.size();

            if(outputDisplay) {
                Overlay detectedOverlay = new Overlay();
                totPartNum = filteredROIs.size();
                for(int i=0;i<totPartNum;i++) detectedOverlay.add(new Roi(filteredROIs.get(i)));
                ImagePlus outputImStack = new ImagePlus("Detection", imstackin);
                outputImStack.setOverlay(detectedOverlay);
                outputImStack.show();
            }

            System.out.println(totPartNum);
            statusText.setText("Detecting ROIs "+totPartNum+"\\"+myRT.size());

        };//end detect runnable

        measureTracesRunnable = () -> {

            if(outputDisplay)statusText.setText("Channel/Frame ");


            short[][] allChanRawImage16 = new short[totChanNum][totNOP];

            allDrifts = new int[2][totFrameNum];
            int[] tempImageForAlign = new int[alignROILength*alignROILength];
            myFFT aligner = new myFFT(alignROILength);
            if(driftCorrectTrace) {
                aligner.set_Reference(imageForAlignment);
            }
            //calculate frames used for alignment
            int chanStart = 0,chanEnd = totChanNum;
            if(alignChannel>0){
                chanStart = alignChannel-1;
                chanEnd = alignChannel;
            }

            ImageStack imstackin = new ImageStack(totImageWidth, totImageHeight);

            traces = new double[totChanNum][totFrameNum][totPartNum];
            backTraces =  new double[totChanNum][totFrameNum][totPartNum];




            for (int frameNum = 0; frameNum < totFrameNum; frameNum++) {
                if (outputDisplay) statusText.setText("Channel/Frame "+String.valueOf(frameNum + 1) + "/" + String.valueOf(totFrameNum));
                //read images
                for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                    getImage(chanNum, frameNum, posNum);
                    if (totNOP >= 0) System.arraycopy(rawImage16, 0, allChanRawImage16[chanNum], 0, totNOP);
                }

                //align images
                allDrifts[0][frameNum] = 0;
                allDrifts[1][frameNum] = 0;
                if (driftCorrectTrace) {
                    //get sum of channels used for alignment
                    int[] chanSum = new int[totNOP];
                    for (int chanNum = chanStart; chanNum < chanEnd; chanNum++)
                        for(int i=0;i<totNOP;i++)chanSum[i] += (int)allChanRawImage16[chanNum][i];

                    //align image
                    getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
                    aligner.align(tempImageForAlign, alignMaxShift);
                    allDrifts[0][frameNum] = aligner.maxXPos;
                    allDrifts[1][frameNum] = aligner.maxYPos;


                    //add aligned images to stack
                    if (outputDisplay && displayAlignedStack) {
                        for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                            getROIImageShort(allChanRawImage16[chanNum],rawImage16, fullImageRec, allDrifts[0][frameNum], allDrifts[1][frameNum]);
                            imstackin.addSlice(new ShortProcessor(totImageWidth, totImageHeight, rawImage16.clone(),null));
                        }
                    }
                }

                //calculate traces
                int xIn,yIn;
                for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                    for (int partNum = 0; partNum < filteredROIs.size(); partNum++) {
                        long foregroundSum = 0;
                        long backgroundSum = 0;
                        int foregroundCount = 0;
                        int backgroundCount = 0;
                        Rectangle roiRect = filteredROIs.get(partNum);
                        for (int i = -backgroundWidth; i <  roiRect.width + backgroundWidth; i++)
                            for (int j = -backgroundWidth; j < roiRect.height + backgroundWidth; j++) {
                                xIn = (i + roiRect.x + allDrifts[0][frameNum]);
                                yIn = (j + roiRect.y + allDrifts[1][frameNum]);
                                if(xIn<0||yIn<0||xIn>=totImageWidth||yIn>=totImageHeight);
                                else if (i >= 0 && i < roiRect.width && j >= 0 && j < roiRect.height) {
                                    foregroundSum += allChanRawImage16[chanNum][xIn + yIn * totImageWidth];
                                    foregroundCount++;
                                } else if (backgroundMask[(i + roiRect.x) + (j + roiRect.y) * totImageWidth] == 0) {
                                    backgroundSum += allChanRawImage16[chanNum][xIn + yIn * totImageWidth];
                                    backgroundCount++;
                                }
                            }
                        // System.out.println(String.valueOf(foregroundSum)+" "+String.valueOf(backgroundSum)+" "+String.valueOf(pixelCountRatio)+" "+String.valueOf(foregroundSum - (backgroundSum * pixelCountRatio)));
                        if(foregroundCount>0 && backgroundCount>0) {
                            traces[chanNum][frameNum][partNum] = (foregroundSum - (backgroundSum * foregroundCount / backgroundCount));
                            backTraces[chanNum][frameNum][partNum] = backgroundSum / backgroundCount;
                        }
                    }
                }
            }

            if(outputDisplay && displayAlignedStack) {
                ImagePlus outputImStack = new ImagePlus("Aligned Stack ", imstackin);
                outputImStack = new HyperStackConverter().toHyperStack(outputImStack, totChanNum, 1, totFrameNum, "CZT", "grayscale");
                outputImStack.show();
            }

            if(saveTraces){
                try {
                    String folderName = getFolderName();
                    Files.createDirectories(Paths.get(folderName));
                    for (int chanCount = 0; chanCount < totChanNum; chanCount++) {
                        FileWriter myOutput = new FileWriter(folderName + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Intensities.csv");
                        myOutput.write("Each row is a particle. Each column is a Frame\n");
                        FileWriter myBackOutput = new FileWriter(folderName + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Backgrounds.csv");
                        myBackOutput.write("Each row is the mean background surrounding the particle. Each column is a Frame\n");

                        String myLine, myBackLine;
                        for (int i = 0; i < totPartNum; i++) {
                            myLine = "";
                            myBackLine = "";
                            for (int j = 0; j < totFrameNum; j++) {
                                myLine = myLine + String.valueOf(traces[chanCount][j][i]) + ",";
                                myBackLine = myBackLine + String.valueOf(backTraces[chanCount][j][i]) + ",";
                            }
                            myLine = myLine.substring(0, myLine.length() - 1);
                            myLine = myLine + "\n";
                            myOutput.write(myLine);

                            myBackLine = myBackLine.substring(0, myBackLine.length() - 1);
                            myBackLine = myBackLine + "\n";
                            myBackOutput.write(myBackLine);
                        }
                        myOutput.close();
                        myBackOutput.close();
                    }
                }catch(Exception e) {
                    System.out.println(e);
                    statusText.setText(e.toString());
                }
            }//end writing out traces

        };//end measure trace runnable

        stepFitRunnbale = () -> {

            stepfits = new double[5][totPartNum];//pos,mean before, mean after, std dev, class
            //Find steps
            for (int partNum = 0; partNum < totPartNum; partNum++) {
                double minStdDev = Double.MAX_VALUE;
                double sum1 = 0;
                double sum2 = 0;
                double mean1, mean2, stddev;
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)
                    sum2 += traces[channelToStepFit][frameNum][partNum];

                for (int posin = 1; posin < totFrameNum; posin++) {
                    sum1 += traces[channelToStepFit][posin - 1][partNum];
                    mean1 = sum1 / posin;
                    sum2 -= traces[channelToStepFit][posin - 1][partNum];
                    mean2 = sum2 / (totFrameNum - posin);
                    stddev = 0;
                    for (int frameNum = 0; frameNum < posin; frameNum++)
                        stddev += (traces[channelToStepFit][frameNum][partNum] - mean1) * (traces[channelToStepFit][frameNum][partNum] - mean1);
                    for (int frameNum = posin; frameNum < totFrameNum; frameNum++)
                        stddev += (traces[channelToStepFit][frameNum][partNum] - mean2) * (traces[channelToStepFit][frameNum][partNum] - mean2);
                    if (stddev < minStdDev) {
                        minStdDev = stddev;
                        stepfits[0][partNum] = posin;
                        stepfits[1][partNum] = mean1;
                        stepfits[2][partNum] = mean2;
                        stepfits[3][partNum] = Math.sqrt(stddev);
                    }
                }
            }

            if(saveTraces) {
                try {
                    String folderName = getFolderName();
                    Files.createDirectories(Paths.get(folderName));

                    FileWriter myStepOutput = new FileWriter(folderName + "Stepfit_Single_Step_Fits.csv");
                    myStepOutput.write("Trace Number, No Step Mean, One or more step Probability, Step Position, Initial Mean, Final Mean, Probability of More Steps, Residual Standard Deviation\n");

                    for (int j = 0; j < totPartNum; j++) {
                        String myLine = String.valueOf(j + 1) + ",0,1,";
                        for (int i = 0; i < 3; i++)
                            myLine = myLine + String.valueOf(stepfits[i][j]) + ",";//[5][totPartNum];pos,mean before, mean after, std dev, class
                        myLine = myLine + "0," + String.valueOf(stepfits[3][j]) + "\n";
                        myStepOutput.write(myLine);
                    }
                    myStepOutput.close();
                }catch(Exception e) {
                    System.out.println(e);
                    statusText.setText(e.toString());
                }
            }


        };

        detectionImageButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                if(myDataViewer==null){
                    System.out.println("Error - Window not found");
                    statusText.setText("Error - Window not found");
                    return;
                }

                myDataProvider = myDataViewer.getDataProvider();
                newcoordsBuilder = myDataViewer.getDisplayPosition().copyBuilder();
                totChanNum = myDataProvider.getNextIndex("channel");
                totFrameNum = myDataProvider.getNextIndex("time");
                totPosNum = myDataProvider.getNextIndex("position");
                currentFrame = newcoordsBuilder.build().getT();
                currentPos = newcoordsBuilder.build().getP();
                batchDirectoryBox.setText(myDataProvider.getSummaryMetadata().getDirectory());
                parseParameters();
                posNum = currentPos;
                outputDisplay = true;
                Thread detectThread = new Thread(imageForDetectRunnable);
                detectThread.start();

            }

        });

        detectParticlesButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                parseParameters();
                posNum = currentPos;
                outputDisplay = true;
                Thread detectThread = new Thread(detectRunnable);
                detectThread.start();

            }
        });

        GenerateTracesButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {

                parseParameters();
                Thread measureTraceThread = new Thread(measureTracesRunnable);
                measureTraceThread.start();
                try{measureTraceThread.join();}catch (Exception e1){System.out.println(e1);}


                boolean bNormalizeTraces = bNormalizeTracesBox.isSelected();
                int startTrace = (Integer.parseInt(pageNumberBox.getText())-1)*36;

                //Make Mean Trace
                double[][] meanTrace = new double[totChanNum][totFrameNum];
                for (int chanNum = 0; chanNum < totChanNum; chanNum++)
                    for (int frameNum = 0; frameNum < totFrameNum; frameNum++)
                        for (int partNum = 0; partNum < traces[0][0].length; partNum++)
                            meanTrace[chanNum][frameNum]+=traces[chanNum][frameNum][partNum]/traces[0][0].length;


                double maxval;
                if(bNormalizeTraces){
                    for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                        maxval = 0;
                        for (int frameNum = 0; frameNum < totFrameNum; frameNum++)if(meanTrace[chanNum][frameNum]>maxval)maxval = meanTrace[chanNum][frameNum];
                        for (int frameNum = 0; frameNum < totFrameNum; frameNum++)meanTrace[chanNum][frameNum] = meanTrace[chanNum][frameNum]/maxval;
                    }
                }

                //plot mean trace
                Plot plot = new Plot("Mean Trace "+traces[0][0].length+" Particles", "Time ("+timePerFrameUnits+")", "Intensity (a.u.)");
                plot.setFrameSize(400, 250);
                PlotWindow.noGridLines = true;
                plot.setAxisLabelFont(Font.BOLD, 40);
                plot.setFont(Font.BOLD, 40);
                plot.setLineWidth(6);
                //plot.addLabel(0.25,0,"Mean Trace");
                double[] frames = new double[totFrameNum];
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)frames[frameNum] = frameNum*timePerFrame;
                for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                    plot.setColor(mycolour.get(chanNum));
                    plot.add("line",frames, meanTrace[chanNum]);
                }
                plot.setLimitsToFit(true);
                if(saveTraces) new FileSaver(plot.getImagePlus()).saveAsPng(getFolderName()+"Mean_Trace_"+traces[0][0].length+"_Particles.png");
                plot.show();


                //make trace page

                Plot plot2;
                ImagePlus plotIm = plot.makeHighResolution("discard", 1, true, false);
                plotWidth = plotIm.getWidth();
                plotHeight = plotIm.getHeight();
                ImageStack imstackin = new ImageStack(plotWidth, plotHeight);
                double[] toplot = new double[totFrameNum];
                for (int partNum = startTrace; partNum < Math.min(totPartNum, startTrace + 36); partNum++) {
                    plot2 = new Plot("Particle " + String.valueOf(partNum + 1), "Time ("+timePerFrameUnits+")", "Intensity");
                    plot2.setFrameSize(400, 250);
                    PlotWindow.noGridLines = true;
                    plot2.setAxisLabelFont(Font.BOLD, 40);
                    plot2.setFont(Font.BOLD, 40);
                    plot2.setLineWidth(6);
                    plot2.addLabel(0.2,0.01,"No. "+String.valueOf(partNum + 1)+" X "+String.valueOf(filteredROIs.get(partNum).x+filteredROIs.get(partNum).width/2)+" Y "+String.valueOf(filteredROIs.get(partNum).y+filteredROIs.get(partNum).height/2));
                    for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                        plot2.setColor(mycolour.get(chanNum));
                        maxval = 0;
                        for (int framenum = 0; framenum < totFrameNum; framenum++) {
                            toplot[framenum] = traces[chanNum][framenum][partNum];
                            if (toplot[framenum] > maxval) maxval = toplot[framenum];
                        }
                        if (bNormalizeTraces) for (int framenum = 0; framenum < totFrameNum; framenum++)
                            toplot[framenum] = toplot[framenum] / maxval;
                        plot2.add("line", frames, toplot);
                    }
                    plot2.setLimitsToFit(true);
                    plot2.draw();
                    double[] limitsOut = plot2.getLimits();
                    limitsOut[0] = Math.min(limitsOut[0],0.0);
                    limitsOut[2] = Math.min(limitsOut[2],0.0);
                    plot2.setLimits(limitsOut[0],limitsOut[1] ,limitsOut[2] ,limitsOut[3]);
                    plot2.draw();
                    ImagePlus plotIm2 = plot2.makeHighResolution("Particle " + String.valueOf(partNum + 1), 1, true, false);
                    imstackin.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                }
                if(imstackin.size()>0) {
                    ImagePlus outputImStack = new ImagePlus("Detection", imstackin);
                    MontageMaker myMaker = new MontageMaker();
                    ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, imstackin.size(), 1, 0, false);
                    //if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                    if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                    outputMontage.show();
                }

                //plot Drifts
                Plot plotDrift = new Plot("Sample Drift", "Time ("+timePerFrameUnits+")","Pixels");
                plotDrift.setSize(600,600);
                plotDrift.setFrameSize(400, 250);
                PlotWindow.noGridLines = true;
                plotDrift.setAxisLabelFont(Font.BOLD, 40);
                plotDrift.setFont(Font.BOLD, 40);
                plotDrift.setLineWidth(6);
                //plot.addLabel(0.25,0,"Mean Trace");
                for (int chanNum = 0; chanNum < 2; chanNum++) {
                    plotDrift.setColor(mycolour.get(chanNum));
                    plotDrift.add("line",frames, Arrays.stream(allDrifts[chanNum]).asDoubleStream().toArray());
                }
                plotDrift.setLimitsToFit(true);
                if(saveTraces) new FileSaver(plotDrift.getImagePlus()).saveAsPng(getFolderName()+"Sample_Drift.png");
                plotDrift.show();

                System.out.println(totPartNum);
            }
        });

        stepFitButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                //stepfit
                parseParameters();
                Thread myThread = new Thread(stepFitRunnbale);
                myThread.start();
                try{myThread.join();}catch (Exception e1){System.out.println(e1);}

                int startTrace = (Integer.parseInt(pageNumberBox.getText())-1)*36;

                double maxSecondMeanFirstMeanRatio = 0.25;
                double minNoStepSecondMeanFirstMeanRatio = 0.5;



                //classify 0 - single Step 1 - no step 2 - other
                int stepCount = 0;
                int noStepCount = 0;
                double[] survivalCurve = new double[totPartNum];
                for(int partNum = 0;partNum<totPartNum;partNum++)
                    if(Math.abs(stepfits[2][partNum])<maxSecondMeanFirstMeanRatio*stepfits[1][partNum]){
                        stepfits[4][partNum] = 0;
                        survivalCurve[stepCount] = stepfits[0][partNum];
                        stepCount++;}
                else if(Math.abs(stepfits[2][partNum])>minNoStepSecondMeanFirstMeanRatio*stepfits[1][partNum]){stepfits[4][partNum] = 1;noStepCount++;}
                else stepfits[4][partNum] = 2;

                survivalCurve = Arrays.copyOf(survivalCurve,stepCount);
                Arrays.sort(survivalCurve,0,survivalCurve.length);

                Plot plot2;
                double[] toplot = new double[totFrameNum];

                //plot examples
                String[] classNames = {"Single Steps", "No Step", "Other"};


                double[] frames = new double[totFrameNum];
                double[] stepframes = {0.0, 1.0, 1.0, totFrameNum*timePerFrame};
                double[] stepToPlot = new double[4];
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++) frames[frameNum] = frameNum*timePerFrame;
                for (int classToPlot = 0; classToPlot < 3; classToPlot++) {
                    ImageStack imstackin = new ImageStack(plotWidth, plotHeight);
                    int plotcount = 0;
                    for (int partNum = 0; partNum < totPartNum; partNum++) {
                        if (stepfits[4][partNum] == classToPlot) {
                            plotcount++;
                            if(plotcount<startTrace+1)continue;
                            plot2 = new Plot("Particle " + String.valueOf(partNum + 1), "Time ("+timePerFrameUnits+")", "Intensity");
                            plot2.setFrameSize(400, 250);
                            PlotWindow.noGridLines = true;
                            plot2.setAxisLabelFont(Font.BOLD, 40);
                            plot2.setFont(Font.BOLD, 40);
                            plot2.setLineWidth(6);
                            plot2.addLabel(0.25,0,"No. "+String.valueOf(partNum + 1)+" X "+String.valueOf(filteredROIs.get(partNum).x+filteredROIs.get(partNum).width/2)+" Y "+String.valueOf(filteredROIs.get(partNum).y+filteredROIs.get(partNum).height/2));
                            plot2.setColor(mycolour.get(0));
                            for (int framenum = 0; framenum < totFrameNum; framenum++) {
                                toplot[framenum] = traces[channelToStepFit][framenum][partNum];
                            }
                            plot2.add("line", frames, toplot);
                            stepframes[1] = stepfits[0][partNum]*timePerFrame;
                            stepframes[2] = (stepfits[0][partNum] + 1)*timePerFrame;
                            stepToPlot[0] = stepfits[1][partNum];
                            stepToPlot[1] = stepfits[1][partNum];
                            stepToPlot[2] = stepfits[2][partNum];
                            stepToPlot[3] = stepfits[2][partNum];
                            plot2.setColor(mycolour.get(1));
                            plot2.add("line", stepframes, stepToPlot);
                            plot2.setLimitsToFit(true);
                            plot2.draw();
                            double[] limitsOut = plot2.getLimits();
                            limitsOut[0] = Math.min(limitsOut[0],0.0);
                            limitsOut[2] = Math.min(limitsOut[2],0.0);
                            plot2.setLimits(limitsOut[0],limitsOut[1] ,limitsOut[2] ,limitsOut[3]);
                            plot2.draw();
                            ImagePlus plotIm2 = plot2.makeHighResolution("Particle " + String.valueOf(partNum + 1), 1, true, false);
                            if(imstackin.size()==0)imstackin = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
                            imstackin.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                            if (plotcount >= startTrace+36) break;
                        }
                    }
                    if(imstackin.size()>0) {
                        ImagePlus outputImStack = new ImagePlus(classNames[classToPlot], imstackin);
                        MontageMaker myMaker = new MontageMaker();
                        ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, imstackin.size(), 1, 0, false);
                        outputMontage.setTitle(classNames[classToPlot]);
                        outputMontage.show();
                        if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_"+classNames[classToPlot]+"_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                    }
                }//end plotting examples


                //Survival Analysis

                double[] survivalCurveX = new double[totFrameNum];
                double[] survivalCurveY = new double[totFrameNum];
                int partCount = 0;
                for(int i=0;i<totFrameNum;i++){
                    while(survivalCurve[partCount]-0.001<i && partCount+1<survivalCurve.length)partCount++;
                    survivalCurveX[i] = i*timePerFrame;
                    survivalCurveY[i] = stepCount-partCount+noStepCount;
                    //System.out.println(String.valueOf(i)+" "+String.valueOf(partCount)+" "+String.valueOf((int)(survivalCurve[partCount]))+" "+String.valueOf(stepCount)+" "+String.valueOf(noStepCount)+" "+String.valueOf(survivalCurve[0]));
                }


                myLeastSquare myLS = new myLeastSquare();
                double[] expFit = myLS.fitExp(survivalCurveX,survivalCurveY);
                double[] expFitY = new double[totFrameNum];
                for(int i=0;i<totFrameNum;i++){
                    expFitY[i] = expFit[0]+expFit[1]*Math.exp(-1.0*expFit[2]*survivalCurveX[i]);
                }

                plot2 = new Plot("Survival Curve Mean = "+IJ.d2s(1/expFit[2],2)+" Observed = "+IJ.d2s(100-100*Math.exp(-1.0*expFit[2]*(totFrameNum-1)),0)+"%"
                        +" Count = "+IJ.d2s(expFit[1],0)+" Offset = "+IJ.d2s(expFit[0],0)+" Raw Steps Count = "+survivalCurve.length+" All Particles = "+totPartNum, "Time ("+timePerFrameUnits+")", "Remaining Particles");
                plot2.setFrameSize(400, 250);
                PlotWindow.noGridLines = true;
                plot2.setAxisLabelFont(Font.BOLD, 40);
                plot2.setFont(Font.BOLD, 40);
                plot2.setLineWidth(6);
                plot2.setColor(mycolour.get(2));
                plot2.add("line", survivalCurveX, expFitY);
                plot2.setColor(mycolour.get(0));
                plot2.add("line", survivalCurveX, survivalCurveY);
                plot2.setLimitsToFit(true);
                plot2.draw();
                double[] limitsOut = plot2.getLimits();
                limitsOut[0] = Math.min(limitsOut[0],0.0);
                limitsOut[2] = Math.min(limitsOut[2],0.0);
                plot2.setLimits(limitsOut[0],limitsOut[1] ,limitsOut[2] ,limitsOut[3]);
                plot2.draw();
                plot2.show();
                if(saveTraces) new FileSaver(plot2.getImagePlus()).saveAsPng(getFolderName()+"Stepfit_Survival_Mean_"+IJ.d2s(1/expFit[2],2)+"_Observed_"+IJ.d2s(100-100*Math.exp(-1.0*expFit[2]*(totFrameNum-1)),0)+"%_Count_"
                        +IJ.d2s(expFit[1],0)+"_Offset_"+IJ.d2s(expFit[0],0)+"_Raw_Steps_Count_"+survivalCurve.length+"_All_Particles_"+totPartNum+".png");


                //Step Height Histogram
                double[] stepHeights = new double[stepCount];
                int count = 0;
                for (int partNum = 0; partNum < totPartNum; partNum++)
                    if (stepfits[4][partNum] == 0){
                        stepHeights[count] = stepfits[1][partNum]-stepfits[2][partNum];
                        count++;
                    }
                MakeHistogram myHistMaker = new MakeHistogram();
                double[][] histData = myHistMaker.makeHistogram(stepHeights);

                double meanStepHeight= Arrays.stream(stepHeights).sum()/stepHeights.length;

                plot2 = new Plot("Step Heights - Fit Mean = "+IJ.d2s(meanStepHeight,2), "Intensity", "Density");
                plot2.setFrameSize(400, 250);
                PlotWindow.noGridLines = true;
                plot2.setAxisLabelFont(Font.BOLD, 40);
                plot2.setFont(Font.BOLD, 40);
                plot2.setLineWidth(6);
                plot2.setColor(mycolour.get(0));
                plot2.add("line", histData[0], histData[1]);
                plot2.setLimitsToFit(true);
                plot2.draw();
                limitsOut = plot2.getLimits();
                limitsOut[0] = Math.min(limitsOut[0],0.0);
                limitsOut[2] = Math.min(limitsOut[2],0.0);
                plot2.setLimits(limitsOut[0],limitsOut[1] ,limitsOut[2] ,limitsOut[3]);
                plot2.draw();
                plot2.show();
                if(saveTraces) new FileSaver(plot2.getImagePlus()).saveAsPng(getFolderName()+"Stepfit_StepHeight.png");


            }
        });
        batchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                Runnable batchRunnable = () -> {
                    try {
                        outputDisplay = false;
                        saveTraces = true;
                        for (int posCount = 0; posCount < totPosNum; posCount++) {
                            statusText.setText("Batch File "+String.valueOf(posCount) + " / " + String.valueOf(totPosNum));
                            posNum = posCount;

                            Thread myThread = new Thread(imageForDetectRunnable);
                            myThread.start();
                            myThread.join();

                            myThread = new Thread(detectRunnable);
                            myThread.start();
                            myThread.join();

                            myThread = new Thread(measureTracesRunnable);
                            myThread.start();
                            myThread.join();
                            if(batchStepFit) {
                                myThread = new Thread(stepFitRunnbale);
                                myThread.start();
                                myThread.join();
                            }

                        }


                        statusText.setText("Batch File "+String.valueOf(totPosNum) + " / " + String.valueOf(totPosNum));
                    } catch (Exception e1) {
                        System.out.println(e1);
                    }
                };
                Thread batchThread = new Thread(batchRunnable);
                batchThread.start();

            }
        });
        browseButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                JFileChooser fileChooser = new JFileChooser(batchDirectoryBox.getText());
                fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
                int option = fileChooser.showOpenDialog(null);
                if(option == JFileChooser.APPROVE_OPTION){
                    File file = fileChooser.getSelectedFile();
                    batchDirectoryBox.setText(file.getAbsolutePath());
                }
            }
        });



        filesDropDownMenu.addPopupMenuListener(new PopupMenuListener() {
            @Override
            public void popupMenuWillBecomeVisible(PopupMenuEvent popupMenuEvent) {
                List<DataViewer> allDisplays = myDisplayManager.getAllDataViewers();
                filesDropDownMenu.removeAllItems();
                for(DataViewer dataIn : allDisplays){
                    filesDropDownMenu.addItem(dataIn.getName());
                }
            }

            @Override
            public void popupMenuWillBecomeInvisible(PopupMenuEvent popupMenuEvent) {
                List<DataViewer> allDisplays =myDisplayManager.getAllDataViewers();
                myDataViewer = null;
                for(DataViewer dataIn : allDisplays){
                    if(filesDropDownMenu.getSelectedItem().toString().equalsIgnoreCase(dataIn.getName())){
                        myDataViewer = dataIn;
                        break;
                    }
                }
                if(myDataViewer==null){
                    System.out.println("Error - Window not found");
                    statusText.setText("Error - Window not found");
                    return;
                }

                myDataProvider = myDataViewer.getDataProvider();
                newcoordsBuilder = myDataViewer.getDisplayPosition().copyBuilder();
                totChanNum = myDataProvider.getNextIndex("channel");
                totFrameNum = myDataProvider.getNextIndex("time");
                totPosNum = myDataProvider.getNextIndex("position");
                currentFrame = newcoordsBuilder.build().getT();
                currentPos = newcoordsBuilder.build().getP();
                batchDirectoryBox.setText(myDataProvider.getSummaryMetadata().getDirectory());

                try {
                    totImageWidth = myDataProvider.getAnyImage().getWidth();
                    totImageHeight = myDataProvider.getAnyImage().getHeight();
                    fullImageRec = new Rectangle(0,0,totImageWidth,totImageHeight);
                } catch (java.io.IOException e1) {
                    statusText.setText("Error!!! no image detected!!! ");
                    System.out.println("Error!!! no image detected!!! ");
                    return;
                }

            }

            @Override
            public void popupMenuCanceled(PopupMenuEvent popupMenuEvent) {
            }

        });

        helpButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                try {
                    if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
                        Desktop.getDesktop().browse(new URI("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/Jimbob.html"));
                    }
                }catch(Exception e1){
                    GenericDialog gd = new GenericDialog("Error opening browser");
                    gd.addMessage("Error opening help page. Click the help button or manually enter the website:");
                    gd.addMessage("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/Jimbob.html");
                    gd.addHelp("https://jim-immobilized-microscopy-suite.readthedocs.io/en/latest/Jimbob.html");
                    gd.showDialog();
                }
            }
        });
    }


}
