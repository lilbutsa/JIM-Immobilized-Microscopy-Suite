package org.micromanager.plugins.Poor_Mans_JIM;

import javax.swing.*;
import java.util.ArrayList;
import java.util.Arrays;

public class myFHT {
    //To clone set these variables equal
    int NumberOfReferences;
    float[] data, refplus,refminus;

    //end
    int ROILength;
    int NOP;

    int maxXPos, maxYPos;
    float[] sampledata,crosscorr,normedSample;


    int[] myRevPos;

    float[] C,S;
    int[] bitrev;
    float[] tempArr;
    int Nlog2;




    public myFHT(int ROIlengthin){
        try {

            ROILength = ROIlengthin;
            NOP = ROILength*ROILength;
            crosscorr = new float[NOP];

            sampledata = new float[NOP];


            initializeTables(ROILength);
            Nlog2 = log2(ROILength);


            myRevPos = new int[NOP];
            for(int i=1;i<ROILength;i++)for(int j=1;j<ROILength;j++)myRevPos[i+j*ROILength] = NOP-1-((i-1)+(j-1)*ROILength);
            for(int i=0;i<ROILength;i++)myRevPos[i]=i;
            for(int j=1;j<ROILength;j++)myRevPos[j*ROILength] = NOP-j*ROILength;


            //System.out.println(Arrays.toString(myRevPos));

        } catch (Exception error) {
            JOptionPane.showMessageDialog(null, " myFHT "+error);

        }
    }



    void set_Reference(float[] datain){

        data = datain.clone();

        float mean = 0;
        for(int i=0;i<data.length;i++)mean +=data[i];
        mean = mean/data.length;

        float stddev = 0;
        for(int i=0;i<data.length;i++)stddev+=(data[i]-mean)*(data[i]-mean);
        stddev = (float) Math.sqrt(stddev/data.length);

        for(int i=0;i<data.length;i++)data[i] = (data[i]-mean)/stddev;

        float[] normeddata = data.clone();

        rc2DFHT(data, false);

        refplus = new float[NOP];
        refminus = new float[NOP];


        refplus[0] = data[0];
        refminus[0]=0;
        for(int i=1;i<NOP;i++){
            refplus[i] = (data[i] + data[myRevPos[i]])/2;
            refminus[i] = (data[myRevPos[i]]-data[i])/2;
        }

        data = normeddata.clone();

    }

    void align(float[] sample,int maxShift){
        sampledata = sample;
        float mean = 0;
        for(int i=0;i<sampledata.length;i++)mean +=sampledata[i];
        mean = mean/sampledata.length;

        float stddev = 0;
        for(int i=0;i<sampledata.length;i++)stddev+=(sampledata[i]-mean)*(sampledata[i]-mean);
        stddev = (float) Math.sqrt(stddev/sampledata.length);

        for(int i=0;i<sampledata.length;i++)sampledata[i] = (sampledata[i]-mean)/stddev;
        normedSample = sampledata.clone();
        rc2DFHT(sampledata, false);

        //Cross Correlate
        crosscorr[0] = sampledata[0]*refplus[0];
        for(int i=1;i<NOP;i++){
            //crosscorr[i] = (float)((sampledata[i]*data.get(refNum)[i]+sampledata[NOP-i]*data.get(refNum)[NOP-i])/2.0);
            crosscorr[i] = sampledata[i]*refplus[i]+sampledata[myRevPos[i]]*refminus[i];
        }
        rc2DFHT(crosscorr, true);

        //Find Max
        int maxAt = 0;
        for (int i = 0; i < crosscorr.length; i++) {
            if(((i%ROILength)<maxShift || (i%ROILength)>ROILength-maxShift) && (i/ROILength<maxShift || i/ROILength>ROILength-maxShift))
                maxAt = crosscorr[i] > crosscorr[maxAt] ? i : maxAt;
        }


        maxXPos = maxAt % ROILength;
        maxYPos = (int) maxAt / ROILength;

        if (maxXPos > ROILength / 2) maxXPos += -ROILength;
        if (maxYPos > ROILength / 2) maxYPos += -ROILength;

    }





    /** Performs a 2D FHT (Fast Hartley Transform). */
    public void rc2DFHT(float[] x, boolean inverse) {
        if (S==null) initializeTables(ROILength);
        for (int row=0; row<ROILength; row++)
            dfht3(x, row*ROILength, inverse);
        transposeR(x, ROILength);
        for (int row=0; row<ROILength; row++)
            dfht3(x, row*ROILength, inverse);
        transposeR(x, ROILength);

        int mRow, mCol;
        float A1,B1,C1,D1,E1;
        for (int row=0; row<=ROILength/2; row++) { // Now calculate actual Hartley transform
            for (int col=0; col<=ROILength/2; col++) {
                mRow = (ROILength - row) % ROILength;
                mCol = (ROILength - col)  % ROILength;
                A1 = x[row * ROILength + col];	//  see Bracewell, 'Fast 2D Hartley Transf.' IEEE Procs. 9/86
                B1 = x[mRow * ROILength + col];
                C1 = x[row * ROILength + mCol];
                D1 = x[mRow * ROILength + mCol];
                E1 = ((A1 + D1) - (B1 + C1)) / 2;
                x[row * ROILength + col] = A1 - E1;
                x[mRow * ROILength + col] = B1 + E1;
                x[row * ROILength + mCol] = C1 + E1;
                x[mRow * ROILength + mCol] = D1 - E1;
            }
        }
    }



