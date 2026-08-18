package Jimbob;

import java.awt.*;

public class floatImage {
    int imageWidth,imageHeight,totNOP;
    float[] imData;

    floatImage(int imageWidthIn,int imageHeightIn){
        imageWidth = imageWidthIn;
        imageHeight = imageHeightIn;
        totNOP = imageWidth*imageHeight;
        imData = new float[totNOP];
    }

    float[] getROIFromIntImage(intImage imageIn, Rectangle ROI, int driftX, int driftY, boolean add){
        if(imData==null || imData.length != ROI.width * ROI.height){
            if(add)System.out.println("WARNING Imaging reset when adding!!!");
            imageWidth = ROI.width;
            imageHeight = ROI.height;
            imData = new float[ROI.width * ROI.height];
        }
        for (int i = 0; i < ROI.width; i++)
            for (int j = 0; j < ROI.height; j++) {
                int xIn = (i + ROI.x + driftX);
                if(xIn<0)xIn=0;
                if(xIn>=imageIn.imageWidth)xIn = imageIn.imageWidth-1;
                int yIn = (j + ROI.y + driftY);
                if(yIn<0)yIn=0;
                if(yIn>=imageIn.imageHeight)yIn = imageIn.imageHeight-1;

                if(add) imData[i + j * ROI.width] = imData[i + j * ROI.width]+imageIn.rawImage16[(xIn + yIn * imageIn.imageWidth)];
                else imData[i + j * ROI.width] = imageIn.rawImage16[(xIn + yIn * imageIn.imageWidth)];
            }
        return imData;
    }
}
