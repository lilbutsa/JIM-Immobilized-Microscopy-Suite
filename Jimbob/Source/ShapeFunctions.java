package org.micromanager.plugins.Poor_Mans_JIM;

import java.io.FileWriter;
import java.util.ArrayList;
import java.util.Arrays;

public class ShapeFunctions {

    static void binaryToPositions(byte[] binary, int imageWidth, ArrayList<ArrayList<Integer>> positions) {

        positions.clear();

        int imageHeight = binary.length/imageWidth;
        int[] posImage = new int[binary.length];

        int[] xedges = { -1,0,1,-1,1,-1,0,1 };
        int[] yedges = { -1,-1,-1,0,0,1,1,1 };

        ArrayList<Integer> newROI;

        int count = 0;
        for (int i = 0;i < binary.length;i++)
            if (binary[i]>0 && posImage[i]==0) {
                count++;
                newROI = new ArrayList<>();
                newROI.add(i);

                posImage[i] = count;

                for (int j = 0;j < newROI.size();j++) {
                    int xIn = newROI.get(j) % imageWidth;
                    int yIn = newROI.get(j) / imageWidth;

                    for (int k = 0;k < xedges.length;k++) {
                        int xIn2 = (int)xIn + xedges[k];
                        int yIn2 = (int)yIn + yedges[k];
                        int posIn = xIn2 + yIn2 * imageWidth;

                        if (xIn2 > -1 && xIn2 < (int)imageWidth && yIn2 > -1 && yIn2 < (int)imageHeight && binary[posIn]>0 && posImage[posIn] == 0) {
                            newROI.add(posIn);
                            posImage[posIn] = count;
                        }
                    }
                }
                positions.add(newROI);
            }

    }

    static ArrayList<ArrayList<Integer>> getEdgePos(ArrayList<ArrayList<Integer>> detectedPos, int imageWidth, int imageNOP) {
        //Make the positions image
        int imageHeight = imageNOP/imageWidth;
        int[] posImage = new int[imageNOP];
        Arrays.fill(posImage,0);
        for(int i=0;i<detectedPos.size();i++)
            for(int j=0;j<detectedPos.get(i).size();j++)posImage[detectedPos.get(i).get(j)] = i+1;

        int[] xedges = { -1,1,0,0};
        int[] yedges = { 0,0,-1,1};

        //convert to an edge image
        ArrayList<ArrayList<Integer>> edgePos = new ArrayList<>();

        for(int i=0;i<detectedPos.size();i++) {
            edgePos.add(new ArrayList<>());
            for (int j = 0; j < detectedPos.get(i).size(); j++) {
                int xIn = detectedPos.get(i).get(j) % imageWidth;
                int yIn = detectedPos.get(i).get(j) / imageWidth;
                for (int k = 0; k < xedges.length; k++) {
                    if (xIn + xedges[k] >= 0 && xIn + xedges[k] < imageWidth && yIn + yedges[k] >= 0 &&
                            yIn + yedges[k] < imageHeight && posImage[xIn + xedges[k] + imageWidth * (yIn + yedges[k])] == 0) {
                        edgePos.get(i).add(detectedPos.get(i).get(j));
                        break;
                    }
                }
            }
        }
        return edgePos;
    }


