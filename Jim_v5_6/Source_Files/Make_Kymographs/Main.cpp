#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"


#define SQUARE(x) ((x)*(x))

using namespace std;


int main(int argc, char *argv[])
{

	double boundaryDist = 4.1, backgroundDist = 20, backinnerradius = 0;


	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string tracesfile = argv[1];
	std::string backgroundtracesfile = argv[2];
	std::string positionsfile = argv[3];
	std::string output = argv[4];

	cout << "Making traces from " << tracesfile << "\n";
	cout << "Taking background intensities from " << backgroundtracesfile << "\n";

	//Expand the background image

	std::vector<std::vector<int>> backgroundinit(3000, vector<int>(1000, 0));
	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(positionsfile, backgroundinit,headerLine);

	vector<int> filamentlinecount = backgroundinit[0];

	std::vector<std::vector<double>> traces;
	BLCSVIO::readVariableWidthCSV(tracesfile, traces,headerLine);

	std::vector<std::vector<double>> backgroundtraces;
	BLCSVIO::readVariableWidthCSV(backgroundtracesfile, backgroundtraces,headerLine);

	for (int i = 0; i < traces.size(); i++)for (int j = 0; j < traces[i].size(); j++) {
		traces[i][j] = traces[i][j] + 1000;
		if (traces[i][j] < 0)traces[i][j] = 0;
		if (traces[i][j] > 65535)traces[i][j] = 65535;
	}

	std::vector<std::vector<double>> tracesout,backout;

	int count = 0;

	for (int i = 3; i < filamentlinecount.size(); i++) {
		tracesout.clear();
		backout.clear();
		for (int j = 0; j < filamentlinecount[i]; j++) {
			tracesout.push_back(traces[count]);
			backout.push_back(backgroundtraces[count]);
			count++;
		}
		BLTiffIO::TiffOutput(output +"_"+to_string(i-2)+".tif", tracesout.size(), tracesout[0].size(), 16).write2dImage(tracesout);
		BLTiffIO::TiffOutput(output + "_Background_" + to_string(i - 2) + ".tif", backout.size(), backout[0].size(),16).write2dImage(backout);
	}


	return 0;
}