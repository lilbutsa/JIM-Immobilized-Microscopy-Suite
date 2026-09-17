package Jimbob;

import java.util.ArrayList;

public class myBleachCorrect {

    int numOfFrames;
    double meanBleachFrame;
    boolean binding;

    double[][] aMat, aMatHold;
    double[] fitOut;

    double[] wp,zzp;
    int[] indexp;

    double[] bleachCorrected, bleachFit;

    ArrayList<Double> stepHeights, stepFrames;

    myBleachCorrect(int numOfFramesIn,double meanBleachFrameIn,boolean bindingIn){

        if (numOfFramesIn <= 0) {
            throw new IllegalArgumentException("numOfFrames must be positive");
        }
        if (!Double.isFinite(meanBleachFrameIn) || meanBleachFrameIn <= 0.0) {
            throw new IllegalArgumentException(
                    "meanBleachFrame must be finite and positive");
        }

        numOfFrames = numOfFramesIn;

        fitOut = new double[numOfFrames];
        aMatHold = new double[numOfFrames][numOfFrames];
        aMat = new double[numOfFrames][numOfFrames];

        binding = bindingIn;
        meanBleachFrame = meanBleachFrameIn;

        if(binding){
            for (int i = 0;i < numOfFrames;i++) for (int j = i;j < numOfFrames;j++)aMatHold[i][j] = Math.exp((double)-1.0 * (j - i) / meanBleachFrame);
        } else {
            for (int j = 0;j < numOfFrames;j++)aMatHold[0][j] = Math.exp((double)-1.0 * j  / meanBleachFrame);
            for (int i = 1;i < numOfFrames;i++) for (int j = i;j < numOfFrames;j++)aMatHold[i][j] = -Math.exp(-1.0 * j / meanBleachFrame);
        }

        wp = new double[numOfFrames];
        zzp = new double[numOfFrames];
        indexp = new int[numOfFrames];

        bleachCorrected = new double[numOfFrames];
        bleachFit = new double[numOfFrames];

    }

     void Bleach_Correct(double[] trace) {
        stepHeights = new ArrayList<>();
        stepFrames = new ArrayList<>();
         if (trace == null || trace.length != numOfFrames) {
             throw new IllegalArgumentException(
                     "trace must contain exactly " + numOfFrames + " frames");
         }

        for (int i = 0;i < numOfFrames;i++) System.arraycopy(aMatHold[i], 0, aMat[i], 0, numOfFrames);
        double[] traceIn = trace.clone();

        nnls(aMat, numOfFrames, numOfFrames, traceIn, fitOut, wp, zzp, indexp);

        for (int i = 0;i < numOfFrames;i++){
            bleachFit[i] = 0;
            for (int j = 0;j < numOfFrames;j++)bleachFit[i] += aMatHold[j][i] * fitOut[j];
        }

        bleachCorrected[0] = fitOut[0];
        for (int i = 1; i < numOfFrames; i++)
            if (binding) bleachCorrected[i] = bleachCorrected[i - 1] + fitOut[i];
            else bleachCorrected[i] = bleachCorrected[i - 1] - fitOut[i];

        int count = 1;
        for (int i = 1; i < numOfFrames; i++)if(Math.abs(fitOut[i])>1e-9){
            stepHeights.add(Math.abs(fitOut[i]));
            stepFrames.add((double) count);
            count = 1;
        } else count++;

    }


