
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

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author James_Walsh
 */
public class SingleMainWindow extends javax.swing.JFrame {


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
    String workingDir;
   


    // 2 - Drift Correct Parameters
    int iterations;
    int alignStartFrame;
    int alignEndFrame;

    // 3 - Make a SubAverage of the Image Stack for Detection Parameters
    boolean useMaxProjection;
    int detectionStartFrame;
    int detectionEndFrame;

    // 4 - Detect Particles Parameters
    double cutoff;

    int left;
    int right;
    int top; 
    int bottom;

    int minCount;
    int maxCount;

    double minEccentricity;
    double maxEccentricity;

    double minLength;
    double maxLength;

    double maxDistFromLinear;
    
    // 5 - Expand Regions Parameters

    double foregroundDist;
    double backInnerDist;
    double backOuterDist;

    // 6 - Calculate Traces Parameter
    boolean verboseOutput;

    // 7 - View Traces Parameter
    int pageNumber;

    // 8 - Detect files for batch
    boolean filesInSubFolders;

    // 9 - Batch Analysis
    boolean overwritePreviouslyAnalysed;
   
    
    
    java.util.List<String> results;
    
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
            


        // 2 - Drift Correct Parameters
        iterations = 1;
        alignStartFrame = 1;
        alignEndFrame = 5;

        // 3 - Make a SubAverage of the Image Stack for Detection Parameters
        useMaxProjection = false;
        detectionStartFrame = 1;
        detectionEndFrame = 25;

        // 4 - Detect Particles Parameters
        cutoff = 0.5;

        left = 25;
        right = 25;
        top = 25; 
        bottom = 25;

        minCount = 0;
        maxCount = 10000;

        minEccentricity = -0.1;
        maxEccentricity = 1.1;

        minLength = 0;
        maxLength = 10000;

        maxDistFromLinear = 10000;

        // 5 - Expand Regions Parameters

        foregroundDist = 4.1;
        backInnerDist = 4.1;
        backOuterDist = 20;

        // 6 - Calculate Traces Parameter
        verboseOutput = false;

        // 7 - View Traces Parameter
        pageNumber = 1;

        // 8 - Detect files for batch
        filesInSubFolders = true;

