
import ij.IJ;
import ij.ImagePlus;
import ij.gui.GenericDialog;
import ij.io.DirectoryChooser;
import ij.io.LogStream;
import ij.io.OpenDialog;
import ij.plugin.ContrastEnhancer;
import ij.plugin.RGBStackMerge;
import ij.process.ImageConverter;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Arrays;
import ij.gui.Plot;
import ij.gui.PlotWindow;
import ij.plugin.MontageMaker;
import java.awt.Color;
import java.awt.Font;
import java.util.Collections;
import java.util.Locale;
import ij.io.FileSaver;
import ij.plugin.ImagesToStack;
import ij.ImageStack;
import ij.gui.Overlay;
import ij.gui.Roi;
import ij.gui.TextRoi;
import ij.measure.ResultsTable;

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author James_Walsh
 */
public class SingleMolMainWindow extends javax.swing.JFrame {


    GenericDialog gd;
    String OS;
    String JIM;
    String fileSep;
    String fileEXE;
    String quote;
    String newCMDWindowBefore,newCMDWindowAfter;
    int error;
    String completeName;
    String[] filnamebaseandext;
    
    
    String row;
    int count;
    String[] data;
    BufferedReader csvReader;
    FileWriter fw;
    
    
    String compiledDir;
    java.util.List<String> results;
    java.util.List<String> resultsDir;

    int stepfitIterations;
   
    double minFirstStepProb;
    double maxSecondMeanFirstMeanRatio;
    double maxMoreStepProb;
    
    double expYMinPercent;
    double expYMaxPercent;
    
    double  gausMinPercent;
    double gausMaxPercent; 
    
    double singleMolMode;
    
    ArrayList<ArrayList<Double>> allResults;
    
