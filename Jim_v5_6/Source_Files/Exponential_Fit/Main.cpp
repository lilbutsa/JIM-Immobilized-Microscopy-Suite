
#include <iostream>
#include <cmath>
#include "mkl.h"
#include "ipp.h"
#include<vector>
#include "BLCSVIO.h"

using namespace std;

int fitExp(vector<double>& xdata, vector<double>& ydata, vector<double>& paramvec);

int main(int argc, char *argv[])
{
	if (argc < 2) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	double xminPercent=0, xmaxPercent =1, yminPercent =0, ymaxPercent =1;

	double xminAbs = -DBL_MAX, xmaxAbs = DBL_MAX, yminAbs = -DBL_MAX, ymaxAbs = DBL_MAX;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-xminPercent") {
			if (i + 1 < argc) {
				xminPercent = stod(argv[i + 1]);
				cout << "xmin set to " << xminPercent <<" Percent" << endl;
			}
			else { std::cout << "error inputting xmin Percent" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-xmaxPercent") {
			if (i + 1 < argc) {
				xmaxPercent = stod(argv[i + 1]);
				cout << "xmax set to " << xmaxPercent << " Percent" << endl;
			}
			else { std::cout << "error inputting xmax Percent" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-yminPercent") {
			if (i + 1 < argc) {
				yminPercent = stod(argv[i + 1]);
				cout << "ymin set to " << yminPercent << " Percent" << endl;
			}
			else { std::cout << "error inputting ymin Percent" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-ymaxPercent") {
			if (i + 1 < argc) {
				ymaxPercent = stod(argv[i + 1]);
				cout << "ymax set to " << ymaxPercent << " Percent" << endl;
			}
			else { std::cout << "error inputting ymax Percent" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-xminAbs") {
			if (i + 1 < argc) {
				xminAbs = stod(argv[i + 1]);
				cout << "Absolute xmin set to " << xminAbs << endl;
			}
			else { std::cout << "error inputting xmin Abs" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-xmaxAbs") {
			if (i + 1 < argc) {
				xmaxAbs = stod(argv[i + 1]);
				cout << "Absolute xmax set to " << xmaxPercent << endl;
			}
			else { std::cout << "error inputting xmax Abs" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-yminAbs") {
			if (i + 1 < argc) {
				yminAbs = stod(argv[i + 1]);
				cout << "Absolute ymin set to " << yminAbs << endl;
			}
			else { std::cout << "error inputting ymin Abs" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-ymaxAbs") {
			if (i + 1 < argc) {
				ymaxAbs = stod(argv[i + 1]);
				cout << "Absolute ymax set to " << ymaxPercent  << endl;
			}
			else { std::cout << "error inputting ymax Abs" << std::endl; return 1; }
		}
	}

	std::vector< std::vector<double> > alldatatofit(3000, vector<double>(1000, 0));
	vector< std::string > headerLine;
	BLCSVIO::readVariableWidthCSV(inputfile, alldatatofit, headerLine);

	vector< vector<double> > allparams(floor(alldatatofit.size()/2), vector<double>(3,0.0));

	vector<double> xdata, ydata;

	double xinmin, xinmax, yinmin, yinmax,xinminPercent,xinmaxPercent,yinminPercent,yinmaxPercent;

	for (int i = 0; i + 1 < alldatatofit.size(); i = i + 2) {
		xdata.clear();
		ydata.clear();
		ippsMinMax_64f(alldatatofit[i].data(), alldatatofit[i].size(), &xinmin, &xinmax);
		ippsMinMax_64f(alldatatofit[i+1].data(), alldatatofit[i+1].size(), &yinmin, &yinmax);
		xinminPercent = xinmin + xminPercent*(xinmax - xinmin);
		xinmaxPercent = xinmin + xmaxPercent*(xinmax - xinmin);
		yinminPercent = yinmin + yminPercent*(yinmax - yinmin);
		yinmaxPercent = yinmin + ymaxPercent*(yinmax - yinmin);
		cout << "Taking x values between " << xinminPercent << " and " << xinmaxPercent << "\n";
		cout << "Taking y values between " << yinminPercent << " and " << yinmaxPercent << "\n";
		for (int j = 0; j < alldatatofit[i].size(); j++)if (alldatatofit[i][j] >= xminAbs && alldatatofit[i][j] >= xinminPercent && alldatatofit[i][j] <= xmaxAbs && alldatatofit[i][j] <= xinmaxPercent &&
			alldatatofit[i + 1][j] >= yminAbs && alldatatofit[i + 1][j] >= yinminPercent && alldatatofit[i + 1][j] <= ymaxAbs && alldatatofit[i + 1][j] <= yinmaxPercent) {
			xdata.push_back(alldatatofit[i][j]);
			ydata.push_back(alldatatofit[i + 1][j]);
		}

		fitExp(xdata, ydata, allparams[i/2]);

		cout << "Fitting f(x) = A+B*exp(-c*x) for dataset "<<i/2+1<<" gives parameters :\n";
		cout << "A = " << allparams[i / 2][0] << " B = " << allparams[i / 2][1] << " C = " << allparams[i / 2][2] << "\n";
	}

	BLCSVIO::writeCSV(output + "_ExpFit.csv", allparams, "Offset,Amplitude,Exponent\n");

	//system("PAUSE");
	return 0;
}

