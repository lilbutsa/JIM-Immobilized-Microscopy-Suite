package org.micromanager.plugins.Poor_Mans_JIM;
import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;

import javax.swing.*;

public class myFFT {

    int ROILength, NOP;
    FastFourierTransformer FFT;

    Complex[][] refFourCon, sampleFour;

    double[] crosscorr;

    int maxXPos, maxYPos;
    double quadFitX, quadFitY;
    double[] rowInput;

    public myFFT(int ROIlengthin) {

        ROILength = ROIlengthin;
        NOP = ROILength * ROILength;

        FFT = new FastFourierTransformer(DftNormalization.STANDARD);

        refFourCon = new Complex[ROILength][ROILength];

        sampleFour = new Complex[ROILength][ROILength];

        crosscorr = new double[NOP];

        rowInput = new double[ROILength];

    }

    void  FFT2d(int[] sample, Complex[][] output, TransformType direction) {
        double mean = 0.0;
        for (int value : sample) mean = mean + ((double) value);
        mean = mean / sample.length;

        double stddev = 0.0;
        for (int value : sample) stddev = stddev + (((double) value) - mean) * (((double) value) - mean);
        stddev = Math.sqrt(stddev / sample.length);

        if(stddev==0)stddev = 1;
        //FFT each row
        for (int i = 0; i < ROILength; i++) {
            for (int j = 0; j < ROILength; j++) rowInput[j] = (((double)sample[i * ROILength + j]) - mean) / stddev;
            output[i] = FFT.transform(rowInput, direction);
        }
        //Transpose result
        for (int i = 0; i < ROILength; i++)
            for (int j = i + 1; j < ROILength; j++) {
                Complex temp = output[i][j];
                output[i][j] = output[j][i];
                output[j][i] = temp;
            }
        //FFT each row
        for (int i = 0; i < ROILength; i++) output[i] = FFT.transform(output[i], direction);
        //Transpose result
        for (int i = 0; i < ROILength; i++)
            for (int j = i + 1; j < ROILength; j++) {
                Complex temp = output[i][j];
                output[i][j] = output[j][i];
                output[j][i] = temp;
            }


    }

    void  set_Reference (int[] sample) {

        FFT2d(sample, refFourCon, TransformType.FORWARD);

        for (int i = 0; i < ROILength; i++)
            for (int j = 0; j < ROILength; j++) refFourCon[i][j] = refFourCon[i][j].conjugate();


    }
    void  set_Reference_log (int[] sample,double gaussStdDev) {

        FFT2d(sample, refFourCon, TransformType.FORWARD);

        double sqrtconst = Math.sqrt(Math.PI * Math.sqrt(2.0) * gaussStdDev);
        double const2 = Math.PI *Math.PI * Math.sqrt(2.0) * gaussStdDev;

        for (int i = 0; i < ROILength; i++)
            for (int j = 0; j < ROILength; j++){
                int xIn = i;
                int yIn = j;
                if (xIn >= ROILength / 2)xIn += -ROILength;
                if (yIn >= ROILength / 2)yIn += -ROILength;

                double kSquared = ((double)(xIn * xIn)) / (ROILength * ROILength) + ((double)(yIn * yIn)) / (ROILength * ROILength);
                double logVal = (-kSquared * sqrtconst * Math.exp(-kSquared * const2));

                refFourCon[i][j] = refFourCon[i][j].multiply(logVal*logVal);

                refFourCon[i][j] = refFourCon[i][j].conjugate();

            }
    }


    void align(int[] sample,int maxShift){

        FFT2d(sample,sampleFour,TransformType.FORWARD);

        for(int i=0;i<ROILength;i++)for(int j=0;j<ROILength;j++)sampleFour[i][j] = sampleFour[i][j].multiply(refFourCon[i][j]);

        for(int i=0;i<ROILength;i++)sampleFour[i] = FFT.transform(sampleFour[i], TransformType.INVERSE);
        for (int i = 0; i < ROILength; i++)
            for (int j = i + 1; j < ROILength; j++) {
                Complex temp = sampleFour[i][j];
                sampleFour[i][j] = sampleFour[j][i];
                sampleFour[j][i] = temp;
            }
        for(int i=0;i<ROILength;i++)sampleFour[i] = FFT.transform(sampleFour[i], TransformType.INVERSE);
        for (int i = 0; i < ROILength; i++)for (int j = 0; j < ROILength; j++)crosscorr[i+j*ROILength] = sampleFour[i][j].getReal();

        //Find Max
        int maxAt = 0;
        for (int i = 0; i < crosscorr.length; i++) {
            if(((i%ROILength)<=maxShift || (i%ROILength)>=ROILength-maxShift) && (i/ROILength<=maxShift || i/ROILength>=ROILength-maxShift))
                maxAt = crosscorr[i] > crosscorr[maxAt] ? i : maxAt;
        }

        maxXPos = maxAt % ROILength;
        maxYPos = (int) maxAt / ROILength;
        if (maxXPos > ROILength / 2) maxXPos += -ROILength;
        if (maxYPos > ROILength / 2) maxYPos += -ROILength;

        //System.out.println("maxcc="+crosscorr[maxAt]+" maxpos= "+maxAt+" dx=  "+maxXPos+" dy= "+maxYPos+" ,");

    }

    void fitSubPixelQuadratic(){

        double xyz = 0, yz = 0, xz = 0,x2zm2z = 0,y2zm2z = 0,z;

        for(int i = -2;i<3;i++)for(int j = -2;j<3;j++){
            int xin = maxXPos+i;
            if(xin<0)xin+=ROILength;
            if(xin>=ROILength)xin+=-ROILength;
            int yin = maxYPos+j;
            if(yin<0)yin+=ROILength;
            if(yin>=ROILength)yin+=-ROILength;

            z = crosscorr[xin+yin*ROILength];


            xz+=i*z;
            yz+=j*z;
            xyz+=i*j*z;
            x2zm2z+=(i*i-2)*z;
            y2zm2z+=(j*j-2)*z;
        }

        quadFitX = (98* xyz*yz-280*xz*y2zm2z)/(-49*xyz*xyz+400*x2zm2z*y2zm2z);
        quadFitY = (98* xyz*xz-280*yz*x2zm2z)/(-49*xyz*xyz+400*x2zm2z*y2zm2z);


        quadFitX = maxXPos+quadFitX;
        quadFitY = maxYPos+quadFitY;


        if (quadFitX > ROILength / 2) quadFitX += -ROILength;
        if (quadFitY > ROILength / 2) quadFitY += -ROILength;
        //end subpixel stuff

    }


}

