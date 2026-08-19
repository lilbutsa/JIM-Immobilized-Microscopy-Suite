package Jimbob;

import ij.IJ;
import ij.gui.*;
import org.micromanager.Studio;
import org.micromanager.display.DisplayManager;
import org.micromanager.display.DataViewer;


import javax.swing.*;
import javax.swing.event.PopupMenuEvent;
import javax.swing.event.PopupMenuListener;
import javax.swing.filechooser.FileFilter;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;

public class Jimbob_Window {
    public
    Jimbob_Window mainWindow;

    //Display components
    JPanel MainPanel;
     JButton detectionImageButton;
     JTextField AlignROISizeTextBox;
     JTextField sBackgroundWidth;
     JCheckBox bNormalizeTracesBox;
     JButton detectParticlesButton;
     JTextField detectStartFrameBox;
     JTextField detectEndFrameBox;
     JTextField cutoffBox;
     JTextField ROIPaddingBox;
     JTextField minEccentricityBox;
     JTextField maxEccentricityBox;
     JTextField minCountBox;
     JTextField maxCountBox;
     JTextField minDFEBox;
     JButton GenerateTracesButton;
     JTextField pageNumberBox;
     JButton fitButton;
     JButton batchButton;
     JTextField batchDirectoryBox;
     JButton browseButton;
     JComboBox filesDropDownMenu;
     JTextField driftMaxShiftBox;
     JCheckBox displayAlignedStackBox;
     JCheckBox saveTracesBox;
     JTextField Align_Channel_Select;
     JButton helpButton;
     JTextField timePerFrameBox;
     JTextField timePerFrameUnitsBox;
     JButton inputAlignmentBT;
     JButton detectAlignmentBT;
     JButton addFitToBatchButton;
     JButton showTracesBtn;
     JTextField traceSelectBox;
     JTextField minSeparationBox;
     JButton SelectTraceButton;
     JButton clearFitBatchButton;
     JCheckBox driftOnlyUsingDetectionChannelBox;
     JButton importParametersBtn;
     JButton SaveParametersBtn;
     JComboBox allFitsDropdown;
     JButton overwriteFitButton;

    DisplayManager myDisplayManager;
    DataViewer myDataViewer;
    List<DataViewer> allDisplays;

    int analysisStage = 0;
    //data
    paramsClass params;
    rawDataHandler rawData;
    //held results
    detectParticlesClass detected;
    measureTracesClass measured;
    fittingMainClass fitted;