        // 9 - Batch Analysis
        overwritePreviouslyAnalysed = true;
            
            
    }
    
    void getInputFile(){
        
            OpenDialog fileselector;

                fileselector = new OpenDialog("Select file for analysis");

                completeName = fileselector.getPath();
                
                
                if ("".equals(completeName)){
                        error = 1;
                        return;
                }


                /*gd = new GenericDialog("1) Select Input File and Create a Folder for Results", IJ.getInstance());
                  gd.addMessage("File Selected:");
                  gd.addMessage(completeName);
                  gd.setOKLabel("Continue");
                gd.showDialog(); */



            filnamebaseandext = completeName.split("\\.(?=[^\\.]+$)");
            filnamebaseandext = filnamebaseandext[0].split("\\.(?=[^\\.]+$)");
            workingDir = filnamebaseandext[0]+fileSep;
            
            if(new File(workingDir).exists()==false)
                new File(workingDir).mkdirs();
    }
    
    void driftCorrectImage(){
        
                gd = new GenericDialog("2) Drift Correct", IJ.getInstance());

                gd.addNumericField("Iterations ", iterations, 0);
                gd.addNumericField("Alignment Start Frame", alignStartFrame, 0);
                gd.addNumericField("Alignment End Frame ", alignEndFrame, 0);
                gd.showDialog();
                if (gd.wasCanceled())
                        return;
                iterations = (int) gd.getNextNumber();
                alignStartFrame = (int) gd.getNextNumber();
                alignEndFrame = (int) gd.getNextNumber();
            
                
                String CMD = JIM+"Align_Channels" + fileEXE +" "+quote+ workingDir + "Aligned"+quote +" "+quote+ completeName + quote+ " -Start "+ IJ.d2s(alignStartFrame,0) + " -End " + IJ.d2s(alignEndFrame,0) + " -Iterations "+IJ.d2s(iterations,0);
            
           
                String[] args={};
                Process process;
                Runtime runtime= Runtime.getRuntime();
          try {
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
                
          }catch(Exception e)
          {
                gd = new GenericDialog("Error", IJ.getInstance());
                gd.addMessage("Error During Drift Correction ... ");
                gd.addMessage(CMD);
                gd.addMessage(e.getMessage());
                gd.addMessage(e.getLocalizedMessage());
                gd.addMessage(e.toString());
                gd.showDialog(); 
                error = 1;
              return;
          }
          
          IJ.open(workingDir+"Aligned_initial_mean.tiff");
          IJ.open(workingDir+"Aligned_final_mean.tiff");
            
            gd = new GenericDialog("2) Drift Correct", IJ.getInstance());
            gd.addMessage("Drift Correction Completed");
            gd.addMessage("Before Alignment : Aligned_initial_mean.tiff");
            gd.addMessage("After Alignment : Aligned_final_mean.tiff");
            gd.setOKLabel("Continue");
            gd.showDialog(); 
            if (gd.wasCanceled()){
                error = 2;
            } 
    }
    
    void makeSubImage(){
        

        gd = new GenericDialog("3) Make Sub-Average", IJ.getInstance());
        gd.addMessage("Make a Sub-Average of the Image Stack for Detection");
        gd.addCheckbox("Use Max Projection",useMaxProjection);
        gd.addNumericField("Detection Start Frame", detectionStartFrame, 0);
        gd.addNumericField("Detectin End Frame", detectionEndFrame, 0);
        gd.showDialog();
        if (gd.wasCanceled())
                return;

        useMaxProjection = gd.getNextBoolean();
        detectionStartFrame = (int) gd.getNextNumber();
        detectionEndFrame = (int) gd.getNextNumber();

        String maxProjectionString = "";
        if(useMaxProjection)
            maxProjectionString = " -MaxProjection";

        String CMD = JIM+"Mean_of_Frames" + fileEXE +" NULL "+quote + workingDir + "Aligned_Drifts.csv"+quote+" "+quote + workingDir + "Aligned"+quote+" "+quote +
            completeName+quote+" -Start "+IJ.d2s(detectionStartFrame,0)+ " -End "+IJ.d2s(detectionEndFrame,0)+ maxProjectionString;

       
        String[] args={};
        Process process;
        Runtime runtime= Runtime.getRuntime();
          try {
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
       }catch(Exception e)
       {
           gd = new GenericDialog("Error", IJ.getInstance());
           gd.addMessage("Error During Sub Average Generation ... ");
           gd.addMessage(CMD);
           gd.showDialog(); 
           return;
       }

        IJ.open(workingDir+"Aligned_Partial_Mean.tiff");
                

    }
    
    void detectParticles(){
                  

        gd = new GenericDialog("4) Detect Particles", IJ.getInstance());
        gd.addMessage("Input particle detection parameters : ");

        gd.addNumericField("Threshold Cutoff", cutoff, 2);
        gd.addMessage(" ");
        gd.addNumericField("Min. Distance From Left Edge", left, 0);
        gd.addNumericField("Min. Distance From Right Edge", right, 0);
        gd.addNumericField("Min. Distance From Top Edge", top, 0);
        gd.addNumericField("Min. Distance From Bottom Edge", bottom, 0);
        gd.addNumericField("Min. Pixel Count", minCount, 0);
        gd.addNumericField("Max. Pixel Count", maxCount, 0);
        gd.addNumericField("Min. Eccentricty", minEccentricity, 2);
        gd.addNumericField("Max. Eccentricty", maxEccentricity, 2);
        gd.addNumericField("Min. Length (Pixels)", minLength, 1);
        gd.addNumericField("Max. Length (Pixels)", maxLength, 1);
        gd.addNumericField("Max. Dist. From Linear", maxDistFromLinear, 2);
        gd.showDialog();
        if (gd.wasCanceled())
                return;


        cutoff =  gd.getNextNumber();
        left =  (int) gd.getNextNumber();
        right =  (int) gd.getNextNumber();
        top =  (int) gd.getNextNumber();
        bottom = (int) gd.getNextNumber();
        minCount = (int) gd.getNextNumber();
        maxCount = (int) gd.getNextNumber();
        minEccentricity =  gd.getNextNumber();
        maxEccentricity =  gd.getNextNumber();
        minLength =  gd.getNextNumber();
        maxLength =  gd.getNextNumber();
        maxDistFromLinear =  gd.getNextNumber();


        String CMD = JIM+"Detect_Particles" + fileEXE +" "+quote+workingDir+"Aligned_Partial_Mean.tiff"+quote+" "+quote+workingDir+"Detected"+quote+" -BinarizeCutoff  "+IJ.d2s(cutoff,2)+
                " -minLength "+IJ.d2s(minLength,2)+" -maxLength "+IJ.d2s(maxLength,2)+" -minCount "+IJ.d2s(minCount,0)+" -maxCount "+IJ.d2s(maxCount,0)+" -minEccentricity "+IJ.d2s(minEccentricity,2)+" -maxEccentricity "+IJ.d2s(maxEccentricity,2)+" -maxDistFromLinear "+IJ.d2s(maxDistFromLinear,2)
                + " -left " + IJ.d2s(left,0) + " -right " + IJ.d2s(right,0) + " -top " + IJ.d2s(top,0) + " -bottom " + IJ.d2s(bottom,0);
 
        String[] args={};
        Process process;
        Runtime runtime= Runtime.getRuntime();
          try {
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
       }catch(Exception e)
       {
           gd = new GenericDialog("Error", IJ.getInstance());
           gd.addMessage("Error During Particle Detection ... ");
           gd.addMessage(CMD);
           gd.showDialog(); 
           return;
       }
        ImagePlus channel1Im, channel2Im, channel3Im;

        channel1Im = IJ.openImage(workingDir+"Aligned_Partial_Mean.tiff");
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
    
    void expandROIs(){
                gd = new GenericDialog("5) Expand Regions", IJ.getInstance());
                gd.addMessage("Input Expansion Distances : ");
                gd.addNumericField("Foreground Distance", foregroundDist, 2);
                gd.addNumericField("Background Inner Distance", backInnerDist, 2);
                gd.addNumericField("Background Outer Distance", backOuterDist, 2);
                gd.showDialog();
                if (gd.wasCanceled())
                        return;
                
                foregroundDist =  gd.getNextNumber();
                backInnerDist =  gd.getNextNumber();
                backOuterDist =  gd.getNextNumber();
                
                
                String CMD = JIM+"Expand_Shapes" + fileEXE +" "+quote+workingDir+"Detected_Filtered_Positions.csv"+quote+" "+quote+workingDir+"Detected_Positions.csv"+quote+" "+quote+workingDir+"Expanded"+quote+" -boundaryDist "
                        +IJ.d2s(foregroundDist,2)+" -backgroundDist "+IJ.d2s(backOuterDist)+" -backInnerDist "+IJ.d2s(backInnerDist);

                String[] args={};
                Process process;
                Runtime runtime= Runtime.getRuntime();
          try {
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
               }catch(Exception e)
               {
                   gd = new GenericDialog("Error", IJ.getInstance());
                   gd.addMessage("Error During Region Expansion ... ");
                   gd.addMessage(CMD);
                   gd.showDialog(); 
                   return;
               }
                
                ImagePlus channel1Im,channel2Im,channel3Im;
                channel1Im = IJ.openImage(workingDir+"Aligned_Partial_Mean.tiff");
                channel2Im = IJ.openImage(workingDir+"Expanded_ROIs.tif");
                channel3Im = IJ.openImage(workingDir+"Expanded_Background_Regions.tif");
                
                
                ImageConverter ic2 = new ImageConverter(channel1Im);
                ic2.convertToGray8();
                new ContrastEnhancer().equalize(channel1Im);
                
                ImagePlus[] rgbstack2 = {channel1Im,channel2Im,channel3Im};
                ImagePlus rgbimage2 = RGBStackMerge.mergeChannels(rgbstack2, true);
                rgbimage2.show();
                rgbimage2.setTitle("Red - Detection Image, Green - Foreground Region, Blue - Background Region");               
                
            
        
    }
    
    void measureTraces(){
        
            gd = new GenericDialog("6) Calculate Traces", IJ.getInstance());
            gd.addMessage("Measure Fluorescent Intensity for each region in each frame");
            gd.addCheckbox("Verbose Output",verboseOutput);
            gd.setOKLabel("Create Traces");
            gd.showDialog(); 
            if (gd.wasCanceled())
                    return;
            
            verboseOutput = gd.getNextBoolean();
            
            String verboseString = "";
            if(verboseOutput)
                verboseString = " -Verbose";
            
            
            String CMD = JIM+"Calculate_Traces" + fileEXE +" "+quote+completeName+quote+" "+quote+workingDir+"Expanded_ROI_Positions.csv"+quote+" "+quote+workingDir+"Expanded_Background_Positions.csv"+quote+" "+quote+workingDir+"Channel_1"+quote+" -Drift "+quote+workingDir+"Aligned_Drifts.csv"+quote+verboseString;
            
            String[] args={};
            Process process;
            Runtime runtime= Runtime.getRuntime();
          try {
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
                
                String currentDate = java.time.LocalDate.now().toString();
               
                String variablesString = ("Date, " + currentDate + "\niterations," + IJ.d2s(iterations,0) +
                      "\nalignStartFrame," + IJ.d2s(alignStartFrame,0) + "\nalignEndFrame," + IJ.d2s(alignEndFrame,0) +
                      "\nuseMaxProjection," + IJ.d2s((useMaxProjection?1:0),0) + "\ndetectionStartFrame," + IJ.d2s(detectionStartFrame,0) +
                      "\ndetectionEndFrame," + IJ.d2s(detectionEndFrame,0) + "\ncutoff," + IJ.d2s(cutoff,2) +
                      "\nleft," + IJ.d2s(left,0) + "\nright," + IJ.d2s(right,0) + "\ntop," + IJ.d2s(top,0) + "\nbottom," + IJ.d2s(bottom,0) +
                      "\nminCount," + IJ.d2s(minCount,0) + "\nmaxCount," + IJ.d2s(maxCount,0) +
                      "\nminEccentricity," +IJ.d2s(minEccentricity) + "\nmaxEccentricity," + IJ.d2s(maxEccentricity) +
                      "\nminLength," + IJ.d2s(minLength,2) + "\nmaxLength," + IJ.d2s(maxLength,2) +
                      "\nmaxDistFromLinear," + IJ.d2s(maxDistFromLinear,2) + "\nforegroundDist," + IJ.d2s(foregroundDist,2) +
                      "\nbackInnerDist," + IJ.d2s(backInnerDist,2) + "\nbackOuterDist," + IJ.d2s(backOuterDist,2) +
                      "\nverboseOutput," + IJ.d2s((verboseOutput?1:0),0));
                
                FileWriter fw=new FileWriter(workingDir+"Trace_Generation_Variables.csv");    
                fw.write(variablesString);    
                fw.close();
   
               
           }catch(Exception e)
           {
               gd = new GenericDialog("Error", IJ.getInstance());
               gd.addMessage("Error During Calculating Traces... ");
               gd.addMessage(CMD);
               gd.showDialog(); 
               return;
           }
             
            
            gd = new GenericDialog("6) Calculate Traces", IJ.getInstance());
            gd.addMessage("Traces Generated");
            gd.setOKLabel("Continue");
            gd.showDialog(); 
        
    }
    
void viewTraces(){
    try{
        gd = new GenericDialog("9) View Traces", IJ.getInstance());
        gd.addNumericField("Page Number",pageNumber,0);
        gd.showDialog();
        if (gd.wasCanceled())
                return;
        
        pageNumber =  (int) gd.getNextNumber();
        
        String row;
        int count;
        String[] data;
        BufferedReader csvReader;
        
        ArrayList<ArrayList<Double>> traces = new ArrayList<>();
        ArrayList<ArrayList<Double>> measures = new ArrayList<>();
        
        
        csvReader = new BufferedReader(new FileReader((workingDir+"Channel_1_Fluorescent_Intensities.csv")));
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
        
        Plot plot = new Plot("PageNumber "+IJ.d2s(pageNumber,0),"Frames","Intensity");
        
       // ImagePlus myStack = IJ.createHyperStack("Plot Stack",imp.getWidth(),imp.getHeight(),1,1,36,24);
        count = 0;
        for(int particleCount = 0;particleCount<36;particleCount++){
            int abPartCount = particleCount+36*(pageNumber-1);
            if(abPartCount>= traces.size())break;
            count++;
            plot.setFrameSize(400, 250);
            PlotWindow.noGridLines = false; // draw grid lines
            plot.setAxisLabelFont(Font.BOLD, 40);
            plot.setFont(Font.BOLD, 40);
            //Plot plot = new Plot("Particle "+IJ.d2s(abPartCount+1,0)+" x "+IJ.d2s(measures.get(abPartCount).get(0),0)+" y "+IJ.d2s(measures.get(abPartCount).get(1),0),"Frames","Intensity");
            plot.setLimits(1, traces.get(abPartCount).size(), Collections.min(traces.get(abPartCount)), Collections.max(traces.get(abPartCount)));
            plot.setLineWidth(6);
            plot.setColor(Color.black);
            plot.add("line",frameNumber, axisZero);            
            plot.setColor(Color.red);
            double[] toplot = (traces.get(abPartCount)).stream().mapToDouble(d -> d).toArray(); 
            plot.add("line",frameNumber, toplot);
            
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
        gd.showDialog(); 
        return;
    }
}
    
    void getBatchFiles(){
        
            
            java.util.List<String> subfolderlist;
            
            gd = new GenericDialog("8) Select Files for Batch analyse", IJ.getInstance());
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
            for (File file : files) {
                if (file.isFile() && filesInSubFolders==false) {
                    filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                    if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1]))
                    results.add(file.getPath());
                }
                else if(file.isFile()==false && filesInSubFolders){
                    subfolderlist.add(file.getPath());
                }
            } 
           if (filesInSubFolders) 
           for(String folderin:subfolderlist){
               files = new File(folderin).listFiles();
               for (File file : files) {
                   if (file.isFile()){
                        filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                        if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1]))
                        results.add(file.getPath());
                   }
               }
           }         
            gd = new GenericDialog("8) Select Files for Batch analyse", IJ.getInstance());
            gd.addMessage("Detected Files : ");
            for( int i=0;i<results.size();i++) gd.addMessage(results.get(i));
            gd.setOKLabel("Continue");
            gd.showDialog(); 

        
        
    }
    
    void runBatchFiles(){
            gd = new GenericDialog("9) Batch Analyse", IJ.getInstance());

            gd.setOKLabel("Run Batch");
            gd.showDialog(); 
            if (gd.wasCanceled())
                   return;

   
            
            String maxProjectionString = "";
            if(useMaxProjection)
                maxProjectionString = " -MaxProjection";
            
            String verboseString = "";
            if(verboseOutput)
                verboseString = " -Verbose";
           
        LogStream.redirectSystem();
        try{    
            for (String filenamein : results) {
                System.out.println("Analysing "+filenamein);
                filnamebaseandext = filenamein.split("\\.(?=[^\\.]+$)");
                workingDir = filnamebaseandext[0]+fileSep;
                if(new File(workingDir).exists()==false)
                    new File(workingDir).mkdirs();

                
                String[] args={};
                String CMDString;
                Process process;
                Runtime runtime= Runtime.getRuntime();
                
                String CMD = JIM+"Align_Channels" + fileEXE +" "+quote+ workingDir + "Aligned"+quote +" "+quote+ completeName + quote+ " -Start "+ IJ.d2s(alignStartFrame,0) + " -End " + IJ.d2s(alignEndFrame,0) + " -Iterations "+IJ.d2s(iterations,0);

                

                if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                    args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                    process = runtime.exec(args);
                    process.waitFor();
                }
                else if (OS.indexOf("win") >= 0){
                    CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                    process = runtime.exec(CMDString);
                    process.waitFor();
                } 
              
              
                        
            CMD = JIM+"Mean_of_Frames" + fileEXE +" NULL "+quote + workingDir + "Aligned_Drifts.csv"+quote+" "+quote + workingDir + "Aligned"+quote+" "+quote +
            completeName+quote+" -Start "+IJ.d2s(detectionStartFrame,0)+ " -End "+IJ.d2s(detectionEndFrame,0)+ maxProjectionString;
            
                if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                    args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                    process = runtime.exec(args);
                    process.waitFor();
                }
                else if (OS.indexOf("win") >= 0){
                    CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                    process = runtime.exec(CMDString);
                    process.waitFor();
                }              

            CMD = JIM+"Detect_Particles" + fileEXE +" "+quote+workingDir+"Aligned_Partial_Mean.tiff"+quote+" "+quote+workingDir+"Detected"+quote+" -BinarizeCutoff  "+IJ.d2s(cutoff,2)+
                " -minLength "+IJ.d2s(minLength,2)+" -maxLength "+IJ.d2s(maxLength,2)+" -minCount "+IJ.d2s(minCount,0)+" -maxCount "+IJ.d2s(maxCount,0)+" -minEccentricity "+IJ.d2s(minEccentricity,2)+" -maxEccentricity "+IJ.d2s(maxEccentricity,2)+" -maxDistFromLinear "+IJ.d2s(maxDistFromLinear,2)
                + " -left " + IJ.d2s(left,0) + " -right " + IJ.d2s(right,0) + " -top " + IJ.d2s(top,0) + " -bottom " + IJ.d2s(bottom,0);
                
                if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                    args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                    process = runtime.exec(args);
                    process.waitFor();
                }
                else if (OS.indexOf("win") >= 0){
                    CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                    process = runtime.exec(CMDString);
                    process.waitFor();
                }                      

            CMD = JIM+"Expand_Shapes" + fileEXE +" "+quote+workingDir+"Detected_Filtered_Positions.csv"+quote+" "+quote+workingDir+"Detected_Positions.csv"+quote+" "+quote+workingDir+"Expanded"+quote+" -boundaryDist "
                        +IJ.d2s(foregroundDist,2)+" -backgroundDist "+IJ.d2s(backOuterDist)+" -backInnerDist "+IJ.d2s(backInnerDist);

                if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                    args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                    process = runtime.exec(args);
                    process.waitFor();
                }
                else if (OS.indexOf("win") >= 0){
                    CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                    process = runtime.exec(CMDString);
                    process.waitFor();
                };                

            CMD = JIM+"Calculate_Traces" + fileEXE+" "+quote+completeName+quote+" "+quote+workingDir+"Expanded_ROI_Positions.csv"+quote+" "+quote+workingDir+"Expanded_Background_Positions.csv"+quote+" "+quote+workingDir+"Channel_1"+quote+" -Drift "+quote+workingDir+"Aligned_Drifts.csv"+quote+verboseString;
                
            if ((OS.indexOf("mac") >= 0) || (OS.indexOf("darwin") >= 0)){
                    args = new String[]{ "osascript", "-e", newCMDWindowBefore+CMD+newCMDWindowAfter};
                    process = runtime.exec(args);
                    process.waitFor();
                }
                else if (OS.indexOf("win") >= 0){
                    CMDString =  "cmd.exe /c start /wait " + CMD+" & TIMEOUT 2";                   
                    process = runtime.exec(CMDString);
                    process.waitFor();
                }
                     
                     
                String currentDate = java.time.LocalDate.now().toString();
               
                String variablesString = ("Date, " + currentDate + "\niterations," + IJ.d2s(iterations) +
                      "\nalignStartFrame," + IJ.d2s(alignStartFrame) + "\nalignEndFrame," + IJ.d2s(alignEndFrame) +
                      "\nuseMaxProjection," + IJ.d2s((useMaxProjection?1:0)) + "\ndetectionStartFrame," + IJ.d2s(detectionStartFrame) +
                      "\ndetectionEndFrame," + IJ.d2s(detectionEndFrame) + "\ncutoff," + IJ.d2s(cutoff) +
                      "\nleft," + IJ.d2s(left) + "\nright," + IJ.d2s(right) + "\ntop," + IJ.d2s(top) + "\nbottom," + IJ.d2s(bottom) +
                      "\nminCount," + IJ.d2s(minCount) + "\nmaxCount," + IJ.d2s(maxCount) +
                      "\nminEccentricity," +IJ.d2s(minEccentricity) + "\nmaxEccentricity," + IJ.d2s(maxEccentricity) +
                      "\nminLength," + IJ.d2s(minLength) + "\nmaxLength," + IJ.d2s(maxLength) +
                      "\nmaxDistFromLinear," + IJ.d2s(maxDistFromLinear) + "\nforegroundDist," + IJ.d2s(foregroundDist) +
                      "\nbackInnerDist," + IJ.d2s(backInnerDist) + "\nbackOuterDist," + IJ.d2s(backOuterDist) +
                      "\nverboseOutput," + IJ.d2s((verboseOutput?1:0)));
                
                FileWriter fw=new FileWriter(workingDir+"Trace_Generation_Variables.csv");    
                fw.write(variablesString);    
                fw.close();

            }
            System.out.println("Batch Complete...");
            LogStream.revertSystem();
            IJ.selectWindow("Log");
            IJ.run("Close"); 
            
            gd = new GenericDialog("9) Batch Analyse", IJ.getInstance());
            gd.addMessage("Batch Processing Completed");
            gd.setOKLabel("Continue");
            gd.showDialog(); 
            
        }catch(Exception e)
           {
               gd = new GenericDialog("Error", IJ.getInstance());
               gd.addMessage("Error During Batch Processing... ");
               gd.showDialog(); 
               return;
           }
        
        
    }
    
    void UpdateParameters(){


            gd = new GenericDialog("Update Parameters", IJ.getInstance());
            
            gd.addNumericField("Iterations ", iterations, 0);
            gd.addNumericField("Alignment Start Frame", alignStartFrame, 0);
            gd.addNumericField("Alignment End Frame ", alignEndFrame, 0);
            gd.addMessage(" ");
            
            gd.addCheckbox("Use Max Projection",useMaxProjection);
            gd.addNumericField("Detection Start Frame", detectionStartFrame, 0);
            gd.addNumericField("Detection End Frame", detectionEndFrame, 0);
            gd.addMessage(" ");
            
            gd.addNumericField("Threshold Cutoff", cutoff, 2);
            gd.addNumericField("Min. Distance From Left Edge", left, 0);
            gd.addNumericField("Min. Distance From Right Edge", right, 0);
            gd.addNumericField("Min. Distance From Top Edge", top, 0);
            gd.addNumericField("Min. Distance From Bottom Edge", bottom, 0);
            gd.addNumericField("Min. Pixel Count", minCount, 0);
            gd.addNumericField("Max. Pixel Count", maxCount, 0);
            gd.addNumericField("Min. Eccentricty", minEccentricity, 2);
            gd.addNumericField("Max. Eccentricty", maxEccentricity, 2);
            gd.addNumericField("Min. Length (Pixels)", minLength, 1);
            gd.addNumericField("Max. Length (Pixels)", maxLength, 1);
            gd.addNumericField("Max. Dist. From Linear", maxDistFromLinear, 2);
            gd.addMessage(" ");
     
            gd.addNumericField("Foreground Distance", foregroundDist, 2);
            gd.addNumericField("Background Inner Distance", backInnerDist, 2);
            gd.addNumericField("Background Outer Distance", backOuterDist, 2);
            gd.addMessage(" ");
            gd.addCheckbox("Verbose Output",verboseOutput);
            
            gd.showDialog();
            
            if (gd.wasCanceled())
                    return;
            
            
            iterations = (int) gd.getNextNumber();
            alignStartFrame = (int) gd.getNextNumber();
            alignEndFrame = (int) gd.getNextNumber();
            
            useMaxProjection = gd.getNextBoolean();
            detectionStartFrame = (int) gd.getNextNumber();
            detectionEndFrame = (int) gd.getNextNumber();

            cutoff =  gd.getNextNumber();
            left =  (int) gd.getNextNumber();
            right =  (int) gd.getNextNumber();
            top =  (int) gd.getNextNumber();
            bottom = (int) gd.getNextNumber();
            minCount = (int) gd.getNextNumber();
            maxCount = (int) gd.getNextNumber();
            minEccentricity =  gd.getNextNumber();
            maxEccentricity =  gd.getNextNumber();
            minLength =  gd.getNextNumber();
            maxLength =  gd.getNextNumber();
            maxDistFromLinear =  gd.getNextNumber();
            
            foregroundDist =  gd.getNextNumber();
            backInnerDist =  gd.getNextNumber();
            backOuterDist =  gd.getNextNumber();
            
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
            // do something with the data            
            if(count == 1)iterations=(int)Double.parseDouble(data[1]);
            if(count == 2)alignStartFrame=(int)Double.parseDouble(data[1]);
            if(count == 3)alignEndFrame=(int)Double.parseDouble(data[1]);
            
            
            if(count == 4)useMaxProjection=((int)Double.parseDouble(data[1]))==1;
            if(count == 5)detectionStartFrame=(int)Double.parseDouble(data[1]);
            if(count == 6)detectionEndFrame=(int)Double.parseDouble(data[1]);
            
            if(count == 7)cutoff=Double.parseDouble(data[1]);
            if(count == 8)left=(int)Double.parseDouble(data[1]);
            if(count == 9)right=(int)Double.parseDouble(data[1]);
            if(count == 10)top=(int)Double.parseDouble(data[1]);
            if(count == 11)bottom=(int)Double.parseDouble(data[1]);
            if(count == 12)minCount=(int)Double.parseDouble(data[1]);
            if(count == 13)maxCount=(int)Double.parseDouble(data[1]);
            if(count == 14)minEccentricity=Double.parseDouble(data[1]);
            if(count == 15)maxEccentricity=Double.parseDouble(data[1]);
            if(count == 16)minLength=Double.parseDouble(data[1]);
            if(count == 17)maxLength=Double.parseDouble(data[1]);
            if(count == 18)maxDistFromLinear=Double.parseDouble(data[1]);
            
            if(count == 19)foregroundDist=Double.parseDouble(data[1]);
            if(count == 20)backInnerDist=Double.parseDouble(data[1]);
            if(count == 21)backOuterDist=Double.parseDouble(data[1]);
            
            if(count == 22)verboseOutput=((int)Double.parseDouble(data[1]))==1;
            
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

            String variablesString = ("Date, " + currentDate + "\niterations," + IJ.d2s(iterations,0) +
                  "\nalignStartFrame," + IJ.d2s(alignStartFrame,0) + "\nalignEndFrame," + IJ.d2s(alignEndFrame,0) +
                  "\nuseMaxProjection," + IJ.d2s((useMaxProjection?1:0),0) + "\ndetectionStartFrame," + IJ.d2s(detectionStartFrame,0) +
                  "\ndetectionEndFrame," + IJ.d2s(detectionEndFrame,0) + "\ncutoff," + IJ.d2s(cutoff,2) +
                  "\nleft," + IJ.d2s(left,0) + "\nright," + IJ.d2s(right,0) + "\ntop," + IJ.d2s(top,0) + "\nbottom," + IJ.d2s(bottom,0) +
                  "\nminCount," + IJ.d2s(minCount,0) + "\nmaxCount," + IJ.d2s(maxCount,0) +
                  "\nminEccentricity," +IJ.d2s(minEccentricity) + "\nmaxEccentricity," + IJ.d2s(maxEccentricity) +
                  "\nminLength," + IJ.d2s(minLength,2) + "\nmaxLength," + IJ.d2s(maxLength,2) +
                  "\nmaxDistFromLinear," + IJ.d2s(maxDistFromLinear,2) + "\nforegroundDist," + IJ.d2s(foregroundDist,2) +
                  "\nbackInnerDist," + IJ.d2s(backInnerDist,2) + "\nbackOuterDist," + IJ.d2s(backOuterDist,2) +
                  "\nverboseOutput," + IJ.d2s((verboseOutput?1:0),0));
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
    

    public SingleMainWindow() {
        initComponents();
        this.setTitle("Generate Single Channel Trace");
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
        jTextField3 = new javax.swing.JTextField();
        jButton12 = new javax.swing.JButton();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);

        jButton1.setLabel("1) Select Input File");
        jButton1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton1ActionPerformed(evt);
            }
        });

        jButton2.setText("2) Drift Correct");
        jButton2.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton2ActionPerformed(evt);
            }
        });

        jButton3.setText("3) Make Sub-Average");
        jButton3.setActionCommand("");
        jButton3.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton3ActionPerformed(evt);
            }
        });

        jButton4.setLabel("4) Detect Particles");
        jButton4.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton4ActionPerformed(evt);
            }
        });

        jButton5.setLabel("5) Expand Regions");
        jButton5.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton5ActionPerformed(evt);
            }
        });

        jButton6.setText("6) Calculate Traces");
        jButton6.setActionCommand("Make Traces");
        jButton6.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton6ActionPerformed(evt);
            }
        });

        jButton7.setText("Select Batch Files");
        jButton7.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButton7ActionPerformed(evt);
            }
        });

        jButton8.setText("Run Batch");
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
        jTextField1.setText("Analyse Single File");
        jTextField1.setBorder(null);

        jTextField2.setEditable(false);
        jTextField2.setFont(new java.awt.Font("Tahoma", 1, 12)); // NOI18N
        jTextField2.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        jTextField2.setText("Parameters");
        jTextField2.setBorder(null);

        jTextField3.setEditable(false);
        jTextField3.setFont(new java.awt.Font("Tahoma", 1, 12)); // NOI18N
        jTextField3.setHorizontalAlignment(javax.swing.JTextField.CENTER);
        jTextField3.setText("Batch Process");
        jTextField3.setBorder(null);

        jButton12.setActionCommand("Make Traces");
        jButton12.setLabel("7) View Traces");
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
                    .addComponent(jButton8, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jButton7, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jTextField3)
                    .addComponent(jButton11, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jButton10, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jButton9, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addComponent(jTextField2))
                .addContainerGap(59, Short.MAX_VALUE))
        );

        layout.linkSize(javax.swing.SwingConstants.HORIZONTAL, new java.awt.Component[] {jButton1, jButton10, jButton11, jButton12, jButton2, jButton3, jButton4, jButton5, jButton6, jButton7, jButton8, jButton9, jTextField1, jTextField2, jTextField3});

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
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(jButton4)
                    .addComponent(jTextField3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton5)
                    .addComponent(jButton7))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButton6)
                    .addComponent(jButton8))
                .addGap(5, 5, 5)
                .addComponent(jButton12)
                .addContainerGap(javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void jButton1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton1ActionPerformed
        // TODO add your handling code here:
            getInputFile();
    }//GEN-LAST:event_jButton1ActionPerformed

    private void jButton2ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton2ActionPerformed
        // TODO add your handling code here:
        driftCorrectImage();
    }//GEN-LAST:event_jButton2ActionPerformed

    private void jButton3ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton3ActionPerformed
        // TODO add your handling code here:
        makeSubImage();
    }//GEN-LAST:event_jButton3ActionPerformed

    private void jButton4ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton4ActionPerformed
        // TODO add your handling code here:
        detectParticles();
    }//GEN-LAST:event_jButton4ActionPerformed

    private void jButton5ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton5ActionPerformed
        // TODO add your handling code here:
        expandROIs();
    }//GEN-LAST:event_jButton5ActionPerformed

    private void jButton6ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton6ActionPerformed
        // TODO add your handling code here:
        measureTraces();
    }//GEN-LAST:event_jButton6ActionPerformed

    private void jButton7ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButton7ActionPerformed
        // TODO add your handling code here:
        getBatchFiles();
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
        viewTraces();
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
            java.util.logging.Logger.getLogger(SingleMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(SingleMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(SingleMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(SingleMainWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new SingleMainWindow().setVisible(true);
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
    private javax.swing.JTextField jTextField3;
    // End of variables declaration//GEN-END:variables

}
