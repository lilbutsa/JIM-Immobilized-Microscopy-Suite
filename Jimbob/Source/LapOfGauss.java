package org.micromanager.plugins.Poor_Mans_JIM;

import ij.plugin.filter.*;
import ij.process.*;
import java.awt.*;


public class LapOfGauss {
    float[][] kernel=null;
    int sz, r;

    public LapOfGauss(int gaussianSigma){
        sz = gaussianSigma;
        r = (sz-1)/2;
        float[] kernx= gauss1D(r);
        float[] kern_diff= diff2Gauss1D(r);
        kernel=new float[3][];
        kernel[0]=kernx;
        kernel[1]=kern_diff;
        float[] kernel2=computeKernel2D(r);
        kernel[2]=kernel2;
    }
    public FloatProcessor run(FloatProcessor ipin,boolean seperableKernal) {

        FloatProcessor ip = ipin;
        if (seperableKernal)
            convolveSep(ip, kernel[0], kernel[1]);
        else {
            Convolver con=new Convolver();
            con.convolveFloat(ip, kernel[2], sz, sz);
        }
        double sigma2=(sz-1)/6.0;
        sigma2*=sigma2;
        ip.multiply(sigma2);

        return ip;
    }

    private void convolveSep(ImageProcessor ip, float[] kernx, float[] kern_diff) {
        FloatProcessor ip2 = null;
        FloatProcessor ipx = null;
        ip2 = (FloatProcessor)ip.duplicate();
        ip2.setRoi(ip.getRoi());
        ip2.setSnapshotPixels(ip.getSnapshotPixels());
        ipx=(FloatProcessor)ip2.duplicate();
        ipx.setRoi(ip.getRoi());
        ipx.setSnapshotPixels(ip.getSnapshotPixels());
        Convolver con=new Convolver();
        con.convolveFloat1D(ipx, kern_diff, sz, 1); // x direction
        ipx.setSnapshotPixels(null);
        con.convolveFloat1D(ipx, kernx, 1, sz); // y direction
        con.convolveFloat1D(ip2, kernx, sz, 1); // x direction
        ip2.setSnapshotPixels(null);
        con.convolveFloat1D(ip2, kern_diff, 1, sz); // y direction
        add(ip2, ipx, ip2.getRoi());
        insert(ip2, ip);
    }


    private void insert(ImageProcessor ip1, ImageProcessor ip2) {
        float[] pixels1 = (float[])ip1.getPixels();
        float[] pixels2 = (float[])ip2.getPixels();
        Rectangle r = ip1.getRoi();
        int offset = r.y*r.width;
        int n = r.width*r.height;
        for (int i=0; i<n; i++) {
            pixels2[offset] = pixels1[offset];
            offset++;
        }
    }

    private void add(ImageProcessor ip1, ImageProcessor ip2, Rectangle r) {
        for (int y=r.y; y<r.y+r.height; y++) {
            for (int x=r.x;x<r.x+r.width; x++) {
                float sum = ip1.getf(x,y) + ip2.getf(x,y);
                ip1.setf(x, y, sum);
            }
        }
    }


    public float[] computeKernel2D(int r) {
        sz=2*r+1;
        final double sigma2=2*((double)r/3.0+1/6.0)*((double)r/3.0 +1/6.0);
        float[] kernel=new float[sz*sz];
        final double PIs=4/Math.sqrt(Math.PI*sigma2)/sigma2/sigma2;
        float sum=0;
        for (int u=-r; u<=r; u++) {
            for (int w=-r; w<=r; w++) {
                final double x2=u*u+w*w;
                final int idx=u+r + sz*(w+r);
                kernel[idx]=(float)((x2 -sigma2)*Math.exp(-x2/sigma2)*PIs);
                ///System.out.print(kernel[c] +" ");
                sum+=kernel[idx];

            }
        }
        sum=Math.abs(sum);
        if (sum<1e-5) sum=1;
        if (sum!=1) {
            for (int i=0; i<kernel.length; i++) {
                kernel[i]/=sum;
                //System.out.print(kernel[i] +" ");
            }
        }
        return kernel;
    }

    public float[] gauss1D(int r) {
        sz=2*r+1;
        //final double sigma2=2*((double)r/3.5 +1/7.0)*((double)r/3.5 +1/7.0);
        final double sigma2=((double)r/3.0+1/6)*((double)r/3.0 +1/6.0);
        float[] kernel=new float[sz];
        float sum=0;
        final double PIs=1/Math.sqrt(2*Math.PI*sigma2);
        for (int u=-r; u<=r; u++) {
            final double x2=u*u;
            final int idx=u+r ;
            kernel[idx]=(float)(Math.exp(-0.5*x2/sigma2)*PIs);

        }
        sum=Math.abs(sum);
        if (sum<1e-5) sum=1;
        if (sum!=1) {
            for (int i=0; i<kernel.length; i++) {
                kernel[i]/=sum;
                //System.out.print(kernel[i] +" ");
            }
        }
        return kernel;
    }

    public float[] diff2Gauss1D(int r) {
        sz=2*r+1;
        final double sigma2=((double)r/3.0+1/6)*((double)r/3.0 +1/6.0);
        float[] kernel=new float[sz];
        //((w^2-r^2)*%e^(-r^2/(2*w^2)))/(2^(3/2)*sqrt(%pi)*w^4*abs(w))
        float sum=0;
        final double PIs=1/Math.sqrt(2*Math.PI*sigma2);
        for (int u=-r; u<=r; u++) {
            final double x2=u*u;
            final int idx=u+r ;
            kernel[idx]=(float)((x2-sigma2)*Math.exp(-0.5*x2/sigma2)*PIs);

        }
        sum=Math.abs(sum);
        if (sum<1e-5) sum=1;
        if (sum!=1) {
            for (int i=0; i<kernel.length; i++) {
                kernel[i]/=sum;
                //System.out.print(kernel[i] +" ");
            }
        }
        return kernel;
    }

    private float[] joinXY(float[][] kernel, int a, int b) {
        int sz=kernel[0].length;
        float[] jkernel=new float[sz*sz];
        for (int i=0; i<jkernel.length; i++)
            jkernel[i]=1.0f;
        for (int m=0; m<sz; m++) { // row
            for (int n=0; n<sz; n++) { // col
                final int idx=n + m *sz;
                jkernel[idx]*=kernel[a][n];
            }
        }
        for (int m=0; m<sz; m++) { // row
            for (int n=0; n<sz; n++) { // col
                final int idx=n + m *sz;
                jkernel[idx]*=kernel[b][m];
            }
        }
        return jkernel;
    }



}

