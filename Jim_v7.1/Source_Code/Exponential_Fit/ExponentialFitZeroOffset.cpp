
#include <iostream>
#include <cmath>
#include "mkl.h"
#include "ipp.h"
#include <vector>

using namespace std;


void exp_funczo(int NOP, vector<double> & c, vector<double> & x, vector<double> & f, vector<double> & datain)
{

	for (int i = 0; i < NOP; i++)f[i] = (datain[i] - ( c[0] * exp(-c[1] * x[i])));
	return;
}

void exp_jaczo(int NOP, vector<double> & c, vector<double> & x, vector<double> & jac)
{

	for (int i = 0; i < NOP; i++) {
		jac[ i] = -exp(-c[1] * x[i]);
		jac[NOP + i] = x[i] * c[0] * exp(-c[1] * x[i]);
	}
	return;
}

int fitExpZeroOffset(vector<double>& xdata, vector<double>& ydata, vector<double>& paramvecin) {

	
	paramvecin.resize(3);
	vector<double> paramvec(2);



	int NOP = xdata.size();
	int NOV = 2;


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
	double min, max, xmin;
	ippsMinMax_64f(ydata.data(), NOP, &min, &max);
	ippsMin_64f(xdata.data(), NOP, &xmin);

	double xmean;

	ippsMean_64f(xdata.data(), xdata.size(), &xmean);

	paramvec[1] = 1.0 / (xmean - xmin);
	paramvec[0] = max / (exp(-xmin*paramvec[1]));


	/* set initial values */
	exp_funczo(NOP, paramvec, xdata, fvec, ydata);
	exp_jaczo(NOP, paramvec, xdata, jacvec);

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
			exp_funczo(NOP, paramvec, xdata, fvec, ydata);
		}
		if (RCI_Request == 2)
		{
			/* compute jacobi matrix*/
			exp_jaczo(NOP, paramvec, xdata, jacvec);

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

	paramvecin[0] = 0;
	paramvecin[1] = paramvec[0];
	paramvecin[2] = paramvec[1];

	return 0;
}