    int nnls(
            double[][] a, int m, int n, double[] b,
            double[] x,
            double[] w,
            double[] zz,
            int[] index
    ) {
        /* Check the parameters and data */
        if (m <= 0 || n <= 0 || b == null || x == null) return(2);
        /* Allocate memory for working space, if required */

        /* Initialize the arrays INDEX[] and X[] */
        for (int ni = 0; ni < n; ni++) { x[ni] = 0.; index[ni] = ni; }
        int iz1 = 0;
        int iz2 = (int)n - 1;
        int nsetp = 0;
        int npp1 = 0;

    /* Main loop; quit if all coefficients are already in the solution or
       if M cols of A have been triangulated */
        double up = 0.0;
        int itmax; if (n < 3) itmax = (int)n * 3; else itmax = (int)n * (int)n;
        int iter = 0;
        int k, j = 0, jj = 0;
        while (iz1 <= iz2 && nsetp < m) {
            /* Compute components of the dual (negative gradient) vector W[] */
            for (int iz = iz1; iz <= iz2; iz++) {
                int ni = index[iz];
                double sm = 0.;
                for (int mi = npp1; mi < m; mi++) sm += a[ni][mi] * b[mi];
                w[ni] = sm;
            }

            double wmax;
            int izmax = 0;
            while (true) {

                /* Find largest positive W[j] */
                wmax = 0.0;
                for (int iz = iz1; iz <= iz2; iz++) {
                    int i = index[iz];
                    if (w[i] > wmax) { wmax = w[i]; izmax = iz; }
                }

                /* Terminate if wmax<=0.; */
                /* it indicates satisfaction of the Kuhn-Tucker conditions */
                if (wmax <= 0.0) break;
                j = index[izmax];

            /* The sign of W[j] is ok for j to be moved to set P.
               Begin the transformation and check new diagonal element to avoid
               near linear dependence. */
                double asave = a[j][npp1];
                up = 0.0;
                up = _lss_h12(1, npp1, npp1 + 1, (int)m, a[j], 1, up, null, 1, 1, 0);
                double unorm = 0.0;
                if (nsetp != 0) for (int mi = 0; mi < nsetp; mi++) unorm += a[j][mi] * a[j][mi];
                unorm = Math.sqrt(unorm);
                double d = unorm + Math.abs(a[j][npp1]) * 0.01;
                if ((d - unorm) > 0.0) {
                /* Col j is sufficiently independent. Copy B into ZZ, update ZZ
                   and solve for ztest ( = proposed new value for X[j] ) */
                    for (int mi = 0; mi < m; mi++) zz[mi] = b[mi];
                    up = _lss_h12(2, npp1, npp1 + 1, (int)m, a[j], 1, up, zz, 1, 1, 1);
                    double ztest = zz[npp1] / a[j][npp1];
                    /* See if ztest is positive */
                    if (ztest > 0.) break;
                }

            /* Reject j as a candidate to be moved from set Z to set P. Restore
               A[npp1,j], set W[j]=0., and loop back to test dual coefficients again */
                a[j][npp1] = asave; w[j] = 0.;
            } /* while(1) */
            if (wmax <= 0.0) break;

        /* Index j=INDEX[izmax] has been selected to be moved from set Z to set P.
           Update B and indices, apply householder transformations to cols in
           new set Z, zero sub-diagonal elements in col j, set W[j]=0. */
            for (int mi = 0; mi < m; mi++) b[mi] = zz[mi];
            index[izmax] = index[iz1]; index[iz1] = j; iz1++; nsetp = npp1 + 1; npp1++;
            if (iz1 <= iz2)
                for (int jz = iz1; jz <= iz2; jz++) {
                    jj = index[jz];
                    up = _lss_h12(2, nsetp - 1, npp1, (int)m, a[j], 1, up, a[jj], 1, (int)m, 1);
                }
            if (nsetp != m) for (int mi = npp1; mi < (int)m; mi++) a[j][mi] = 0.;
            w[j] = 0.;

            /* Solve the triangular system; store the solution temporarily in Z[] */
            for (int mi = 0; mi < nsetp; mi++) {
                int ip = nsetp - (mi + 1);
                if (mi != 0) for (int ii = 0; ii <= ip; ii++) zz[ii] -= a[jj][ii] * zz[ip + 1];
                jj = index[ip]; zz[ip] /= a[jj][ip];
            }

            /* Secondary loop begins here */
            while (++iter < itmax) {
                /* See if all new constrained coefficients are feasible; if not, compute alpha */
                double alpha = 2.0;
                for (int ip = 0; ip < nsetp; ip++) {
                    int ni = index[ip];
                    if (zz[ip] <= 0.) {
                        double t = -x[ni] / (zz[ip] - x[ni]);
                        if (alpha > t) { alpha = t; jj = ip - 1; }
                    }
                }

            /* If all new constrained coefficients are feasible then still alpha==2.
               If so, then exit from the secondary loop to main loop */
                if (alpha == 2.0) break;

                /* Use alpha (0.<alpha<1.) to interpolate between old X and new ZZ */
                for (int ip = 0; ip < nsetp; ip++) {
                    int ni = index[ip]; x[ni] += alpha * (zz[ip] - x[ni]);
                }

                /* Modify A and B and the INDEX arrays to move coefficient i from set P to set Z. */
                int pfeas = 1;
                k = index[jj + 1];
                do {
                    x[k] = 0.;
                    if (jj != (nsetp - 1)) {
                        jj++;
                        for (int ni = jj + 1; ni < nsetp; ni++) {
                            int ii = index[ni]; index[ni - 1] = ii;
                            double ss = 0, cc = 0;
                            double[] ret = _lss_g1(a[ii][ni - 1], a[ii][ni], cc, ss, a[ii][ni - 1]);
                            cc = ret[0];
                            ss = ret[1];
                            a[ii][ni - 1] = ret[2];

                            a[ii][ni] = 0.0;
                            for (int nj = 0; nj < n; nj++) if (nj != ii) {
                                /* Apply procedure G2 (CC,SS,A(J-1,L),A(J,L)) */
                                double temp = a[nj][ni - 1];
                                a[nj][ni - 1] = cc * temp + ss * a[nj][ni];
                                a[nj][ni] = -ss * temp + cc * a[nj][ni];
                            }
                            /* Apply procedure G2 (CC,SS,B(J-1),B(J)) */
                            double temp = b[ni - 1]; b[ni - 1] = cc * temp + ss * b[ni]; b[ni] = -ss * temp + cc * b[ni];
                        }
                    }
                    npp1 = nsetp - 1; nsetp--; iz1--; index[iz1] = k;

                /* See if the remaining coefficients in set P are feasible; they should be
                   because of the way alpha was determined. If any are infeasible
                   it is due to round-off error. Any that are non-positive
                   will be set to zero and moved from set P to set Z. */
                    for (jj = 0, pfeas = 1; jj < nsetp; jj++) {
                        k = index[jj]; if (x[k] <= 0.) { pfeas = 0; break; }
                    }
                } while (pfeas == 0);

                /* Copy B[] into zz[], then solve again and loop back */
                for (int mi = 0; mi < m; mi++) zz[mi] = b[mi];
                for (int mi = 0; mi < nsetp; mi++) {
                    int ip = nsetp - (mi + 1);
                    if (mi != 0) for (int ii = 0; ii <= ip; ii++) zz[ii] -= a[jj][ii] * zz[ip + 1];
                    jj = index[ip]; zz[ip] /= a[jj][ip];
                }
            } /* end of secondary loop */

            if (iter >= itmax) break;
            for (int ip = 0; ip < nsetp; ip++) { k = index[ip]; x[k] = zz[ip]; }
        } /* end of main loop */



        return(0);
    } /* nnls */
/*****************************************************************************/