    private void setup_Jim_Programs(){
        error = 0;
        
        OS = System.getProperty("os.name", "generic").toLowerCase(Locale.ENGLISH);
      if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)) {
        JIM = (new File("").getAbsolutePath())+"/plugins/Jim_Programs_Mac/";
        fileEXE = "";
        fileSep = "/";
        quote = "\\\"";
        newCMDWindowBefore = "tell application \"Terminal\"\n" + "activate\n" +"do script \"";
        newCMDWindowAfter = "\"\n" +"delay 1\n" + "repeat until busy of first window is false\n" +"delay 0.1\n" +
                                "end repeat\n" +"delay 1\n" +"close first window\n" +"end tell";
      } else if (OS.indexOf("win") >= 0) {
        JIM = (new File("").getAbsolutePath())+"\\plugins\\Jim_Programs\\";
        fileEXE = ".exe";
        fileSep = "\\";
        quote="\"";
      } 
      
        if(new File(JIM).exists()==false)
        {
            gd = new GenericDialog("Error Jim Folder not found", IJ.getInstance());
            gd.addMessage("The folder containing JIM analysis programs does not exist in the ImageJ plugin folder.");
            gd.addMessage("Copy the Jim_Programs folder fom the JIM distribution to : ");
            gd.addMessage(JIM);
            gd.setOKLabel("Close Analysis");
            gd.showDialog();
            error = 1;
            return;
        }
            

        stepfitIterations = 10000;
        
        minFirstStepProb = 0.5;
        maxSecondMeanFirstMeanRatio=0.25;
        maxMoreStepProb=0.99;   
            
        expYMinPercent = 0;
        expYMaxPercent = 0.75;
        
        gausMinPercent = 0;
        gausMaxPercent = 0.75;
        
        singleMolMode = 1;
        
        
    }
    
    void getInputFile(){
        
            java.util.List<String> subfolderlist;
            
            gd = new GenericDialog("1) Select Files for Single Molecule Analysis", IJ.getInstance());
            gd.addMessage("Select the folder that contains all image files");
            gd.addMessage("that have first had traces generated using");
            gd.addMessage("Generate Single Channel Traces");
            gd.addCheckbox("Image Files in subfolders",true);

            gd.setOKLabel("Select Folder");
            gd.showDialog(); 
            if (gd.wasCanceled())
                    return;

            boolean filesInSubFolders = gd.getNextBoolean();

            DirectoryChooser dir = new DirectoryChooser("Select Folder containg all image stacks");

            String pathname = dir.getDirectory();

            results = new ArrayList<>();
            resultsDir= new ArrayList<>();
            subfolderlist = new ArrayList<>();

            File[] files = new File(pathname).listFiles();
            
            
            
            if(filesInSubFolders){
                for (File file : files){
                    if(file.isFile()==false)subfolderlist.add(file.getPath());
                }
            }
            else subfolderlist.add(new File(pathname).getPath());
            
            java.util.List<String> analysisfolderlist;
            
            analysisfolderlist = new ArrayList<>();
            
           for(String folderin:subfolderlist){
               files = new File(folderin).listFiles();
                for (File file : files){
                    if(file.isFile()==false)analysisfolderlist.add(file.getPath());
                }               
               
           }
            
           for(String folderin:analysisfolderlist){
               if(new File(folderin+fileSep+"Channel_1_Fluorescent_Intensities.csv").exists()==true){
                    results.add(folderin+fileSep+"Channel_1_Fluorescent_Intensities.csv");
                    resultsDir.add(folderin+fileSep);
               }
           }
                   
            gd = new GenericDialog("1) Select Files for Single Molecule analyse", IJ.getInstance());
            gd.addMessage("Detected Files : ");
            for( int i=0;i<results.size();i++) gd.addMessage(resultsDir.get(i));
            gd.setOKLabel("Continue");
            gd.showDialog(); 
            
            
            compiledDir = pathname+fileSep+"Compiled_Photobleaching_Analysis"+fileSep;
            
            
            allResults = new ArrayList<>();
            for(int i=0;i<results.size()+3;i++){
                allResults.add(new ArrayList<>());
                for(int j = 0;j<16;j++)allResults.get(i).add(1.0);    
            }
    
    }
    
    void stepfitFiles(){
        
                    if(new File(compiledDir).exists()==false)
                    new File(compiledDir).mkdirs();

                try{
                fw=new FileWriter(compiledDir+"Bleaching_File_Names.csv");
                row = "File Names used for photobleaching analysis \n";
                fw.write(row);
                for(int i=0;i<results.size();i++){
                    row = results.get(i)+"\n";
                    fw.write(row);
                }
                fw.close();
                        }catch(Exception e)
            {
                gd = new GenericDialog("Error", IJ.getInstance());
                gd.addMessage("Error Writing out file names... ");
                gd.addMessage(e.getMessage());
                gd.addMessage(e.getLocalizedMessage());
                gd.addMessage(e.toString());
                gd.showDialog(); 
                return;

            }
        
        
        
                gd = new GenericDialog("2) Stepfit Traces", IJ.getInstance());

                gd.addNumericField("Stepfit Iterations ", stepfitIterations, 0);
                gd.showDialog();
                if (gd.wasCanceled())
                        return;
                stepfitIterations = (int) gd.getNextNumber();
            
           
                String[] args={};
                Process process;
                Runtime runtime= Runtime.getRuntime();
                String CMD = "";
          try {
              for(int i=0;i<results.size();i++){
                  String filein = results.get(i);
                  String folderin = resultsDir.get(i);
                  CMD = JIM+"Change_Point_Analysis" + fileEXE +" "+quote+ filein+quote +" "+quote+ folderin+"Stepfit" + quote+ " -FitSingleSteps -Iterations "+ IJ.d2s(stepfitIterations,0);
                    if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                        args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                        process = runtime.exec(args);
                        process.waitFor();
                    }
                    else if (OS.indexOf("win") >= 0){
                        String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                        process = runtime.exec(CMDString);
                        process.waitFor();
                    }                   
              }
                
          }catch(Exception e)
          {
                gd = new GenericDialog("Error", IJ.getInstance());
                gd.addMessage("Error During step fitting ... ");
                gd.addMessage(CMD);
                gd.addMessage(e.getMessage());
                gd.addMessage(e.getLocalizedMessage());
                gd.addMessage(e.toString());
                gd.showDialog(); 
                error = 1;
              return;
          }
          
        gd = new GenericDialog("2) Stepfit Traces", IJ.getInstance());
        gd.addMessage("Step fitting Complte");
        gd.showDialog();          
    }
    
    void filterSingleTrace(){
        int fileToCheck=1;
        int pageNumber = 1;
        
        gd = new GenericDialog("3) Filter Single File", IJ.getInstance());
        
        gd.addNumericField("File to check ", fileToCheck, 0);
        gd.addNumericField("Page Number", pageNumber, 0);
        gd.addMessage("");
        gd.addNumericField("Min. First Step Probability ", minFirstStepProb, 2);
        gd.addNumericField("Max Second to First Mean Ratio ", maxSecondMeanFirstMeanRatio, 2);
        gd.addNumericField("Max More Step Probability ", maxMoreStepProb, 2);
        gd.showDialog();
        if (gd.wasCanceled())
                return;
        
        fileToCheck =-1+ (int) gd.getNextNumber();
        pageNumber = (int) gd.getNextNumber();
        
        minFirstStepProb = gd.getNextNumber();
        maxSecondMeanFirstMeanRatio = gd.getNextNumber();
        maxMoreStepProb = gd.getNextNumber();
        
        ArrayList<ArrayList<Double>> traces = new ArrayList<>();
        ArrayList<ArrayList<Double>> measures = new ArrayList<>();

        String row;
        int count;
        String[] data;
        BufferedReader csvReader;        
     
    try{
        
        csvReader = new BufferedReader(new FileReader(results.get(fileToCheck)));
        csvReader.readLine();
        count=0;
        while ((row = csvReader.readLine()) != null) {
            traces.add(new ArrayList<>());
            data = row.split(",");
            for(int i=0;i<data.length;i++){
                (traces.get(count)).add(Double.parseDouble(data[i]));             
            }         
            count++;
        }
        csvReader.close();
        
        
        csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Stepfit_Single_Step_Fits.csv")));
        csvReader.readLine();
        count=0;
        while ((row = csvReader.readLine()) != null) {
            measures.add(new ArrayList<>());
            data = row.split(",");
            for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));          
            count++;
        }
        csvReader.close();
  
        
        
        
        ArrayList<ArrayList<Double>> singleStepTraces = new ArrayList<>();
        ArrayList<ArrayList<Double>> singleStepMeasures = new ArrayList<>();
        ArrayList<ArrayList<Double>> multiStepTraces = new ArrayList<>();
        ArrayList<ArrayList<Double>> multiStepMeasures = new ArrayList<>();
        
        for( int i=0;i<traces.size();i++){
            if(measures.get(i).get(2) > minFirstStepProb && measures.get(i).get(5)<maxSecondMeanFirstMeanRatio*measures.get(i).get(4) && measures.get(i).get(6) < maxMoreStepProb ){
                singleStepTraces.add(new ArrayList<>());
                singleStepMeasures.add(new ArrayList<>());
                for(Double valuein:(traces.get(i)))singleStepTraces.get(singleStepTraces.size()-1).add(valuein);
                for(Double valuein:(measures.get(i)))singleStepMeasures.get(singleStepMeasures.size()-1).add(valuein);
            }
            else{
                multiStepTraces.add(new ArrayList<>());
                multiStepMeasures.add(new ArrayList<>());
                for(Double valuein:(traces.get(i)))multiStepTraces.get(multiStepTraces.size()-1).add(valuein);
                for(Double valuein:(measures.get(i)))multiStepMeasures.get(multiStepMeasures.size()-1).add(valuein);                   
            }
        }
        
        
        
        double[] frameNumber = new double[singleStepTraces.get(0).size()];
        double[] axisZero = new double[singleStepTraces.get(0).size()];
        for(int i=0;i<singleStepTraces.get(0).size();i++){
            frameNumber[i] = (i+1.0);
            axisZero[i] = (0.0);
        }
        
        double[] xstepfit = new double[4];
        double[] ystepfit = new double[4];
        
            Plot plot = new Plot("PageNumber "+IJ.d2s(pageNumber,0),"Frames","Intensity");
        
       // ImagePlus myStack = IJ.createHyperStack("Plot Stack",imp.getWidth(),imp.getHeight(),1,1,36,24);
        count = 0;
        for(int particleCount = 0;particleCount<36;particleCount++){
            int abPartCount = particleCount+36*(pageNumber-1);
            if(abPartCount>= singleStepTraces.size())break;
            count++;
            plot.setFrameSize(400, 250);
            PlotWindow.noGridLines = false; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 40);
            plot.setFont(Font.BOLD, 40);
            plot.setLimits(1, singleStepTraces.get(abPartCount).size(), Collections.min(singleStepTraces.get(abPartCount)), Collections.max(singleStepTraces.get(abPartCount)));
            plot.setLineWidth(6);
            plot.setColor(Color.black);
            plot.add("line",frameNumber, axisZero);            
            plot.setColor(Color.red);
            double[] toplot = (singleStepTraces.get(abPartCount)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",frameNumber, toplot);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.25, 0,"Single Step - Trace "+IJ.d2s(singleStepMeasures.get(abPartCount).get(0),0));
            
            xstepfit[0] = 0;
            xstepfit[1] = singleStepMeasures.get(abPartCount).get(3);
            xstepfit[2] = singleStepMeasures.get(abPartCount).get(3);
            xstepfit[3] = singleStepTraces.get(abPartCount).size();
            
            ystepfit[0] = singleStepMeasures.get(abPartCount).get(4);
            ystepfit[1] = singleStepMeasures.get(abPartCount).get(4);
            ystepfit[2] = singleStepMeasures.get(abPartCount).get(5);
            ystepfit[3] = singleStepMeasures.get(abPartCount).get(5);
                        
            plot.setColor(Color.blue);
            plot.add("line",xstepfit, ystepfit);
            
            plot.appendToStack();
        }
        
        plot.show();
        
        ImagePlus imp = IJ.getImage();
        
        MontageMaker mymontage = new MontageMaker();
        mymontage.makeMontage(imp, 6, 6, 1, 1, count, 1, 5, false); 
        imp.close();
        
        
        plot = new Plot("PageNumber "+IJ.d2s(pageNumber,0),"Frames","Intensity");
        
        count = 0;
        for(int particleCount = 0;particleCount<36;particleCount++){
            int abPartCount = particleCount+36*(pageNumber-1);
            if(abPartCount>= multiStepTraces.size())break;
            count++;
            plot.setFrameSize(400, 250);
            PlotWindow.noGridLines = false; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 40);
            plot.setFont(Font.BOLD, 40);
            plot.setLimits(1, multiStepTraces.get(abPartCount).size(), Collections.min(multiStepTraces.get(abPartCount)), Collections.max(multiStepTraces.get(abPartCount)));
            plot.setLineWidth(6);
            plot.setColor(Color.black);
            plot.add("line",frameNumber, axisZero);            
            plot.setColor(Color.red);
            double[] toplot = (multiStepTraces.get(abPartCount)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",frameNumber, toplot);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.25, 0,"Multi Step - Trace "+IJ.d2s(multiStepMeasures.get(abPartCount).get(0),0));
            
            xstepfit[0] = 0;
            xstepfit[1] = multiStepMeasures.get(abPartCount).get(3);
            xstepfit[2] = multiStepMeasures.get(abPartCount).get(3);
            xstepfit[3] = multiStepTraces.get(abPartCount).size();
            
            ystepfit[0] = multiStepMeasures.get(abPartCount).get(4);
            ystepfit[1] = multiStepMeasures.get(abPartCount).get(4);
            ystepfit[2] = multiStepMeasures.get(abPartCount).get(5);
            ystepfit[3] = multiStepMeasures.get(abPartCount).get(5);
                        
            plot.setColor(Color.blue);
            plot.add("line",xstepfit, ystepfit);
            
            plot.appendToStack();
        }
        
        plot.show();
        
        imp = IJ.getImage();
        
        MontageMaker mymontage2 = new MontageMaker();
        mymontage2.makeMontage(imp, 6, 6, 1, 1, count, 1, 5, false); 
        imp.close();
        
        
        
        
        }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Filtering Traces... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }

    }
    
    void singleStepFilterAllFIles(){
        
        gd = new GenericDialog("4) Filter All Files ", IJ.getInstance());
        
        gd.addNumericField("Min. First Step Probability ", minFirstStepProb, 2);
        gd.addNumericField("Max Second to First Mean Ratio ", maxSecondMeanFirstMeanRatio, 2);
        gd.addNumericField("Max More Step Probability ", maxMoreStepProb, 2);
        gd.showDialog();
        if (gd.wasCanceled())
                return;
        
        minFirstStepProb = gd.getNextNumber();
        maxSecondMeanFirstMeanRatio = gd.getNextNumber();
        maxMoreStepProb = gd.getNextNumber();
        

        int totalNumberOfTraces = 0;
        int totalNumberOfSSTraces = 0;
     
    try{
        
        for( int fileToCheck = 0;fileToCheck<results.size();fileToCheck++){

            ArrayList<ArrayList<Double>> traces = new ArrayList<>();
            ArrayList<ArrayList<Double>> measures = new ArrayList<>();


            csvReader = new BufferedReader(new FileReader(results.get(fileToCheck)));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                traces.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++){
                    (traces.get(count)).add(Double.parseDouble(data[i]));             
                }         
                count++;
            }
            csvReader.close();


            csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Stepfit_Single_Step_Fits.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                measures.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();




            ArrayList<ArrayList<Double>> singleStepTraces = new ArrayList<>();
            ArrayList<ArrayList<Double>> singleStepMeasures = new ArrayList<>();
            ArrayList<ArrayList<Double>> multiStepTraces = new ArrayList<>();
            ArrayList<ArrayList<Double>> multiStepMeasures = new ArrayList<>();

            for( int i=0;i<traces.size();i++){
                if(measures.get(i).get(2) > minFirstStepProb && measures.get(i).get(5)<maxSecondMeanFirstMeanRatio*measures.get(i).get(4) && measures.get(i).get(6) < maxMoreStepProb ){
                    singleStepTraces.add(new ArrayList<>());
                    singleStepMeasures.add(new ArrayList<>());
                    for(Double valuein:(traces.get(i)))singleStepTraces.get(singleStepTraces.size()-1).add(valuein);
                    for(Double valuein:(measures.get(i)))singleStepMeasures.get(singleStepMeasures.size()-1).add(valuein);
                }
                else{
                    multiStepTraces.add(new ArrayList<>());
                    multiStepMeasures.add(new ArrayList<>());
                    for(Double valuein:(traces.get(i)))multiStepTraces.get(multiStepTraces.size()-1).add(valuein);
                    for(Double valuein:(measures.get(i)))multiStepMeasures.get(multiStepMeasures.size()-1).add(valuein);                   
                }
            }

            allResults.get(fileToCheck).set(0, 1.0*traces.size());
            allResults.get(fileToCheck).set(1,1.0*singleStepTraces.size());
            totalNumberOfTraces += traces.size();
            totalNumberOfSSTraces += singleStepTraces.size();
            
            
            fw=new FileWriter(resultsDir.get(fileToCheck)+"Single_Step_Traces.csv");
            row = "Each row is a particle. Each column is a Frame\n";
            fw.write(row);
            for(int i=0;i<singleStepTraces.size();i++){
                row = IJ.d2s(singleStepTraces.get(i).get(0),8);
                for(int j=1;j<singleStepTraces.get(i).size();j++)row+=","+IJ.d2s(singleStepTraces.get(i).get(j),8);
                row+="\n";
                fw.write(row);
            }
            fw.close();


            fw=new FileWriter(resultsDir.get(fileToCheck)+"Multi_Step_Traces.csv");
            row = "Each row is a particle. Each column is a Frame\n";
            fw.write(row);
            for(int i=0;i<multiStepTraces.size();i++){
                row = IJ.d2s(multiStepTraces.get(i).get(0),8);
                for(int j=1;j<multiStepTraces.get(i).size();j++)row+=","+IJ.d2s(multiStepTraces.get(i).get(j),8);
                row+="\n";
                fw.write(row);
            }
            fw.close();

            fw=new FileWriter(resultsDir.get(fileToCheck)+"Single_Step_Step_Fit.csv");
            row = "Trace Number, No step mean, One or more Step Probability, Step Position, Initial Mean, Final Mean, Probability of more steps, Residual Standard Deviation \n";
            fw.write(row);
            for(int i=0;i<singleStepMeasures.size();i++){
                row = IJ.d2s(singleStepMeasures.get(i).get(0),8);
                for(int j=1;j<singleStepMeasures.get(i).size();j++)row+=","+IJ.d2s(singleStepMeasures.get(i).get(j),8);
                row+="\n";
                fw.write(row);
            }
            fw.close();


            fw=new FileWriter(resultsDir.get(fileToCheck)+"Multi_Step_Step_Fit.csv");
            row = "Trace Number, No step mean, One or more Step Probability, Step Position, Initial Mean, Final Mean, Probability of more steps, Residual Standard Deviation \n";
            fw.write(row);
            for(int i=0;i<multiStepMeasures.size();i++){
                row = IJ.d2s(multiStepMeasures.get(i).get(0),8);
                for(int j=1;j<multiStepMeasures.get(i).size();j++)row+=","+IJ.d2s(multiStepMeasures.get(i).get(j),8);
                row+="\n";
                fw.write(row);
            }
            fw.close();

        }
        
        allResults.get(results.size()+2).set(0, 1.0*totalNumberOfTraces);
        allResults.get(results.size()+2).set(1,1.0*totalNumberOfSSTraces);
        
                }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Filtering Traces... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }
 
        gd = new GenericDialog("4) Filter All Files", IJ.getInstance());
        gd.addMessage("Filtering Complete");
        gd.showDialog();  
    
    
    
    }
    
    void fitBleachTimes(){
        expYMinPercent = 0;
        expYMaxPercent = 0.75; 
        
        gd = new GenericDialog("4) Fit Bleaching Times", IJ.getInstance());
        
        gd.addNumericField("Min. Cutoff Percent ", expYMaxPercent, 2);
        gd.addNumericField("Max. Cutoff Percent ", expYMinPercent, 2);
        gd.showDialog();
        if (gd.wasCanceled())
                return;
        
        expYMaxPercent = gd.getNextNumber();
        expYMinPercent = gd.getNextNumber();

        ArrayList<Double> allBleachingX = new ArrayList<>();
        ArrayList<Double> allBleachingY = new ArrayList<>();
        
        try{
            
             fw=new FileWriter(compiledDir+"Bleaching_Survival_Curves.csv");
            row = "Each First Line is the frame number, Each Second Line is Number of Unbleached Particles after that number of Frames\n";
            fw.write(row);                        
            
            
            for( int fileToCheck = 0;fileToCheck<results.size();fileToCheck++){
            
                ArrayList<ArrayList<Double>> measures = new ArrayList<>();
                ArrayList<Double> BleachingX = new ArrayList<>();
                ArrayList<Double> BleachingY = new ArrayList<>();

                csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Single_Step_Step_Fit.csv")));
                csvReader.readLine();
                count=0;
                while ((row = csvReader.readLine()) != null) {
                    measures.add(new ArrayList<>());
                    data = row.split(",");
                    for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));          
                    count++;
                }
                csvReader.close();
                
                for(int i=0;i<measures.size();i++){
                    BleachingX.add(measures.get(i).get(3));
                    BleachingY.add(1.0*measures.size()-i);                    
                    allBleachingX.add(measures.get(i).get(3));
                }
                
                Collections.sort(BleachingX);
                
                row = IJ.d2s(BleachingX.get(0),8);
                for(int j=1;j<BleachingX.size();j++)row+=","+IJ.d2s(BleachingX.get(j),8);
                row+="\n";
                fw.write(row);
                
                row = IJ.d2s(BleachingY.get(0),8);
                for(int j=1;j<BleachingY.size();j++)row+=","+IJ.d2s(BleachingY.get(j),8);
                row+="\n";
                fw.write(row);    
            }
            
            Collections.sort(allBleachingX);            
            for(int i=0;i<allBleachingX.size();i++)allBleachingY.add(1.0*allBleachingX.size()-i);
            
            row = IJ.d2s(allBleachingX.get(0),8);
            for(int j=1;j<allBleachingX.size();j++)row+=","+IJ.d2s(allBleachingX.get(j),8);
            row+="\n";
            fw.write(row);

            row = IJ.d2s(allBleachingY.get(0),8);
            for(int j=1;j<allBleachingY.size();j++)row+=","+IJ.d2s(allBleachingY.get(j),8);
            row+="\n";
            fw.write(row);    
            
            fw.close();
            
            
            String[] args={};
            Process process;
            Runtime runtime= Runtime.getRuntime();
            String CMD = "";
            
    
            CMD = JIM+"Exponential_Fit" + fileEXE +" "+quote+ compiledDir+"Bleaching_Survival_Curves.csv"+quote +" "+quote+ compiledDir+"Bleaching_Survival_Curves"+ quote+ " -ymaxPercent "+ IJ.d2s(expYMaxPercent,2)+ " -yminPercent "+ IJ.d2s(expYMinPercent,2);
              if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                  args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                  process = runtime.exec(args);
                  process.waitFor();
              }
              else if (OS.indexOf("win") >= 0){
                  String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                  process = runtime.exec(CMDString);
                  process.waitFor();
              }  
        

            
            
            ArrayList<ArrayList<Double>> expfit = new ArrayList<>();  
              
            csvReader = new BufferedReader(new FileReader((compiledDir+"Bleaching_Survival_Curves_ExpFit.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                expfit.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(expfit.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();
            
            PlotWindow.fontSize = 24;
            Plot plot = new Plot("Bleaching Rate","Frames","Remaining Particles");

            plot.setFrameSize(400, 250);
            PlotWindow.noGridLines = true; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 24);
            plot.setFont(Font.BOLD, 24);
            plot.setLimits(0, Collections.max(allBleachingX), 0, 1.1*Collections.max(allBleachingY));
            plot.setLineWidth(4);           
            plot.setColor(new Color(0,114,189));
            double[] toplotx = (allBleachingX).stream().mapToDouble(d -> d).toArray();
            double[] toploty = (allBleachingY).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.25, 0,"Bleaching Rate");
            plot.addLegend("Experiment\nExponential Fit\n", "Top-Right");
            
            plot.setColor(new Color(217,83,25));
            
            
            ArrayList<Double> expfitx = new ArrayList<>();
            ArrayList<Double> expfity = new ArrayList<>();
            
            for(int i=0;i<=Collections.max(allBleachingX);i++){
                expfitx.add(1.0*i);
                expfity.add(expfit.get(expfit.size()-1).get(0)+expfit.get(expfit.size()-1).get(1)*Math.exp(-1.0*i*expfit.get(expfit.size()-1).get(2)));
            }
            
            toplotx = (expfitx).stream().mapToDouble(d -> d).toArray();
            toploty = (expfity).stream().mapToDouble(d -> d).toArray();
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.white);
            plot.addLegend("Experiment\nExponential Fit\n", "Top-Right");
        
            
            plot.show();
            
            ImagePlus toout = plot.makeHighResolution("Bleaching Rate", 4.0f,false, false);
            
            new FileSaver(toout).saveAsPng(compiledDir+"Bleaching_Rate.png");
            
            for(int i=0;i<results.size();i++){
                allResults.get(i).set(2, 1.0*expfit.get(i).get(2));
                allResults.get(i).set(3, 0.693147/expfit.get(i).get(2));
                allResults.get(i).set(4, 0.10536/expfit.get(i).get(2));
            }
                allResults.get(results.size()+2).set(2, 1.0*expfit.get(expfit.size()-1).get(2));
                allResults.get(results.size()+2).set(3, 0.693147/expfit.get(expfit.size()-1).get(2));
                allResults.get(results.size()+2).set(4, 0.10536/expfit.get(expfit.size()-1).get(2));            
            
            
                
                
                
                
                
                
                
        }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Fitting Bleaching... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }        
        
    }
    
    void fitStepHeights(){
        gausMinPercent = 0;
        gausMaxPercent = 0.75; 
        
        gd = new GenericDialog("4) Fit Bleaching Times", IJ.getInstance());
        
        gd.addNumericField("Min. Cutoff Percent ", gausMinPercent, 2);
        gd.addNumericField("Max. Cutoff Percent ", gausMaxPercent, 2);
        gd.showDialog();
        if (gd.wasCanceled())
                return;
        
        gausMinPercent = gd.getNextNumber();
        gausMaxPercent = gd.getNextNumber();

        ArrayList<Double> allstepHeights = new ArrayList<>();
        
        try{
            
             fw=new FileWriter(compiledDir+"Step_Heights.csv");
            row = "Each Line is the step height from a single experiment\n";
            fw.write(row);                        
            
            
            for( int fileToCheck = 0;fileToCheck<results.size();fileToCheck++){
            
                ArrayList<ArrayList<Double>> measures = new ArrayList<>();
                ArrayList<Double> stepHeights = new ArrayList<>();

                csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Single_Step_Step_Fit.csv")));
                csvReader.readLine();
                count=0;
                while ((row = csvReader.readLine()) != null) {
                    measures.add(new ArrayList<>());
                    data = row.split(",");
                    for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));          
                    count++;
                }
                csvReader.close();
                
                for(int i=0;i<measures.size();i++){
                    stepHeights.add(measures.get(i).get(4)-measures.get(i).get(5));                 
                    allstepHeights.add(measures.get(i).get(4)-measures.get(i).get(5));
                }

                
                row = IJ.d2s(stepHeights.get(0),8);
                for(int j=1;j<stepHeights.size();j++)row+=","+IJ.d2s(stepHeights.get(j),8);
                row+="\n";
                fw.write(row);
                  
            }
            

            row = IJ.d2s(allstepHeights.get(0),8);
            for(int j=1;j<allstepHeights.size();j++)row+=","+IJ.d2s(allstepHeights.get(j),8);
            row+="\n";
            fw.write(row);    
            
            fw.close();
            
            String[] args={};
            Process process;
            Runtime runtime= Runtime.getRuntime();
            String CMD = "";
            

            CMD = JIM+"Gaussian_Fit" + fileEXE +" "+quote+ compiledDir+"Step_Heights.csv"+quote +" "+quote+ compiledDir+"Step_Heights"+ quote+ " -ymaxPercent "+ IJ.d2s(gausMaxPercent,2)+ " -yminPercent "+ IJ.d2s(gausMinPercent,2);
              if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                  args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                  process = runtime.exec(args);
                  process.waitFor();
              }
              else if (OS.indexOf("win") >= 0){
                  String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                  process = runtime.exec(CMDString);
                  process.waitFor();
              }  
        

            CMD = JIM+"Make_Histogram" + fileEXE +" "+quote+ compiledDir+"Step_Heights.csv"+quote +" "+quote+ compiledDir+"Step_Heights"+ quote;
              if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                  args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                  process = runtime.exec(args);
                  process.waitFor();
              }
              else if (OS.indexOf("win") >= 0){
                  String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                  process = runtime.exec(CMDString);
                  process.waitFor();
              }              
              
              
            ArrayList<ArrayList<Double>> gausfit = new ArrayList<>();  
              
            csvReader = new BufferedReader(new FileReader((compiledDir+"Step_Heights_GaussFit.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                gausfit.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(gausfit.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();
            
            ArrayList<ArrayList<Double>> histograms = new ArrayList<>();  
              
            csvReader = new BufferedReader(new FileReader((compiledDir+"Step_Heights_Histograms.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                histograms.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(histograms.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();
            
            Double maxVal = Collections.max(histograms.get(histograms.size()-1)); 
            Integer maxIdx = histograms.get(histograms.size()-1).indexOf(maxVal);
            
            singleMolMode = histograms.get(histograms.size()-2).get(maxIdx);
            
            Collections.sort(allstepHeights); 
            
            
            PlotWindow.fontSize = 24;
            Plot plot = new Plot("Step Height Distribution","Intensity","Probability (PDF)");

            plot.setFrameSize(400, 250);
            //plot.setScale(0.25f);
            PlotWindow.noGridLines = true; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 24);
            plot.setFont(Font.BOLD, 24);
            int maxpos = (int)Math.round(0.99*allstepHeights.size());
            plot.setLimits(0, allstepHeights.get(maxpos), 0, 1.1*Collections.max(histograms.get(histograms.size()-1)));
            plot.setLineWidth(4);           
            plot.setColor(new Color(0,114,189));
            double[] toplotx = (histograms.get(histograms.size()-2)).stream().mapToDouble(d -> d).toArray();
            double[] toploty = (histograms.get(histograms.size()-1)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.15, 0,"Step Height Distribution");
            plot.addLegend("Experiment\nGaussian Fit\n", "Top-Right");
            
            plot.setColor(new Color(217,83,25));
            
            
            ArrayList<Double> expfitx = new ArrayList<>();
            ArrayList<Double> expfity = new ArrayList<>();
            
            for(int i=0;i<=Collections.max(histograms.get(histograms.size()-2));i++){
                expfitx.add(1.0*i);
                expfity.add(1.0/(Math.sqrt(2*3.141592653*gausfit.get(gausfit.size()-1).get(1)*gausfit.get(gausfit.size()-1).get(1)))*Math.exp(-1.0*(gausfit.get(gausfit.size()-1).get(0)-i)*(gausfit.get(gausfit.size()-1).get(0)-i)/(2*gausfit.get(gausfit.size()-1).get(1)*gausfit.get(gausfit.size()-1).get(1))));
            }
            
            toplotx = (expfitx).stream().mapToDouble(d -> d).toArray();
            toploty = (expfity).stream().mapToDouble(d -> d).toArray();
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.white);
            plot.addLegend("Experiment\nGaussian Fit\n", "Top-Right");
                   
            plot.show();
            
            ImagePlus toout = plot.makeHighResolution("Step Height Distribution", 4.0f,false, false);           
            new FileSaver(toout).saveAsPng(compiledDir+"Step_Height_Distribution.png");
            
            for(int i=0;i<results.size();i++){
                allResults.get(i).set(5, 1.0*gausfit.get(i).get(0));
                allResults.get(i).set(6, 1.0*gausfit.get(i).get(1));
                allResults.get(i).set(7, 1.0*gausfit.get(i).get(2));
                allResults.get(i).set(8, 1.0*gausfit.get(i).get(3));
                allResults.get(i).set(9, 1.0*gausfit.get(i).get(4));
                maxVal = Collections.max(histograms.get(2*i+1)); 
                maxIdx = histograms.get(2*i+1).indexOf(maxVal);
                allResults.get(i).set(10, 1.0*histograms.get(2*i).get(maxIdx));   
            }
            allResults.get(results.size()+2).set(5, 1.0*gausfit.get(gausfit.size()-1).get(0));
            allResults.get(results.size()+2).set(6, 1.0*gausfit.get(gausfit.size()-1).get(1));
            allResults.get(results.size()+2).set(7, 1.0*gausfit.get(gausfit.size()-1).get(2));
            allResults.get(results.size()+2).set(8, 1.0*gausfit.get(gausfit.size()-1).get(3));
            allResults.get(results.size()+2).set(9, 1.0*gausfit.get(gausfit.size()-1).get(4));
            allResults.get(results.size()+2).set(10, 1.0*singleMolMode);
            
        }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Fitting step heights... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }
    }
    
void signalToNoise(){
            ArrayList<Double> allSNR = new ArrayList<>();
        
        try{
            
             fw=new FileWriter(compiledDir+"Signal_to_Noise.csv");
            row = "Each Line is the step height divided my the std. dev. of the residual from a single experiment\n";
            fw.write(row);                        
            
            
            for( int fileToCheck = 0;fileToCheck<results.size();fileToCheck++){
            
                ArrayList<ArrayList<Double>> measures = new ArrayList<>();
                ArrayList<Double> SNR = new ArrayList<>();

                csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Single_Step_Step_Fit.csv")));
                csvReader.readLine();
                count=0;
                while ((row = csvReader.readLine()) != null) {
                    measures.add(new ArrayList<>());
                    data = row.split(",");
                    for(int i=0;i<data.length;i++)(measures.get(count)).add(Double.parseDouble(data[i]));          
                    count++;
                }
                csvReader.close();
                
                for(int i=0;i<measures.size();i++){
                    SNR.add((measures.get(i).get(4)-measures.get(i).get(5))/measures.get(i).get(7));                 
                    allSNR.add((measures.get(i).get(4)-measures.get(i).get(5))/measures.get(i).get(7));
                }

                
                row = IJ.d2s(SNR.get(0),8);
                for(int j=1;j<SNR.size();j++)row+=","+IJ.d2s(SNR.get(j),8);
                row+="\n";
                fw.write(row);
                
                Double average = SNR.stream().mapToDouble(val -> val).average().orElse(0.0);
                allResults.get(fileToCheck).set(11,average);
                  
            }
            
            Double average2 = allSNR.stream().mapToDouble(val -> val).average().orElse(0.0);
            allResults.get(results.size()+2).set(11,average2);

            row = IJ.d2s(allSNR.get(0),8);
            for(int j=1;j<allSNR.size();j++)row+=","+IJ.d2s(allSNR.get(j),8);
            row+="\n";
            fw.write(row);    
            
            fw.close();
            
            String[] args={};
            Process process;
            Runtime runtime= Runtime.getRuntime();
            String CMD = "";
            
        

            CMD = JIM+"Make_Histogram" + fileEXE +" "+quote+ compiledDir+"Signal_to_Noise.csv"+quote +" "+quote+ compiledDir+"Signal_to_Noise"+ quote;
              if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                  args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                  process = runtime.exec(args);
                  process.waitFor();
              }
              else if (OS.indexOf("win") >= 0){
                  String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                  process = runtime.exec(CMDString);
                  process.waitFor();
              }              
              
              
            
            ArrayList<ArrayList<Double>> histograms = new ArrayList<>();  
              
            csvReader = new BufferedReader(new FileReader((compiledDir+"Signal_to_Noise_Histograms.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                histograms.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(histograms.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();
            
            PlotWindow.fontSize = 24;
            Plot plot = new Plot("Signal to Noise Distribution","Step Height/Residual Std. Dev.","Probability (PDF)");

            Collections.sort(allSNR); 
            
            
            plot.setFrameSize(400, 250);
            //plot.setScale(0.25f);
            PlotWindow.noGridLines = true; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 24);
            plot.setFont(Font.BOLD, 24);
            int maxpos = (int)Math.round(0.99*allSNR.size());
            plot.setLimits(0, allSNR.get(maxpos), 0, 1.1*Collections.max(histograms.get(histograms.size()-1)));
            plot.setLineWidth(4);           
            plot.setColor(new Color(0,114,189));
            double[] toplotx = (histograms.get(histograms.size()-2)).stream().mapToDouble(d -> d).toArray();
            double[] toploty = (histograms.get(histograms.size()-1)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.13, 0,"Signal to Noise Distribution");
        
            
            plot.show();
            
            ImagePlus toout = plot.makeHighResolution("Signal to Noise Distribution", 4.0f,false, false);
           // toout.show();
            

            
            //IJ.run("Image...  ", "outputfile=["+compiledDir+"Bleaching_Rate.png] display=[Bleaching Rate.png]");
            
            new FileSaver(toout).saveAsPng(compiledDir+"Signal_to_Noise.png");
            
        }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Fitting signal to noise... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }
}
    
    void initialParticleIntensity(){
                ArrayList<Double> allInitialIntensities = new ArrayList<>();
        
        int count0,count1,count2,count3;        
                
        try{
            
             fw=new FileWriter(compiledDir+"Initial_Intensities.csv");
            row = "Each Line is the step height divided my the std. dev. of the residual from a single experiment\n";
            fw.write(row);                        
            
            
            for( int fileToCheck = 0;fileToCheck<results.size();fileToCheck++){
            
                ArrayList<ArrayList<Double>> traces = new ArrayList<>();
                ArrayList<Double> InitialIntensities = new ArrayList<>();

                csvReader = new BufferedReader(new FileReader((resultsDir.get(fileToCheck)+"Channel_1_Fluorescent_Intensities.csv")));
                csvReader.readLine();
                count=0;
                while ((row = csvReader.readLine()) != null) {
                    traces.add(new ArrayList<>());
                    data = row.split(",");
                    for(int i=0;i<data.length;i++)(traces.get(count)).add(Double.parseDouble(data[i]));          
                    count++;
                }
                csvReader.close();
                
                for(int i=0;i<traces.size();i++){
                    InitialIntensities.add((traces.get(i).get(0)) / singleMolMode);                 
                    allInitialIntensities.add((traces.get(i).get(0)) / singleMolMode);
                }

                
                row = IJ.d2s(InitialIntensities.get(0),8);
                for(int j=1;j<InitialIntensities.size();j++)row+=","+IJ.d2s(InitialIntensities.get(j),8);
                row+="\n";
                fw.write(row);
                
                
                count0 = 0;count1 = 0;count2 = 0;count3 = 0;
                
                for(int i=0;i<InitialIntensities.size();i++){
                    if(InitialIntensities.get(i)<0.5)count0++;
                    else if(InitialIntensities.get(i)<1.5)count1++;
                    else if(InitialIntensities.get(i)<2.5)count2++;
                    else count3++;
                }
                
                allResults.get(fileToCheck).set(12, 1.0*count0/InitialIntensities.size());
                allResults.get(fileToCheck).set(13, 1.0*count1/InitialIntensities.size());
                allResults.get(fileToCheck).set(14, 1.0*count2/InitialIntensities.size());
                allResults.get(fileToCheck).set(15, 1.0*count3/InitialIntensities.size());
                  
            }
            
            count0 = 0;count1 = 0;count2 = 0;count3 = 0;
            
            for(int i=0;i<allInitialIntensities.size();i++){
                if(allInitialIntensities.get(i)<0.5)count0++;
                else if(allInitialIntensities.get(i)<1.5)count1++;
                else if(allInitialIntensities.get(i)<2.5)count2++;
                else count3++;
            }

            allResults.get(results.size()+2).set(12, 1.0*count0/allInitialIntensities.size());
            allResults.get(results.size()+2).set(13, 1.0*count1/allInitialIntensities.size());
            allResults.get(results.size()+2).set(14, 1.0*count2/allInitialIntensities.size());
            allResults.get(results.size()+2).set(15, 1.0*count3/allInitialIntensities.size());            
            
            

            row = IJ.d2s(allInitialIntensities.get(0),8);
            for(int j=1;j<allInitialIntensities.size();j++)row+=","+IJ.d2s(allInitialIntensities.get(j),8);
            row+="\n";
            fw.write(row);    
            
            fw.close();
            
            String[] args={};
            Process process;
            Runtime runtime= Runtime.getRuntime();
            String CMD = "";
            
        

            CMD = JIM+"Make_Histogram" + fileEXE +" "+quote+ compiledDir+"Initial_Intensities.csv"+quote +" "+quote+ compiledDir+"Initial_Intensities"+ quote;
              if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                  args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                  process = runtime.exec(args);
                  process.waitFor();
              }
              else if (OS.indexOf("win") >= 0){
                  String CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                  process = runtime.exec(CMDString);
                  process.waitFor();
              }              
              
              
            
            ArrayList<ArrayList<Double>> histograms = new ArrayList<>();  
              
            csvReader = new BufferedReader(new FileReader((compiledDir+"Initial_Intensities_Histograms.csv")));
            csvReader.readLine();
            count=0;
            while ((row = csvReader.readLine()) != null) {
                histograms.add(new ArrayList<>());
                data = row.split(",");
                for(int i=0;i<data.length;i++)(histograms.get(count)).add(Double.parseDouble(data[i]));          
                count++;
            }
            csvReader.close();
            
            PlotWindow.fontSize = 24;
            Plot plot = new Plot("Particle Intensity Distribution","Particle Intensities (# Molecules)","Probability (PDF)");

            Collections.sort(allInitialIntensities); 
            
            
            plot.setFrameSize(400, 250);
            //plot.setScale(0.25f);
            PlotWindow.noGridLines = true; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 24);
            plot.setFont(Font.BOLD, 24);
            int maxpos = (int)Math.round(0.99*allInitialIntensities.size());
            plot.setLimits(-1, allInitialIntensities.get(maxpos), 0, 1.1*Collections.max(histograms.get(histograms.size()-1)));
            plot.setLineWidth(4);           
            plot.setColor(new Color(0,114,189));
            double[] toplotx = (histograms.get(histograms.size()-2)).stream().mapToDouble(d -> d).toArray();
            double[] toploty = (histograms.get(histograms.size()-1)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",toplotx, toploty);
            
            plot.setColor(Color.black);
            plot.addLabel( 0.13, 0,"Particle Intensity Distribution");
        
            
            plot.show();
            
            ImagePlus toout = plot.makeHighResolution("Particle Intensity Distribution", 4.0f,false, false);
            
            new FileSaver(toout).saveAsPng(compiledDir+"All_Particle_Intensities.png");
            
            
            
        }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Fitting Particle Intensity Distribution... ");
        gd.addMessage(e.getMessage());
        gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }
            
        
    }
    
    void runBatchFiles(){
        
    try{
        
        fw=new FileWriter(compiledDir+"Bleaching_Summary.csv");
        
     row = "Sample,Num of Particles,Num of Single Steps,Bleach Rate (1/frames),Half Life (frames),10% Bleached (frames),Gauss Fit Mean, Gauss Fit Std. Dev.,Mean Step Height, Std. Dev. Step Height,Median Step Height, Mode Step Height,Mean Signal to Noise,Submonomer Fraction,Monomer Fraction,Dimer Fraction, Higher Order Fraction\n";
     fw.write(row);
     
     double[] sums = new double[16];
     double[] stddev = new double[16];
     for(int i=0;i<results.size();i++)for(int j=0;j<16;j++)sums[j]+=allResults.get(i).get(j);
     for(int j=0;j<16;j++)sums[j] = sums[j]/results.size();
     
     for(int i=0;i<results.size();i++)for(int j=0;j<16;j++)stddev[j]+=(allResults.get(i).get(j)-sums[j])*(allResults.get(i).get(j)-sums[j]);
     if(results.size()>1){for(int j=0;j<16;j++)stddev[j] = Math.sqrt(stddev[j]/(results.size()-1));}
     else for(int j=0;j<16;j++)stddev[j] = 0;
     
     for(int j=0;j<16;j++){
         allResults.get(results.size()).set(j,sums[j]);
         allResults.get(results.size()+1).set(j,stddev[j]);
     }
     
     for(int i=0;i<results.size()+3;i++){
       if(i<results.size())row = IJ.d2s(i+1,0);
       else if(i == results.size())row = "Mean";
        else if(i == results.size()+1)row = "Std. Dev.";
        else row = "Pooled";

       for(int j=0;j<16;j++){
           row+=","+IJ.d2s(allResults.get(i).get(j),8);
       }
       row+="\n";
       fw.write(row);
     }
     
     fw.close();
     
     
    ResultsTable.open(compiledDir+"Bleaching_Summary.csv").show("Bleaching Summary");
     
     
       
    ImagePlus resultImStack;
        
    resultImStack = IJ.openImage(compiledDir+"Bleaching_Rate.png");
    ImageStack myimstack = new ImageStack(resultImStack.getWidth(),resultImStack.getHeight());
    myimstack.addSlice(resultImStack.getProcessor());
    resultImStack = IJ.openImage(compiledDir+"Step_Height_Distribution.png");
    myimstack.addSlice(resultImStack.getProcessor());
    resultImStack = IJ.openImage(compiledDir+"Signal_to_Noise.png");
    myimstack.addSlice(resultImStack.getProcessor());
    resultImStack = IJ.openImage(compiledDir+"All_Particle_Intensities.png");
    myimstack.addSlice(resultImStack.getProcessor());
    
    
    
    ImagePlus implus = new ImagePlus("Combined Results",myimstack);

    IJ.setBackgroundColor(255, 255, 255);
    
    MontageMaker mymontage = new MontageMaker();
    ImagePlus toout = mymontage.makeMontage2(implus, 2, 2, 1, 1, 4, 1, 0, false);
    
    Font font = new Font("Arial", Font.BOLD, 150);
    Roi mytext = new TextRoi(10, -10, "A", font);
    mytext.setStrokeColor(Color.black);
    Overlay overlay = new Overlay(mytext);
    
    mytext =new TextRoi(2200, -10, "B", font);
    mytext.setStrokeColor(Color.black);
    overlay.add(mytext);
    
    mytext =new TextRoi(10, 1400, "C", font);
    mytext.setStrokeColor(Color.black);
    overlay.add(mytext);
    
    mytext =new TextRoi(2200, 1400, "D", font);
    mytext.setStrokeColor(Color.black);
    overlay.add(mytext);

    toout.setOverlay(overlay);
    
    toout.show();
     
    new FileSaver(toout).saveAsPng(compiledDir+"Combined_Figure.png");
    

        
    String currentDate = java.time.LocalDate.now().toString();

    String variablesString = ("Date, " + currentDate + "\niterations," + IJ.d2s(stepfitIterations,0) +
      "\nminFirstStepProb," + IJ.d2s(minFirstStepProb,8) + "\nmaxSecondMeanFirstMeanRatio," + IJ.d2s(maxSecondMeanFirstMeanRatio,8) +
      "\nmaxMoreStepProb," + IJ.d2s(maxMoreStepProb,8) + 
      "\nexpYMinPercent," + IJ.d2s(expYMinPercent,8) + "\nexpYMaxPercent," + IJ.d2s(expYMaxPercent,8) + 
      "\ngausMinPercent," + IJ.d2s(gausMinPercent,8) + "\ngausMaxPercent," + IJ.d2s(gausMaxPercent,8));

        FileWriter fw=new FileWriter(compiledDir+"Single_Molecule_Photobleaching_Parameters.csv");    
        fw.write(variablesString);    
        fw.close();

    
             }catch(Exception e)
    {
        gd = new GenericDialog("Error", IJ.getInstance());
        gd.addMessage("Error Fitting Particle Intensity Distribution... ");
       // gd.addMessage(e.getMessage());
      //  gd.addMessage(e.getLocalizedMessage());
        gd.addMessage(e.toString());
        gd.showDialog(); 
        return;
        
    }
    }
    
    void UpdateParameters(){


            gd = new GenericDialog("Update Parameters", IJ.getInstance());
            gd.addNumericField("Stepfit Iterations", stepfitIterations, 0);
            gd.addMessage(" ");
            gd.addNumericField("Min. First Step Probability ", minFirstStepProb, 2);
            gd.addNumericField("Max Second to First Mean Ratio ", maxSecondMeanFirstMeanRatio, 2);
            gd.addNumericField("Max More Step Probability ", maxMoreStepProb, 2);
            gd.addMessage(" ");
            gd.addNumericField("Min. Bleach time Cutoff Percent ", expYMaxPercent, 2);
            gd.addNumericField("Max. Bleach time Cutoff Percent ", expYMinPercent, 2);
            gd.addMessage(" ");
            gd.addNumericField("Min. Step Height Cutoff Percent ", gausMinPercent, 2);
            gd.addNumericField("Max. Step Height Cutoff Percent ", gausMaxPercent, 2);

            gd.showDialog();
            
            if (gd.wasCanceled())
                    return;
            
            
        stepfitIterations = (int) gd.getNextNumber();
            
        minFirstStepProb = gd.getNextNumber();
        maxSecondMeanFirstMeanRatio = gd.getNextNumber();
        maxMoreStepProb = gd.getNextNumber();
            
        expYMaxPercent = gd.getNextNumber();
        expYMinPercent = gd.getNextNumber();  
        
        gausMinPercent = gd.getNextNumber();
        gausMaxPercent = gd.getNextNumber();
        
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
            // do something with the data            
            if(count == 1)stepfitIterations=(int)Double.parseDouble(data[1]);
            
            if(count == 2)minFirstStepProb=Double.parseDouble(data[1]);
            if(count == 3)maxSecondMeanFirstMeanRatio=Double.parseDouble(data[1]);   
            if(count == 4)maxMoreStepProb=(Double.parseDouble(data[1]));
            
            if(count == 5)expYMaxPercent=Double.parseDouble(data[1]);
            if(count == 6)expYMinPercent=Double.parseDouble(data[1]);
            
            if(count == 7)gausMinPercent=Double.parseDouble(data[1]);
            if(count == 8)gausMaxPercent=Double.parseDouble(data[1]);
            
            count++;
        }
        csvReader.close();
        }catch(Exception e)
        {
            
            gd = new GenericDialog("Error", IJ.getInstance());
            gd.addMessage("Error During Parameter Import... ");
            gd.addMessage(e.getMessage());
            gd.addMessage(e.getLocalizedMessage());
            gd.addMessage(e.toString());
            gd.showDialog(); 
            return;
        }
        
        
    }
    
    void saveParameters(){
        try{
            OpenDialog fileselector;

            fileselector = new OpenDialog("Save Parameters CSV");

            String saveName = fileselector.getPath();
            
            String currentDate = java.time.LocalDate.now().toString();

            String variablesString = ("Date, " + currentDate + "\niterations," + IJ.d2s(stepfitIterations,0) +
      "\nminFirstStepProb," + IJ.d2s(minFirstStepProb,8) + "\nmaxSecondMeanFirstMeanRatio," + IJ.d2s(maxSecondMeanFirstMeanRatio,8) +
      "\nmaxMoreStepProb," + IJ.d2s(maxMoreStepProb,8) + 
      "\nexpYMinPercent," + IJ.d2s(expYMinPercent,8) + "\nexpYMaxPercent," + IJ.d2s(expYMaxPercent,8) + 
      "\ngausMinPercent," + IJ.d2s(gausMinPercent,8) + "\ngausMaxPercent," + IJ.d2s(gausMaxPercent,8));
            FileWriter fw=new FileWriter(saveName+".csv");    
            fw.write(variablesString);    
            fw.close();
            }catch(Exception e)
       {
           gd = new GenericDialog("Error", IJ.getInstance());
           gd.addMessage("Error During Batch Processing... ");
           gd.showDialog(); 
           return;
       }
    }
    
    

    
    //window maintainence from here
    

    public SingleMolMainWindow() {
        initComponents();
        this.setTitle("Single Molecule Photobleaching");
        setup_Jim_Programs();
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jButton1 = new javax.swing.JButton();
        jButton2 = new javax.swing.JButton();
        jButton3 = new javax.swing.JButton();
        jButton4 = new javax.swing.JButton();
        jButton5 = new javax.swing.JButton();
        jButton6 = new javax.swing.JButton();
        jButton7 = new javax.swing.JButton();
        jButton8 = new javax.swing.JButton();
        jButton9 = new javax.swing.JButton();
        jButton10 = new javax.swing.JButton();
        jButton11 = new javax.swing.JButton();
        jTextField1 = new javax.swing.JTextField();
        jTextField2 = new javax.swing.JTextField();
        jButton12 = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        jButton1.setText("1) Select Input Folder");
        jButton1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton1ActionPerformed(evt);
            }
        });

        jButton2.setText("2) Stepfit Traces");
        jButton2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton2ActionPerformed(evt);
            }
        });

        jButton3.setText("3)Single Step Filters");
        jButton3.setActionCommand("");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });

        jButton4.setText("4) Filter All Files");
        jButton4.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton4ActionPerformed(evt);
            }
        });

        jButton5.setText("5) Fit Bleach Times");
        jButton5.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton5ActionPerformed(evt);
            }
        });

        jButton6.setText("6) Fit Step Heights");
        jButton6.setActionCommand("Make Traces");
        jButton6.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton6ActionPerformed(evt);
            }
        });

        jButton7.setText("8) Particle Intensities ");
        jButton7.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton7ActionPerformed(evt);
            }
        });

        jButton8.setText("9) Combine Results");
        jButton8.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton8ActionPerformed(evt);
            }
        });

        jButton9.setText("View/Adjust Parameters");
        jButton9.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton9ActionPerformed(evt);
            }
        });

        jButton10.setText("Import Parameters");
        jButton10.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton10ActionPerformed(evt);
            }
        });

        jButton11.setText("Save Parameters");
        jButton11.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton11ActionPerformed(evt);
            }
        });

        jTextField1.setEditable(false);
        jTextField1.setFont(new java.awt.Font("Tahoma", 1, 12)); // NOI18N
        jTextField1.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        jTextField1.setText("Single Molecule Analysis");
        jTextField1.setBorder(null);

        jTextField2.setEditable(false);
        jTextField2.setFont(new java.awt.Font("Tahoma", 1, 12)); // NOI18N
        jTextField2.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        jTextField2.setText("Parameters");
        jTextField2.setBorder(null);

        jButton12.setText("7) Find Signal to Noise");
        jButton12.setActionCommand("Make Traces");
        jButton12.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton12ActionPerformed(evt);
            }
        });

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addGap(41, 41, 41)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jButton8, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jButton7, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jTextField1, javax.swing.GroupLayout.DEFAULT_SIZE, 147, Short.MAX_VALUE)
                            .addComponent(jButton1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton2, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton3, javax.swing.GroupLayout.DEFAULT_SIZE, 147, Short.MAX_VALUE)
                            .addComponent(jButton4, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton5, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton6, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton12, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                        .addGap(80, 80, 80)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jButton11, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton10, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jButton9, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                            .addComponent(jTextField2))))
                .addContainerGap(59, Short.MAX_VALUE))
        );

        layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {jButton1, jButton10, jButton11, jButton12, jButton2, jButton3, jButton4, jButton5, jButton6, jButton7, jButton8, jButton9, jTextField1, jTextField2});

        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jTextField1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jTextField2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton1)
                    .addComponent(jButton9))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton2)
                    .addComponent(jButton10))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton3)
                    .addComponent(jButton11))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jButton4)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jButton5)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jButton6)
                .addGap(5, 5, 5)
                .addComponent(jButton12)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jButton7)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jButton8)
                .addContainerGap(20, Short.MAX_VALUE))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
        // TODO add your handling code here:
            getInputFile();
    }//GEN-LAST:event_jButton1ActionPerformed

    private void jButton2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton2ActionPerformed
        // TODO add your handling code here:
        stepfitFiles();
    }//GEN-LAST:event_jButton2ActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        // TODO add your handling code here:
        filterSingleTrace();
    }//GEN-LAST:event_jButton3ActionPerformed

    private void jButton4ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton4ActionPerformed
        // TODO add your handling code here:
        singleStepFilterAllFIles();
    }//GEN-LAST:event_jButton4ActionPerformed

    private void jButton5ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton5ActionPerformed
        // TODO add your handling code here:
        fitBleachTimes();
    }//GEN-LAST:event_jButton5ActionPerformed

    private void jButton6ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton6ActionPerformed
        // TODO add your handling code here:
        fitStepHeights();
    }//GEN-LAST:event_jButton6ActionPerformed

    private void jButton7ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton7ActionPerformed
        // TODO add your handling code here:
        initialParticleIntensity();
    }//GEN-LAST:event_jButton7ActionPerformed

    private void jButton8ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton8ActionPerformed
        // TODO add your handling code here:
        runBatchFiles();
    }//GEN-LAST:event_jButton8ActionPerformed

    private void jButton9ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton9ActionPerformed
        // TODO add your handling code here:
        UpdateParameters();
    }//GEN-LAST:event_jButton9ActionPerformed

    private void jButton11ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton11ActionPerformed
        // TODO add your handling code here:
        saveParameters();
    }//GEN-LAST:event_jButton11ActionPerformed

    private void jButton10ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton10ActionPerformed
        // TODO add your handling code here:
        importParameters();
    }//GEN-LAST:event_jButton10ActionPerformed

    private void jButton12ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton12ActionPerformed
        // TODO add your handling code here:
        signalToNoise();
    }//GEN-LAST:event_jButton12ActionPerformed

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(SingleMolMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(SingleMolMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(SingleMolMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(SingleMolMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new SingleMolMainWindow().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButton1;
    private javax.swing.JButton jButton10;
    private javax.swing.JButton jButton11;
    private javax.swing.JButton jButton12;
    private javax.swing.JButton jButton2;
    private javax.swing.JButton jButton3;
    private javax.swing.JButton jButton4;
    private javax.swing.JButton jButton5;
    private javax.swing.JButton jButton6;
    private javax.swing.JButton jButton7;
    private javax.swing.JButton jButton8;
    private javax.swing.JButton jButton9;
    private javax.swing.JTextField jTextField1;
    private javax.swing.JTextField jTextField2;
    // End of variables declaration//GEN-END:variables

}
