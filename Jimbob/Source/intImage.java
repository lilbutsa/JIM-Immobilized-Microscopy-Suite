package Jimbob;

import java.awt.*;

public class intImage {
    int imageWidth,imageHeight,totNOP;
    int[] rawImage16,ROIImage;
    Rectangle fullImageRec;

    intImage(int imageWidthIn,int imageHeightIn){
        imageWidth = imageWidthIn;
        imageHeight = imageHeightIn;
        totNOP = imageWidth*imageHeight;
        rawImage16 = new int[totNOP];
        fullImageRec = new Rectangle(0,0,imageWidth,imageHeight);
    }

    int[] getROI( Rectangle ROI, int driftX, int driftY){
        if(ROIImage==null || ROIImage.length != ROI.width * ROI.height){
            ROIImage = new int[ROI.width * ROI.height];
        }
        for (int i = 0; i < ROI.width; i++)
            for (int j = 0; j < ROI.height; j++) {
                int xIn = (i + ROI.x + driftX);
                if(xIn<0)xIn=0;
                if(xIn>=imageWidth)xIn = imageWidth-1;
                int yIn = (j + ROI.y + driftY);
                if(yIn<0)yIn=0;
                if(yIn>=imageHeight)yIn = imageHeight-1;

                ROIImage[i + j * ROI.width] = rawImage16[(xIn + yIn * imageWidth)];

            }
        return ROIImage;
    }
}
