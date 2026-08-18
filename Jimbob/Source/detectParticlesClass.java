package Jimbob;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.gui.Overlay;
import ij.gui.Roi;
import ij.process.FloatProcessor;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.Arrays;

public class detectParticlesClass {
    //detection results
    ArrayList<ArrayList<Integer>> expandedForegroundPos,expandedBackgroundPos;
    double[][] myFilteredResults;
    int totPartNum;
    intImage imageForAlignment;
    floatImage imageForDetection;

    ImagePlus detectImStack;

    detectParticlesClass(){};

    detectParticlesClass(detectParticlesClass other){
        expandedForegroundPos = new ArrayList<>();
        for(int i=0;i<other.expandedForegroundPos.size();i++)expandedForegroundPos.add(new ArrayList<>(other.expandedForegroundPos.get(i)));

        expandedBackgroundPos = new ArrayList<>();
        for(int i=0;i<other.expandedBackgroundPos.size();i++)expandedBackgroundPos.add(new ArrayList<>(other.expandedBackgroundPos.get(i)));

        myFilteredResults = new double[other.myFilteredResults.length][];
        for(int i=0;i<other.myFilteredResults.length;i++)myFilteredResults[i] = other.myFilteredResults[i].clone();


        totPartNum = other.totPartNum;
        imageForAlignment = other.imageForAlignment;
        imageForDetection = other.imageForDetection;

        detectImStack = other.detectImStack;

    }

