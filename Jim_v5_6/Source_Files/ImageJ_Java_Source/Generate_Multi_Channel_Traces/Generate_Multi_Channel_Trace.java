import ij.plugin.PlugIn;
import static javax.swing.WindowConstants.DISPOSE_ON_CLOSE;

/*James Walsh
This plugin generates intensity traces for a single channel data
*/

public class Generate_Multi_Channel_Trace implements PlugIn {

    public void run(String arg) {
        
           // setup_Jim_Programs();
            
            MultiMainWindow mymainwindow = new MultiMainWindow();
            mymainwindow.setDefaultCloseOperation(DISPOSE_ON_CLOSE);
            mymainwindow.setVisible(true);

  
    }
       
}















/*import ij.*;
import ij.plugin.PlugIn;
import ij.gui.*;
import ij.io.*;
import java.io.File;
import ij.process.ImageConverter;
import ij.plugin.RGBStackMerge;
import ij.plugin.ContrastEnhancer;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;
*/
/*James Walsh
This plugin generates intensity traces for a single channel data
*/
/*
public class Generate_Multi_Channel_Trace implements PlugIn {

    public void run(String arg) {
            
            GenericDialog gd;
            NonBlockingGenericDialog nbgd;
            ImagePlus origimage,image1,image2;

        
            String jimpath = (new File("").getAbsolutePath())+"\\plugins\\Jim_Programs\\";
            if(new File(jimpath).exists()==false)
            {
                gd = new GenericDialog("Error Jim Folder not found", IJ.getInstance());
                gd.addMessage("The folder containing JIM analysis programs does not exist in the ImageJ plugin folder.");
                gd.addMessage("Copy the Jim_Programs folder fom the JIM distribution to : ");
                gd.addMessage(jimpath);
                gd.setOKLabel("Close Analysis");
                gd.showDialog();
                return;
            }
            
            
            
            gd = new GenericDialog("1/8 Select File", IJ.getInstance());
              gd.addMessage("To begin, select a multi-channel image stack to analyse.");
              gd.setOKLabel("Select File");
            gd.showDialog(); 
            
            if (gd.wasCanceled())
                    return;
            
            boolean bloop = true;
            OpenDialog fileselector;
            String filename="";
            while(bloop){
                fileselector = new OpenDialog("Select file for analysis");

                filename = fileselector.getPath();
                
                
                if ("".equals(filename))
                        return;


                gd = new GenericDialog("1/8 Select File", IJ.getInstance());
                  gd.addMessage("File Selected:");
                  gd.addMessage(filename);
                  gd.enableYesNoCancel("Reselect File","Continue");
                gd.showDialog(); 

                if (gd.wasCanceled())
                    return;
                else if (gd.wasOKed()==false)
                    bloop = false;
            }
            //fileselector.
            String[] filnamebaseandext = filename.split("\\.(?=[^\\.]+$)");
            filnamebaseandext = filnamebaseandext[0].split("\\.(?=[^\\.]+$)");
            String filenamebase = filnamebaseandext[0]+"\\";

            
            new File(filenamebase).mkdirs();
            
            
            int numofchannels = 2;
            nbgd = new NonBlockingGenericDialog("2/8 Split Channels");
            nbgd.addCheckbox("Use Micromanager Metadata File ",false);
            nbgd.addNumericField("Number of Channels", numofchannels, 0);    
            nbgd.setOKLabel("Split Channels");
            nbgd.showDialog(); 
            if (nbgd.wasCanceled())
                   return;

            boolean bmetafile = nbgd.getNextBoolean();
            numofchannels = (int) nbgd.getNextNumber();
            String CMD;
            LogStream.redirectSystem();
            if (bmetafile){
                String metafilename = filnamebaseandext[0]+"_metadata.txt"; // Finds the metadata file in the same folder as the tiff imagestack with the suffix _metadata.txt
                System.out.println("Using Metadata File :"+metafilename);
                CMD = "\""+jimpath+"TIFFChannelSplitter.exe\" \""+filename+"\" \""+filenamebase+"Images\" -MetadataFile \""+metafilename+"\"";
            }else{
                System.out.println("Number Of Channels set to "+IJ.d2s(numofchannels,0));
                CMD = "\""+jimpath+"TIFFChannelSplitter.exe\" \""+filename+"\" \""+filenamebase+"Images\" -NumberOfChannels "+IJ.d2s(numofchannels,0);
            }
           Process process;
           String line;
          try {
               process = Runtime.getRuntime().exec(CMD);
               System.out.println("Splitting Channels...");
                BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                while ((line = in.readLine()) != null) {
                    System.out.println(line); 
                }
                in.close();
                LogStream.revertSystem();
                IJ.selectWindow("Log");
                IJ.run("Close");    
               process.waitFor();
          }catch(Exception e)
          {
              gd = new GenericDialog("Error", IJ.getInstance());
              gd.addMessage("Error During Drift Correction ... ");
              gd.showDialog(); 
              return;
          }
            
            
          
          
          
          //Align Channels
          
          
          
            double xoffset=0.0;
            double yoffset = 0.0;
            double rotationangle = 0.0;
            double scale=1;
          
          
            
            nbgd = new NonBlockingGenericDialog("3/8 Align and Drift Correct Image Stack");
            nbgd.addCheckbox("Manual Alignment ",false);
            nbgd.addNumericField("X Offset", xoffset, 2);
            nbgd.addNumericField("Y Offset", yoffset, 2);
            nbgd.addNumericField("Rotation Angle", rotationangle, 2);
            nbgd.addNumericField("Scale", scale, 2);

            nbgd.setOKLabel("Align and Drift Correct");
            nbgd.showDialog(); 
            
            if (nbgd.wasCanceled())
                    return;            

            boolean bmanualalignment = nbgd.getNextBoolean();
            xoffset = (int) nbgd.getNextNumber();
            yoffset = (int) nbgd.getNextNumber();
            rotationangle = (int) nbgd.getNextNumber();
            scale = (int) nbgd.getNextNumber();
            

            CMD = "\""+jimpath+"Align_Channels.exe\" \""+filenamebase+"Aligned\"";
            for(int i=0;i<numofchannels;i++)CMD=CMD+" \""+filenamebase+"Images_Channel_"+IJ.d2s(i+1, 0)+".tiff\"";
            if(bmanualalignment)CMD=CMD+" -Alignment "+IJ.d2s(xoffset,2)+" "+IJ.d2s(yoffset,2)+" "+IJ.d2s(rotationangle,2)+" "+IJ.d2s(scale,2);
            
          try {
              LogStream.redirectSystem();
               process = Runtime.getRuntime().exec(CMD);
               System.out.println("Running Channel Alignment...");
                BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                while ((line = in.readLine()) != null) {
                    System.out.println(line); 
                }
                in.close();   
               process.waitFor();
          }catch(Exception e)
          {
              gd = new GenericDialog("Error", IJ.getInstance());
              gd.addMessage("Error During Drift Correction ... ");
              gd.showDialog(); 
              return;
          }
            

            //may need to generlaize this for multichannel
            ImagePlus imagech1,imagech2;
            
            imagech1 = IJ.openImage(filenamebase+"Aligned_initial_mean_1.tiff");
            new ContrastEnhancer().equalize(imagech1);
            imagech2 = IJ.openImage(filenamebase+"Aligned_initial_mean_2.tiff");
            new ContrastEnhancer().equalize(imagech2);
            ImagePlus[] rgbstack = {imagech1,imagech2};  
            ImagePlus rgbimage = RGBStackMerge.mergeChannels(rgbstack, true);
            rgbimage.setTitle("Before alignment");
            rgbimage.show();
            
            imagech1 = IJ.openImage(filenamebase+"Aligned_initial_mean_1.tiff");
            new ContrastEnhancer().equalize(imagech1);
            imagech2 = IJ.openImage(filenamebase+"Aligned_final_mean_aligned_2.tiff");
            new ContrastEnhancer().equalize(imagech2);
            ImagePlus[] rgbstack2 = {imagech1,imagech2};  
            ImagePlus rgbimage2 = RGBStackMerge.mergeChannels(rgbstack2, true);
            rgbimage2.setTitle("After alignment");
            rgbimage2.show();            
            
            nbgd = new NonBlockingGenericDialog("3/8 Drift Correction");
            nbgd.addMessage("Drift Correction Completed");
            nbgd.setOKLabel("Continue");
            nbgd.showDialog(); 
            if (nbgd.wasCanceled())
                    return;
            
            LogStream.revertSystem();
            IJ.selectWindow("Log");
            IJ.run("Close"); 
            
            
            
            
            
            
            
            
            
            
            
            
            int startframe = 1;
            int endframe = 5;
            bloop = true;
            
            while(bloop){
                nbgd = new NonBlockingGenericDialog("4/8 Create Sub-Average");
                nbgd.addMessage("Create sub-average for mask detection");
                nbgd.addMessage("Select start and end frames between which");
                nbgd.addMessage("the majority (~90%) of particles exist");
                nbgd.addNumericField("Start Frame", startframe, 0);
                nbgd.addNumericField("End Frame", endframe, 0);
                nbgd.showDialog();
                if (nbgd.wasCanceled())
                        return;
                startframe = (int) nbgd.getNextNumber();
                endframe = (int) nbgd.getNextNumber();
            
                CMD = "\""+jimpath+"MeanofFrames.exe\" \""+filename+"\" \""+filenamebase+"Aligned_Drifts.csv\" \""+filenamebase+"Aligned\" -End "+IJ.d2s(endframe,0)+" -Start "+IJ.d2s(startframe,0);
                
                try {
                    process = Runtime.getRuntime().exec(CMD);
                    process.waitFor();
               }catch(Exception e)
               {
                   gd = new GenericDialog("Error", IJ.getInstance());
                   gd.addMessage("Error During Sub Average Generation ... ");
                   gd.showDialog(); 
                   return;
               }
                
                
                IJ.open(filenamebase+"Aligned_Partial_Mean.tiff");
                
                  nbgd = new NonBlockingGenericDialog("4/8 Create Sub-Average");
                  nbgd.addMessage("Sub-average created between frame "+IJ.d2s(startframe,0)+" and "+IJ.d2s(endframe,0));
                  nbgd.addMessage("Sub-average shown in Image Aligned_Partial_Mean");
                  nbgd.enableYesNoCancel("Remake Sub-Average","Continue");
                  nbgd.showDialog(); 

                if (nbgd.wasCanceled())
                    return;
                else if (nbgd.wasOKed()==false)
                    bloop = false;
            }
            
            
            
            double cutoff=0.4;
            double mindistfromedge = 25;
            double mincount = 10;
            double maxcount=1000000;
            double mineccentricity = -0.1;
            double maxeccentricity = 1.1;
            double minlength = 0;
            double maxlength = 1000000;
            double maxDistFromLinear = 1000000;
            
            
            bloop = true;
            
            while(bloop){
                nbgd = new NonBlockingGenericDialog("5/8 Detect Particles");
                nbgd.addMessage("Input particle detection parameters : ");

                nbgd.addNumericField("Threshold Cutoff", cutoff, 2);
                nbgd.addMessage(" ");
                nbgd.addNumericField("Min. Distance From Edge", mindistfromedge, 1);
                nbgd.addNumericField("Min. Pixel Count", mincount, 0);
                nbgd.addNumericField("Max. Pixel Count", maxcount, 0);
                nbgd.addNumericField("Min. Eccentricty", mineccentricity, 2);
                nbgd.addNumericField("Max. Eccentricty", maxeccentricity, 2);
                nbgd.addNumericField("Min. Length (Pixels)", minlength, 1);
                nbgd.addNumericField("Max. Length (Pixels)", maxlength, 1);
                nbgd.addNumericField("Max. Dist. From Linear", maxDistFromLinear, 2);
                nbgd.showDialog();
                if (nbgd.wasCanceled())
                        return;
                
                
                cutoff =  nbgd.getNextNumber();
                mindistfromedge =  nbgd.getNextNumber();
                mincount =  nbgd.getNextNumber();
                maxcount =  nbgd.getNextNumber();
                mineccentricity =  nbgd.getNextNumber();
                maxeccentricity =  nbgd.getNextNumber();
                minlength =  nbgd.getNextNumber();
                maxlength =  nbgd.getNextNumber();
                maxDistFromLinear =  nbgd.getNextNumber();
                
            
                CMD = "\""+jimpath+"Find_Particles.exe\" \""+filenamebase+"Aligned_Partial_Mean.tiff\" \""+filenamebase+"Detected\"  -BinarizeCutoff  "+IJ.d2s(cutoff)+" -minLength "+IJ.d2s(minlength)+" -maxLength "+IJ.d2s(maxlength)+" -minCount "+IJ.d2s(mincount)+" -maxCount "+IJ.d2s(maxcount)+" -minEccentricity "+IJ.d2s(mineccentricity)+" -maxEccentricity "+IJ.d2s(maxeccentricity)+" -minDistFromEdge "+IJ.d2s(mindistfromedge)+" -maxDistFromLinear "+IJ.d2s(maxDistFromLinear);
                
                try {
                    process = Runtime.getRuntime().exec(CMD);
                    process.waitFor();
               }catch(Exception e)
               {
                   gd = new GenericDialog("Error", IJ.getInstance());
                   gd.addMessage("Error During Particle Detection ... ");
                   gd.showDialog(); 
                   return;
               }
                
                
                image1 = IJ.openImage(filenamebase+"Detected_Regions.tif");
                image2 = IJ.openImage(filenamebase+"Detected_Filtered_Regions.tif");
                
                origimage = IJ.openImage(filenamebase+"Aligned_Partial_Mean.tiff");
                ImageConverter ic = new ImageConverter(origimage);
                ic.convertToGray8();
                new ContrastEnhancer().equalize(origimage);
                
                ImagePlus[] rgbstack3 = {origimage,image1,image2};
                
                ImagePlus rgbimage3 = RGBStackMerge.mergeChannels(rgbstack3, true);
                
                rgbimage3.show();
                
                  nbgd = new NonBlockingGenericDialog("5/8 Detect Particles");
                  nbgd.addMessage("Red - Original Partial Mean");
                  nbgd.addMessage("Green - Thresholded Regions");
                  nbgd.addMessage("Blue - Filtered Regions");
                  nbgd.enableYesNoCancel("Redetect Particles","Continue");
                  nbgd.showDialog(); 

                if (nbgd.wasCanceled())
                    return;
                else if (nbgd.wasOKed()==false)
                    bloop = false;
            }
            
            double innerradius = 4.1;
            double outerradius = 20;
            
            bloop = true;
            
            while(bloop){
                nbgd = new NonBlockingGenericDialog("6/8 Expand Regions");
                nbgd.addMessage("Input Expansion Distances : ");

                nbgd.addNumericField("Inner radius", innerradius, 2);
                nbgd.addNumericField("Background Radius", outerradius, 2);
                nbgd.showDialog();
                if (nbgd.wasCanceled())
                        return;
                
                innerradius =  nbgd.getNextNumber();
                outerradius =  nbgd.getNextNumber();
                
                
                CMD = "\""+jimpath+"Fit_Arbitrary_Shapes.exe\" \""+filenamebase+"Detected_Filtered_Positions.csv\" \""+filenamebase+"Detected_Positions.csv\" \""+filenamebase+"Expanded\"  -boundaryDist  "+IJ.d2s(innerradius)+" -backgroundDist "+IJ.d2s(outerradius);
                
                try {
                    LogStream.redirectSystem();
                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Expanding Regions of Interest...");
                      BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                      while ((line = in.readLine()) != null) {
                          System.out.println(line); 
                      }
                      in.close();
                      LogStream.revertSystem();
                      IJ.selectWindow("Log");
                      IJ.run("Close");    
                     process.waitFor();
               }catch(Exception e)
               {
                   gd = new GenericDialog("Error", IJ.getInstance());
                   gd.addMessage("Error During Region Expansion ... ");
                   gd.showDialog(); 
                   return;
               }
                
                image1 = IJ.openImage(filenamebase+"Expanded_ROIs.tif");
                image2 = IJ.openImage(filenamebase+"Expanded_Background_Regions.tif");
                
                origimage = IJ.openImage(filenamebase+"Aligned_Partial_Mean.tiff");
                ImageConverter ic2 = new ImageConverter(origimage);
                ic2.convertToGray8();
                new ContrastEnhancer().equalize(origimage);
                
                ImagePlus[] rgbstack4 = {origimage,image1,image2};
                ImagePlus rgbimage4 = RGBStackMerge.mergeChannels(rgbstack4, true);
                rgbimage4.show();
                
                  nbgd = new NonBlockingGenericDialog("6/8 Expand Regions");
                  nbgd.addMessage("Red - Original Partial Mean");
                  nbgd.addMessage("Green - Foreground Region");
                  nbgd.addMessage("Blue - Background Region");
                  nbgd.enableYesNoCancel("Reexpand Regions","Continue");
                  nbgd.showDialog(); 
                
                if (nbgd.wasCanceled())
                    return;
                else if (nbgd.wasOKed()==false)
                    bloop = false;
                
            }
            
            nbgd = new NonBlockingGenericDialog("7/8 Generate Traces");
            nbgd.addMessage("Measure Flourescent Intensity for each region in each frame");
            nbgd.setOKLabel("Create Traces");
            nbgd.showDialog(); 
            if (nbgd.wasCanceled())
                    return;
            
            
            CMD = "\""+jimpath+"AS_Measure_Each_Frame.exe\" \""+filename+"\" \""+filenamebase+"Expanded_ROI_Positions.csv\" \""+filenamebase+"Expanded_Background_Positions.csv\" \""+filenamebase+"Channel_1\"  -Drifts \""+filenamebase+"Aligned_Drifts.csv\"";

            try {
              LogStream.redirectSystem();
               process = Runtime.getRuntime().exec(CMD);
               System.out.println("Creating Traces...");
                BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                while ((line = in.readLine()) != null) {
                    System.out.println(line); 
                }
                in.close();
                LogStream.revertSystem();
                IJ.selectWindow("Log");
                IJ.run("Close");    
               process.waitFor();
           }catch(Exception e)
           {
               gd = new GenericDialog("Error", IJ.getInstance());
               gd.addMessage("Error During Region Expansion ... ");
               gd.showDialog(); 
               return;
           }
            
            
            nbgd = new NonBlockingGenericDialog("7/8 Generate Traces");
            nbgd.addMessage("Traces Generated");
            nbgd.setOKLabel("Continue");
            nbgd.showDialog(); 
            if (nbgd.wasCanceled())
                    return;
    
            
            java.util.List<String> results = new ArrayList<String>();
            java.util.List<String> subfolderlist = new ArrayList<String>();
            bloop = true;
            while(bloop){
                nbgd = new NonBlockingGenericDialog("8/8 Batch analyse Files");
                nbgd.addMessage("Select the folder that contains all image files to analyse");
                nbgd.addCheckbox("Image Files in subfolders",true);

                nbgd.setOKLabel("Select Folder");
                nbgd.showDialog(); 
                if (nbgd.wasCanceled())
                        return;

                boolean binsubfolder = nbgd.getNextBoolean();

                DirectoryChooser dir = new DirectoryChooser("Select Folder containg all image stacks");

                String pathname = dir.getDirectory();

                results = new ArrayList<>();
                subfolderlist = new ArrayList<>();

                File[] files = new File(pathname).listFiles();
                //If this pathname does not denote a directory, then listFiles() returns null. 

                for (File file : files) {
                    if (file.isFile() && binsubfolder==false) {
                        filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                        if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1]))
                        results.add(file.getPath());
                    }
                    else if(file.isFile()==false && binsubfolder){
                        subfolderlist.add(file.getPath());
                    }
                }

               if (binsubfolder) 
               for(String folderin:subfolderlist){
                   files = new File(folderin).listFiles();
                   for (File file : files) {
                        filnamebaseandext = file.getPath().split("\\.(?=[^\\.]+$)");
                        if("TIFF".equals(filnamebaseandext[1])||"tiff".equals(filnamebaseandext[1])||"TIF".equals(filnamebaseandext[1])||"tif".equals(filnamebaseandext[1])||"tf8".equals(filnamebaseandext[1]))
                        results.add(file.getPath());
                   }

               }

                nbgd = new NonBlockingGenericDialog("8/8 Batch analyse Files");
                nbgd.addMessage("Detected Files : ");
                for( int i=0;i<results.size();i++) nbgd.addMessage(results.get(i));
                nbgd.enableYesNoCancel("Reselect Folder","Continue");
                nbgd.showDialog(); 
                    if (nbgd.wasCanceled())
                        return;
                    else if (nbgd.wasOKed()==false)
                        bloop = false;
            }
            
        boolean bverbose = false;
        LogStream.redirectSystem();
        try{    
            for (String filenamein : results) {
                System.out.println("Analysing "+filenamein);
                filnamebaseandext = filenamein.split("\\.(?=[^\\.]+$)");
                filenamebase = filnamebaseandext[0]+"\\";           
                new File(filenamebase).mkdirs();

                CMD = "\""+jimpath+"Align_Channels.exe\" \""+filenamebase+"Aligned\" \""+filenamein+"\"";
                    
                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Running Channel Alignment...");
                     if (bverbose){
                        BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                        while ((line = in.readLine()) != null) {
                            System.out.println(line); 
                        }
                        in.close();
                     }   
                     process.waitFor();
                        
                CMD = "\""+jimpath+"MeanofFrames.exe\" \""+filenamein+"\" \""+filenamebase+"Aligned_Drifts.csv\" \""+filenamebase+"Aligned\" -End "+IJ.d2s(endframe,0)+" -Start "+IJ.d2s(startframe,0);
                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Generating Mean of Frames...");
                     if (bverbose){
                        BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                        while ((line = in.readLine()) != null) {
                            System.out.println(line); 
                        }
                        in.close();
                     }   
                     process.waitFor();                

                CMD = "\""+jimpath+"Find_Particles.exe\" \""+filenamebase+"Aligned_Partial_Mean.tiff\" \""+filenamebase+"Detected\"  -BinarizeCutoff  "+IJ.d2s(cutoff)+" -minLength "+IJ.d2s(minlength)+" -maxLength "+IJ.d2s(maxlength)+" -minCount "+IJ.d2s(mincount)+" -maxCount "+IJ.d2s(maxcount)+" -minEccentricity "+IJ.d2s(mineccentricity)+" -maxEccentricity "+IJ.d2s(maxeccentricity)+" -minDistFromEdge "+IJ.d2s(mindistfromedge)+" -maxDistFromLinear "+IJ.d2s(maxDistFromLinear);
                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Detecting Particles...");
                     if (bverbose){
                        BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                        while ((line = in.readLine()) != null) {
                            System.out.println(line); 
                        }
                        in.close();
                     }   
                     process.waitFor();                        

                CMD = "\""+jimpath+"Fit_Arbitrary_Shapes.exe\" \""+filenamebase+"Detected_Filtered_Positions.csv\" \""+filenamebase+"Detected_Positions.csv\" \""+filenamebase+"Expanded\"  -boundaryDist  "+IJ.d2s(innerradius)+" -backgroundDist "+IJ.d2s(outerradius);
                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Expanding ROIs...");
                     if (bverbose){
                        BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                        while ((line = in.readLine()) != null) {
                            System.out.println(line); 
                        }
                        in.close();
                     }   
                     process.waitFor();                

                CMD = "\""+jimpath+"AS_Measure_Each_Frame.exe\" \""+filenamein+"\" \""+filenamebase+"Expanded_ROI_Positions.csv\" \""+filenamebase+"Expanded_Background_Positions.csv\" \""+filenamebase+"Channel_1\"  -Drifts \""+filenamebase+"Aligned_Drifts.csv\"";

                     process = Runtime.getRuntime().exec(CMD);
                     System.out.println("Expanding ROIs...");
                     if (bverbose){
                        BufferedReader in = new BufferedReader(new InputStreamReader(process.getInputStream()));
                        while ((line = in.readLine()) != null) {
                            System.out.println(line); 
                        }
                        in.close();
                     }   
                     process.waitFor(); 

            }
            System.out.println("Batch Complete...");
            LogStream.revertSystem();
            IJ.selectWindow("Log");
            IJ.run("Close"); 
            
            nbgd = new NonBlockingGenericDialog("8/8 Batch Processing");
            nbgd.addMessage("Batch Processing Completed");
            nbgd.setOKLabel("Continue");
            nbgd.showDialog(); 
            if (nbgd.wasCanceled())
                    return;
            
        }catch(Exception e)
           {
               gd = new GenericDialog("Error", IJ.getInstance());
               gd.addMessage("Error During Batch Processing... ");
               gd.showDialog(); 
               return;
           }
        
    }
    
}
*/
