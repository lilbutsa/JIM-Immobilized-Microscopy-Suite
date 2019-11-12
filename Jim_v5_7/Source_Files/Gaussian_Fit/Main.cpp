
#include <iostream>
#include <cmath>
#include "mkl.h"
#include "ipp.h"
#include <vector>
#include "BLCSVIO.h"

using namespace std;

int fitGaus(vector<double>& xdata, vector<double>& ydata, vector<double>& paramvec);

double CalcMedian(vector<double> scores);

int main(int argc, char *argv[])
{
	if (argc < 2) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	double xminPercent = 0, xmaxPercent = 1, yminPercent = 0, ymaxPercent = 1;

	double xminAbs = -DBL_MAX, xmaxAbs = DBL_MAX;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-xminPercent") {
			if (i + 1 < argc) {
				xminPercent = stod(argv[i + 1]);
				cout << "xmin set to " << xminPercent << " Percent" << endl;
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
	}

	std::vector< std::vector<double> > alldatatofit(3000, vector<double>(1000, 0));
	vector< std::string > headerLine;
	BLCSVIO::readVariableWidthCSV(inputfile, alldatatofit, headerLine);

	vector< vector<double> > allparams(alldatatofit.size(), vector<double>(5, 0.0));

	vector<double> xdata, ydata, xdata1, ydata1,gausfitparams;

	double xinmin, xinmax, yinmin, yinmax, xinminPercent, xinmaxPercent, yinminPercent, yinmaxPercent;

	for (int i = 0; i < alldatatofit.size(); i++) {


		xdata1 = alldatatofit[i];
		sort(xdata1.begin(), xdata1.end());
		ydata1.resize(xdata1.size());
		for (int j = 0; j < ydata1.size(); j++)ydata1[j] = (j + 1.0) / ((double)ydata1.size());

		xdata.clear();
		ydata.clear();
		ippsMinMax_64f(xdata1.data(), xdata1.size(), &xinmin, &xinmax);
		xinminPercent = xinmin + xminPercent*(xinmax - xinmin);
		xinmaxPercent = xinmin + xmaxPercent*(xinmax - xinmin);
		yinminPercent = yminPercent;
		yinmaxPercent = ymaxPercent;
		cout << "Taking x values between " << xinminPercent << " and " << xinmaxPercent << "\n";
		cout << "Taking y values between " << yinminPercent << " and " << yinmaxPercent << " Percent\n";
		for (int j = 0; j < xdata1.size(); j++)if (xdata1[j] >= xminAbs && xdata1[j] >= xinminPercent && xdata1[j] <= xmaxAbs && xdata1[j] <= xinmaxPercent &&
			ydata1[j] >= yinminPercent && ydata1[j] <= yinmaxPercent) {
			xdata.push_back(xdata1[j]);
			ydata.push_back(ydata1[j]);
			//cout << "{" << xdata1[j] << "," << ydata1[j] << "} ";
		}

		fitGaus(xdata, ydata, gausfitparams);
		allparams[i][0] = gausfitparams[0];
		allparams[i][1] = gausfitparams[1];

		double mean, stddev;
		ippsMeanStdDev_64f(alldatatofit[i].data(), alldatatofit[i].size(), &allparams[i][2], &allparams[i][3]);
		allparams[i][4] = CalcMedian(alldatatofit[i]);



		cout << "Fitting f(x) = exp(-(x-u)^2/(2 o^2) for dataset " << i / 2 + 1 << " gives parameters :\n";
		cout << "u = " << allparams[i][0] << " o = " << allparams[i][1]  << "\n";
		cout << "General statistics:\n";
		cout<<"mean = " << allparams[i][2] << " std. dev. = " << allparams[i][3] << " Median = " << allparams[i][4] << "\n";
	}


	BLCSVIO::writeCSV(output + "_GaussFit.csv", allparams, "Gaussian Mean,Gaussian Std Dev.,Mean, Std. Dev., Median\n");

	//system("PAUSE");
	return 0;
}

