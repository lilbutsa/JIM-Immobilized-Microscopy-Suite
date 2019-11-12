#include <iostream>
#include <cmath>
#include <vector>
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;

void makeHistogram(vector<double> values, double binWidth, vector<double>& xhistogram, vector<double>& yhistogram) {
	double min, max;
	ippsMinMax_64f(values.data(), values.size(), &min, &max);

	min -= binWidth;
	max += binWidth;

	int numOfBins = ceil((max - min) / binWidth);
	int pos;

	yhistogram.clear();

	xhistogram.resize(numOfBins);
	yhistogram.resize(numOfBins);

	for (int i = 0; i < numOfBins; i++)xhistogram[i] = min + (i + 0.5)*binWidth;

	for (int i = 0; i < values.size(); i++) {
		pos = floor((values[i] - min) / binWidth);
		yhistogram[pos] = yhistogram[pos] + 1;
	}

	for (int i = 0; i < numOfBins; i++)yhistogram[i] = yhistogram[i] / (values.size()*binWidth);

}

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


void CalcQuartile(vector<double> scores,vector<double>& quartiles)
{
	quartiles.resize(3);

	int size = scores.size();

	quartiles[1] = CalcMedian(scores);

	sort(scores.begin(), scores.begin() + size);


	if (size % 2 == 0)
	{
		quartiles[0] = CalcMedian(vector<double>(scores.data(),&scores[size / 2 - 1]));

		quartiles[2] = CalcMedian(vector<double>(&scores[size / 2], &scores[size -1]));
	}
	else
	{

		quartiles[0] = CalcMedian(vector<double>(scores.data(), &scores[(size-1) / 2 - 1]));

		quartiles[2] = CalcMedian(vector<double>(&scores[(size-1) / 2+1], &scores[size - 1]));

	}


}




int main(int argc, char *argv[])
{
	if (argc < 2) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];
	double binWidth;
	bool bcalcBinWidth = true;


	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-binWidth") {
			if (i + 1 < argc) {
				binWidth = stod(argv[i + 1]);
				bcalcBinWidth = false;
				cout << "Bin Width set to " << binWidth << " Percent" << endl;
			}
			else { std::cout << "error inputting bin width" << std::endl; return 1; }
		}
	}

	std::vector< std::vector<double> > alldatatofit(3000, vector<double>(1000, 0));
	vector< std::string > headerLine;
	BLCSVIO::readVariableWidthCSV(inputfile, alldatatofit, headerLine);

	vector<double> quartiles, xdata,xhistogram,yhistogram;

	vector< vector<double> > allhistograms;

	for (int i = 0; i < alldatatofit.size(); i++) {
		cout << "Making histogram for data set " << i << "\n";
		xdata = alldatatofit[i];
		if (bcalcBinWidth) {
			CalcQuartile(xdata, quartiles);
			cout << "1st Quartile = " << quartiles[0] << " 2nd Quartile = " << quartiles[1] << " 3rd Quartile = " << quartiles[2] << "\n";
			cout << xdata.size() << " " << pow(1.0*xdata.size(), 0.3333333) << "\n";
			binWidth = 2.0*(quartiles[2] - quartiles[0]) / (pow(1.0*xdata.size(), 0.3333333)); //Using the Freedman–Diaconis rule
			cout << "Bin width set to " << binWidth << "\n";
		}

		makeHistogram(xdata, binWidth, xhistogram, yhistogram);

		allhistograms.push_back(xhistogram);
		allhistograms.push_back(yhistogram);
	}

	BLCSVIO::writeCSV(output + "_Histograms.csv", allhistograms, "First lines are bin middles, second lines are are normalized bin heights\n");
	//system("PAUSE");
	return 0;
}