package Jimbob;

import ij.IJ;
import ij.gui.GenericDialog;
import org.micromanager.data.Coords;
import org.micromanager.data.DataProvider;
import org.micromanager.data.Datastore;
import org.micromanager.data.Metadata;
import org.micromanager.data.internal.DefaultCoords;
import org.micromanager.display.DataViewer;
import org.micromanager.display.DisplayManager;

import java.awt.*;
import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;

public class rawDataHandler {

    DataViewer myDataViewerin;
    int totChanNum,totFrameNum,totPosNum;
    int currentFrame, currentPos;
    int imageWidth = 1,imageHeight = 1, totNOP = 1;
    intImage imData;

    //Micromanager hooks

    DataProvider myDataProvider;
    Coords.Builder newcoordsBuilder ;

    rawDataHandler(rawDataHandler other){
        myDataViewerin = other.myDataViewerin;
        totChanNum = other.totChanNum;
        totFrameNum = other.totFrameNum;
        totPosNum = other.totPosNum;
        currentFrame = other.currentFrame;
        currentPos = other.currentPos;
        imageWidth = other.imageWidth;
        imageHeight = other.imageHeight;
        totNOP = other.totNOP;
        imData = new intImage(imageWidth,imageHeight);
        myDataProvider = other.myDataProvider;
        newcoordsBuilder = myDataViewerin.getDisplayPosition().copyBuilder();

    }

    rawDataHandler(DataViewer myDataViewer){
        updateDataSet(myDataViewer);
    }

    void updateDataSet(DataViewer myDataViewer){
        try {
            myDataViewerin = myDataViewer;

            myDataProvider = myDataViewer.getDataProvider();
            newcoordsBuilder = myDataViewer.getDisplayPosition().copyBuilder();
            Coords nextCoords = newcoordsBuilder.build();
            imageWidth = myDataProvider.getImage(nextCoords).getWidth();
            imageHeight = myDataProvider.getImage(nextCoords).getHeight();
            totNOP = imageHeight*imageWidth;
            imData = new intImage(imageWidth,imageHeight);
            totChanNum = myDataProvider.getNextIndex("channel");
            totFrameNum = myDataProvider.getNextIndex("time");
            totPosNum = myDataProvider.getNextIndex("position");
            currentFrame = newcoordsBuilder.build().getT();
            currentPos = newcoordsBuilder.build().getP();


        } catch (java.io.IOException e1) {
            System.out.println("Error!!! no image detected!!! ");
            GenericDialog gd = new GenericDialog("Error - no image detected");
            gd.addMessage("Error - Please select image from top drop down menu");
            gd.showDialog();
            return;
        }
    }

    boolean isOpen(){
        return myDataViewerin!=null && myDataViewerin.isVisible();
    }

    int getCurrentPos(){
        newcoordsBuilder = myDataViewerin.getDisplayPosition().copyBuilder();
        return newcoordsBuilder.build().getP();
    }

    double getFrameInterval(){

        try{
        newcoordsBuilder = newcoordsBuilder.t(0);
        newcoordsBuilder = newcoordsBuilder.c(0);
        newcoordsBuilder = newcoordsBuilder.p(currentPos);
        Coords nextCoords = newcoordsBuilder.build();
        double startTime= myDataProvider.getImage(nextCoords).getMetadata().getElapsedTimeMs(0);

        newcoordsBuilder = newcoordsBuilder.t(totFrameNum-1);
        nextCoords = newcoordsBuilder.build();
        double endTime= myDataProvider.getImage(nextCoords).getMetadata().getElapsedTimeMs(0);

        return (totFrameNum>1? (double)Math.round((endTime-startTime)/(totFrameNum-1)/10)/100:0);
        } catch (java.io.IOException e1) {
            System.out.println("Error!!! no image detected!!! ");
            GenericDialog gd = new GenericDialog("Error - no image detected");
            gd.addMessage("Error - Please select image from top drop down menu");
            gd.showDialog();
            return 0;
        }

    }

    intImage getImage(int chanNum, int frameNum,int posNum){

        try {
            newcoordsBuilder = newcoordsBuilder.t(frameNum);
            newcoordsBuilder = newcoordsBuilder.c(chanNum);
            newcoordsBuilder = newcoordsBuilder.p(posNum);
            Coords nextCoords = newcoordsBuilder.build();
            if(imData.imageWidth!=myDataProvider.getImage(nextCoords).getWidth() || imData.imageHeight!=myDataProvider.getImage(nextCoords).getHeight()){
                imData = new intImage(myDataProvider.getImage(nextCoords).getWidth(),myDataProvider.getImage(nextCoords).getHeight());
            }

            Object pixels = myDataProvider.getImage(nextCoords).getRawPixels();

            if (pixels instanceof short[]) {
                short[] src = (short[]) pixels;
                for (int i = 0; i < src.length; i++) {
                    imData.rawImage16[i] = Short.toUnsignedInt(src[i]);
                }
            } else if (pixels instanceof byte[]) {
                byte[] src = (byte[]) pixels;
                for (int i = 0; i < src.length; i++) {
                    imData.rawImage16[i] = Byte.toUnsignedInt(src[i]);
                }
            } else {
                throw new IllegalArgumentException("Unsupported pixel type: " + pixels.getClass().getName());
            }


        } catch (java.io.IOException e1) {
            System.out.println(e1);

            IJ.error("Error Getting Image "+ e1.toString());


            imData = new intImage(imageWidth,imageHeight);
            return imData;
        }

        return imData;
    }

    String getFolderName(int posNum,String folderName, boolean createDirectoryIfNotExist){//String folderName = batchDirectoryBox.getText();
        try{
            newcoordsBuilder = newcoordsBuilder.t(0);
            newcoordsBuilder = newcoordsBuilder.c(0);
            newcoordsBuilder = newcoordsBuilder.p(posNum);
            Coords nextCoords = newcoordsBuilder.build();

            Metadata myMetadata= myDataProvider.getImage(nextCoords).getMetadata();
            String fileName = myMetadata.getFileName();


            //System.out.println(fileName);

            if(fileName==null || fileName.isEmpty())fileName = folderName+ File.separator+"Analysis"+File.separator;
            else fileName = folderName+File.separator+fileName.substring(0, Math.max(fileName.length() - 8,0))+File.separator;

            if(createDirectoryIfNotExist) Files.createDirectories(Paths.get(fileName));

            return  fileName;
        } catch (java.io.IOException e1) {

            return "";
        }

    }

    String getCurrentDataDirectory() {
        if (myDataViewerin != null) {
            Datastore store = myDataViewerin.getDatastore();
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

}
