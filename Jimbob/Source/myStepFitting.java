package Jimbob;

import ij.IJ;
import ij.ImagePlus;
import ij.ImageStack;
import ij.gui.Plot;
import ij.gui.PlotWindow;
import ij.io.FileSaver;
import ij.plugin.MontageMaker;
import ij.process.ImageProcessor;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.Arrays;

public class myStepFitting {


    static void stepFit(double[][] allData,double threshold,int maxSteps,ArrayList<ArrayList<Integer>> allFitPoints,ArrayList<ArrayList<Double>> allFitMeans,String outputDir){

        allFitPoints.clear();
        allFitMeans.clear();

        double stddev = approxStdDev(allData);
        double stepPenalty = threshold * threshold * stddev * stddev;

        ArrayList<Integer> fitPoints = new ArrayList<>();
        ArrayList<Double> fitMeans = new ArrayList<>();
        for(int i=0;i< allData.length;i++){
            Aggarwal(allData[i],stepPenalty, maxSteps, fitPoints, fitMeans);
            allFitPoints.add(new ArrayList<>(fitPoints));
            allFitMeans.add(new ArrayList<>(fitMeans));
        }

        if(!outputDir.isEmpty()){
            ShapeFunctions.writeCSVALI(outputDir  + "_StepPoints.csv", allFitPoints,"Each row is a particle. Each column first frame of a new step. First frame is 0");
            ShapeFunctions.writeCSVALD(outputDir  + "_StepMeans.csv", allFitMeans,  "Each row is a particle. Each column is the height of the next step");
        }

    }


    static void Aggarwal(double[] tofit, double stepPenalty, int maxSteps, ArrayList<Integer> fitPoints, ArrayList<Double> fitMeans){


        ArrayList<ArrayList<Integer>> savedpoints = new ArrayList<>();
        ArrayList<ArrayList<Double>> savedmeans  = new ArrayList<>();

        ArrayList<Integer> points  = new ArrayList<>(), proposedpoints  = new ArrayList<>();
        ArrayList<Double> variance = new ArrayList<>(), proposedvar1 = new ArrayList<>(), proposedvar2 = new ArrayList<>();
        ArrayList<Double> means = new ArrayList<>(),proposedmeans1 = new ArrayList<>(),proposedmeans2 = new ArrayList<>(), totalJ = new ArrayList<>();


        int pos = 0, minJPos = 0;

        //initialise point list and variance
        double[] l2Result  = calculateL2(tofit, tofit.length);//mean and l2

        double initialVariance = l2Result[1];

        means.add(l2Result[0]);
        variance.add(initialVariance);

        savedmeans.add( new ArrayList<>(means));
        savedpoints.add( new ArrayList<>());

        //initialise J

        totalJ.add(initialVariance);
        double minJ = initialVariance;


        //initilise proposed points and variance
        double[] findStepResult = new double[4];
        int findStepPos = findstepL2(tofit,0,tofit.length, findStepResult);
        proposedpoints.add(findStepPos);
        proposedmeans1.add(findStepResult[0]);
        proposedmeans2.add(findStepResult[1]);
        proposedvar1.add(findStepResult[2]);
        proposedvar2.add(findStepResult[3]);



        //cout << "starting " << variance[0] << " " << proposedpoints[0] << " " << proposedvar1[0] << " " << proposedvar2[0] << " " << (var1 + var2) / sum1 << "\n";

        for (int stepCount = 0; stepCount < maxSteps; stepCount++) {
            //find proposed point with minimum variance
            double minPorposedVar = Double.MAX_VALUE;
            int minSection = 0;
            for (int i = 0; i < proposedpoints.size(); i++) {
                double varSum = proposedvar1.get(i) + proposedvar2.get(i);
                for (int j = 0; j < variance.size(); j++)if (j != i)varSum += variance.get(j);

                if (varSum < minPorposedVar) {
                    minPorposedVar = varSum;
                    minSection = i;
                }
            }
            //add point to list and variance
            points.add(minSection,proposedpoints.get(minSection));
            variance.set(minSection,proposedvar2.get(minSection));
            variance.add(minSection,proposedvar1.get(minSection));
            means.set(minSection,proposedmeans2.get(minSection));
            means.add(minSection,proposedmeans1.get(minSection));


            //calculate new proposed point right side
            int newSize = minSection >= points.size() - 1 ? tofit.length - points.get(minSection) : points.get(minSection + 1) - points.get(minSection);//If its the last step go to the end of data

            findStepPos = findstepL2(tofit,points.get(minSection), newSize, findStepResult);

            findStepPos = findStepPos+points.get(minSection);
            proposedpoints.set(minSection,findStepPos);

            proposedmeans1.set(minSection,findStepResult[0]);
            proposedmeans2.set(minSection,findStepResult[1]);
            proposedvar1.set(minSection,findStepResult[2]);
            proposedvar2.set(minSection,findStepResult[3]);


            //calculate new proposed point left side
            int prevPoint = minSection > 0 ? points.get(minSection - 1) : 0;
            newSize = points.get(minSection) - prevPoint;
            findStepPos = findstepL2(tofit,prevPoint, newSize, findStepResult);
            if (minSection > 0) findStepPos =findStepPos+ points.get(minSection - 1);

            proposedpoints.add(minSection,findStepPos);
            proposedmeans1.add(minSection,findStepResult[0]);
            proposedmeans2.add(minSection,findStepResult[1]);
            proposedvar1.add(minSection,findStepResult[2]);
            proposedvar2.add(minSection,findStepResult[3]);


            //save variance and J
            savedmeans.add( new ArrayList<>(means));
            savedpoints.add( new ArrayList<>(points));


            double var1 = 0;
            for (int i = 0; i < variance.size(); i++)var1 += variance.get(i);
            totalJ.add(var1 + stepPenalty * (points.size()));

            //std::cout << var1 << " " << stepPenalty * (points.size()) << " " << var1 + stepPenalty * (points.size()) <<"\n";

            if (totalJ.get(stepCount + 1) < minJ) {
                minJ = totalJ.get(stepCount + 1);
                minJPos = stepCount+1;
            }

            if (stepCount+1 - minJPos > 4)break;

        }

        fitPoints.clear();
        fitPoints.add(0);
        fitPoints.addAll(savedpoints.get(minJPos));


        fitMeans.clear();
        fitMeans.addAll(savedmeans.get(minJPos));

    }

