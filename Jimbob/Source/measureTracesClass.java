package Jimbob;

import ij.ImagePlus;
import ij.ImageStack;
import ij.gui.Plot;
import ij.gui.PlotWindow;
import ij.io.FileSaver;
import ij.plugin.HyperStackConverter;
import ij.plugin.MontageMaker;
import ij.process.ImageProcessor;
import ij.process.ShortProcessor;

import javax.swing.*;
import java.awt.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;

public class measureTracesClass {

    double[][][] tracesCPF,backTracesCPF;//[channel][frame][particle];
    int[][] allDrifts;

    double[][] meanTrace, meanBackTrace;
    ImagePlus alignedImStack;

    int totChanNum;
    int totFrameNum;
    int totPartNum;


    void measureTracesFunc(rawDataHandler rawData, detectParticlesClass detected, paramsClass params,boolean outputDisplay){

        int[][] allChanRawImage16 = new int[rawData.totChanNum][rawData.totNOP];

        int[] imageHold = new int[rawData.totNOP];

        intImage intImageHold = new intImage(rawData.imageWidth, rawData.imageHeight);
        short[] shortHold = new short[rawData.totNOP];

        allDrifts = new int[2][rawData.totFrameNum];
        int[] tempImageForAlign = new int[params.alignROILength*params.alignROILength];
        myFFT aligner = new myFFT(params.alignROILength);

        aligner.set_Reference_log(detected.imageForAlignment.rawImage16,params.measureAlignStdDev);

        //calculate frames used for alignment
        int chanStart = 0,chanEnd = rawData.totChanNum;

        //Future add option to drift correct using all channels
        if(params.alignChannel>0 && params.driftCorrectOnlyDetect){
            chanStart = params.alignChannel-1;
            chanEnd = params.alignChannel;
        }

        ImageStack imstackin = new ImageStack(rawData.imageWidth, rawData.imageHeight);


        totChanNum = rawData.totChanNum;
        totFrameNum = rawData.totFrameNum;
        totPartNum = detected.totPartNum;

        tracesCPF = new double[totChanNum][totPartNum][totFrameNum];
        backTracesCPF = new double[totChanNum][totPartNum][totFrameNum];



        for (int frameNum = 0; frameNum < totFrameNum; frameNum++) {
            //read images
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                int C2CAlignXin = (chanNum>0 && params.C2CalignmentX.length>=chanNum)?params.C2CalignmentX[chanNum-1]:0;
                int C2CAlignYin = (chanNum>0 && params.C2CalignmentY.length>=chanNum)?params.C2CalignmentY[chanNum-1]:0;

                intImage imageIn = rawData.getImage(chanNum, frameNum, params.posNum);
                allChanRawImage16[chanNum] = imageIn.getROI(imageIn.fullImageRec, C2CAlignXin, C2CAlignYin).clone();
            }

            //align images

            //get sum of channels used for alignment
            intImage chanSum = new intImage(rawData.imageWidth,rawData.imageHeight);
            for (int chanNum = chanStart; chanNum < chanEnd; chanNum++)
                for(int i=0;i<rawData.totNOP;i++)chanSum.rawImage16[i] += (int)allChanRawImage16[chanNum][i];

            //align image
            tempImageForAlign = chanSum.getROI(params.alignmentRectangle,0,0);
            aligner.align(tempImageForAlign, params.alignMaxShift);

            allDrifts[0][frameNum] = aligner.maxXPos;
            allDrifts[1][frameNum] = aligner.maxYPos;


            //add aligned images to stack
            if (outputDisplay && params.displayAlignedStack) {
                for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++) {
                    intImageHold.rawImage16 = allChanRawImage16[chanNum];
                    imageHold = intImageHold.getROI(intImageHold.fullImageRec, allDrifts[0][frameNum], allDrifts[1][frameNum]);
                    for (int holdCount = 0;holdCount<rawData.totNOP;holdCount++)shortHold[holdCount] = (short)imageHold[holdCount];
                    imstackin.addSlice(new ShortProcessor(rawData.imageWidth, rawData.imageHeight, shortHold.clone(),null));
                }
            }