    public Jimbob_Window(Studio studioin) {
        myDisplayManager = studioin.getDisplayManager();
        myDataViewer=null;

        mainWindow = this;

        params = new paramsClass();
        params.allFits = new ArrayList<>();

        detected = new detectParticlesClass();
        measured = new measureTracesClass();
        fitted = new fittingMainClass();

        detectionImageButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                if(myDataViewer==null || analysisStage == 0){
                    System.out.println("Error - Window not found");
                    IJ.error("No image selected or window not found!");
                    return;
                }

                rawData = new rawDataHandler(myDataViewer);
                params.posNum = rawData.getCurrentPos();
                params.parseParameters(mainWindow);

                Runnable imageForDetectRunnable = ()-> {
                    rawDataHandler dataIn = new rawDataHandler(rawData);
                    paramsClass paramsIn = new paramsClass(params);
                    detected.imageForDetectFunc(dataIn,paramsIn,true);
                    analysisStage = 2;
                };

                Thread detectThread = new Thread(imageForDetectRunnable);
                detectThread.start();

            }

        });

        detectParticlesButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {

                if(analysisStage < 2){
                    System.out.println("Error - Generate Detection Image First");
                    IJ.error("Generate Detection Image First!");
                    return;
                }

                params.parseParameters(mainWindow);

                Runnable detectRunnable = ()-> {
                    paramsClass paramsIn = new paramsClass(params);
                    detected.detectFunc(paramsIn,true);
                    analysisStage = 3;
                };

                Thread detectThread = new Thread(detectRunnable);
                detectThread.start();

            }
        });

        GenerateTracesButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {

                if(analysisStage < 3){
                    System.out.println("Error - Detect ROIs First");
                    IJ.error("Detect ROIs First!");
                    return;
                }

                params.parseParameters(mainWindow);
                Runnable measureTracesRunnable = ()-> {
                    rawDataHandler dataIn = new rawDataHandler(rawData);
                    paramsClass paramsIn = new paramsClass(params);
                    detectParticlesClass detectedIn = new detectParticlesClass(detected);

                    measured.measureTracesFunc(dataIn, detectedIn, paramsIn,true);
                    analysisStage =4;
                };

                Thread measureTraceThread = new Thread(measureTracesRunnable);
                measureTraceThread.start();


            }
        });

        fitButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                //stepfit

                if(analysisStage < 4){
                    System.out.println("Error - Generate Traces First");
                    IJ.error("Generate Traces First!");
                    return;
                }
                params.parseParameters(mainWindow);
                if(params.selectedFit!=-1) {

                    Runnable fitMeanRunnable = () -> {
                        paramsClass paramsIn = new paramsClass(params);

                        paramsIn.allFits.get(paramsIn.selectedFit).fitMain(measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).fitChannel],
                                measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).fitNormChannel],
                                measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).alignChannel],
                                measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).alignNormChannel],true
                                );

                        analysisStage = 5;
                    };

                    Thread fitThread = new Thread(fitMeanRunnable);
                    fitThread.start();
                }
            }
        });


        batchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent actionEvent) {
                params.parseParameters(mainWindow);
                params.saveTraces = true;

                Runnable batchRunnable = () -> {
                    paramsClass paramsIn = new paramsClass(params);
                    for (int posCount = 0; posCount < rawData.totPosNum; posCount++) {
                        paramsIn.posNum = posCount;
                        paramsIn.fileBase = rawData.getFolderName(paramsIn.posNum,paramsIn.folderName,paramsIn.saveTraces);



                        detected.imageForDetectFunc(rawData, paramsIn, false);
                        detected.detectFunc(paramsIn,false);
                        measured.measureTracesFunc(rawData, detected, paramsIn,false);
                        for(int fitCount = 0;fitCount<params.allFits.size();fitCount++){
                            paramsIn.selectedFit = fitCount;
                            paramsIn.allFits.get(paramsIn.selectedFit).saveTraces = true;
                            paramsIn.allFits.get(paramsIn.selectedFit).fileBase = paramsIn.fileBase+"Fit_"+(fitCount+1)+paramsIn.allFits.get(fitCount).fitNameNoSpaces+ File.separator;
                            paramsIn.allFits.get(paramsIn.selectedFit).fitMain(measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).fitChannel],
                                    measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).fitNormChannel],
                                    measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).alignChannel],
                                    measured.tracesCPF[paramsIn.allFits.get(paramsIn.selectedFit).alignNormChannel],false
                            );
                        }

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
                allDisplays = myDisplayManager.getAllDataViewers();
                filesDropDownMenu.removeAllItems();
                for(DataViewer dataIn : allDisplays){
                    filesDropDownMenu.addItem(dataIn.getName());
                }
            }

            @Override
            public void popupMenuWillBecomeInvisible(PopupMenuEvent popupMenuEvent) {
                int selected = filesDropDownMenu.getSelectedIndex();
                if (selected == -1) return;

                myDataViewer = allDisplays.get(selected);

                if(myDataViewer==null){
                    System.out.println("Error - Window not found");
                    return;
                }

                rawData=new rawDataHandler(myDataViewer);

                batchDirectoryBox.setText(rawData.getCurrentDataDirectory());

                if(params.C2CalignmentX==null || params.C2CalignmentX.length<rawData.totChanNum-1) {
                    params.C2CalignmentX = new int[rawData.totChanNum - 1];
                    params.C2CalignmentY = new int[rawData.totChanNum - 1];
                }

                //get frame rate
                double calcTimePerFrame = rawData.getFrameInterval();
                timePerFrameBox.setText(IJ.d2s(calcTimePerFrame,calcTimePerFrame>100?0:(calcTimePerFrame>10?1:(calcTimePerFrame>1?2:3))));

                analysisStage = 1;
            }

            @Override
            public void popupMenuCanceled(PopupMenuEvent popupMenuEvent) {
            }

        });


        allFitsDropdown.addPopupMenuListener(new PopupMenuListener() {
            @Override
            public void popupMenuWillBecomeVisible(PopupMenuEvent popupMenuEvent) {
                allFitsDropdown.removeAllItems();
                for(int i=0;i<params.allFits.size();i++){
                    allFitsDropdown.addItem(params.allFits.get(i).fitNameString);
                }
            }

            @Override
            public void popupMenuWillBecomeInvisible(PopupMenuEvent popupMenuEvent) {
                params.selectedFit = allFitsDropdown.getSelectedIndex();



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
                if(params.C2CalignmentX==null || params.C2CalignmentX.length<rawData.totChanNum-1) {
                    params.C2CalignmentX = new int[rawData.totChanNum - 1];
                    params.C2CalignmentY = new int[rawData.totChanNum - 1];
                }

                GenericDialog gd = new GenericDialog("Input Alignment", IJ.getInstance());

                for(int i=0;i<rawData.totChanNum-1;i++) {
                    gd.addNumericField("Channel "+Integer.toString(i+2)+" x: ", params.C2CalignmentX[i], 1);
                    gd.addToSameRow();
                    gd.addNumericField("y: ", params.C2CalignmentY[i], 1);
                }

                gd.showDialog();
                if (gd.wasCanceled())
                    return;

                for(int i=0;i<rawData.totChanNum-1;i++) {
                    params.C2CalignmentX[i] = (int)gd.getNextNumber();
                    params.C2CalignmentY[i] = (int)gd.getNextNumber();
                }


            }
        });
        detectAlignmentBT.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                params.parseParameters(mainWindow);
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
                Runnable detectAlignmentRunnableIn = () -> {
                    detected.detectAlignmentFunc(rawData,params,finalC2CAlignStartFrame,finalC2CAlignEndFrame);
                };
                Thread detectAlignmentThread = new Thread(detectAlignmentRunnableIn);
                detectAlignmentThread.start();

            }
        });
        showTracesBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                int pageNo = Integer.parseInt(pageNumberBox.getText());
                params.parseParameters(mainWindow);
                measured.plotPageOfTraces(pageNo,params,detected);
            }
        });

        SelectTraceButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                int partNum = Integer.parseInt(traceSelectBox.getText())-1;
                Overlay myOverlay = new Overlay();
                myOverlay.add(new Roi(new
                        Rectangle((int)detected.myFilteredResults[partNum][14]-(int)params.padROI,
                        (int)detected.myFilteredResults[partNum][16]-(int)params.padROI,
                        (int)(detected.myFilteredResults[partNum][15]-detected.myFilteredResults[partNum][14]+2*params.padROI),
                        (int)(detected.myFilteredResults[partNum][17]-detected.myFilteredResults[partNum][16]+2*params.padROI))));

                if(measured.alignedImStack != null && measured.alignedImStack.isVisible()){
                    measured.alignedImStack.setOverlay(myOverlay);
                    measured.alignedImStack.show();
                }
                if(detected.detectImStack != null && detected.detectImStack.isVisible()){
                    detected.detectImStack.setOverlay(myOverlay);
                    detected.detectImStack.show();
                }

                //plot Selected trace
                measured.plotSingleTrace(partNum,params);

            }

        });

        addFitToBatchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(params==null)return;
                params.parseParameters(mainWindow);
                //check if there is need to input bleach rate
                fittingMainClass newFit = new fittingMainClass();
                int success = newFit.inputParametersFromGUI();


                if(success ==0) {
                    params.allFits.add(newFit);
                    allFitsDropdown.removeAllItems();
                    for(int i=0;i<params.allFits.size();i++){
                        allFitsDropdown.addItem(params.allFits.get(i).fitNameString);
                    }
                    allFitsDropdown.setSelectedIndex(params.allFits.size() - 1);
                }


            }
        });

        overwriteFitButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(params==null)return;

                params.parseParameters(mainWindow);
                //check if there is need to input bleach rate
                if(params.selectedFit==-1 || params.allFits.size()<=params.selectedFit)return;
                fittingMainClass newFit = new fittingMainClass(params.allFits.get(params.selectedFit));
                int success = newFit.inputParametersFromGUI();

                if(success ==0)params.allFits.set(params.selectedFit,newFit);
                allFitsDropdown.setSelectedIndex(params.selectedFit);
            }
        });

        clearFitBatchButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if(params==null)return;
                params.parseParameters(mainWindow);
                params.allFits.remove(params.selectedFit);
                allFitsDropdown.setSelectedIndex(0);
            }
        });
        importParametersBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {

                JFileChooser fileChooser = new JFileChooser(batchDirectoryBox.getText());
                fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
                fileChooser.setFileFilter(new FileFilter() {
                    public String getDescription() {
                        return "CSV Files(*.csv)";
                    }
                    public boolean accept(File f) {
                        if (f.isDirectory()) {
                            return true;
                        } else {
                            String filename = f.getName().toLowerCase();
                            return filename.endsWith(".csv");
                        }
                    }
                });
                int option = fileChooser.showOpenDialog(null);
                if(option == JFileChooser.APPROVE_OPTION){

                    File file = fileChooser.getSelectedFile();
                    params.readUsedParametersCSV(file.getAbsolutePath(),mainWindow);

                }
            }
        });
        SaveParametersBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                params.parseParameters(mainWindow);
                JFileChooser fileChooser = new JFileChooser(batchDirectoryBox.getText());
                int option = fileChooser.showOpenDialog(null);
                if(option == JFileChooser.APPROVE_OPTION){
                    File file = fileChooser.getSelectedFile();
                    String fileName = file.getAbsolutePath();
                    if(file.getName().isEmpty())fileName = fileName+"Jimbob_Parameters.csv";
                    if(!fileName.endsWith(".csv"))fileName=fileName+".csv";
                    params.writeUsedParametersCSV(fileName);
                }

            }
        });
    }

}