    static int findstepL2(double[] datain, int startPos, int vecsize, double[] results) {//results = mean1,mean2,l2_1,l2_2 - returns pos

        if (vecsize < 2) {
            if(startPos>=datain.length)startPos = datain.length-1;
            results[0] = datain[startPos];
            results[1] = datain[startPos];
            results[2] = Double.MAX_VALUE / 1000;
            results[3] = Double.MAX_VALUE / 1000;
            return 1;
        }
        double diff1, diff2, mean1in, mean2in = 0, L2in1 = 0, L2in2 = 0, minVar = Double.MAX_VALUE;
        double[] dataMeanSubtracted = new double[vecsize];
        for(int i=0;i<vecsize;i++)mean2in = mean2in+datain[startPos+i];
        mean2in = mean2in / vecsize;
        for(int i=0;i<vecsize;i++)dataMeanSubtracted[i] = datain[startPos+i]-mean2in;
        mean1in = 0;

        int posIn = 0;

        for (int i = 0; i < vecsize - 1; i++) {
            dataMeanSubtracted[i] = dataMeanSubtracted[i] - mean1in + mean2in;
            diff1 = (mean1in * i + datain[startPos+i]) / (i + 1) - mean1in;
            mean1in = mean1in+diff1;
            diff2 = (mean2in * (vecsize - i) - datain[startPos+i]) / (vecsize - i - 1) - mean2in;
            mean2in = mean2in+diff2;

            for(int j=0;j<i+1;j++)dataMeanSubtracted[j] =dataMeanSubtracted[j]-diff1;
            for(int j=i+1;j<vecsize;j++)dataMeanSubtracted[j] =dataMeanSubtracted[j]-diff2;

            L2in1 = 0;
            L2in2 = 0;

            for(int j=0;j<i+1;j++)L2in1 =L2in1+dataMeanSubtracted[j]*dataMeanSubtracted[j];
            for(int j=i+1;j<vecsize;j++)L2in2 =L2in2+dataMeanSubtracted[j]*dataMeanSubtracted[j];


            if (L2in1 + L2in2 < minVar) {
                minVar = L2in1 + L2in2;
                posIn = i + 1;
                results[0] = mean1in;
                results[1] = mean2in;
                results[2] = L2in1;
                results[3] =  L2in2;
            }
        }
        return posIn;
    }

    static double[] calculateL2(double[] datain, int vecsize) {//returns [mean, l2]
        double[] result = {0.0,0.0};
        for(int i=0;i<vecsize;i++) result[0] = result[0]+datain[i];
        result[0] =  result[0]/vecsize;

        for(int i=0;i<vecsize;i++)result[1] = result[1]+(datain[i]-result[0])*(datain[i]-result[0]);

        return result;
    }

    static double approxStdDev(double[][] tofit){
        double[] allDiffs = new double[tofit.length*(tofit[0].length-1)];

        for (int i = 0; i < tofit.length; i++)for (int j = 0; j < tofit[0].length-1; j++)
            allDiffs[i*(tofit[0].length-1)+j] = Math.abs(tofit[i][j] - tofit[i][j + 1]);

        Arrays.sort(allDiffs,0,allDiffs.length);

        int n = allDiffs.length / 2;
        double myMedian =  allDiffs[n];

        //Mad scale factor = 1.4826, Data diff to raw data std dev = 1/Sqrt(2)
	    double scaleFactor = 1.04836;

        return myMedian * scaleFactor;

    }

    public static double[][] transposeMatrix(double[][] matrix){
        int m = matrix.length;
        int n = matrix[0].length;

        double[][] transposedMatrix = new double[n][m];

        for(int x = 0; x < n; x++) {
            for(int y = 0; y < m; y++) {
                transposedMatrix[x][y] = matrix[y][x];
            }
        }

        return transposedMatrix;
    }

    public static double[] makeFitTrace(ArrayList<Integer> fitPoints,ArrayList<Double> fitMeans,int numOfFrames){
        double[] toplot = new double[numOfFrames];
        int stepCountIn = 0;
        for (int i = 0; i < fitPoints.size()-1; i++){
            for(int j=0;j<fitPoints.get(i+1)-fitPoints.get(i);j++){
                toplot[stepCountIn] = fitMeans.get(i);
                stepCountIn++;
            }
        }
        for(int j=0;j<toplot.length-fitPoints.get(fitPoints.size()-1);j++){
            toplot[stepCountIn] = fitMeans.get(fitPoints.size()-1);
            stepCountIn++;
        }
        return toplot;
    }

}