            //calculate traces
            int xIn,yIn;
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                for (int partNum = 0; partNum < detected.expandedForegroundPos.size(); partNum++) {
                    long foregroundSum = 0;
                    long backgroundSum = 0;
                    int foregroundCount = 0;
                    int backgroundCount = 0;
                    for(int i=0;i<detected.expandedForegroundPos.get(partNum).size();i++){
                        xIn = detected.expandedForegroundPos.get(partNum).get(i)%rawData.imageWidth + allDrifts[0][frameNum];
                        yIn = detected.expandedForegroundPos.get(partNum).get(i)/rawData.imageWidth + allDrifts[1][frameNum];
                        if(xIn>=0 && yIn>=0 && xIn<rawData.imageWidth && yIn<rawData.imageHeight){
                            foregroundSum += allChanRawImage16[chanNum][xIn + yIn * rawData.imageWidth];
                            foregroundCount++;
                        }
                    }
                    for(int i=0;i<detected.expandedBackgroundPos.get(partNum).size();i++){
                        xIn = detected.expandedBackgroundPos.get(partNum).get(i)%rawData.imageWidth + allDrifts[0][frameNum];
                        yIn = detected.expandedBackgroundPos.get(partNum).get(i)/rawData.imageWidth + allDrifts[1][frameNum];
                        if(xIn>=0 && yIn>=0 && xIn<rawData.imageWidth && yIn<rawData.imageHeight){
                            backgroundSum += allChanRawImage16[chanNum][xIn + yIn * rawData.imageWidth];
                            backgroundCount++;
                        }
                    }

                    // System.out.println(String.valueOf(foregroundSum)+" "+String.valueOf(backgroundSum)+" "+String.valueOf(pixelCountRatio)+" "+String.valueOf(foregroundSum - (backgroundSum * pixelCountRatio)));
                    if(foregroundCount>0 && backgroundCount>0) {
                        tracesCPF[chanNum][partNum][frameNum] = (foregroundSum - ((double)backgroundSum * foregroundCount / backgroundCount));
                        backTracesCPF[chanNum][partNum][frameNum] = (double)backgroundSum / backgroundCount;
                    }
                }
            }
        }

        //Make Mean Trace
        meanTrace = new double[totChanNum][totFrameNum];
        meanBackTrace = new double[totChanNum][totFrameNum];
        for (int chanNum = 0; chanNum <totChanNum; chanNum++)
            for (int frameNum = 0; frameNum < totFrameNum; frameNum++)
                for (int partNum = 0; partNum < tracesCPF[0].length; partNum++) {
                    meanTrace[chanNum][frameNum] += tracesCPF[chanNum][partNum][frameNum] / tracesCPF[0].length;
                    meanBackTrace[chanNum][frameNum] += backTracesCPF[chanNum][partNum][frameNum] / tracesCPF[0].length;
                }


        if(outputDisplay && params.displayAlignedStack) {
            alignedImStack = new ImagePlus("Aligned Stack ", imstackin);
            alignedImStack = new HyperStackConverter().toHyperStack(alignedImStack, totChanNum, 1, totFrameNum, "CZT", "grayscale");
            SwingUtilities.invokeLater(alignedImStack::show);
        }

        //make mean plots and save if needed

        double[][] meanNormedTrace = new double[rawData.totChanNum][rawData.totFrameNum];
        double maxval;
        if(params.bNormalizeTraces){
            for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++) {
                maxval = 0;
                for (int frameNum = 0; frameNum < rawData.totFrameNum; frameNum++)if(meanTrace[chanNum][frameNum]>maxval)maxval = meanTrace[chanNum][frameNum];
                if(maxval==0)maxval=1;
                for (int frameNum = 0; frameNum < rawData.totFrameNum; frameNum++)meanNormedTrace[chanNum][frameNum] = meanTrace[chanNum][frameNum]/maxval;
            }
        } else{
            for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++)
                for (int frameNum = 0; frameNum < rawData.totFrameNum; frameNum++)
                    meanNormedTrace[chanNum][frameNum] = meanTrace[chanNum][frameNum];
        }

        //plot mean trace
        myPlot plot = new myPlot("Mean Trace "+tracesCPF[0].length+" Particles", "Time ("+params.timePerFrameUnits+")", "Intensity (a.u.)");
        double[] frames = new double[rawData.totFrameNum];
        for (int frameNum = 0; frameNum < rawData.totFrameNum; frameNum++)frames[frameNum] = frameNum*params.timePerFrame;
        for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++) plot.addLine(frames, meanNormedTrace[chanNum]);
        plot.saveAndDisplay(params.saveTraces,params.fileBase +"Mean_Trace.png",true,outputDisplay);


        //plot background trace
        plot = new myPlot("Mean Background Trace", "Time ("+params.timePerFrameUnits+")", "Intensity (a.u.)");
        for (int chanNum = 0; chanNum < rawData.totChanNum; chanNum++)plot.addLine(frames, meanBackTrace[chanNum]);
        plot.saveAndDisplay(params.saveTraces,params.fileBase +"Mean_Background_Trace.png",true, outputDisplay);


        //plot Drifts
        plot = new myPlot("Sample Drift", "Time ("+params.timePerFrameUnits+")","Pixels");
        for (int chanNum = 0; chanNum < 2; chanNum++) plot.addLine(frames, Arrays.stream(allDrifts[chanNum]).asDoubleStream().toArray());
        plot.saveAndDisplay(false,"",true, outputDisplay);


        if(params.saveTraces){
            try {
                Files.createDirectories(Paths.get(params.fileBase));

                String headerString = "xCentre,yCentre,eccentricity,xMajorAxis,yMajorAxis,length,xEnd1LinFit,yEnd1LinFit,xEnd2LinFit" +
                        ",yEnd2LinFit,count,xMaxPos,yMaxPos,maxDistFromLinear,xBoundingBoxMin,"+
                        "xBoundingBoxMax,yBoundingBoxMin,yBoundingBoxMax,nearestNeighbour,squared moment anisotropy";

                ShapeFunctions.writeCSV(params.fileBase + "Detected_Filtered_Measurements.csv", detected.myFilteredResults,headerString,false);

                for (int chanCount = 0; chanCount < rawData.totChanNum; chanCount++) {
                    ShapeFunctions.writeCSV(params.fileBase + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Intensities.csv", tracesCPF[chanCount],"Each row is a particle. Each column is a Frame",false);
                    ShapeFunctions.writeCSV(params.fileBase + "Channel_" + String.valueOf(chanCount + 1) + "_Fluorescent_Backgrounds.csv", backTracesCPF[chanCount],"Each row is a particle. Each column is a Frame",false);
                }

                params.writeUsedParametersCSV(params.fileBase + "Jimbob_Parameters.csv");
            }catch(Exception e) {
                System.out.println(e);
            }
        }//end writing out traces

    }

    void plotPageOfTraces(int pageNo,paramsClass params,detectParticlesClass detected){

        double[] frames = new double[totFrameNum];
        for (int frameNum = 0; frameNum < totFrameNum; frameNum++)frames[frameNum] = frameNum*params.timePerFrame;

        int startTrace = (pageNo-1)*36;

        ImageStack imstackin = null;
        double[] toplot = new double[totFrameNum];
        for (int partNum = startTrace; partNum < Math.min(totPartNum, startTrace + 36); partNum++) {
            myPlot plot = new myPlot("Particle " + String.valueOf(partNum + 1), "Time (" + params.timePerFrameUnits + ")", "Intensity");
            plot.plot.addLabel(0.2,0.01,"No. "+String.valueOf(partNum + 1)+" X "+String.valueOf((int)detected.myFilteredResults[partNum][0])+" Y "+String.valueOf((int)detected.myFilteredResults[partNum][1]));
            for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
                for (int framenum = 0; framenum < totFrameNum; framenum++) toplot[framenum] = tracesCPF[chanNum][partNum][framenum];
                if (params.bNormalizeTraces)plot.addNormalizedLine(frames,toplot);
                else plot.addLine(frames,toplot);
            }
            plot.setPlotLimitsWithYBuffer(true);
            ImagePlus plotIm2 = plot.plot.makeHighResolution("Particle " + String.valueOf(partNum + 1), 1.0f, true, false);
            if(imstackin==null)imstackin = new ImageStack(plotIm2.getWidth(), plotIm2.getHeight());
            imstackin.addSlice((ImageProcessor) plotIm2.getProcessor().clone());
        }

        if(imstackin!=null && imstackin.size()>0) {
            ImagePlus outputImStack = new ImagePlus("Detection", imstackin);
            MontageMaker myMaker = new MontageMaker();
            ImagePlus outputMontage = myMaker.makeMontage2(outputImStack, 6, 6, 1, 1, imstackin.size(), 1, 0, false);
            //if(saveTraces) new FileSaver(outputMontage).saveAsPng(getFolderName()+"Example_Traces_Page_"+Integer.parseInt(pageNumberBox.getText())+".png");
            if(params.saveTraces) new FileSaver(outputMontage).saveAsPng(params.fileBase+"Example_Traces_Page_"+pageNo+".png");
            outputMontage.show();
        }
    }

    void plotSingleTrace(int partNum,paramsClass params){

        int totChanNum = tracesCPF.length;
        int totFrameNum = tracesCPF[0][0].length;
        int totPartNum = tracesCPF[0].length;

        double[] frames = new double[totFrameNum];
        for (int frameNum = 0; frameNum < totFrameNum; frameNum++)frames[frameNum] = frameNum*params.timePerFrame;


        double[] toplot = new double[totFrameNum];

        myPlot plot = new myPlot("Particle " + String.valueOf(partNum + 1), "Time (" + params.timePerFrameUnits + ")", "Intensity");
        for (int chanNum = 0; chanNum < totChanNum; chanNum++) {
            for (int framenum = 0; framenum < totFrameNum; framenum++) toplot[framenum] = tracesCPF[chanNum][partNum][framenum];
            if (params.bNormalizeTraces)plot.addNormalizedLine(frames,toplot);
            else plot.addLine(frames,toplot);
        }

        plot.saveAndDisplay(false,"",true, true);


    }

}