    void imageForDetectFunc(rawDataHandler rawData,paramsClass params,boolean outputDisplay) {

        if(!rawData.isOpen())return;

        //rawData.getImage(0, 0, params.posNum);
        myFFT aligner = new myFFT(params.alignROILength);

        //Declare summed image sizes
        intImage tempImageForAlign = new intImage(params.alignROILength,params.alignROILength);
        imageForAlignment = new intImage(params.alignROILength,params.alignROILength);
        imageForDetection = new floatImage(rawData.imageWidth, rawData.imageHeight);

        //Debug stuff delete when working
       /* ImageStack debugStack = new ImageStack(totImageWidth, totImageHeight);
        ImageStack debugStackCC = new ImageStack(alignROILength, alignROILength);
        float[] debugImage = new float[totNOP];
        */


        //set the bounds for channels that are used for detection and alignment
        int chanStart = 0,chanEnd = rawData.totChanNum;
        if(params.alignChannel>0){
            chanStart = params.alignChannel-1;
            chanEnd = params.alignChannel;
        }

        //Make an initial small stack to align everything to, up to the first 10 frames. Might need to make this number a variable in future
        double[] alignsum = new double[params.alignROILength*params.alignROILength];

        for (int frameNum = params.detectStart; frameNum < Math.min(params.detectEnd,params.detectStart+params.initialSmallStackNum); frameNum++) {
            //get sum of channels
            for (int chanNum = chanStart; chanNum < chanEnd; chanNum++) {
                intImage imData =rawData.getImage(chanNum, frameNum, params.posNum);

                int C2CAlignXin = (chanNum > 0 && params.C2CalignmentX.length >= chanNum) ? params.C2CalignmentX[chanNum - 1] : 0;
                int C2CAlignYin = (chanNum > 0 && params.C2CalignmentY.length >= chanNum) ? params.C2CalignmentY[chanNum - 1] : 0;

                for (int i = 0; i < params.alignROILength; i++)
                    for (int j = 0; j < params.alignROILength; j++) {
                        int xIn = Math.max(0, Math.min(rawData.imageWidth  - 1, i + C2CAlignXin + params.alignmentRectangle.x));
                        int yIn = Math.max(0, Math.min(rawData.imageHeight  - 1, j + C2CAlignYin + params.alignmentRectangle.y));
                        alignsum[i + j * params.alignROILength] = alignsum[i + j * params.alignROILength]+imData.rawImage16[xIn + rawData.imageWidth * yIn];
                    }

            }
        }

        for (int i = 0; i < params.alignROILength*params.alignROILength; i++)
            tempImageForAlign.rawImage16[i] = (int)(alignsum[i]/(Math.min(params.detectEnd-params.detectStart,params.initialSmallStackNum)*(chanEnd-chanStart)));

        aligner.set_Reference_log(tempImageForAlign.rawImage16, params.alignFilterStdDev);

        int[] chanSum;

        for (int frameNum = params.detectStart; frameNum < params.detectEnd; frameNum++) {
            chanSum = new int[rawData.totNOP];
            //get sum of channels
            for (int chanNum = chanStart; chanNum < chanEnd; chanNum++) {
                intImage imData = rawData.getImage(chanNum, frameNum, params.posNum);

                int C2CAlignXin = (chanNum>0 && params.C2CalignmentX.length>=chanNum)?params.C2CalignmentX[chanNum-1]:0;
                int C2CAlignYin = (chanNum>0 && params.C2CalignmentY.length>=chanNum)?params.C2CalignmentY[chanNum-1]:0;

                for(int i=0;i<rawData.imageWidth;i++)for(int j=0;j<rawData.imageHeight;j++){
                    int xIn = Math.max(0, Math.min(rawData.imageWidth-1, i+C2CAlignXin));
                    int yIn = Math.max(0, Math.min(rawData.imageHeight-1, j+C2CAlignYin));
                    chanSum[i+j*rawData.imageWidth] += imData.rawImage16[xIn+rawData.imageWidth*yIn];
                }

            }
            //align image

            for(int i=0;i<params.alignROILength;i++)for(int j=0;j<params.alignROILength;j++)
                tempImageForAlign.rawImage16[i+j*params.alignROILength] = (int)chanSum[params.alignmentRectangle.x+i+(params.alignmentRectangle.y+j)*rawData.imageWidth];
            aligner.align(tempImageForAlign.rawImage16, params.alignMaxShift);
            int xDrift = aligner.maxXPos;
            int yDrift = aligner.maxYPos;

            //add aligned images to stack
            for(int i=0;i<rawData.imageWidth;i++)for(int j=0;j<rawData.imageHeight;j++){
                int xIn = Math.max(0, Math.min(rawData.imageWidth-1, i+xDrift));
                int yIn = Math.max(0, Math.min(rawData.imageHeight-1, j+yDrift));
                imageForDetection.imData[i+j*rawData.imageWidth] += chanSum[xIn+rawData.imageWidth*yIn];
            }


            //debug comment later
           /* getROIImageFloat(chanSum, debugImage, fullImageRec,  xDrift, yDrift, false);
            debugStack.addSlice(new FloatProcessor(totImageWidth, totImageHeight, debugImage.clone()));
            float[] debugCCTemp = new float[alignROILength*alignROILength];
            for(int i=0;i<alignROILength*alignROILength;i++)debugCCTemp[i] = (float)aligner.crosscorr[i];
            debugStackCC.addSlice(new FloatProcessor(alignROILength, alignROILength, debugCCTemp.clone()));*/
        }


        for(int i=0;i<params.alignROILength;i++)for(int j=0;j<params.alignROILength;j++)
            imageForAlignment.rawImage16[i+j*params.alignROILength] = (int)imageForDetection.imData[params.alignmentRectangle.x+i+(params.alignmentRectangle.y+j)*rawData.imageWidth];

        if(outputDisplay) SwingUtilities.invokeLater(new ImagePlus("Detection Image",new FloatProcessor(rawData.imageWidth, rawData.imageHeight, imageForDetection.imData.clone()))::show);

        //show debug comment out later
       /* ImagePlus debugIP = new ImagePlus("Hopefully Drift Corrected", debugStack);
        SwingUtilities.invokeLater(debugIP::show);
        ImagePlus debugCCIP = new ImagePlus("CrossCorrelation", debugStackCC);
        SwingUtilities.invokeLater(debugCCIP::show);*/
    }