    /*****************************************************************************/


    static double _lss_h12(//return up
            int mode,
            int lpivot,
            int l1,
            int m,
            double[] u,
            int u_dim1,
            double up,
            double[] cm,
            int ice,
            int icv,
            int ncv
    ) {
        /* Check parameters */

        double cl = Math.abs(u[lpivot * u_dim1]);

        if (mode == 2) { /* Apply transformation I+U*(U**T)/B to cm[] */
            if (cl <= 0.) return(up);
        }
        else {   /* Construct the transformation */

            /* trying to compensate overflow */
            for (int j = l1; j < m; j++) {  // Computing MAX
                cl = Math.max(Math.abs(u[j * u_dim1]), cl);
            }
            // zero vector?
            if (cl <= 0.) return(up);

            double clinv = 1.0 / cl;

            // cl = sqrt( (u[pivot]*clinv)^2 + sigma(i=l1..m)( (u[i]*clinv)^2 ) )
            double d1 = u[lpivot * u_dim1] * clinv;
            double sm = d1 * d1;
            for (int j = l1; j < m; j++) {
                double d2 = u[j * u_dim1] * clinv;
                sm += d2 * d2;
            }
            cl *= Math.sqrt(sm);
            if (u[lpivot * u_dim1] > 0.) cl = -cl;
            up = u[lpivot * u_dim1] - cl;
            u[lpivot * u_dim1] = cl;
        }

        // no vectors where to apply? only change pivot vector!
        double b = (up) * u[lpivot * u_dim1];

        /* b must be non-positive here; if b>=0., then return */
        if (b >= 0.0) return(up); // was if(b==0) before 2013-06-22

        // ok, for all vectors we want to apply
        if (cm == null) return(up);
        for (int j = 0; j < ncv; j++) {
            // take s = c[p,j]*h + sigma(i=l..m){ c[i,j] *v [ i ] }
            double sm = cm[lpivot * ice + j * icv] * (up);
            for (int k = l1; k < m; k++) sm += cm[k * ice + j * icv] * u[k * u_dim1];
            if (sm != 0.0) {
                sm *= (1.0 / b); // was (1/b) before 2013-06-22
                // cm[lpivot, j] = ..
                cm[lpivot * ice + j * icv] += sm * (up);
                // for i = l1...m , set c[i,j] = c[i,j] + s*v[i]
                for (int k = l1; k < m; k++) cm[k * ice + j * icv] += u[k * u_dim1] * sm;
            }
        }

        return(up);
    } /* _lss_h12 */
/*****************************************************************************/

    /*****************************************************************************/
    static double[] _lss_g1(double a, double b, double cterm, double sterm, double sig)
    {

        //return {cterm,sterm,sig}
        double d1, xr, yr;

        if (Math.abs(a) > Math.abs(b)) {
            xr = b / a; d1 = xr; yr = Math.sqrt(d1*d1+ 1.0); d1 = 1. / yr;
        cterm = (a>=0?1:-1)*Math.abs(d1);
        sterm = (cterm) * xr;
        sig = Math.abs(a) * yr;
        }
        else if (b != 0.) {
            xr = a / b; d1 = xr; yr = Math.sqrt(d1*d1+ 1.0); d1 = 1. / yr;
        sterm = (b>=0?1:-1)*Math.abs(d1);
        cterm = (sterm) * xr; sig = Math.abs(b) * yr;
        }
        else {
        sig = 0.; cterm = 0.; sterm = 1.;
        }

        return new double[]{cterm,sterm,sig};
    } /* _lss_g1 */
/*****************************************************************************/

}
