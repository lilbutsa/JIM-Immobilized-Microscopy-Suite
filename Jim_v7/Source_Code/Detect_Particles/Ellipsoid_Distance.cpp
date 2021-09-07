#include <stdio.h>
#include<math.h>
#include<errno.h>
#include<stdlib.h>
#include <complex>

std::complex<double> c_cbrt(std::complex<double> x);

/*Distance of Closest Approach of two arbitrary ellipses*/
double distance2d(double a1, double b1, double a2, double b2, double angle1, double angle2)
{
	double eps1, eps2, k1dotd, k2dotd, k1dotk2, nu, Ap[2][2],
		lambdaplus, lambdaminus, bp2, ap2, cosphi, tanphi2, delta, dp;
	std::complex<double> A(0,0), B(0,0), C(0, 0), D(0, 0), E(0, 0), alpha(0, 0), beta(0, 0), gamma(0, 0), P(0, 0), Q(0, 0), U(0, 0), y(0, 0), qu(0, 0);
	//the fix on July 2012 
	if (fabs(angle2 - angle1) == 3.141592653589)
	{
		angle2 = angle1;
	}
	//
	eps1 = sqrt(1.0 - (b1 * b1) / (a1 * a1));
	eps2 = sqrt(1.0 - (b2 * b2) / (a2 * a2));
	k1dotd = cos(angle1);
	k2dotd = cos(angle2);
	k1dotk2 = cos(angle2 - angle1);
	nu = a1 / b1 - 1.0;
	Ap[0][0] = b1 * b1 / (b2 * b2) * (1.0 + 0.5 * (1.0 + k1dotk2) *
		(nu * (2.0 + nu) - eps2 * eps2 * (1.0 + nu * k1dotk2) * (1.0 + nu * k1dotk2)));
	Ap[1][1] = b1 * b1 / (b2 * b2) * (1.0 + 0.5 * (1.0 - k1dotk2) *
		(nu * (2.0 + nu) - eps2 * eps2 * (1.0 - nu * k1dotk2) * (1.0 - nu * k1dotk2)));
	Ap[0][1] = b1 * b1 / (b2 * b2) * 0.5 * sqrt(1.0 - k1dotk2 * k1dotk2) *
		(nu * (2.0 + nu) + eps2 * eps2 * (1.0 - nu * nu * k1dotk2 * k1dotk2));
	lambdaplus = 0.5 * (Ap[0][0] + Ap[1][1]) + sqrt(0.25 * (Ap[0][0] - Ap[1][1]) *
		(Ap[0][0] - Ap[1][1]) + Ap[0][1] * Ap[0][1]);
	lambdaminus = 0.5 * (Ap[0][0] + Ap[1][1]) - sqrt(0.25 * (Ap[0][0] - Ap[1][1]) *
		(Ap[0][0] - Ap[1][1]) + Ap[0][1] * Ap[0][1]);
	bp2 = 1.0 / sqrt(lambdaplus);
	ap2 = 1.0 / sqrt(lambdaminus);
	if (fabs(k1dotk2) == 1.0)
	{
		if (Ap[0][0] > Ap[1][1])
			cosphi = b1 / a1 * k1dotd / sqrt(1.0 - eps1 * eps1 * k1dotd * k1dotd);
		else
			cosphi = sqrt(1.0 - k1dotd * k1dotd) / sqrt(1.0 - eps1 * eps1 * k1dotd * k1dotd);
	}
	else
	{
		cosphi = 1.0 / sqrt(2.0 * (Ap[0][1] * Ap[0][1] + (lambdaplus - Ap[0][0]) * (lambdaplus - Ap[0][0])) *
			(1.0 - eps1 * eps1 * k1dotd * k1dotd)) * (Ap[0][1] / sqrt(1.0 + k1dotk2) * (b1 / a1 * k1dotd +
				k2dotd + (b1 / a1 - 1.0) * k1dotd * k1dotk2) + (lambdaplus - Ap[0][0]) / sqrt(1.0 - k1dotk2) *
				(b1 / a1 * k1dotd - k2dotd - (b1 / a1 - 1.0) * k1dotd * k1dotk2));
	}
	delta = ap2 * ap2 / (bp2 * bp2) - 1.0;
	if (delta == 0.0 || cosphi == 0.0)
		dp = 1.0 + ap2;
	else
	{
		tanphi2 = 1.0 / (cosphi * cosphi) - 1.0;
		A = -(1.0 + tanphi2) / (bp2 * bp2);
		B = -2.0 * (1.0 + tanphi2 + delta) / bp2;
		C = -tanphi2 - (1.0 + delta) * (1.0 + delta) + (1.0 + (1.0 + delta) * tanphi2) / (bp2 * bp2);
		D = 2.0 * (1.0 + tanphi2) * (1.0 + delta) / bp2;
		E = (1.0 + tanphi2 + delta) * (1.0 + delta);
		alpha = -3.0 * B * B / (8.0 * A * A) + C / A;
		beta = B * B * B / (8.0 * A * A * A) - B * C / (2.0 * A * A) + D / A;
		gamma = -3.0 * B * B * B * B / (256.0 * A * A * A * A) + C * B * B / (16.0 * A * A * A) - B * D / (4.0 * A * A) + E / A;
		if (beta == 0.0)
		{
			qu = -B / (4.0 * A) + sqrt(0.5 * (-alpha + sqrt(alpha * alpha - 4.0 * gamma)));
		}
		else
		{
			P = -alpha * alpha / 12.0 - gamma;
			Q = -alpha * alpha * alpha / 108.0 + alpha * gamma / 3.0 - beta * beta / 8.0;
			U = c_cbrt((std::complex<double>(-1,0))*Q * 0.5 + sqrt(Q * Q * 0.25 + P * P * P / 27.0));
			if (U == 0.0)
				y = -5.0 * alpha / 6.0 - c_cbrt(Q);
			else
				y = -5.0 * alpha / 6.0 + U - P / (3.0 * U);
			qu = -B / (4.0 * A) + 0.5 * (sqrt(alpha + 2.0 * y) +
				sqrt(-(3.0 * alpha + 2.0 * y + 2.0 * beta / sqrt(alpha + 2.0 * y))));
		}
		 std::complex<double>holding = sqrt((qu * qu - 1.0) / delta * (1.0 + bp2 * (1.0 + delta) / qu) *
			(1.0 + bp2 * (1.0 + delta) / qu) + (1.0 - (qu * qu - 1.0) / delta) * (1.0 + bp2 / qu) * (1.0 + bp2 / qu));
		 dp = holding.real();
	}
	return dp * b1 / sqrt(1.0 - eps1 * eps1 * k1dotd * k1dotd);
}
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
/* Principal cubic root of a complex number */
std::complex<double> c_cbrt(std::complex<double> x)
{
	double a, b, r, phi, rn;
	a = x.real();
	b = x.imag();
	r = sqrt(a * a + b * b);
	phi = atan2(b, a);
	phi /= 3.0;
	rn = cbrt(r);
	return(std::complex<double>(rn * cos(phi), rn * sin(phi)));
}