    /** Performs an optimized 1D FHT of an array or part of an array.
     *  @param x        Input array; will be overwritten by the output in the range given by base and ROILength.
     *  @param base     First index from where data of the input array should be read.
     *  @param inverse  True for inverse transform.
     *  ROILength      Length of data that should be transformed; this must be always
     *                  the same for a given FHT object.
     *  Note that all amplitudes in the output 'x' are multiplied by ROILength.
     */
    public void dfht3(float[] x, int base, boolean inverse) {
        int i, stage, gpNum, gpSize, numGps;
        int bfNum, numBfs;
        int Ad0, Ad1, Ad2, Ad3, Ad4, CSAd;
        float rt1, rt2, rt3, rt4;


        BitRevRArr(x, base, Nlog2, ROILength);	//bitReverse the input array
        gpSize = 2;     //first & second stages - do radix 4 butterflies once thru
        numGps = ROILength / 4;
        for (gpNum=0; gpNum<numGps; gpNum++)  {
            Ad1 = gpNum * 4;
            Ad2 = Ad1 + 1;
            Ad3 = Ad1 + gpSize;
            Ad4 = Ad2 + gpSize;
            rt1 = x[base+Ad1] + x[base+Ad2];   // a + b
            rt2 = x[base+Ad1] - x[base+Ad2];   // a - b
            rt3 = x[base+Ad3] + x[base+Ad4];   // c + d
            rt4 = x[base+Ad3] - x[base+Ad4];   // c - d
            x[base+Ad1] = rt1 + rt3;      // a + b + (c + d)
            x[base+Ad2] = rt2 + rt4;      // a - b + (c - d)
            x[base+Ad3] = rt1 - rt3;      // a + b - (c + d)
            x[base+Ad4] = rt2 - rt4;      // a - b - (c - d)
        }

        if (Nlog2 > 2) {
            // third + stages computed here
            gpSize = 4;
            numBfs = 2;
            numGps = numGps / 2;
            for (stage=2; stage<Nlog2; stage++) {
                for (gpNum=0; gpNum<numGps; gpNum++) {
                    Ad0 = gpNum * gpSize * 2;
                    Ad1 = Ad0;     // 1st butterfly is different from others - no mults needed
                    Ad2 = Ad1 + gpSize;
                    Ad3 = Ad1 + gpSize / 2;
                    Ad4 = Ad3 + gpSize;
                    rt1 = x[base+Ad1];
                    x[base+Ad1] = x[base+Ad1] + x[base+Ad2];
                    x[base+Ad2] = rt1 - x[base+Ad2];
                    rt1 = x[base+Ad3];
                    x[base+Ad3] = x[base+Ad3] + x[base+Ad4];
                    x[base+Ad4] = rt1 - x[base+Ad4];
                    for (bfNum=1; bfNum<numBfs; bfNum++) {
                        // subsequent BF's dealt with together
                        Ad1 = bfNum + Ad0;
                        Ad2 = Ad1 + gpSize;
                        Ad3 = gpSize - bfNum + Ad0;
                        Ad4 = Ad3 + gpSize;

                        CSAd = bfNum * numGps;
                        rt1 = x[base+Ad2] * C[CSAd] + x[base+Ad4] * S[CSAd];
                        rt2 = x[base+Ad4] * C[CSAd] - x[base+Ad2] * S[CSAd];

                        x[base+Ad2] = x[base+Ad1] - rt1;
                        x[base+Ad1] = x[base+Ad1] + rt1;
                        x[base+Ad4] = x[base+Ad3] + rt2;
                        x[base+Ad3] = x[base+Ad3] - rt2;

                    } /* end bfNum loop */
                } /* end gpNum loop */
                gpSize *= 2;
                numBfs *= 2;
                numGps = numGps / 2;
            } /* end for all stages */
        } /* end if Nlog2 > 2 */

        if (inverse)  {
            for (i=0; i<ROILength; i++)
                x[base+i] = x[base+i] / ROILength;
        }
    }

    void transposeR (float[] x, int ROILength) {
        int   r, c;
        float  rTemp;

        for (r=0; r<ROILength; r++)  {
            for (c=r; c<ROILength; c++) {
                if (r != c)  {
                    rTemp = x[r*ROILength + c];
                    x[r*ROILength + c] = x[c*ROILength + r];
                    x[c*ROILength + r] = rTemp;
                }
            }
        }
    }

    int log2 (int x) {
        int count = 31;
        while (!btst(x, count))
            count--;
        return count;
    }


    void initializeTables(int ROILength) {

        this.makeSinCosTables(ROILength);
        this.makeBitReverseTable(ROILength);
        this.tempArr = new float[ROILength];

    }

    void makeSinCosTables(int ROILength) {
        int n = ROILength / 4;
        this.C = new float[n];
        this.S = new float[n];
        double theta = 0.0D;
        double dTheta = 6.283185307179586D / (double) ROILength;

        for (int i = 0; i < n; ++i) {
            this.C[i] = (float) Math.cos(theta);
            this.S[i] = (float) Math.sin(theta);
            theta += dTheta;
        }
    }

    void makeBitReverseTable(int ROILength) {
        this.bitrev = new int[ROILength];
        int nLog2 = this.log2(ROILength);

        for(int i = 0; i < ROILength; ++i) {
            this.bitrev[i] = this.bitRevX(i, nLog2);
        }

    }

    private boolean btst(int x, int bit) {
        return (x & 1 << bit) != 0;
    }

    void BitRevRArr(float[] x, int base, int bitlen, int ROILength) {
        int i;
        for(i = 0; i < ROILength; ++i) {
            this.tempArr[i] = x[base + this.bitrev[i]];
        }

        for(i = 0; i < ROILength; ++i) {
            x[base + i] = this.tempArr[i];
        }

    }

    private int bitRevX(int x, int bitlen) {
        int temp = 0;

        for(int i = 0; i <= bitlen; ++i) {
            if ((x & 1 << i) != 0) {
                temp |= 1 << bitlen - i - 1;
            }
        }

        return temp;
    }




}




