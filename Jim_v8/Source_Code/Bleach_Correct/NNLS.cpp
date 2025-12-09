//This is from https://github.com/alexgittens/nmfmpi/blob/master/nnls.c

#include <stdlib.h>
#include <math.h>
#include <vector>

/* Local function definitions */
int _lss_h12(
    int mode, int lpivot, int l1, int m, double* u, int iue,
    double* up, double* cm, int ice, int icv, int ncv
);
void _lss_g1(
    double a, double b, double* cterm, double* sterm, double* sig
);
/*****************************************************************************/

/*****************************************************************************/
int nnls(
    std::vector<std::vector<double>>& a,
    size_t m,
    size_t n,
    double* b,
    double* x,
    double* rnorm,
    double* wp,
    double* zzp,
    int* indexp
) {
    /* Check the parameters and data */
    if (m <= 0 || n <= 0 || b == NULL || x == NULL) return(2);
    /* Allocate memory for working space, if required */
    int* index = NULL, * indexl = NULL;
    double* w = NULL, * zz = NULL, * wl = NULL, * zzl = NULL;
    if (wp != NULL) w = wp; else w = wl = (double*)calloc(n, sizeof(double));
    if (zzp != NULL) zz = zzp; else zz = zzl = (double*)calloc(m, sizeof(double));
    if (indexp != NULL) index = indexp; else index = indexl = (int*)calloc(n, sizeof(int));
    if (w == NULL || zz == NULL || index == NULL) return(2);

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
        while (1) {

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
            _lss_h12(1, npp1, npp1 + 1, (int)m, &a[j][0], 1, &up, NULL, 1, 1, 0);
            double unorm = 0.0;
            if (nsetp != 0) for (int mi = 0; mi < nsetp; mi++) unorm += a[j][mi] * a[j][mi];
            unorm = sqrt(unorm);
            double d = unorm + fabs(a[j][npp1]) * 0.01;
            if ((d - unorm) > 0.0) {
                /* Col j is sufficiently independent. Copy B into ZZ, update ZZ
                   and solve for ztest ( = proposed new value for X[j] ) */
                for (int mi = 0; mi < m; mi++) zz[mi] = b[mi];
                _lss_h12(2, npp1, npp1 + 1, (int)m, &a[j][0], 1, &up, zz, 1, 1, 1);
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
                _lss_h12(2, nsetp - 1, npp1, (int)m, &a[j][0], 1, &up, &a[jj][0], 1, (int)m, 1);
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
                        double ss, cc;
                        _lss_g1(a[ii][ni - 1], a[ii][ni], &cc, &ss, &a[ii][ni - 1]);
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

    /* Compute the norm of the final residual vector */
    if (rnorm != NULL) {
        double sm = 0.0;
        if (npp1 < m) for (int mi = npp1; mi < m; mi++) sm += (b[mi] * b[mi]);
        else for (int ni = 0; ni < n; ni++) w[ni] = 0.;
        *rnorm = sm; //sqrt(sm);
    }

    /* Free working space, if it was allocated here */
    w = NULL; zz = NULL; index = NULL;
    if (wl != NULL) free(wl);
    if (zzl != NULL) free(zzl);
    if (indexl != NULL) free(indexl);
    if (iter >= itmax) return(1);

    return(0);
} /* nnls */
/*****************************************************************************/

/*****************************************************************************/

int _lss_h12(
    int mode,
    int lpivot,
    int l1,
    int m,
    double* u,
    int u_dim1,
    double* up,
    double* cm,
    int ice,
    int icv,
    int ncv
) {
    /* Check parameters */
    if (mode != 1 && mode != 2) return(1);
    if (m < 1 || u == NULL || u_dim1 < 1 /*|| cm==NULL*/) return(1);
    if (lpivot<0 || lpivot >= l1 || l1>m) return(1);

    double cl = fabs(u[lpivot * u_dim1]);

    if (mode == 2) { /* Apply transformation I+U*(U**T)/B to cm[] */
        if (cl <= 0.) return(0);
    }
    else {   /* Construct the transformation */

        /* trying to compensate overflow */
        for (int j = l1; j < m; j++) {  // Computing MAX 
            cl = fmax(fabs(u[j * u_dim1]), cl);
        }
        // zero vector?   
        if (cl <= 0.) return(0);

        double clinv = 1.0 / cl;

        // cl = sqrt( (u[pivot]*clinv)^2 + sigma(i=l1..m)( (u[i]*clinv)^2 ) )
        double d1 = u[lpivot * u_dim1] * clinv;
        double sm = d1 * d1;
        for (int j = l1; j < m; j++) {
            double d2 = u[j * u_dim1] * clinv;
            sm += d2 * d2;
        }
        cl *= sqrt(sm);
        if (u[lpivot * u_dim1] > 0.) cl = -cl;
        *up = u[lpivot * u_dim1] - cl;
        u[lpivot * u_dim1] = cl;
    }

    // no vectors where to apply? only change pivot vector! 
    double b = (*up) * u[lpivot * u_dim1];

    /* b must be non-positive here; if b>=0., then return */
    if (b >= 0.0) return(0); // was if(b==0) before 2013-06-22

    // ok, for all vectors we want to apply
    if (cm == NULL) return(2);
    for (int j = 0; j < ncv; j++) {
        // take s = c[p,j]*h + sigma(i=l..m){ c[i,j] *v [ i ] }
        double sm = cm[lpivot * ice + j * icv] * (*up);
        for (int k = l1; k < m; k++) sm += cm[k * ice + j * icv] * u[k * u_dim1];
        if (sm != 0.0) {
            sm *= (1.0 / b); // was (1/b) before 2013-06-22
            // cm[lpivot, j] = ..
            cm[lpivot * ice + j * icv] += sm * (*up);
            // for i = l1...m , set c[i,j] = c[i,j] + s*v[i]
            for (int k = l1; k < m; k++) cm[k * ice + j * icv] += u[k * u_dim1] * sm;
        }
    }

    return(0);
} /* _lss_h12 */
/*****************************************************************************/

/*****************************************************************************/
void _lss_g1(double a, double b, double* cterm, double* sterm, double* sig)
{
    double d1, xr, yr;

    if (fabs(a) > fabs(b)) {
        xr = b / a; d1 = xr; yr = hypot(d1, 1.0); d1 = 1. / yr;
        *cterm = copysign(d1, a);
        *sterm = (*cterm) * xr; *sig = fabs(a) * yr;
    }
    else if (b != 0.) {
        xr = a / b; d1 = xr; yr = hypot(d1, 1.0); d1 = 1. / yr;
        *sterm = copysign(d1, b);
        *cterm = (*sterm) * xr; *sig = fabs(b) * yr;
    }
    else {
        *sig = 0.; *cterm = 0.; *sterm = 1.;
    }
} /* _lss_g1 */
/*****************************************************************************/