    static double[][] componentMeasurements(byte[] binaryImageIn, int imageWidth, ArrayList<ArrayList<Integer>> detectedPos) {

        // measurementresults:
        // [0]  xCentre
        // [1]  yCentre
        // [2]  eccentricity
        // [3]  xMajorAxis
        // [4]  yMajorAxis
        // [5]  length
        // [6]  xEnd1LinFit
        // [7]  yEnd1LinFit
        // [8]  xEnd2LinFit
        // [9]  yEnd2LinFit
        // [10] count
        // [11] xMaxPos  // currently rounded centroid x, not true max-intensity position
        // [12] yMaxPos  // currently rounded centroid y, not true max-intensity position
        // [13] maxDistFromLinear
        // [14] xBoundingBoxMin
        // [15] xBoundingBoxMax
        // [16] yBoundingBoxMin
        // [17] yBoundingBoxMax
        // [18] nearestNeighbour

        binaryToPositions(binaryImageIn,imageWidth,detectedPos);

        double[][] measurementresults = new double[detectedPos.size()][19];
        double[] xpos, ypos;
        double x2, y2, xy;
        double max, min,ymin,ymax;


        //main measurements loop
        for (int i = 0; i < detectedPos.size(); i++) {
            xpos = new double[detectedPos.get(i).size()];
            ypos = new double[detectedPos.get(i).size()];

            double xSum = 0,ySum = 0;
            for (int j = 0; j < detectedPos.get(i).size(); j++) {
                xpos[j] = (double)(detectedPos.get(i).get(j) % imageWidth);
                ypos[j] = (double)((int)detectedPos.get(i).get(j) / imageWidth);
                xSum+=xpos[j];
                ySum+=ypos[j];
            }
            xSum = xSum/xpos.length;
            ySum = ySum/ypos.length;

            //x and y centre of mass
            measurementresults[i][0] = xSum;
            measurementresults[i][1] = ySum;

            //subtract Centre of mass from positions
            for (int j = 0; j < xpos.length; j++) {
                xpos[j] = xpos[j]-xSum;
                ypos[j] = ypos[j]-ySum;
            }

            //best fit ellipse
            x2 = 0; y2 = 0; xy = 0;
            for (int j = 0; j < xpos.length; j++) {
                x2 += xpos[j]*xpos[j];
                y2 += ypos[j]*ypos[j];
                xy+=xpos[j]*ypos[j];
            }
            x2 = x2/xpos.length;
            y2 = y2/xpos.length;
            xy = xy/xpos.length;
            double eccentricity = ((x2 - y2) * (x2 - y2) + 4 * xy * xy) / ((x2 + y2) * (x2 + y2));//Eccentricity from https://docs.baslerweb.com/visualapplets/files/manuals/content/examples%20imagemoments.html
            double mainAxisAngle = (0.5 * Math.atan2(2 * xy, (x2 - y2)));//theta = 1/2*np.arctan2(2*mu11/mu00, (mu20 - mu02)/mu00) from https://ojskrede.github.io/inf4300/notes/week_05/

            measurementresults[i][2] = eccentricity;

            double xMajorAxis = Math.cos(mainAxisAngle);
            double yMajorAxis = Math.sin(mainAxisAngle);

            if(xMajorAxis<0){
                xMajorAxis = -xMajorAxis;
                yMajorAxis = -yMajorAxis;
            }

            measurementresults[i][3] =xMajorAxis;
            measurementresults[i][4] =yMajorAxis;

            //Find the projection of each point along the semi major axis. Max proj. - Min. Proj. gives length

            max = 0;
            min = 0;
            for (int j = 0; j < xpos.length; j++) {
                double proj = xpos[j] * xMajorAxis +ypos[j] * yMajorAxis;
                if (proj < min) min = proj;
                if (proj > max) max = proj;
            }

            measurementresults[i][5] =max-min;
            // Ends are taken as the projections

            measurementresults[i][6] = xSum+min* xMajorAxis;
            measurementresults[i][7] = ySum+min* yMajorAxis;
            measurementresults[i][8] = xSum+max* xMajorAxis;
            measurementresults[i][9] = ySum+max* yMajorAxis;

            measurementresults[i][10] =(double)xpos.length;//count

            //Ignoring Pixel Position of the max intensity
            // Just going to return the centroid
            measurementresults[i][11] =Math.round(xSum);
            measurementresults[i][12] =Math.round(ySum);

            //max distance from linear. note xpos and y pos have subtracted their COM
            //dist = abs(x*yvec-y*xvec)
            max = 0;
            for (int j = 0; j < xpos.length; j++) {
                double dist = Math.abs(xpos[j] * yMajorAxis - ypos[j] * xMajorAxis);
                if (dist > max) max = dist;
            }
            measurementresults[i][13] = max;

            //Bounding box
            min = 0;max = 0;ymin = 0;ymax = 0;
            for (int j = 0; j < xpos.length; j++){
                if(xpos[j]<min)min = xpos[j];
                if(xpos[j]>max)max = xpos[j];
                if(ypos[j]<ymin)ymin = ypos[j];
                if(ypos[j]>ymax)ymax = ypos[j];
            }
            measurementresults[i][14] =min+xSum;
            measurementresults[i][15] =max+xSum;
            measurementresults[i][16] =ymin+ySum;
            measurementresults[i][17] =ymax+ySum;

        }


        //nearest neighbour
        //find distance to bounding boxes

        //make edge positions file for nearest neighbour
        ArrayList<ArrayList<Integer>> edgePos= getEdgePos(detectedPos,imageWidth, binaryImageIn.length);

        long[][] distToBoundingBox = new long[detectedPos.size()][2];

        for (int i = 0; i < detectedPos.size(); i++) {
            //Find dist to bounding box
            for (int j = 0; j < detectedPos.size(); j++){
                int xDiff = Math.max(0, (int)Math.max(measurementresults[i][14] - measurementresults[j][15], measurementresults[j][14] - measurementresults[i][15]));
                int yDiff = Math.max(0, (int)Math.max(measurementresults[i][16] - measurementresults[j][17], measurementresults[j][16] - measurementresults[i][17]));

                distToBoundingBox[j][0] = (long)xDiff*xDiff+(long)yDiff*yDiff;
                distToBoundingBox[j][1] = j;
            }
            Arrays.sort(distToBoundingBox, (a, b) -> Long.compare(a[0], b[0]));

            long currentClosest = (long)(imageWidth+binaryImageIn.length/imageWidth)*(imageWidth+binaryImageIn.length/imageWidth);
            for (int j = 0; j < detectedPos.size(); j++){
                if(currentClosest>distToBoundingBox[j][0] && distToBoundingBox[j][1]!=i){//check if the next closest bounding box is closer than the current nearest neighbour
                    for(int k=0;k<edgePos.get(i).size();k++){
                        int xIn1 = edgePos.get(i).get(k)%imageWidth;
                        int yIn1 = edgePos.get(i).get(k)/imageWidth;
                        for(int l=0;l<edgePos.get((int)distToBoundingBox[j][1]).size();l++) {
                            int xIn2 = edgePos.get((int)distToBoundingBox[j][1]).get(l)%imageWidth;
                            int yIn2 = edgePos.get((int)distToBoundingBox[j][1]).get(l)/imageWidth;
                            if((long)(xIn1-xIn2)*(xIn1-xIn2)+(long)(yIn1-yIn2)*(yIn1-yIn2)<currentClosest) currentClosest = (long)(xIn1-xIn2)*(xIn1-xIn2)+(long)(yIn1-yIn2)*(yIn1-yIn2);
                        }
                    }
                } else if(currentClosest<distToBoundingBox[j][0]) break;
            }
            if(detectedPos.size()>1) measurementresults[i][18] = Math.sqrt(currentClosest);
            else measurementresults[i][18] = -1;
        }

        return measurementresults;
    }


