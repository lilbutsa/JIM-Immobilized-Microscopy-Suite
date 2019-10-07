#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"

#define SQUARE(x) ((x)*(x))



using namespace std;

void joinfragments(std::vector<std::vector<int>>& initialcullpos, std::vector<std::vector<float>>& icmeasurementresults, float maxangle, float maxjoindist, float maxendline, int imagewidth, std::vector<float> & imagef);


int main(int argc, char *argv[])
{
	if (argc < 4) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string inputmeasurefile = argv[2];
	std::string inputpos = argv[3];
	std::string output = argv[4];

	double minDistFromEdge = -0.1, minEccentricity = -0.1, maxEccentricity = 1.1, minLength = 0, maxLength = 10000000000, minCount = 0, maxCount = 1000000000, maxDistFromLinear = 10000000;
	double leftminDistFromEdge = -0.1, rightminDistFromEdge = -0.1, topminDistFromEdge = -0.1, bottomminDistFromEdge = -0.1;

	float maxangle = 0.785398;
	float maxjoindist = 40;
	float maxline = 1.5;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-minDistFromEdge") {
			if (i + 1 < argc) {
				minDistFromEdge = stod(argv[i + 1]);
				leftminDistFromEdge = minDistFromEdge, rightminDistFromEdge = minDistFromEdge, topminDistFromEdge = minDistFromEdge, bottomminDistFromEdge = minDistFromEdge;
				cout << "Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-left") {
			if (i + 1 < argc) {
				leftminDistFromEdge = stod(argv[i + 1]);
				cout << "Left Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-right") {
			if (i + 1 < argc) {
				rightminDistFromEdge = stod(argv[i + 1]);
				cout << "Right Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-top") {
			if (i + 1 < argc) {
				topminDistFromEdge = stod(argv[i + 1]);
				cout << "Top Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-bottom") {
			if (i + 1 < argc) {
				bottomminDistFromEdge = stod(argv[i + 1]);
				cout << "Bottom Minimum Distance From Edge of Image set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Minimum Distance From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minEccentricity") {
			if (i + 1 < argc) {
				minEccentricity = stod(argv[i + 1]);
				cout << "Minimum Eccentricity set to " << minEccentricity << endl;
			}
			else { std::cout << "error inputting Minimum Eccentricity From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxEccentricity") {
			if (i + 1 < argc) {
				maxEccentricity = stod(argv[i + 1]);
				cout << "Maximum Eccentricity set to " << maxEccentricity << endl;
			}
			else { std::cout << "error inputting maximum Eccentricity From Edge" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minLength") {
			if (i + 1 < argc) {
				minLength = stod(argv[i + 1]);
				cout << "Minimum Length set to " << minLength << endl;
			}
			else { std::cout << "error inputting minimum length" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxLength") {
			if (i + 1 < argc) {
				maxLength = stod(argv[i + 1]);
				cout << "Maximum Length set to " << maxLength << endl;
			}
			else { std::cout << "error inputting maximum length" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-minCount") {
			if (i + 1 < argc) {
				minCount = stod(argv[i + 1]);
				cout << "Minimum Count set to " << minCount << endl;
			}
			else { std::cout << "error inputting minimum Count" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxCount") {
			if (i + 1 < argc) {
				maxCount = stod(argv[i + 1]);
				cout << "Maximum Count set to " << maxCount << endl;
			}
			else { std::cout << "error inputting maximum Count" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxDistFromLinear") {
			if (i + 1 < argc) {
				maxDistFromLinear = stod(argv[i + 1]);
				cout << "Maximum Distance From Linear set to " << minDistFromEdge << endl;
			}
			else { std::cout << "error inputting Maximum Distance From Linear" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxAngle") {
			if (i + 1 < argc) {
				maxangle = stod(argv[i + 1]);
				cout << "maximum angle distance set to " << maxangle << endl;
			}
			else { std::cout << "error inputting maximum angle distance" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxJoinDist") {
			if (i + 1 < argc) {
				maxjoindist = stod(argv[i + 1]);
				cout << "maximum joining distance set to " << maxjoindist << endl;
			}
			else { std::cout << "error inputting maximum joining distance" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-maxLine") {
			if (i + 1 < argc) {
				maxline = stod(argv[i + 1]);
				cout << "maximum joining distance to line of best fit set to " << maxline << endl;
			}
			else { std::cout << "error inputting maximum joining distance to line of best fit" << std::endl; return 1; }
		}

	}

	BLTiffIO::TiffInput inputstack(inputfile);
	vector<float> imagef(inputstack.imagePoints, 0);
	inputstack.read1dImage(0, imagef);

	std::vector<std::vector<int>> labelledpos(3000, vector<int>(1000, 0));
	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(inputpos, labelledpos,headerLine);
	labelledpos.erase(labelledpos.begin());


	vector<vector<float>> centroidresults;
	BLCSVIO::readVariableWidthCSV(inputmeasurefile, centroidresults,headerLine);


	int imageWidth = inputstack.imageWidth;
	int imageHeight = inputstack.imageHeight;
	std::vector<std::vector<int>> filteredpos;
	std::vector<std::vector<float>> filteredcents;


	vector<uint8_t> initiallines(inputstack.imagePoints, 0);
	int posin,xin,yin;
	for (int i = 0; i < centroidresults.size(); i++)for (int j = -1000; j < 1000; j++) {
		xin = (centroidresults[i][0] - ((float)j) *0.001*centroidresults[i][3] * centroidresults[i][4]);
		yin = (centroidresults[i][1] - ((float)j) *0.001*centroidresults[i][3] * centroidresults[i][5]);
		for (int n = -1; n < 2; n++)for (int m = -1; m < 2; m++) {
			posin =n+ xin + imageWidth*(m+yin);
			initiallines[posin] = 255;
		}
		//cout << xin << " " << yin << " " << posin << "\n";
	}
	BLTiffIO::TiffOutput(output + "_Initial_Lines.tif", imageWidth, imageHeight, 8).write1dImage(initiallines);




	joinfragments(labelledpos, centroidresults, maxangle, maxjoindist,  maxline, inputstack.imageWidth,imagef);


	for (int i = 0; i < centroidresults.size(); i++) {
		if (centroidresults[i][10] >= leftminDistFromEdge && centroidresults[i][11] <= imageWidth - 1 - rightminDistFromEdge && centroidresults[i][12] >= topminDistFromEdge && centroidresults[i][13] <= imageHeight - 1 - bottomminDistFromEdge
			&& centroidresults[i][2] >= minEccentricity && centroidresults[i][2] <= maxEccentricity && centroidresults[i][3] >= minLength && centroidresults[i][3] <= maxLength
			&& centroidresults[i][6] >= minCount && centroidresults[i][6] <= maxCount && centroidresults[i][9] <= maxDistFromLinear) {
			filteredpos.push_back(labelledpos[i]);
			filteredcents.push_back(centroidresults[i]);
		}
	}

	vector<uint8_t> filtereddetected(inputstack.imagePoints, 0);
	for (int i = 0; i < filteredcents.size(); i++)for (int j = -1000; j < 1000; j++) {
		xin = (filteredcents[i][0] - ((float)j) *0.001*filteredcents[i][3] * filteredcents[i][4]);
		yin = (filteredcents[i][1] - ((float)j) *0.001*filteredcents[i][3] * filteredcents[i][5]);
		for (int n = -1; n < 2; n++)for (int m = -1; m < 2; m++) {
			posin = n + xin + imageWidth*(m + yin);
			filtereddetected[posin] = 255;
		}
		//cout << xin << " " << yin << " " << posin << "\n";
	}
	BLTiffIO::TiffOutput(output + "_Joined_Lines.tif", imageWidth, imageHeight, 8).write1dImage(filtereddetected);


	labelledpos.insert(labelledpos.begin(), {imageWidth, imageHeight, (int) inputstack.imagePoints });
	BLCSVIO::writeCSV(output + "_ROI_Positions.csv", labelledpos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	BLCSVIO::writeCSV(output + "_Measurements.csv", filteredcents, "x Centroid, y Centroid,Eccentricity, Length ,x Vector of major axis,Y Vector of major axis, Count,X Max Pos, Y Max Pos, Max Dist From Linear Fit, x Min Bounding Box,x Max Bounding Box, y Min Bounding Box,y Max Bounding Box\n");

	//system("PAUSE");
	return 0;
}