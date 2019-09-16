#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLCSVIO.h"

using namespace std;


int main(int argc, char *argv[])
{
	if (argc < 5) { cout << "could not read files" << endl; return 1; }
	string channelalignfile = argv[1];
	string driftfile = argv[2];
	string meaurementsfile = argv[3];
	string outputfile = argv[4];


	vector<vector<double>> channelalignin(50, vector<double>(11, 0.0)), driftsin(5000, vector<double>(2, 0.0)), positionsin(5000, vector<double>(6, 0.0));

	vector<vector<int>> positionslistin(2000, vector<int>(1000, 0)), positionslistout;
	vector<vector<int>> backpositionslistin(2000, vector<int>(1000, 0)), backpositionslistout;
	bool bpositionslist = false, bbacklist = false;
	string positionsfile;
	int imageWidth, imageHeight;
	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-positions") {
			if (i + 1 < argc) {
				positionsfile = argv[i + 1];
				cout << "Positions file being read from " << positionsfile << endl;
				bpositionslist = true;
				BLCSVIO::readVariableWidthCSV(positionsfile, positionslistin);
				positionslistout = positionslistin;
				imageWidth = positionslistin[0][0];
				imageHeight = positionslistin[0][1];
			}
			else { std::cout << "error inputting positions file" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-backgroundpositions") {
			if (i + 1 < argc) {
				positionsfile = argv[i + 1];
				cout << "Background Positions file being read from " << positionsfile << endl;
				bbacklist = true;
				BLCSVIO::readVariableWidthCSV(positionsfile, backpositionslistin);
				backpositionslistout = backpositionslistin;
			}
			else { std::cout << "error inputting positions file" << std::endl; return 1; }
		}
	}


	BLCSVIO::readCSV(channelalignfile, channelalignin);
	BLCSVIO::readCSV(driftfile, driftsin);
	BLCSVIO::readCSV(meaurementsfile, positionsin);

	double xin, yin, xout, yout, xcentre, ycentre;
	vector<vector<double>> driftsout, positionsout;
	driftsout = driftsin;
	positionsout = positionsin;

	for (int chancount = 0; chancount < channelalignin.size(); chancount++) {

		for (int pos = 0; pos < driftsin.size(); pos++) {
			xin = driftsin[pos][0];
			yin = driftsin[pos][1];
			driftsout[pos][0] = xin * channelalignin[chancount][5] + yin * channelalignin[chancount][6];
			driftsout[pos][1] = xin * channelalignin[chancount][7] + yin * channelalignin[chancount][8];
		}
		BLCSVIO::writeCSV(outputfile + "_Drifts_Channel_" + to_string(chancount + 2) + ".csv", driftsout, "X Drift, Y Drift\n");
	}

	for (int chancount = 0; chancount < channelalignin.size(); chancount++) {
		xcentre = channelalignin[chancount][9];
		ycentre = channelalignin[chancount][10];
		for (int pos = 0; pos < positionsin.size(); pos++) {
			xin = positionsin[pos][0];
			yin = positionsin[pos][1];
			xin += -xcentre;
			yin += -ycentre;
			xout = xin * channelalignin[chancount][5] + yin * channelalignin[chancount][6];
			yout = xin * channelalignin[chancount][7] + yin * channelalignin[chancount][8];
			xout += xcentre;
			yout += ycentre;
			xout += -channelalignin[chancount][3];
			yout += -channelalignin[chancount][4];
			positionsout[pos][0] = xout;
			positionsout[pos][1] = yout;
		}
		BLCSVIO::writeCSV(outputfile + "_Measurements_Channel_" + to_string(chancount + 2) + ".csv", positionsout, "X Gaussian Pos,Y Gaussian Pos, PSF, Quality of Fit,x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos\n");

		if (bpositionslist) {
			for (int pos = 1; pos < positionslistin.size(); pos++) for (int i = 0; i<positionslistin[pos].size(); i++) {
				xin = (int)positionslistin[pos][i] % imageWidth;
				yin = (int)positionslistin[pos][i] / imageWidth;
				xin += -xcentre;
				yin += -ycentre;
				xout = xin * channelalignin[chancount][5] + yin * channelalignin[chancount][6];
				yout = xin * channelalignin[chancount][7] + yin * channelalignin[chancount][8];
				xout += xcentre;
				yout += ycentre;
				xout += -channelalignin[chancount][3];
				yout += -channelalignin[chancount][4];
				xout = round(xout);
				yout = round(yout);
				if (xout < 0)xout = 0;
				if (yout < 0)yout = 0;
				if (xout > imageWidth - 1) xout = imageWidth - 1;
				if (yout > imageHeight - 1)yout = imageHeight - 1;
				positionslistout[pos][i] = round(xout + yout*imageWidth);
			}
			BLCSVIO::writeCSV(outputfile + "_Positions_Channel_" + to_string(chancount + 2) + ".csv", positionslistout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
		}

		if (bbacklist) {
			for (int pos = 1; pos < backpositionslistin.size(); pos++) for (int i = 0; i<backpositionslistin[pos].size(); i++) {
				xin = (int)backpositionslistin[pos][i] % imageWidth;
				yin = (int)backpositionslistin[pos][i] / imageWidth;
				xin += -xcentre;
				yin += -ycentre;
				xout = xin * channelalignin[chancount][5] + yin * channelalignin[chancount][6];
				yout = xin * channelalignin[chancount][7] + yin * channelalignin[chancount][8];
				xout += xcentre;
				yout += ycentre;
				xout += -channelalignin[chancount][3];
				yout += -channelalignin[chancount][4];
				xout = round(xout);
				yout = round(yout);
				if (xout < 0)xout = 0;
				if (yout < 0)yout = 0;
				if (xout > imageWidth - 1) xout = imageWidth - 1;
				if (yout > imageHeight - 1)yout = imageHeight - 1;
				backpositionslistout[pos][i] = round(xout + yout*imageWidth);
			}
			BLCSVIO::writeCSV(outputfile + "_Background_Positions_Channel_" + to_string(chancount + 2) + ".csv", backpositionslistout, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
		}

	}

	return 0;
}