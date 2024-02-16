package org.micromanager.plugins.Poor_Mans_JIM;

import ij.ImagePlus;
import ij.gui.Roi;
import ij.process.FloatProcessor;

import java.awt.*;

public class ImageAligner {
    myFHT aligner;
    int alignROILength,totImageWidth,totImageHeight,maxShift, xDrift,yDrift;
    Rectangle centreRect;
    float[] ROIImageF;
    ImageAligner(int alignROILengthIn, int totImageWidthIn, int totImageHeightIn, int maxShiftIn){
        alignROILength = alignROILengthIn;
        totImageWidth = totImageWidthIn;
        totImageHeight = totImageHeightIn;
        maxShift = maxShiftIn;

        aligner = new myFHT(alignROILength);

        centreRect = new Rectangle((totImageWidth - alignROILength) / 2, (totImageHeight - alignROILength) / 2, alignROILength, alignROILength);

        ROIImageF = new float[alignROILength*alignROILength];
        xDrift = 0;
        yDrift = 0;

    }

    void getROIImageFloat(short[] imageIn){

        for (int i = 0; i < centreRect.width; i++)
            for (int j = 0; j < centreRect.height; j++) {
                int xIn = (i + centreRect.x);
                if(xIn<0)xIn=0;
                if(xIn>=totImageWidth)xIn = totImageWidth-1;
                int yIn = (j + centreRect.y);
                if(yIn<0)yIn=0;
                if(yIn>=totImageHeight)yIn = totImageHeight-1;

                ROIImageF[i + j * centreRect.width] = imageIn[(xIn + yIn * totImageWidth)];
            }
    }

    void getROIImageFloat(float[] imageIn){

        for (int i = 0; i < centreRect.width; i++)
            for (int j = 0; j < centreRect.height; j++) {
                int xIn = (i + centreRect.x);
                if(xIn<0)xIn=0;
                if(xIn>=totImageWidth)xIn = totImageWidth-1;
                int yIn = (j + centreRect.y);
                if(yIn<0)yIn=0;
                if(yIn>=totImageHeight)yIn = totImageHeight-1;

                ROIImageF[i + j * centreRect.width] = imageIn[(xIn + yIn * totImageWidth)];
            }
    }

    void set_Reference(short[] imageIn){
        getROIImageFloat(imageIn);
        aligner.set_Reference(ROIImageF);
        //new ImagePlus("Reference",new FloatProcessor(centreRect.width,centreRect.height,ROIImageF.clone())).show();
    }

    void set_Reference(float[] imageIn){
        getROIImageFloat(imageIn);
        aligner.set_Reference(ROIImageF);
        //new ImagePlus("Reference",new FloatProcessor(centreRect.width,centreRect.height,ROIImageF.clone())).show();
    }

    void align(short[] imageIn){
        getROIImageFloat(imageIn);
        //new ImagePlus("ToAlign",new FloatProcessor(centreRect.width,centreRect.height,ROIImageF.clone())).show();
        aligner.align(ROIImageF,maxShift);
        xDrift = aligner.maxXPos;
        yDrift = aligner.maxYPos;
    }

    void align(float[] imageIn){
        getROIImageFloat(imageIn);
        //new ImagePlus("ToAlign",new FloatProcessor(centreRect.width,centreRect.height,ROIImageF.clone())).show();
        aligner.align(ROIImageF,maxShift);
        xDrift = aligner.maxXPos;
        yDrift = aligner.maxYPos;
    }


}