    static void expandShapes(double foregroundDist, double backgroundDist, ArrayList<ArrayList<Integer>> foregroundPos,ArrayList<ArrayList<Integer>> backgroundPos,int imageWidth,int imageHeight
            ,ArrayList<ArrayList<Integer>> expandedForegroundPos,ArrayList<ArrayList<Integer>> expandedBackgroundPos){

        if (expandedForegroundPos == null || expandedBackgroundPos == null) {
            throw new IllegalArgumentException("Output lists must not be null");
        }

        int posMax = foregroundPos.size();

        int imageNOP = imageWidth*imageHeight;
        int[] posImage = new int[imageNOP];
        Arrays.fill(posImage,0);
        for(int i=0;i<foregroundPos.size();i++)
            for(int j=0;j<foregroundPos.get(i).size();j++)posImage[foregroundPos.get(i).get(j)] = i+1;

        int[] backgroundImage = new int[imageNOP];
        Arrays.fill(backgroundImage,0);
        for(int i=0;i<backgroundPos.size();i++)
            for(int j=0;j<backgroundPos.get(i).size();j++)backgroundImage[backgroundPos.get(i).get(j)] = 1;


        //find search positions for each ring
        int foregroundCount = 0, backgroundCount = 0;
        for (int i = (int)(-backgroundDist); i <= (int)backgroundDist;i++)
            for (int j = (int)(-backgroundDist); j <= (int)backgroundDist;j++)
                if (i * i + j * j <= foregroundDist * foregroundDist + 0.000001)foregroundCount++;
                else if (i * i + j * j <= backgroundDist * backgroundDist + 0.000001)backgroundCount++;


        int[][] foregroundSearchPos = new int[foregroundCount][3];
        int[][] backgroundSearchPos = new int[backgroundCount][3];
        foregroundCount = 0;
        backgroundCount = 0;

        for (int i = (int)(-backgroundDist); i <= (int)backgroundDist;i++)
            for (int j = (int)(-backgroundDist); j <= (int)backgroundDist;j++)
                if (i * i + j * j <= foregroundDist * foregroundDist + 0.000001){
                    foregroundSearchPos[foregroundCount][0] = i * i + j * j;
                    foregroundSearchPos[foregroundCount][1] = i ;
                    foregroundSearchPos[foregroundCount][2] = j;
                    foregroundCount++;
                }
                else if (i * i + j * j <= backgroundDist * backgroundDist + 0.000001){
                    backgroundSearchPos[backgroundCount][0] = i * i + j * j;
                    backgroundSearchPos[backgroundCount][1] = i ;
                    backgroundSearchPos[backgroundCount][2] = j;
                    backgroundCount++;
                }

        Arrays.sort(foregroundSearchPos, (a, b) -> Integer.compare(a[0], b[0]));
        Arrays.sort(backgroundSearchPos, (a, b) -> Integer.compare(a[0], b[0]));

//search around each pixel for foreground and background

        expandedForegroundPos.clear();
        expandedBackgroundPos.clear();
        for(int i=0;i<posMax;i++){
            expandedForegroundPos.add(i, new ArrayList<>());
            expandedBackgroundPos.add(i, new ArrayList<>());
        }

        boolean[] bBackgroundFound = new boolean[posMax];

        for (int x = 0;x < imageWidth;x++)for (int y = 0;y < imageHeight;y++) {
            boolean notfound = true;
            Arrays.fill(bBackgroundFound, true);


            for (int i = 0;i < foregroundSearchPos.length;i++) {//search for foreground
                int xIn = x + foregroundSearchPos[i][1];
                int yIn = y + foregroundSearchPos[i][2];
                if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight) {
                    if (posImage[xIn + yIn * imageWidth] > 0) {//if found in the foreground points then add it to the list
                        expandedForegroundPos.get(posImage[xIn + yIn * imageWidth] - 1).add(x + y * imageWidth);
                        notfound = false;
                        break;
                    }
                    else if (backgroundImage[xIn + yIn * imageWidth] > 0) {//if only found in the background points then discard
                        notfound = false;
                        //break;
                    }
                }
            }
            if (notfound) {
                for (int i = 0;i < backgroundSearchPos.length;i++) {//search for background
                    int xIn = x + backgroundSearchPos[i][1];
                    int yIn = y + backgroundSearchPos[i][2];
                    if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight && posImage[xIn + yIn * imageWidth] > 0 && bBackgroundFound[posImage[xIn + yIn * imageWidth] - 1]) {//add everything found
                        expandedBackgroundPos.get(posImage[xIn + yIn * imageWidth] - 1).add(x + y * imageWidth);
                        bBackgroundFound[posImage[xIn + yIn * imageWidth] - 1] = false;
                    }
                }
            }
        }


    }

    static void writeCSV(String fileName, double[][] data,String headerline,boolean transposeData){
        try {
            FileWriter myOutput = new FileWriter(fileName);
            myOutput.write(headerline+"\n");
            String myLine;
            if(!transposeData) {
                for (int i = 0; i < data.length; i++) {
                    myLine = "";
                    for (int j = 0; j < data[i].length; j++) {
                        myLine = myLine + String.valueOf(data[i][j]) + ",";
                    }
                    myLine = myLine.substring(0, myLine.length() - 1);
                    myLine = myLine + "\n";
                    myOutput.write(myLine);
                }
            } else {

                for (int i = 0; i < data[0].length; i++) {
                    myLine = "";
                    for (int j = 0; j < data.length; j++) {
                        myLine = myLine + String.valueOf(data[j][i]) + ",";
                    }
                    myLine = myLine.substring(0, myLine.length() - 1);
                    myLine = myLine + "\n";
                    myOutput.write(myLine);
                }
            }

            myOutput.close();

        }catch(Exception e) {
            System.out.println(e);
        }
    }
}