    void detectFunc(paramsClass params,boolean outputDisplay){

       /* FloatProcessor meanFP = new FloatProcessor(totImageWidth, totImageHeight, imageForDetection.clone());
        LapOfGauss logClass = new LapOfGauss(31);//31 should be equivilent to current 5
        FloatProcessor logim = logClass.run(meanFP,true);
        float[] flogim = (float[])logim.getPixels();*/

        if (imageForDetection == null) {
            IJ.error("Detection image has not been generated.");
            return;
        }

        myLapOfGaussFFT myLoG = new myLapOfGaussFFT(imageForDetection.imageWidth,imageForDetection.imageHeight);
        double[] flogim = myLoG.laplaceOfGaussian(imageForDetection.imData,params.LoGStdDev);
        for (int i = 0; i < flogim.length; i++)flogim[i] = -flogim[i];

        //Debugging LoG
        /*
        float[] flogimDisplay = new float[flogim.length];
        for (int i = 0; i < flogim.length; i++)flogimDisplay[i] = (float) flogim[i];
        FloatProcessor flogProcessor = new FloatProcessor(
                totImageWidth,
                totImageHeight,
                flogimDisplay
        );
        ImagePlus flogImp = new ImagePlus("LoG filtered image", flogProcessor);
        SwingUtilities.invokeLater(flogImp::show);
        */
        //End debugging LoG

        //find max of detection image for displays of regions
        float detectMax = 0;
        for (float i : imageForDetection.imData) if(i>detectMax)detectMax = i;

        //find threshold based on std dev above mean for LoG image
        double mean = 0;
        for (double i : flogim) {
            mean += i;
        }
        mean = mean / flogim.length;

        double stddev = 0;
        for (double num : flogim) {
            stddev += Math.pow(num - mean, 2);
        }
        stddev =  (float)Math.sqrt(stddev / flogim.length);

        float threshold = (float)(mean+params.cutoff*stddev);
        byte[] detectIm = new byte[imageForDetection.totNOP];
        float[] roiImageFloat = new float[imageForDetection.totNOP];
        for(int i=0;i<flogim.length;i++)
            if(flogim[i]>threshold){
                detectIm[i]=1;
                roiImageFloat[i]=detectMax;
            }


        //measure detected ROIs and filter
        ArrayList<ArrayList<Integer>> detectedPos = new ArrayList<>(),filteredPos = new ArrayList<>();
        ArrayList<Integer> toSelect = new ArrayList<>();
        double[][] myResults = ShapeFunctions.componentMeasurements( detectIm, imageForDetection.imageWidth,  detectedPos);
        System.out.println("Initial Particles Detected = "+detectedPos.size());

        for(int i=0;i<myResults.length;i++){
            if(myResults[i][10]>=params.minCount && myResults[i][10]<=params.maxCount && myResults[i][2]>=params.minEccentricity-0.001 && myResults[i][2]<=params.maxEccentricity+0.001
                    && myResults[i][14]>(params.minDFE) && myResults[i][15]<imageForDetection.imageWidth - (params.minDFE) && myResults[i][16]>(params.minDFE) && myResults[i][17]<imageForDetection.imageHeight - (params.minDFE) &&
                    myResults[i][18] > params.minSeparation)
                toSelect.add(i);
        }
        System.out.println("Filtered Particles Detected = "+toSelect.size());
        myFilteredResults = new double[toSelect.size()][20];
        for(int i=0;i<toSelect.size();i++){
            filteredPos.add(detectedPos.get(toSelect.get(i)));
            myFilteredResults[i] = myResults[toSelect.get(i)];
        }

        //Expand shapes
        expandedForegroundPos = new ArrayList<>();
        expandedBackgroundPos = new ArrayList<>();
        ShapeFunctions.expandShapes(params.padROI, params.padBackground, filteredPos,detectedPos,imageForDetection.imageWidth,imageForDetection.imageHeight,expandedForegroundPos, expandedBackgroundPos);

        totPartNum = expandedForegroundPos.size();

        //display results if required
        if(outputDisplay){
            ImageStack imstackin = new ImageStack(imageForDetection.imageWidth, imageForDetection.imageHeight);
            imstackin.addSlice(new FloatProcessor(imageForDetection.imageWidth, imageForDetection.imageHeight, imageForDetection.imData.clone()));
            imstackin.addSlice(new FloatProcessor(imageForDetection.imageWidth, imageForDetection.imageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : filteredPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = detectMax;
            imstackin.addSlice(new FloatProcessor(imageForDetection.imageWidth, imageForDetection.imageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : expandedForegroundPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = detectMax;
            imstackin.addSlice(new FloatProcessor(imageForDetection.imageWidth, imageForDetection.imageHeight, roiImageFloat.clone()));

            Arrays.fill(roiImageFloat,0);
            for (ArrayList<Integer> ROIIn : expandedBackgroundPos)
                for (Integer posIn : ROIIn) roiImageFloat[posIn] = detectMax;
            imstackin.addSlice(new FloatProcessor(imageForDetection.imageWidth, imageForDetection.imageHeight, roiImageFloat.clone()));

            Overlay detectedOverlay = new Overlay();

            detectImStack = new ImagePlus("Detection", imstackin);
            for(int i=0;i<totPartNum;i++)
                detectedOverlay.add(new Roi(new
                        Rectangle((int)myFilteredResults[i][14]-(int)params.padROI,(int)myFilteredResults[i][16]-(int)params.padROI,(int)(myFilteredResults[i][15]-myFilteredResults[i][14]+1)+2*(int)params.padROI,(int)(myFilteredResults[i][17]-myFilteredResults[i][16]+1)+2*(int)params.padROI)));
            detectImStack.setOverlay(detectedOverlay);

            SwingUtilities.invokeLater(detectImStack::show);

        }

        System.out.println("Particles Detected = "+totPartNum);

    }


    void detectAlignmentFunc(rawDataHandler rawData,paramsClass params,int C2CAlignStartFrame, int C2CAlignEndFrame){

        //add detection in here
        ImageStack imstackin = new ImageStack(rawData.imageWidth, rawData.imageHeight);
        params.C2CalignmentX = new int[rawData.totChanNum - 1];
        params.C2CalignmentY = new int[rawData.totChanNum - 1];

        myFFT aligner = new myFFT(params.alignROILength);
        int[] tempImageForAlign = new int[params.alignROILength*params.alignROILength];
        float[] tempAlignedImage = new float[rawData.totNOP];

        if(C2CAlignStartFrame<0) C2CAlignStartFrame = rawData.totFrameNum+C2CAlignStartFrame;
        else C2CAlignStartFrame = C2CAlignStartFrame-1;

        if(C2CAlignEndFrame<0) C2CAlignEndFrame = rawData.totFrameNum+C2CAlignEndFrame+1;
        for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++) {

            intImage chanSum = new intImage(rawData.imageWidth, rawData.imageHeight);
            for (int frameNum = C2CAlignStartFrame; frameNum < C2CAlignEndFrame; frameNum++) {
                intImage imdata =  rawData.getImage(chanNum, frameNum, params.posNum);
                for (int i = 0; i < rawData.totNOP; i++)chanSum.rawImage16[i] += imdata.rawImage16[i];
            }
            //align image
            if (chanNum==0) {

                aligner.set_Reference_log(chanSum.getROI(params.alignmentRectangle,0,0),params.alignFilterStdDev);

                //for display
                for(int i=0;i<rawData.totNOP;i++)tempAlignedImage[i] = (float)chanSum.rawImage16[i];
            } else{
                aligner.align(chanSum.getROI(params.alignmentRectangle,0,0), params.alignMaxShift);
                params.C2CalignmentX[chanNum-1] = aligner.maxXPos;
                params.C2CalignmentY[chanNum-1] = aligner.maxYPos;

                //for display
                chanSum.getROI(chanSum.fullImageRec,aligner.maxXPos, aligner.maxYPos);
                for(int i=0;i<rawData.totNOP;i++)tempAlignedImage[i] = (float)chanSum.ROIImage[i];

            }
            imstackin.addSlice(new FloatProcessor(rawData.imageWidth, rawData.imageHeight, tempAlignedImage.clone(),null));
        }

        String alignResult = "Aligned Channels";
        for(int i=0;i<params.C2CalignmentX.length;i++)alignResult = alignResult+" Channel "+Integer.toString(i+2)+" x:"+Integer.toString(params.C2CalignmentX[i])+" y: "+Integer.toString(params.C2CalignmentY[i]);

        ImagePlus outputImStack = new ImagePlus(alignResult, imstackin);
        SwingUtilities.invokeLater(outputImStack::show);
    }


}
