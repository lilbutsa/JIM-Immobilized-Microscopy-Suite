package org.micromanager.plugins.Poor_Mans_JIM;

import java.util.Arrays;

public class MakeHistogram {
    double[][] makeHistogram(double[] values) {
        double[] quartiles = CalcQuartile(values);

        double binWidth = 2.0*(quartiles[2] - quartiles[0]) / (Math.pow(1.0*values.length, 0.3333333)); //Using the Freedman–Diaconis rule

        double min= Arrays.stream(values).min().getAsDouble();
        double max = Arrays.stream(values).max().getAsDouble();

        min -= binWidth;
        max += binWidth;

        int numOfBins = (int)Math.ceil((max - min) / binWidth);
        int pos;

        double[][] output = new double[2][numOfBins];


        for (int i = 0; i < numOfBins; i++)output[0][i] = min + (i + 0.5)*binWidth;

        for (int i = 0; i < values.length; i++) {
            pos = (int)Math.floor((values[i] - min) / binWidth);
            output[1][pos] = output[1][pos] + 1;
        }

        for (int i = 0; i < numOfBins; i++)output[1][i] = output[1][i] / (values.length*binWidth);

        return output;

    }

    double CalcMedian(double[] scores)
    {
        double median;

        int size = scores.length;

        Arrays.sort(scores);

        if (size % 2 == 0)
        {
            median = (scores[size / 2 - 1] + scores[size / 2]) / 2;
        }
        else
        {
            median = scores[size / 2];
        }

        return median;
    }


    double[] CalcQuartile(double[] scores)
    {
        double[] quartiles = {0.0,0.0,0.0};

        int size = scores.length;

        quartiles[1] = CalcMedian(scores);

        Arrays.sort(scores);
        double[] subarray;


        if (size % 2 == 0)
        {
            subarray = new double[size / 2];
            System.arraycopy(scores, 0, subarray, 0, subarray.length);
            quartiles[0] = CalcMedian(subarray);
            System.arraycopy(scores, size / 2, subarray, 0, subarray.length);
            quartiles[2] = CalcMedian(subarray);
        }
        else
        {
            subarray = new double[(size-1) / 2];
            System.arraycopy(scores, 0, subarray, 0, subarray.length);
            quartiles[0] = CalcMedian(subarray);
            System.arraycopy(scores, (size-1) / 2+1, subarray, 0, subarray.length);
            quartiles[2] = CalcMedian(subarray);

        }

        return quartiles;
    }

}
