package Jimbob;

import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;

public class myLapOfGaussFFT {

    int ROILength, NOP,xPad,yPad,imageWidth,imageHeight;
    FastFourierTransformer FFT;

    Complex[][] refFourCon, sampleFour;

    double[] crosscorr,paddedImage;

    int maxXPos, maxYPos;
    double quadFitX, quadFitY;
    double[] rowInput;

    public myLapOfGaussFFT(int imageWidthIn,int imageHeightIn) {

        imageWidth = imageWidthIn;
        imageHeight = imageHeightIn;

        int maxEdge = Math.max(imageWidth,imageHeight);
        int ln2Length = (int)Math.ceil(Math.log(maxEdge)/Math.log(2));
        ROILength = (int)Math.round(Math.pow(2,ln2Length));

        xPad = (ROILength-imageWidth)/2;
        yPad = (ROILength-imageHeight)/2;


        NOP = ROILength * ROILength;

        FFT = new FastFourierTransformer(DftNormalization.STANDARD);
        refFourCon = new Complex[ROILength][ROILength];
        sampleFour = new Complex[ROILength][ROILength];
        crosscorr = new double[NOP];
        rowInput = new double[ROILength];

        paddedImage = new double[ROILength*ROILength];

    }


    void  FFT2d(double[] sample, Complex[][] output, TransformType direction) {

        //FFT each row
        for (int i = 0; i < ROILength; i++) {
            for (int j = 0; j < ROILength; j++) rowInput[j] = (((double)sample[i * ROILength + j]) ) ;
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


    double[]  laplaceOfGaussian (float[] sample,double gaussStdDev) {

        for (int y = 0; y < ROILength; y++) {
            int yIn = reflectIndex(y - yPad, imageHeight);

            for (int x = 0; x < ROILength; x++) {
                int xIn = reflectIndex(x - xPad, imageWidth);
                paddedImage[x + ROILength * y] = sample[xIn + imageWidth * yIn];
            }
        }

        FFT2d(paddedImage, sampleFour, TransformType.FORWARD);

        double const1 = 4*Math.PI * Math.PI;
        double const2 = 2*Math.PI * Math.PI * gaussStdDev* gaussStdDev;

        for (int i = 0; i < ROILength; i++)
            for (int j = 0; j < ROILength; j++) {
                int xIn = i;
                int yIn = j;
                if (xIn >= ROILength / 2) xIn += -ROILength;
                if (yIn >= ROILength / 2) yIn += -ROILength;

                double kSquared = ((double) (xIn * xIn)) / (ROILength * ROILength) + ((double) (yIn * yIn)) / (ROILength * ROILength);
                double logVal = (-kSquared * const1 * Math.exp(-kSquared * const2));

                sampleFour[i][j] = sampleFour[i][j].multiply(logVal);

            }

        for(int i=0;i<ROILength;i++)sampleFour[i] = FFT.transform(sampleFour[i], TransformType.INVERSE);
        for (int i = 0; i < ROILength; i++)
            for (int j = i + 1; j < ROILength; j++) {
                Complex temp = sampleFour[i][j];
                sampleFour[i][j] = sampleFour[j][i];
                sampleFour[j][i] = temp;
            }
        for(int i=0;i<ROILength;i++)sampleFour[i] = FFT.transform(sampleFour[i], TransformType.INVERSE);

        double[] result = new double[imageWidth*imageHeight];
        for (int i = 0; i < imageWidth; i++)for (int j = 0; j < imageHeight; j++)result[i+j*imageWidth] = sampleFour[i+xPad][j+yPad].getReal();

        return result;

    }

    private int reflectIndex(int index, int length) {
        if (length <= 1) return 0;

        while (index < 0 || index >= length) {
            if (index < 0) {
                index = -index - 1;
            }
            if (index >= length) {
                index = 2 * length - index - 1;
            }
        }

        return index;
    }

}
