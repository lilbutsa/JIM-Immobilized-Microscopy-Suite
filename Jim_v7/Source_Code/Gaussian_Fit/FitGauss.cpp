
#include <iostream>
#include <algorithm>
#include <cmath>
#include "mkl.h"
#include "ipp.h"
#include<vector>

using namespace std;


double CalcMedian(vector<double> scores)
{
	double median;

	int size = scores.size();

	sort(scores.begin(), scores.begin() + size);


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


void gausCDF(int NOP, vector<double> & c, vector<double> & x, vector<double> & f, vector<double> & datain)
{

	for (int i = 0; i < NOP; i++)
		f[i] = datain[i]-0.5*(1 + erf((x[i] - c[0]) / (sqrt(2)*c[1])));
	return;
}

void gausCDFjac(int NOP, vector<double> & c, vector<double> & x, vector<double> & jac)
{

	for (int i = 0; i < NOP; i++) {
		jac[i] = exp(-(x[i] - c[0])*(x[i] - c[0]) / (2 * c[1] * c[1]))/(sqrt(2*3.141592653)*c[1]);
		jac[NOP + i] = (x[i]-c[0])*exp(-(x[i] - c[0])*(x[i] - c[0]) / (2 * c[1] * c[1])) / (sqrt(2 * 3.141592653)*c[1]*c[1]);
	}
	return;
}

int fitGaus(vector<double>& xdata, vector<double>& ydata, vector<double>& paramvec) {



	int NOP = xdata.size();
	int NOV = 2;

	paramvec.resize(NOV);

	vector<double> fvec(NOP, 0.0);
	vector<double> jacvec(NOV * NOP, 0.0);


	/* precisions for stop-criteria (see manual for more detailes) */
	vector<double>	eps(6, 0.000001);
	/* iter1 - maximum number of iterations
	iter2 - maximum number of iterations of calculation of trial-step */
	int iter1 = 100000, iter2 = 10000;
	double	rs = 100.0;

	/* reverse communication interface parameter */
	int RCI_Request, successful;

	/* TR solver handle */
	_TRNSP_HANDLE_t handle; // TR solver handle
							/* cycles counter */
							//Initial guess
	double mean, stddev;
	ippsMeanStdDev_64f(xdata.data(), NOP, &mean, &stddev);

	paramvec[0] = mean;
	paramvec[1] = stddev;

	/* set initial values */
	gausCDF(NOP, paramvec, xdata, fvec, ydata);
	gausCDFjac(NOP, paramvec, xdata, jacvec);

	if (dtrnlsp_init(&handle, &NOV, &NOP, paramvec.data(), eps.data(), &iter1, &iter2, &rs) != TR_SUCCESS)
	{
		/* if function does not complete successful then print error message */
		printf("| error in dtrnlsp_init\n");
		/* and exit */
		return 0;
	}
	/* set initial rci cycle variables */
	RCI_Request = 0;
	successful = 0;
	/* rci cycle */
	while (successful == 0)
	{
		/* call tr solver
		handle		in/out:	tr solver handle
		fvec		in:     vector
		fjac		in:     jacobi matrix
		RCI_request in/out:	return number which denote next step for performing */
		if (dtrnlsp_solve(&handle, fvec.data(), jacvec.data(), &RCI_Request) != TR_SUCCESS)
		{
			/* if function does not complete successful then print error message */
			printf("| error in dtrnlsp_solve\n");
			/* and exit */
			return 0;
		}
		/* according with rci_request value we do next step */
		if (RCI_Request == -1 ||
			RCI_Request == -2 ||
			RCI_Request == -3 ||
			RCI_Request == -4 ||
			RCI_Request == -5 ||
			RCI_Request == -6)
			/* exit rci cycle */
			successful = 1;
		if (RCI_Request == 1)
		{
			/* recalculate function value*/
			gausCDF(NOP, paramvec, xdata, fvec, ydata);
		}
		if (RCI_Request == 2)
		{
			/* compute jacobi matrix*/
			gausCDFjac(NOP, paramvec, xdata, jacvec);

		}
	}

	/* free handle memory */
	if (dtrnlsp_delete(&handle) != TR_SUCCESS)
	{
		/* if function does not complete successful then print error message */
		printf("| error in dtrnlsp_delete\n");
		/* and exit */
		return 1;
	}

	return 0;

}

