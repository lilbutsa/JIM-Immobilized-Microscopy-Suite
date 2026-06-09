package org.micromanager.plugins.Poor_Mans_JIM;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.gui.*;
import ij.io.FileSaver;
import ij.plugin.HyperStackConverter;
import ij.plugin.MontageMaker;
import ij.process.FloatProcessor;
import ij.process.ImageProcessor;
import ij.process.ShortProcessor;
import org.micromanager.Studio;
import org.micromanager.data.Coords;
import org.micromanager.data.DataProvider;
import org.micromanager.data.Datastore;
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

    //Display components
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
    private JTextField driftMaxShiftBox;
    private JCheckBox displayAlignedStackBox;
    private JCheckBox saveTracesBox;
    private JTextField Align_Channel_Select;
    private JButton helpButton;
    private JTextField timePerFrameBox;
    private JTextField timePerFrameUnitsBox;
    private JButton inputAlignmentBT;
    private JButton detectAlignmentBT;
    private JComboBox FitTypeDropdown;
    private JTextField minFitFrameBox;
    private JTextField maxFitFrameBox;
    private JTextField washinFrameBox;
    private JButton addFitToBatchButton;
    private JButton showTracesBtn;
    private JTextField traceSelectBox;
    private JTextField minSeparationBox;
    private JComboBox normalizationDropDown;
    private JButton SelectTraceButton;
    private JTextField NormChannelBox;
    private JButton clearFitBatchButton;
    private JCheckBox driftOnlyUsingDetectionChannelBox;

    //Micromanager hooks
    DisplayManager myDisplayManager;
    DataViewer  myDataViewer;
    DataProvider myDataProvider;
    Coords.Builder newcoordsBuilder ;

    //Basic Image Data
    int totChanNum,totFrameNum,totPosNum;
    int currentFrame, currentPos;
    int totPartNum;
    int totImageWidth,totImageHeight,totNOP;

    int plotWidth = 0;
    int plotHeight = 0;
    final List<Color> mycolour = Arrays.asList(Color.MAGENTA, Color.CYAN, Color.BLUE, Color.BLACK, Color.PINK);

    // Held images
    int[] rawImage16;
    float[] imageForDetection;
    int[] imageForAlignment;
    Rectangle fullImageRec, alignmentRectangle;

    Runnable imageForDetectRunnable,detectRunnable,measureTracesRunnable,stepFitRunnable,fitMeanRunnable,batchRunnable;

    int posNum;
    boolean outputDisplay;

    //Alignment Info
    int[] C2CalignmentX,C2CalignmentY;

    //Detection parameters
    boolean driftCorrectOnlyDetect = true,displayAlignedStack,saveTraces;
    int alignMaxShift,alignROILength,detectStart,detectEnd,alignChannel,minCount,maxCount,minDFE,channelToStepFit;
    double cutoff,minEccentricity,maxEccentricity,timePerFrame,minSeparation,padROI,padBackground;
    String timePerFrameUnits;

    //detection results
    ArrayList<ArrayList<Integer>> expandedForegroundPos,expandedBackgroundPos;
    double[][] myFilteredResults;

    //Traces results
    int[][] allDrifts;
    double[][][] traces=new double[0][0][0];
    double[][][] backTraces=new double[0][0][0];
    double[][] meanTrace, meanBackTrace;

    //Fit parameters
    boolean bNormalizeTraces;
    int fitType = 0;
    int fitMinFrame = 1, fitMaxFrame = -1, washinFrame = 1;
    double[][] stepfits;

    int normType = 0, normChannel = 1;
    double normConstVal = 0.0, bleachFrame = 1;

    //batchFitting
    ArrayList<Integer> batchFitType = new ArrayList<>(), batchChannelToFit = new ArrayList<>(),batchNormType = new ArrayList<>(),batchNormChannel = new ArrayList<>(),
            batchStartFrame = new ArrayList<>(), batchEndFrame = new ArrayList<>(), batchWashInFrame = new ArrayList<>();
    ArrayList<Double> batchNormConstVal = new ArrayList<>(), batchMeanPhotobleachRate = new ArrayList<>();

    //Held displays
    ImagePlus detectImStack;
    ImagePlus alignedImStack;


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
        driftCorrectOnlyDetect = driftOnlyUsingDetectionChannelBox.isSelected();
        alignChannel = Integer.parseInt(Align_Channel_Select.getText());
        if(alignChannel<0||alignChannel>totChanNum){
            alignChannel = 0;
            Align_Channel_Select.setText("0");
        }


        detectStart = Integer.parseInt(detectStartFrameBox.getText())-1;
        detectEnd = Integer.parseInt(detectEndFrameBox.getText());
        if(detectEnd<0)detectEnd = totFrameNum+detectEnd+1;

        cutoff = Double.parseDouble(cutoffBox.getText());
        minDFE = Integer.parseInt(minDFEBox.getText());
        minEccentricity = Double.parseDouble(minEccentricityBox.getText());
        maxEccentricity = Double.parseDouble(maxEccentricityBox.getText());
        minCount = Integer.parseInt(minCountBox.getText());
        maxCount = Integer.parseInt(maxCountBox.getText());
        minSeparation = Double.parseDouble(minSeparationBox.getText());
        padROI = Double.parseDouble(ROIPaddingBox.getText());
        padBackground = Double.parseDouble(sBackgroundWidth.getText());


        displayAlignedStack = displayAlignedStackBox.isSelected();
        saveTraces = saveTracesBox.isSelected();
        timePerFrame = Double.parseDouble(timePerFrameBox.getText());
        timePerFrameUnits = timePerFrameUnitsBox.getText();

        bNormalizeTraces = bNormalizeTracesBox.isSelected();



        fitMinFrame = Integer.parseInt(minFitFrameBox.getText());
        fitMaxFrame = Integer.parseInt(maxFitFrameBox.getText());
        washinFrame = Integer.parseInt(washinFrameBox.getText());
        //bleachFrame = Double.parseDouble(BleachFrameBox.getText());


        channelToStepFit = Integer.parseInt(channelToFitBox.getText())-1;
        if(channelToStepFit<0 || channelToStepFit>=totChanNum){
            channelToStepFit = 0;
            channelToFitBox.setText("1");
        }

        if(normType == 7){
            normConstVal = Double.parseDouble(NormChannelBox.getText());
            if(normConstVal==0.0){
                normConstVal = 1;
                NormChannelBox.setText("1");
            }
        }
        else {
            normChannel = Integer.parseInt(NormChannelBox.getText()) - 1;
            if(normChannel<0 || normChannel>=totChanNum){
                normChannel = 0;
                NormChannelBox.setText("1");
            }
        }
    }




    int getImage(int chanNum, int frameNum,int posNum){
        try {
            newcoordsBuilder = newcoordsBuilder.t(frameNum);
            newcoordsBuilder = newcoordsBuilder.c(chanNum);
            newcoordsBuilder = newcoordsBuilder.p(posNum);
            Coords nextCoords = newcoordsBuilder.build();
            totImageWidth = myDataProvider.getImage(nextCoords).getWidth();
            totImageHeight = myDataProvider.getImage(nextCoords).getHeight();
            totNOP = totImageWidth*totImageHeight;

            Object pixels = myDataProvider.getImage(nextCoords).getRawPixels();

            if (pixels instanceof short[]) {
                short[] src = (short[]) pixels;
                rawImage16 = new int[src.length];
                for (int i = 0; i < src.length; i++) {
                    rawImage16[i] = Short.toUnsignedInt(src[i]);
                }
            } else if (pixels instanceof byte[]) {
                byte[] src = (byte[]) pixels;
                rawImage16 = new int[src.length];
                for (int i = 0; i < src.length; i++) {
                    rawImage16[i] = Byte.toUnsignedInt(src[i]);
                }
            } else {
                throw new IllegalArgumentException("Unsupported pixel type: " + pixels.getClass().getName());
            }


        } catch (java.io.IOException e1) {
            System.out.println(e1);
            return 1;
        }

        return 0;
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

            if(fileName==null || fileName.isEmpty())fileName = folderName+File.separator+"Analysis"+File.separator;
            else fileName = folderName+File.separator+fileName.substring(0, Math.max(fileName.length() - 8,0))+File.separator;

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

        imageForDetectRunnable = this::imageForDetectFunc;
        detectRunnable = this::detectFunc;
        measureTracesRunnable = this::measureTracesFunc;
        stepFitRunnable = this::stepFitFunc;
        fitMeanRunnable = this::fitMeanFunc;

        batchRunnable = () -> {
            imageForDetectFunc();
            detectFunc();
            measureTracesFunc();
            for(int fitCount = 0;fitCount<batchFitType.size();fitCount++){
                fitType = batchFitType.get(fitCount);
                channelToStepFit = batchChannelToFit.get(fitCount);
                normType = batchNormType.get(fitCount);
                normChannel = batchNormChannel.get(fitCount);
                fitMinFrame = batchStartFrame.get(fitCount);
                fitMaxFrame = batchEndFrame.get(fitCount);
                washinFrame = batchWashInFrame.get(fitCount);
                normConstVal = batchNormConstVal.get(fitCount);
                bleachFrame = batchMeanPhotobleachRate.get(fitCount);

                if(fitType==0){
                    stepFitFunc();
                }
                else {
                    fitMeanFunc();
                }

            }
        };

        detectionImageButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                if(myDataViewer==null){
                    System.out.println("Error - Window not found");
                    return;
                }

                myDataProvider = myDataViewer.getDataProvider();
                newcoordsBuilder = myDataViewer.getDisplayPosition().copyBuilder();
                totChanNum = myDataProvider.getNextIndex("channel");
                totFrameNum = myDataProvider.getNextIndex("time");
                totPosNum = myDataProvider.getNextIndex("position");
                currentFrame = newcoordsBuilder.build().getT();
                currentPos = newcoordsBuilder.build().getP();
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


            }
        });



        stepFitButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                //stepfit
                parseParameters();
                if(fitType==4) {
                    GenericDialog gd = new GenericDialog("Input Bleach Frame", IJ.getInstance());
                    gd.addNumericField("Mean Bleach Frame = ", bleachFrame);
                    gd.showDialog();
                    if (gd.wasCanceled())
                        return;
                    bleachFrame = gd.getNextNumber();
                }

                if(fitType==0){
                    Thread myThread = new Thread(stepFitRunnable);
                    myThread.start();
                }
                else {
                    Thread myThread = new Thread(fitMeanRunnable);
                        myThread.start();
                }

            }
        });
        batchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                parseParameters();
                outputDisplay = false;
                saveTraces = true;
                Runnable batchRunnableIn = () -> {
                    try {

                        for (int posCount = 0; posCount < totPosNum; posCount++) {
                            posNum = posCount;
                            Thread myThread = new Thread(batchRunnable);
                            myThread.start();
                            myThread.join();

                        }


                    } catch (Exception e1) {
                        System.out.println(e1);
                    }
                };
                Thread batchThread = new Thread(batchRunnableIn);
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
                Object selected = filesDropDownMenu.getSelectedItem();
                if (selected == null) return;

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
                    return;
                }

                myDataProvider = myDataViewer.getDataProvider();
                newcoordsBuilder = myDataViewer.getDisplayPosition().copyBuilder();
                totChanNum = myDataProvider.getNextIndex("channel");
                totFrameNum = myDataProvider.getNextIndex("time");
                totPosNum = myDataProvider.getNextIndex("position");
                currentFrame = newcoordsBuilder.build().getT();
                currentPos = newcoordsBuilder.build().getP();
                batchDirectoryBox.setText(getCurrentDataDirectory());


                if(C2CalignmentX==null || C2CalignmentX.length<totChanNum-1) {
                    C2CalignmentX = new int[totChanNum - 1];
                    C2CalignmentY = new int[totChanNum - 1];
                }

                try {
                    totImageWidth = myDataProvider.getAnyImage().getWidth();
                    totImageHeight = myDataProvider.getAnyImage().getHeight();
                    totNOP = totImageWidth*totImageHeight;
                    fullImageRec = new Rectangle(0,0,totImageWidth,totImageHeight);

                    //get frame rate

                    newcoordsBuilder = newcoordsBuilder.t(0);
                    newcoordsBuilder = newcoordsBuilder.c(0);
                    newcoordsBuilder = newcoordsBuilder.p(currentPos);
                    Coords nextCoords = newcoordsBuilder.build();
                    double startTime= myDataProvider.getImage(nextCoords).getMetadata().getElapsedTimeMs(0);

                    newcoordsBuilder = newcoordsBuilder.t(totFrameNum-1);
                    nextCoords = newcoordsBuilder.build();
                    double endTime= myDataProvider.getImage(nextCoords).getMetadata().getElapsedTimeMs(0);

                    double calcTimePerFrame =totFrameNum>0? (double)Math.round((endTime-startTime)/(totFrameNum-1)/10)/100:0;

                    timePerFrameBox.setText(IJ.d2s(calcTimePerFrame,calcTimePerFrame>100?0:(calcTimePerFrame>10?1:(calcTimePerFrame>1?2:3))));

                } catch (java.io.IOException e1) {
                    System.out.println("Error!!! no image detected!!! ");
                    return;
                }

            }

            @Override
            public void popupMenuCanceled(PopupMenuEvent popupMenuEvent) {
            }

        });

        FitTypeDropdown.addPopupMenuListener(new PopupMenuListener() {
            @Override
            public void popupMenuWillBecomeVisible(PopupMenuEvent popupMenuEvent) {
                FitTypeDropdown.removeAllItems();

                FitTypeDropdown.addItem("Step Fit");
                FitTypeDropdown.addItem("Linear");
                FitTypeDropdown.addItem("Exponential");
                FitTypeDropdown.addItem("Nuc Pol");
                FitTypeDropdown.addItem("Nuc Pol with Input Bleaching");
                FitTypeDropdown.addItem("Nuc Pol with Fit Bleaching");

            }

            @Override
            public void popupMenuWillBecomeInvisible(PopupMenuEvent popupMenuEvent) {
                Object selected = FitTypeDropdown.getSelectedItem();
                if (selected == null) return;

                if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Step Fit")) fitType = 0;
                else if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Linear")) fitType = 1;
                else if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Exponential")) fitType = 2;
                else if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Nuc Pol")) fitType = 3;
                else if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Nuc Pol with Input Bleaching")) fitType = 4;
                else if(FitTypeDropdown.getSelectedItem().toString().equalsIgnoreCase("Nuc Pol with Fit Bleaching")) fitType = 5;
            }

            @Override
            public void popupMenuCanceled(PopupMenuEvent popupMenuEvent) {
            }

        });

        normalizationDropDown.addPopupMenuListener(new PopupMenuListener() {
            @Override
            public void popupMenuWillBecomeVisible(PopupMenuEvent popupMenuEvent) {
                normalizationDropDown.removeAllItems();

                normalizationDropDown.addItem("None");
                normalizationDropDown.addItem("Min Channel");
                normalizationDropDown.addItem("Max Channel");
                normalizationDropDown.addItem("Mean Channel");
                normalizationDropDown.addItem("First Frame Channel");
                normalizationDropDown.addItem("Last Frame Channel");
                normalizationDropDown.addItem("Each Frame Channel");
                normalizationDropDown.addItem("Constant Value");

            }

            @Override
            public void popupMenuWillBecomeInvisible(PopupMenuEvent popupMenuEvent) {
                Object selected = normalizationDropDown.getSelectedItem();
                if (selected == null) return;

                if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("None")) normType = 0;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Min Channel")) normType = 1;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Max Channel")) normType = 2;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Mean Channel")) normType = 3;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("First Frame Channel")) normType = 4;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Last Frame Channel")) normType = 5;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Each Frame Channel")) normType = 6;
                else if(normalizationDropDown.getSelectedItem().toString().equalsIgnoreCase("Constant Value")) normType = 7;
                else normType = 0;


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
        inputAlignmentBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {

                //if channel to channel alignment is not initialized then initialise to 0;
                if(C2CalignmentX==null || C2CalignmentX.length<totChanNum-1) {
                    C2CalignmentX = new int[totChanNum - 1];
                    C2CalignmentY = new int[totChanNum - 1];
                }

                GenericDialog gd = new GenericDialog("Input Alignment", IJ.getInstance());

                for(int i=0;i<totChanNum-1;i++) {
                    gd.addNumericField("Channel "+Integer.toString(i+2)+" x: ", C2CalignmentX[i], 1);
                    gd.addToSameRow();
                    gd.addNumericField("y: ", C2CalignmentY[i], 1);
                }

                gd.showDialog();
                if (gd.wasCanceled())
                    return;

                for(int i=0;i<totChanNum-1;i++) {
                    C2CalignmentX[i] = (int)gd.getNextNumber();
                    C2CalignmentY[i] = (int)gd.getNextNumber();
                }


            }
        });
        detectAlignmentBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                parseParameters();
                int C2CAlignStartFrame = 1, C2CAlignEndFrame = -1;
                GenericDialog gd = new GenericDialog("Select Range with signal in all channels", IJ.getInstance());
                gd.addNumericField("Start frame: ", C2CAlignStartFrame, 0);
                gd.addNumericField("End frame: ", C2CAlignEndFrame, 0);
                gd.showDialog();

                if (gd.wasCanceled())
                    return;

                C2CAlignStartFrame = (int)gd.getNextNumber();
                C2CAlignEndFrame = (int)gd.getNextNumber();

                //clamp values


                int finalC2CAlignStartFrame = C2CAlignStartFrame;
                int finalC2CAlignEndFrame = C2CAlignEndFrame;
                Runnable detectAlignmentRunnableIn = () -> {detectAlignmentFunc(finalC2CAlignStartFrame, finalC2CAlignEndFrame);};
                Thread detectAlignmentThread = new Thread(detectAlignmentRunnableIn);
                detectAlignmentThread.start();

            }
        });
        showTracesBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                //make trace page
                parseParameters();
                double[] frames = new double[totFrameNum];
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)frames[frameNum] = frameNum*timePerFrame;

                int startTrace = (Integer.parseInt(pageNumberBox.getText())-1)*36;

                Plot plot2 = new Plot("Particle " + String.valueOf(1), "Time ("+timePerFrameUnits+")", "Intensity");

                ImageStack imstackin = null;
                double[] toplot = new double[totFrameNum];
                for (int partNum = startTrace; partNum < Math.min(totPartNum, startTrace + 36); partNum++) {
                    plot2 = new Plot("Particle " + String.valueOf(partNum + 1), "Time ("+timePerFrameUnits+")", "Intensity");
                    plot2.setFrameSize(400, 250);
                    PlotWindow.noGridLines = true;
                    plot2.setAxisLabelFont(Font.BOLD, 40);
                    plot2.setFont(Font.BOLD, 40);
                    plot2.setLineWidth(6);

                    plot2.addLabel(0.2,0.01,"No. "+String.valueOf(partNum + 1)+" X "+String.valueOf((int)myFilteredResults[partNum][0])+" Y "+String.valueOf((int)myFilteredResults[partNum][1]));
                    for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                        plot2.setColor(mycolour.get(chanNum%mycolour.size()));
                        double maxval = 0;
                        for (int framenum = 0; framenum < totFrameNum; framenum++) {
                            toplot[framenum] = traces[chanNum][framenum][partNum];
                            if (toplot[framenum] > maxval) maxval = toplot[framenum];
                        }
                        if (bNormalizeTraces) for (int framenum = 0; framenum < totFrameNum; framenum++) {
                            if (maxval == 0) maxval = 1;
                            toplot[framenum] = toplot[framenum] / maxval;
                        }
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
                    if(imstackin==null)imstackin = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());

                    imstackin.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
                }
                if(imstackin!=null && imstackin.size()>0) {
                    ImagePlus outputImStack = new ImagePlus("Detection", imstackin);
                    MontageMaker myMaker = new MontageMaker();
                    ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, imstackin.size(), 1, 0, false);
                    //if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                    if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
                    outputMontage.show();
                }
            }
        });

        SelectTraceButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                int partNum = Integer.parseInt(traceSelectBox.getText())-1;
                Overlay myOverlay = new Overlay();
                myOverlay.add(new Roi(new
                        Rectangle((int)myFilteredResults[partNum][14],(int)myFilteredResults[partNum][16],
                        (int)(myFilteredResults[partNum][15]-myFilteredResults[partNum][14]),(int)(myFilteredResults[partNum][17]-myFilteredResults[partNum][16]))));

                if(alignedImStack != null && alignedImStack.isVisible()){
                    alignedImStack.setOverlay(myOverlay);
                    alignedImStack.show();
                }
                if(detectImStack != null && detectImStack.isVisible()){
                    detectImStack.setOverlay(myOverlay);
                    detectImStack.show();
                }

                //plot mean trace
                Plot plot = new Plot("No. "+String.valueOf(partNum + 1)+" X "+String.valueOf((int)myFilteredResults[partNum][0])+" Y "+String.valueOf((int)myFilteredResults[partNum][1]), "Time ("+timePerFrameUnits+")", "Intensity (a.u.)");
                plot.setFrameSize(400, 250);
                PlotWindow.noGridLines = true;
                plot.setAxisLabelFont(Font.BOLD, 40);
                plot.setFont(Font.BOLD, 40);
                plot.setLineWidth(6);
                //plot.addLabel(0.25,0,"Mean Trace");
                double[] frames = new double[totFrameNum];
                double[] toplot = new double[totFrameNum];
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)frames[frameNum] = frameNum*timePerFrame;
                for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                    for (int frameNum = 0; frameNum < totFrameNum; frameNum++)toplot[frameNum] = traces[chanNum][frameNum][partNum];
                    plot.setColor(mycolour.get(chanNum%mycolour.size()));
                    plot.add("line",frames, toplot.clone());
                }
                plot.setLimitsToFit(true);
              //  if(saveTraces) new FileSaver(plot.getImagePlus()).saveAsPng(getFolderName()+"Mean_Trace_"+traces[0][0].length+"_Particles.png");
                ImagePlus hiresImage = renderPlotImage(plot, "No. "+String.valueOf(partNum + 1)+" X "+String.valueOf((int)myFilteredResults[partNum][0])+" Y "+String.valueOf((int)myFilteredResults[partNum][1]), true);
                hiresImage.show();
            }


        });
        addFitToBatchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                parseParameters();
                //check if need to input bleach rate
                 if(fitType==4) {
                     GenericDialog gd = new GenericDialog("Input Bleach Frame", IJ.getInstance());
                     gd.addNumericField("Mean Bleach Frame = ", bleachFrame);
                     gd.showDialog();
                     if (gd.wasCanceled())
                         return;
                     bleachFrame = gd.getNextNumber();
                 }


                batchFitType.add(fitType);
                batchChannelToFit.add(channelToStepFit);
                batchNormType.add(normType);
                batchNormChannel.add(normChannel);
                batchStartFrame.add(fitMinFrame);
                batchEndFrame.add(fitMaxFrame);
                batchWashInFrame.add(washinFrame);
                batchNormConstVal.add(normConstVal);
                batchMeanPhotobleachRate.add(bleachFrame);

                JFrame frame = new JFrame("Current Fits");
                frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
                frame.setSize(500, 300);

                // 2. Define column headers
                String[] columns = {"Fit Type", "Channel to Fit", "Normalization Type", "Norm Channel/Value","Fit Start Frame","Fit End Frame","Wash In Frame"};

                // 3. Define raw table data
                String[][] myData = new String[batchFitType.size()][7];
                for(int i=0;i<batchFitType.size();i++){
                    if(batchFitType.get(i)==0) myData[i][0] = "Step Fit";
                    else if(batchFitType.get(i)==1) myData[i][0] = "Linear";
                    else if(batchFitType.get(i)==2) myData[i][0] = "Exponential";
                    else if(batchFitType.get(i)==3) myData[i][0] = "Nuc Pol";
                    else if(batchFitType.get(i)==4) myData[i][0] = "Nuc Pol w/ Input Bleaching";
                    else if(batchFitType.get(i)==5) myData[i][0] = "Nuc Pol w/ Fit Bleaching";

                    myData[i][1] = Integer.toString(batchChannelToFit.get(i));

                    if(batchNormType.get(i)==0) myData[i][2] = "None";
                    else if(batchNormType.get(i)==1) myData[i][2] = "Min Channel";
                    else if(batchNormType.get(i)==2) myData[i][2] = "Max Channel";
                    else if(batchNormType.get(i)==3) myData[i][2] = "Mean Channel";
                    else if(batchNormType.get(i)==4) myData[i][2] = "First Frame Channel";
                    else if(batchNormType.get(i)==5) myData[i][2] = "Last Frame Channel";
                    else if(batchNormType.get(i)==6) myData[i][2] = "Each Frame Channel";
                    else if(batchNormType.get(i)==7) myData[i][2] = "Constant Value";

                    if(batchNormType.get(i)==7)myData[i][3]=IJ.d2s(batchNormConstVal.get(i),2);
                    else myData[i][3] = Integer.toString(batchNormChannel.get(i));

                    myData[i][4] = Integer.toString(batchStartFrame.get(i));
                    myData[i][5] = Integer.toString(batchEndFrame.get(i));
                    myData[i][6] = Integer.toString(batchWashInFrame.get(i));

                }
                // 4. Create the JTable instance with data and columns
                JTable table = new JTable(myData, columns);

                // 5. Wrap the table in a JScrollPane to display headers and enable scrolling
                JScrollPane scrollPane = new JScrollPane(table);

                // 6. Add the scroll pane to the frame and display the window
                frame.add(scrollPane);
                frame.setLocationRelativeTo(null); // Centers the window on screen
                frame.setVisible(true);
            }
        });

        clearFitBatchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                batchFitType.clear();
                batchChannelToFit.clear();
                batchNormType.clear();
                batchNormChannel.clear();
                batchStartFrame.clear();
                batchEndFrame.clear();
                batchWashInFrame.clear();
                batchNormConstVal.clear();
                batchMeanPhotobleachRate.clear();
            }
        });
    }

    void imageForDetectFunc() {
        if (getImage(0, 0, posNum) != 0) return;
        myFFT aligner = new myFFT(alignROILength);


        //Declare summed image sizes

        int[] tempImageForAlign = new int[alignROILength*alignROILength];
        imageForAlignment = new int[alignROILength*alignROILength];
        imageForDetection = new float[totNOP];

        //Debug stuff delete when working
       /* ImageStack debugStack = new ImageStack(totImageWidth, totImageHeight);
        ImageStack debugStackCC = new ImageStack(alignROILength, alignROILength);
        float[] debugImage = new float[totNOP];
        */



        //set the bounds for channels that are used for detection and alignment
        int chanStart = 0,chanEnd = totChanNum;
        if(alignChannel>0){
            chanStart = alignChannel-1;
            chanEnd = alignChannel;
        }

        //Make an initial small stack to align everything to, up to the first 10 frames. Might need to make this number a variable in future
        double[] alignsum = new double[alignROILength*alignROILength];

        for (int frameNum = detectStart; frameNum < Math.min(detectEnd,detectStart+10); frameNum++) {
            //get sum of channels
            for (int chanNum = chanStart; chanNum < chanEnd; chanNum++) {
                if (getImage(chanNum, frameNum, posNum) != 0) return;

                int C2CAlignXin = (chanNum > 0 && C2CalignmentX.length >= chanNum) ? C2CalignmentX[chanNum - 1] : 0;
                int C2CAlignYin = (chanNum > 0 && C2CalignmentY.length >= chanNum) ? C2CalignmentY[chanNum - 1] : 0;

                for (int i = 0; i < alignROILength; i++)
                    for (int j = 0; j < alignROILength; j++) {
                        int xIn = Math.max(0, Math.min(totImageWidth  - 1, i + C2CAlignXin + alignmentRectangle.x));
                        int yIn = Math.max(0, Math.min(totImageHeight  - 1, j + C2CAlignYin + alignmentRectangle.y));
                        alignsum[i + j * alignROILength] = alignsum[i + j * alignROILength]+rawImage16[xIn + totImageWidth * yIn];
                    }

            }
        }

        for (int i = 0; i < alignROILength*alignROILength; i++)
            tempImageForAlign[i] = (int)(alignsum[i]/(Math.min(detectEnd-detectStart,10)*(chanEnd-chanStart)));

        aligner.set_Reference_log(tempImageForAlign, 10);

        int[] chanSum;

        for (int frameNum = detectStart; frameNum < detectEnd; frameNum++) {
            chanSum = new int[totNOP];
            //get sum of channels
            for (int chanNum = chanStart; chanNum < chanEnd; chanNum++) {
                if(getImage(chanNum, frameNum, posNum)!=0)return;

                int C2CAlignXin = (chanNum>0 && C2CalignmentX.length>=chanNum)?C2CalignmentX[chanNum-1]:0;
                int C2CAlignYin = (chanNum>0 && C2CalignmentY.length>=chanNum)?C2CalignmentY[chanNum-1]:0;

                for(int i=0;i<totImageWidth;i++)for(int j=0;j<totImageHeight;j++){
                    int xIn = Math.max(0, Math.min(totImageWidth-1, i+C2CAlignXin));
                    int yIn = Math.max(0, Math.min(totImageHeight-1, j+C2CAlignYin));
                    chanSum[i+j*totImageWidth] += rawImage16[xIn+totImageWidth*yIn];
                }

            }
            //align image

            for(int i=0;i<alignROILength;i++)for(int j=0;j<alignROILength;j++)
                tempImageForAlign[i+j*alignROILength] = (int)chanSum[alignmentRectangle.x+i+(alignmentRectangle.y+j)*totImageWidth];
            aligner.align(tempImageForAlign, alignMaxShift);
            int xDrift = aligner.maxXPos;
            int yDrift = aligner.maxYPos;

            //add aligned images to stack
            getROIImageFloat(chanSum, imageForDetection, fullImageRec,  xDrift, yDrift, true);

            //debug comment later
           /* getROIImageFloat(chanSum, debugImage, fullImageRec,  xDrift, yDrift, false);
            debugStack.addSlice(new FloatProcessor(totImageWidth, totImageHeight, debugImage.clone()));
            float[] debugCCTemp = new float[alignROILength*alignROILength];
            for(int i=0;i<alignROILength*alignROILength;i++)debugCCTemp[i] = (float)aligner.crosscorr[i];
            debugStackCC.addSlice(new FloatProcessor(alignROILength, alignROILength, debugCCTemp.clone()));*/
        }


        for(int i=0;i<alignROILength;i++)for(int j=0;j<alignROILength;j++)
            imageForAlignment[i+j*alignROILength] = (int)imageForDetection[alignmentRectangle.x+i+(alignmentRectangle.y+j)*totImageWidth];

        if(outputDisplay)SwingUtilities.invokeLater(new ImagePlus("Detection Image",new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone()))::show);

        //show debug comment out later
       /* ImagePlus debugIP = new ImagePlus("Hopefully Drift Corrected", debugStack);
        SwingUtilities.invokeLater(debugIP::show);
        ImagePlus debugCCIP = new ImagePlus("CrossCorrelation", debugStackCC);
        SwingUtilities.invokeLater(debugCCIP::show);*/
    }

    void detectFunc(){

        FloatProcessor meanFP = new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone());
        LapOfGauss logClass = new LapOfGauss(5);

        FloatProcessor logim = logClass.run(meanFP,true);
        float[] flogim = (float[])logim.getPixels();

        //find threshold based on std dev above mean for LoG image
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

        float threshold = (float) (mean+cutoff*stddev);
        byte[] detectIm = new byte[totNOP];
        float[] roiImageFloat = new float[totNOP];
        for(int i=0;i<flogim.length;i++)
            if(flogim[i]>threshold){
                detectIm[i]=1;
                roiImageFloat[i]=threshold;
            }


        //measure detected ROIs and filter
        ArrayList<ArrayList<Integer>> detectedPos = new ArrayList<>(),filteredPos = new ArrayList<>();
        ArrayList<Integer> toSelect = new ArrayList<>();
        double[][] myResults = ShapeFunctions.componentMeasurements( detectIm, totImageWidth,  detectedPos);
        System.out.println("Initial Particles Detected = "+detectedPos.size());

        for(int i=0;i<myResults.length;i++){
            if(myResults[i][10]>=minCount && myResults[i][10]<=maxCount && myResults[i][2]>=minEccentricity-0.001 && myResults[i][2]<=maxEccentricity+0.001
                    && myResults[i][14]>(minDFE) && myResults[i][15]<totImageWidth - (minDFE) && myResults[i][16]>(minDFE) && myResults[i][17]<totImageHeight - (minDFE) &&
                    myResults[i][18] > minSeparation)
                toSelect.add(i);
        }
        System.out.println("Filtered Particles Detected = "+toSelect.size());
        myFilteredResults = new double[toSelect.size()][19];
        for(int i=0;i<toSelect.size();i++){
            filteredPos.add(detectedPos.get(toSelect.get(i)));
            myFilteredResults[i] = myResults[toSelect.get(i)];
        }

        //Expand shapes
        expandedForegroundPos = new ArrayList<>();
        expandedBackgroundPos = new ArrayList<>();
        ShapeFunctions.expandShapes(padROI, padBackground, filteredPos,detectedPos,totImageWidth,totImageHeight,expandedForegroundPos, expandedBackgroundPos);

        totPartNum = expandedForegroundPos.size();

        //display results if required
        if(outputDisplay){
            ImageStack imstackin = new ImageStack(totImageWidth, totImageHeight);
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone()));
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : filteredPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = threshold;
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : expandedForegroundPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = threshold;
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : expandedBackgroundPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = threshold;
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, roiImageFloat.clone()));

            Overlay detectedOverlay = new Overlay();

            detectImStack = new ImagePlus("Detection", imstackin);
            for(int i=0;i<totPartNum;i++)
                detectedOverlay.add(new Roi(new
                        Rectangle((int)myFilteredResults[i][14],(int)myFilteredResults[i][16],(int)(myFilteredResults[i][15]-myFilteredResults[i][14]+1),(int)(myFilteredResults[i][17]-myFilteredResults[i][16]+1))));
            detectImStack.setOverlay(detectedOverlay);

            SwingUtilities.invokeLater(detectImStack::show);

        }

        System.out.println("Particles Detected = "+totPartNum);



    }

    void measureTracesFunc(){

        int[][] allChanRawImage16 = new int[totChanNum][totNOP];

        int[] imageHold = new int[totNOP];
        short[] shortHold = new short[totNOP];

        allDrifts = new int[2][totFrameNum];
        int[] tempImageForAlign = new int[alignROILength*alignROILength];
        myFFT aligner = new myFFT(alignROILength);

        aligner.set_Reference_log(imageForAlignment,10);


        //calculate frames used for alignment
        int chanStart = 0,chanEnd = totChanNum;

        //Future add option to drift correct using all channels
        if(alignChannel>0 && driftCorrectOnlyDetect){
            chanStart = alignChannel-1;
            chanEnd = alignChannel;
        }

        ImageStack imstackin = new ImageStack(totImageWidth, totImageHeight);

        traces = new double[totChanNum][totFrameNum][totPartNum];
        backTraces =  new double[totChanNum][totFrameNum][totPartNum];

        for (int frameNum = 0; frameNum < totFrameNum; frameNum++) {
            //read images
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                int C2CAlignXin = (chanNum>0 && C2CalignmentX.length>=chanNum)?C2CalignmentX[chanNum-1]:0;
                int C2CAlignYin = (chanNum>0 && C2CalignmentY.length>=chanNum)?C2CalignmentY[chanNum-1]:0;

                if(getImage(chanNum, frameNum, posNum)!=0)return;
                getROIImageForAlign(rawImage16,allChanRawImage16[chanNum], fullImageRec, C2CAlignXin, C2CAlignYin,false);

            }

            //align images

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
                    getROIImageForAlign(allChanRawImage16[chanNum],imageHold, fullImageRec, allDrifts[0][frameNum], allDrifts[1][frameNum],false);
                    for (int holdCount = 0;holdCount<totNOP;holdCount++)shortHold[holdCount] = (short)imageHold[holdCount];
                    imstackin.addSlice(new ShortProcessor(totImageWidth, totImageHeight, shortHold.clone(),null));
                }
            }


            //calculate traces
            int xIn,yIn;
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                for (int partNum = 0; partNum < expandedForegroundPos.size(); partNum++) {
                    long foregroundSum = 0;
                    long backgroundSum = 0;
                    int foregroundCount = 0;
                    int backgroundCount = 0;
                    for(int i=0;i<expandedForegroundPos.get(partNum).size();i++){
                        xIn = expandedForegroundPos.get(partNum).get(i)%totImageWidth + allDrifts[0][frameNum];
                        yIn = expandedForegroundPos.get(partNum).get(i)/totImageWidth + allDrifts[1][frameNum];
                        if(xIn>=0 && yIn>=0 && xIn<totImageWidth && yIn<totImageHeight){
                            foregroundSum += allChanRawImage16[chanNum][xIn + yIn * totImageWidth];
                            foregroundCount++;
                        }
                    }
                    for(int i=0;i<expandedBackgroundPos.get(partNum).size();i++){
                        xIn = expandedBackgroundPos.get(partNum).get(i)%totImageWidth + allDrifts[0][frameNum];
                        yIn = expandedBackgroundPos.get(partNum).get(i)/totImageWidth + allDrifts[1][frameNum];
                        if(xIn>=0 && yIn>=0 && xIn<totImageWidth && yIn<totImageHeight){
                            backgroundSum += allChanRawImage16[chanNum][xIn + yIn * totImageWidth];
                            backgroundCount++;
                        }
                    }

                    // System.out.println(String.valueOf(foregroundSum)+" "+String.valueOf(backgroundSum)+" "+String.valueOf(pixelCountRatio)+" "+String.valueOf(foregroundSum - (backgroundSum * pixelCountRatio)));
                    if(foregroundCount>0 && backgroundCount>0) {
                        traces[chanNum][frameNum][partNum] = (foregroundSum - ((double)backgroundSum * foregroundCount / backgroundCount));
                        backTraces[chanNum][frameNum][partNum] = (double)backgroundSum / backgroundCount;
                    }
                }
            }
        }

        //Make Mean Trace
        meanTrace = new double[totChanNum][totFrameNum];
        meanBackTrace = new double[totChanNum][totFrameNum];
        for (int chanNum = 0; chanNum < totChanNum; chanNum++)
            for (int frameNum = 0; frameNum < totFrameNum; frameNum++)
                for (int partNum = 0; partNum < traces[0][0].length; partNum++) {
                    meanTrace[chanNum][frameNum] += traces[chanNum][frameNum][partNum] / traces[0][0].length;
                    meanBackTrace[chanNum][frameNum] += backTraces[chanNum][frameNum][partNum] / traces[0][0].length;
                }


        if(outputDisplay && displayAlignedStack) {
            alignedImStack = new ImagePlus("Aligned Stack ", imstackin);
            alignedImStack = new HyperStackConverter().toHyperStack(alignedImStack, totChanNum, 1, totFrameNum, "CZT", "grayscale");
            SwingUtilities.invokeLater(alignedImStack::show);
        }

        //make mean plots and save if needed

        double[][] meanNormedTrace = new double[totChanNum][totFrameNum];
        double maxval;
        if(bNormalizeTraces){
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                maxval = 0;
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)if(meanTrace[chanNum][frameNum]>maxval)maxval = meanTrace[chanNum][frameNum];
                if(maxval==0)maxval=1;
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)meanNormedTrace[chanNum][frameNum] = meanTrace[chanNum][frameNum]/maxval;
            }
        } else{
            for (int chanNum = 0; chanNum < totChanNum; chanNum++)
                for (int frameNum = 0; frameNum < totFrameNum; frameNum++)
                    meanNormedTrace[chanNum][frameNum] = meanTrace[chanNum][frameNum];
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
            plot.setColor(mycolour.get(chanNum%mycolour.size()));
            plot.add("line",frames, meanNormedTrace[chanNum]);
        }
        plot.setLimitsToFit(true);

        ImagePlus meanTracePlotImage = renderPlotImage(plot, "Mean Trace " + traces[0][0].length + " Particles", false);
        if (saveTraces) {
            new FileSaver(meanTracePlotImage).saveAsPng(getFolderName() + "Mean_Trace_" + traces[0][0].length + "_Particles.png");
        }
        if (outputDisplay) {
            SwingUtilities.invokeLater(meanTracePlotImage::show);
        }

        //plot background trace
        plot = new Plot("Mean Background Trace", "Time ("+timePerFrameUnits+")", "Intensity (a.u.)");
        plot.setFrameSize(400, 250);
        PlotWindow.noGridLines = true;
        plot.setAxisLabelFont(Font.BOLD, 40);
        plot.setFont(Font.BOLD, 40);
        plot.setLineWidth(6);
        for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
            plot.setColor(mycolour.get(chanNum%mycolour.size()));
            plot.add("line",frames, meanBackTrace[chanNum]);
        }
        plot.setLimitsToFit(true);

        ImagePlus backgroundPlotImage = renderPlotImage(plot, "Mean Background Trace", false);
        if (saveTraces) {
            new FileSaver(backgroundPlotImage).saveAsPng(getFolderName() + "Mean_Background_Trace.png");
        }
        if (outputDisplay) {
            SwingUtilities.invokeLater(backgroundPlotImage::show);
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
            plotDrift.setColor(mycolour.get(chanNum%mycolour.size()));
            plotDrift.add("line",frames, Arrays.stream(allDrifts[chanNum]).asDoubleStream().toArray());
        }
        plotDrift.setLimitsToFit(true);

        ImagePlus driftPlotImage = renderPlotImage(plotDrift, "Sample Drift", false);
        if (outputDisplay) {
            SwingUtilities.invokeLater(driftPlotImage::show);
        }



        if(saveTraces){
            try {
                String folderName = getFolderName();
                Files.createDirectories(Paths.get(folderName));

                String headerString = "xCentre,yCentre,eccentricity,xMajorAxis,yMajorAxis,length,xEnd1LinFit,yEnd1LinFit,xEnd2LinFit" +
                        ",yEnd2LinFit,count,xMaxPos,yMaxPos,maxDistFromLinear,xBoundingBoxMin,"+
                        "xBoundingBoxMax,yBoundingBoxMin,yBoundingBoxMax,nearestNeighbour";

                ShapeFunctions.writeCSV(folderName + "Detected_Filtered_Measurements.csv", myFilteredResults,headerString,false);

                for (int chanCount = 0; chanCount < totChanNum; chanCount++) {
                    ShapeFunctions.writeCSV(folderName + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Intensities.csv", traces[chanCount],"Each row is a particle. Each column is a Frame",true);
                    ShapeFunctions.writeCSV(folderName + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Backgrounds.csv", backTraces[chanCount],"Each row is a particle. Each column is a Frame",true);
                }
            }catch(Exception e) {
                System.out.println(e);
            }
        }//end writing out traces

    }

    void stepFitFunc(){

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
                    plot2.addLabel(0.25,0,"No. "+String.valueOf(partNum + 1)+" X "+String.valueOf((int)myFilteredResults[partNum][0])+" Y "+String.valueOf((int)myFilteredResults[partNum][1]));
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
                if(outputDisplay)SwingUtilities.invokeLater(outputMontage::show);
                if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_"+classNames[classToPlot]+"_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
            }
        }//end plotting examples


        //Survival Analysis

        double[] survivalCurveX = new double[totFrameNum];
        double[] survivalCurveY = new double[totFrameNum];
        int partCount = 0;
        for(int i=0;i<totFrameNum;i++){
            while(partCount+1<survivalCurve.length && survivalCurve[partCount]-0.001<i)partCount++;
            survivalCurveX[i] = i*timePerFrame;
            survivalCurveY[i] = stepCount-partCount+noStepCount;
            //System.out.println(String.valueOf(i)+" "+String.valueOf(partCount)+" "+String.valueOf((int)(survivalCurve[partCount]))+" "+String.valueOf(stepCount)+" "+String.valueOf(noStepCount)+" "+String.valueOf(survivalCurve[0]));
        }

        if(stepCount<3)return;
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

        ImagePlus survivalPlotImage = renderPlotImage(plot2, "Stepfit Survival", true);
        if(outputDisplay){
            SwingUtilities.invokeLater(survivalPlotImage::show);
        }
        if(saveTraces) new FileSaver(survivalPlotImage).saveAsPng(getFolderName()+"Stepfit_Survival_Mean_"+IJ.d2s(1/expFit[2],2)+"_Observed_"+IJ.d2s(100-100*Math.exp(-1.0*expFit[2]*(totFrameNum-1)),0)+"%_Count_"
                +IJ.d2s(expFit[1],0)+"_Offset_"+IJ.d2s(expFit[0],0)+"_Raw_Steps_Count_"+survivalCurve.length+"_All_Particles_"+totPartNum+".png");


        //Step Height Histogram
        double[] stepHeights = new double[stepCount];
        int count = 0;
        for (int partNum = 0; partNum < totPartNum; partNum++)
            if (stepfits[4][partNum] == 0){
                stepHeights[count] = stepfits[1][partNum]-stepfits[2][partNum];
                count++;
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
            }
        }


        if(stepHeights.length<3)return;

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

        ImagePlus histogramPlotImage = renderPlotImage(plot2, "Step Heights - Fit Mean = "+IJ.d2s(meanStepHeight,2), true);

        if(outputDisplay){
            SwingUtilities.invokeLater(histogramPlotImage::show);
        }
        if(saveTraces) new FileSaver(histogramPlotImage).saveAsPng(getFolderName()+"Stepfit_StepHeight.png");


    }

    void fitMeanFunc(){

        int startFrame = fitMinFrame<0?totFrameNum+fitMinFrame:fitMinFrame-1;
        int endFrame = fitMaxFrame<0?totFrameNum+fitMaxFrame+1:fitMaxFrame;

        int boundWashFrame = washinFrame<0?totFrameNum+washinFrame:washinFrame-1;

        if(startFrame<0)startFrame = 0;
        if(startFrame>=totFrameNum)startFrame = totFrameNum-1;
        if(endFrame<1)endFrame = 1;
        if(endFrame>totFrameNum)endFrame = totFrameNum;
        if(boundWashFrame<0)boundWashFrame = 0;
        if(boundWashFrame>=totFrameNum)boundWashFrame = totFrameNum-1;
        if(boundWashFrame>=endFrame)boundWashFrame = endFrame-1;

        if(startFrame>=endFrame)startFrame = endFrame-1;

        int fitNOF = endFrame-startFrame;

        double[] xIn = new double[fitNOF];
        double[] yIn = new double[fitNOF];
        double[] xFit = new double[endFrame-(boundWashFrame)];
        double[] yFit = new double[endFrame-(boundWashFrame)];

        for( int i=0;i<fitNOF;i++){
            xIn[i] = (i+startFrame-(boundWashFrame))*timePerFrame;
            //yIn[i] = meanTrace[channelToStepFit][i+startFrame];
        }

        if(normType==0) System.arraycopy(meanTrace[channelToStepFit], startFrame, yIn, 0, fitNOF);
        else if (normType == 7) {//const
            if(normConstVal == 0)normConstVal = 1;
            for( int i=0;i<fitNOF;i++)yIn[i] = meanTrace[channelToStepFit][i+startFrame]/normConstVal;
        }
        else
            for(int partCount=0;partCount<totPartNum;partCount++) {
                double normVal = 1;
                if (normType == 1) {//min
                    normVal = traces[normChannel][0][partCount];
                    for (int i = 0; i < totFrameNum; i++)
                        if (traces[normChannel][i][partCount] < normVal) normVal = traces[normChannel][i][partCount];
                } else if (normType == 2) {//max
                    normVal = traces[normChannel][0][partCount];
                    for (int i = 0; i < totFrameNum; i++)
                        if (traces[normChannel][i][partCount] > normVal) normVal = traces[normChannel][i][partCount];
                } else if (normType == 3) {//mean
                    normVal = 0;
                    for (int i = 0; i < totFrameNum; i++)
                        normVal = normVal+traces[normChannel][i][partCount];
                    normVal = normVal / totFrameNum;
                } else if (normType == 4) {//first
                    normVal = traces[normChannel][0][partCount];
                } else if (normType == 5) {//last
                    normVal = traces[normChannel][totFrameNum-1][partCount];
                } else if (normType == 6) {//each
                    for( int i=0;i<fitNOF;i++)yIn[i] += traces[channelToStepFit][i+startFrame][partCount]/traces[normChannel][i+startFrame][partCount]/totPartNum;
                }

                if (normType != 6)for( int i=0;i<fitNOF;i++)yIn[i] = yIn[i]+traces[channelToStepFit][i+startFrame][partCount]/(normVal*totPartNum);

            }


        for( int i=0;i<endFrame-(boundWashFrame);i++)xFit[i] = i*timePerFrame;

        double[] result;
        String resultString="",csvNameString="",csvFitString="";

        myLeastSquare myLS = new myLeastSquare();

        if(fitType==1){
            result = myLS.fitLinear(xIn,yIn);
            for( int i=0;i<xFit.length;i++)yFit[i] = result[0]+result[1]*xFit[i];
            resultString = "Linear Fit = "+IJ.d2s(result[0],2)+(result[1]>0?"+":"")+IJ.d2s(result[1],2)+"x";
            csvNameString = "Linear_Fit";
            csvFitString = "Fit Equation : y=a+bt, a =,"+result[0]+",b =,"+result[1]+"\n";
        }
        else if(fitType==2){
            result = myLS.fitExp(xIn,yIn);
            for( int i=0;i<xFit.length;i++)yFit[i] = result[0]+result[1]*Math.exp(-result[2]*xFit[i]);
            resultString = "Exp Fit="+IJ.d2s(result[0],2)+(result[1]>0?"+":"")+IJ.d2s(result[1],2)+"exp(-"+IJ.d2s(result[2],3)+"x)";
            csvNameString = "Exp_Fit";
            csvFitString = "Fit Equation : y=a+b*exp(-c*t), a =,"+result[0]+",b =,"+result[1]+",c =,"+result[2]+"\n";
        }
        else if(fitType==3){
            result = myLS.fitNucPolNoBleach(xIn,yIn);
            for( int i=0;i<xFit.length;i++)yFit[i] = result[0]*xFit[i]-result[0]/result[1]*(1-Math.exp(-result[1] * xFit[i]));
            resultString = "Polymerisation Rate="+ IJ.d2s(result[0],3)+"Int per "+timePerFrameUnits
                    +" Nucleation Frame="+IJ.d2s(1/result[1],3)+" "+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +" Frames";
            csvNameString = "Nuc_Pol_no_bleaching";
            csvFitString = "Fit Equation : y=p/n*(exp(-nt)+nt-1), p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+"\n";
        }
        else if(fitType==4){
            result = myLS.fitNucPolGivenBleach(xIn,yIn,1.0/(bleachFrame*timePerFrame));
            double p = result[0];
            double n = result[1];
            double b = 1.0/(bleachFrame*timePerFrame);
            for( int i=0;i<xFit.length;i++)yFit[i] =  p * (1-Math.exp(-n * xFit[i])+n/b*(Math.exp(-b * xFit[i])-1))/(b-n);
            resultString = "Polymerisation_Rate="+ IJ.d2s(result[0],3)+"_Int_per_"+timePerFrameUnits
                    +"_Nucleation_Frame="+IJ.d2s(1/result[1],3)+"_"+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +"_Frames";
            csvNameString = "Nuc_Pol_given_bleaching";
            csvFitString = "Fit Equation : y=p * (1-exp(-nt)+n/b*(exp(-bt)-1))/(b-n);, p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+",b (Bleach Rate(1/"+timePerFrameUnits+")) =,"+b+"\n";

        }
        else if(fitType==5){
            result = myLS.fitNucPolFitBleach(xIn,yIn);
            double p = result[0];
            double n = result[1];
            double b = result[2];
            for( int i=0;i<xFit.length;i++)yFit[i] =  p * (1-Math.exp(-n * xFit[i])+n/b*(Math.exp(-b * xFit[i])-1))/(b-n);
            resultString = "Polymerisation_Rate="+ IJ.d2s(result[0],3)+"_Int_per_"+timePerFrameUnits
                    +"_Nucleation_Frame="+IJ.d2s(1/result[1],3)+"_"+timePerFrameUnits+"="+IJ.d2s(1/(result[1]*timePerFrame),3)
                    +"_Frames__Fit_Bleach_Frame="+ IJ.d2s(1.0/(result[2]*timePerFrame),3);
            csvNameString = "Nuc_Pol_fit_bleaching";
            csvFitString = "Fit Equation : y=p * (1-exp(-nt)+n/b*(exp(-bt)-1))/(b-n);, p (Polymerisation Rate (Int./"+timePerFrameUnits+")) =,"+result[0]+",n(Nucleation Rate(1/"+timePerFrameUnits+")) =,"+result[1]+",b (Bleach Rate(1/"+timePerFrameUnits+")) =,"+b+"\n";

        }


        Plot plot2 = new Plot(resultString, "Time ("+timePerFrameUnits+")", "Intensity");
        plot2.setFrameSize(400, 250);
        PlotWindow.noGridLines = true;
        plot2.setAxisLabelFont(Font.BOLD, 40);
        plot2.setFont(Font.BOLD, 40);
        plot2.setLineWidth(6);
        plot2.setColor(mycolour.get(0));
        plot2.add("line", xIn, yIn);
        plot2.setColor(mycolour.get(1));
        plot2.add("line", xFit, yFit);

        plot2.setLimitsToFit(true);
        plot2.draw();


        ImagePlus fitPlotImage = renderPlotImage(plot2,resultString,true);

        if (saveTraces)
            new FileSaver(fitPlotImage).saveAsPng(
                    getFolderName() + "Channel_" + Integer.toString(channelToStepFit + 1) + "_" + csvNameString + ".png");

        if (outputDisplay)
            SwingUtilities.invokeLater(fitPlotImage::show);



        if(saveTraces) {

            //write out csv
            try {
                FileWriter myOutput = new FileWriter(getFolderName() + "Channel_" + Integer.toString(channelToStepFit + 1) + "_" + csvNameString + ".csv");
                myOutput.write(csvFitString);
                myOutput.write("All Mean Data Time("+timePerFrameUnits+"),All Mean Data Intensity,Fit Data Time("+timePerFrameUnits
                        +"),Fit Data Intensity,Fit Time("+timePerFrameUnits+"),Fit Data Intensity\n");

                String myLine;
                int allLength = meanTrace[channelToStepFit].length;
                for (int i = 0; i < Math.max(Math.max(allLength,xIn.length),xFit.length); i++) {
                    if(i<allLength) {
                        double x = (i-boundWashFrame)*timePerFrame;
                        double y = meanTrace[channelToStepFit][i];
                        myLine =IJ.d2s(x,3)+","+IJ.d2s(y,3)+",";
                    } else myLine = ",,";
                    if(i<xIn.length) {
                        myLine =myLine+IJ.d2s(xIn[i],3)+","+IJ.d2s(yIn[i],3)+",";
                    } else myLine = myLine+",,";
                    if(i<xFit.length) {
                        myLine =myLine+IJ.d2s(xFit[i],3)+","+IJ.d2s(yFit[i],3)+"\n";
                    } else myLine = myLine+",\n";
                    myOutput.write(myLine);

                }
                myOutput.close();
            } catch (Exception e) {
                System.out.println(e);
            }
        }
    }

    void detectAlignmentFunc(int C2CAlignStartFrame, int C2CAlignEndFrame){

        //add detection in here
        ImageStack imstackin = new ImageStack(totImageWidth, totImageHeight);
        C2CalignmentX = new int[totChanNum - 1];
        C2CalignmentY = new int[totChanNum - 1];

        myFFT aligner = new myFFT(alignROILength);
        int[] tempImageForAlign = new int[alignROILength*alignROILength];
        float[] tempAlignedImage = new float[totImageWidth*totImageHeight];

        if(C2CAlignStartFrame<0) C2CAlignStartFrame = totFrameNum+C2CAlignStartFrame;
        else C2CAlignStartFrame = C2CAlignStartFrame-1;

        if(C2CAlignEndFrame<0) C2CAlignEndFrame = totFrameNum+C2CAlignEndFrame+1;
        for (int chanNum = 0; chanNum < totChanNum; chanNum++) {

            int[] chanSum = new int[totNOP];
            for (int frameNum = C2CAlignStartFrame; frameNum < C2CAlignEndFrame; frameNum++) {
                if(getImage(chanNum, frameNum, posNum)!=0)return;
                for (int i = 0; i < totNOP; i++)chanSum[i] += (int)rawImage16[i];
            }
            //align image
            if (chanNum==0) {
                getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
                aligner.set_Reference_log(tempImageForAlign,10);

                //for display
                getROIImageFloat(chanSum,tempAlignedImage, fullImageRec,0, 0,false);
            } else{
                getROIImageForAlign(chanSum, tempImageForAlign, alignmentRectangle, 0, 0, false);
                aligner.align(tempImageForAlign, alignMaxShift);
                C2CalignmentX[chanNum-1] = aligner.maxXPos;
                C2CalignmentY[chanNum-1] = aligner.maxYPos;

                //for display
                getROIImageFloat(chanSum,tempAlignedImage, fullImageRec,aligner.maxXPos, aligner.maxYPos,false);

            }
            imstackin.addSlice(new FloatProcessor(totImageWidth, totImageHeight, tempAlignedImage.clone(),null));
        }

        String alignResult = "Aligned Channels";
        for(int i=0;i<C2CalignmentX.length;i++)alignResult = alignResult+" Channel "+Integer.toString(i+2)+" x:"+Integer.toString(C2CalignmentX[i])+" y: "+Integer.toString(C2CalignmentY[i]);

        ImagePlus outputImStack = new ImagePlus(alignResult, imstackin);
        SwingUtilities.invokeLater(outputImStack::show);
    }

    String getCurrentDataDirectory() {
        if (myDataViewer != null) {
            Datastore store = myDataViewer.getDatastore();
            if (store != null) {
                String savePath = store.getSavePath();
                if (savePath != null && !savePath.trim().isEmpty()) {
                    File file = new File(savePath);
                    if (file.isFile()) {
                        return file.getParent();
                    }
                    return file.getAbsolutePath();
                }
            }
        }

        String metadataDirectory = myDataProvider.getSummaryMetadata().getDirectory();
        return metadataDirectory == null ? "" : metadataDirectory;
    }

    ImagePlus renderPlotImage(Plot plot, String title, boolean includeZero) {
        plot.setLimitsToFit(true);
        plot.draw();

        if (includeZero) {
            double[] limits = plot.getLimits();
            limits[0] = Math.min(limits[0], 0.0);
            limits[2] = Math.min(limits[2], 0.0);
            plot.setLimits(limits[0], limits[1], limits[2], limits[3]);
            plot.draw();
        }

        return plot.makeHighResolution(title, 1.0f, true, false);
    }
}
