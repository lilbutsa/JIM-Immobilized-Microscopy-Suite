#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"


#define SQUARE(x) ((x)*(x))

using namespace std;


int main(int argc, char *argv[])
{

	double boundaryDist = 4.1, backgroundDist = 20, backinnerradius = 0;

	int kymographextension = 10;

	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string foregroundmeasurementfile = argv[1];
	std::string backgroundposfile = argv[2];
	std::string output = argv[3];

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-boundaryDist") {
			if (i + 1 < argc) {
				boundaryDist = stod(argv[i + 1]);
				cout << "Distance From Edge of Area to Measured Boundary set to " << boundaryDist << endl;
			}
			else { std::cout << "error inputting Distance From Edge of Area to Measured Boundary" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-backInnerRadius") {
			if (i + 1 < argc) {
				backinnerradius = stod(argv[i + 1]);
				cout << "Backgraound Inner radius set to " << backinnerradius << endl;
			}
			else { std::cout << "error inputting Distance From Edge of Area to Measured Boundary" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-backgroundDist") {
			if (i + 1 < argc) {
				backgroundDist = stod(argv[i + 1]);
				cout << "Distance From Edge of Measured Boundary to Background Boundary set to " << backgroundDist << endl;
			}
			else { std::cout << "error inputting Distance From Edge of Measured Boundary to Background Boundary" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-ExtendKymographs") {
			if (i + 1 < argc) {
				kymographextension = stoi(argv[i + 1]);
				cout << "Kymographs extended at each end by " << kymographextension << endl;
			}
			else { std::cout << "error inputting Distance From Edge of Measured Boundary to Background Boundary" << std::endl; return 1; }
		}
	}

	//Expand the background image

	std::vector<std::vector<int>> backgroundinit(3000, vector<int>(1000, 0));
	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(backgroundposfile, backgroundinit, headerLine);

	int imageWidth = backgroundinit[0][0];
	int imageHeight = backgroundinit[0][1];
	int imagePoints = backgroundinit[0][2];
	backgroundinit.erase(backgroundinit.begin());

	int masklength = (int)2 * backinnerradius + 1;
	vector<uint8_t> initialBoundary(imagePoints, 0), expandedBoundary(imagePoints, 0), mask(masklength*masklength, 0);

	IppiMorphState* pSpec = NULL;
	Ipp8u* pBuffer = NULL;
	IppiSize roiSize = { imageWidth, imageHeight };
	IppiSize maskSize = { masklength,masklength };
	int xpos, ypos, iboundaryDist = boundaryDist, ihalfmasklength = backinnerradius;

	for (int i = 0; i < masklength*masklength; i++) {
		xpos = i%masklength;
		ypos = i / masklength;
		if (SQUARE(xpos - ihalfmasklength) + SQUARE(ypos - ihalfmasklength) <= SQUARE(iboundaryDist)) mask[i] = 1;
	}

	int specSize = 0, bufferSize = 0;
	IppiBorderType borderType = ippBorderRepl;
	Ipp16u borderValue = 0;

	ippiMorphologyBorderGetSize_8u_C1R(roiSize, maskSize, &specSize, &bufferSize);
	pSpec = (IppiMorphState*)ippsMalloc_8u(specSize);
	pBuffer = (Ipp8u*)ippsMalloc_8u(bufferSize);


	vector<uint8_t> alledgeboundaries(imagePoints, 0);
	vector<uint8_t> expandedbackground(imagePoints, 0);
	for (int i = 0; i < backgroundinit.size(); i++)for (int j = 0; j < backgroundinit[i].size(); j++) alledgeboundaries[backgroundinit[i][j]] = 255;

	for (int i = 0; i < masklength*masklength; i++) {
		xpos = i%masklength;
		ypos = i / masklength;
		if (SQUARE(xpos - ihalfmasklength) + SQUARE(ypos - ihalfmasklength) <= SQUARE(ihalfmasklength)) mask[i] = 1;
	}

	ippiMorphologyBorderInit_8u_C1R(roiSize, mask.data(), maskSize, pSpec, pBuffer);

	ippiDilateBorder_8u_C1R(alledgeboundaries.data(), imageWidth * sizeof(Ipp8u), expandedbackground.data(), imageWidth * sizeof(Ipp8u), roiSize, borderType, borderValue, pSpec, pBuffer);

	ippsFree(pBuffer);
	ippsFree(pSpec);

	//find foreground kymograph positions

	vector<vector<float>> measurementresults;
	BLCSVIO::readVariableWidthCSV(foregroundmeasurementfile, measurementresults,headerLine);

	vector<int> filamentlinecount(measurementresults.size()+3, 0);
	filamentlinecount[0] = imageWidth;
	filamentlinecount[1] = imageHeight;
	filamentlinecount[2] = imagePoints;
	vector<vector<int>> foregroundkympos;
	vector<vector<int>> backgroundkympos;
	vector<int> linein;

	float deltax, deltay, deltat, xin, yin, pdeltax, pdeltay, pdeltat;
	int xfinal, yfinal;

	for (int i = 0; i < measurementresults.size(); i++) {
		deltax = measurementresults[i][4];
		deltay = measurementresults[i][5];
		deltat = sqrt(SQUARE(deltax) + SQUARE(deltay));
		if (deltax != 0 && deltay != 0) {
			pdeltax = 1 / deltax;
			pdeltay = -1 / deltay;
			pdeltat = sqrt(SQUARE(pdeltax) + SQUARE(pdeltay));
			pdeltax = pdeltax / pdeltat;
			pdeltay = pdeltay / pdeltat;
		}
		else { pdeltax = deltay; pdeltay = deltax; }
		int fillen = round(measurementresults[i][3]+ kymographextension);

		for (int j = -round(kymographextension); j < fillen + 1; j++) {
			xin = measurementresults[i][10] + j*deltax;
			yin = measurementresults[i][11] + j*deltay;
			linein.clear();
			for (double k = -boundaryDist; k < boundaryDist + 0.05; k += 1) {
				xfinal = min(imageWidth - 1, max(0, (int)round(xin + pdeltax*k)));
				yfinal = min(imageHeight - 1, max(0, (int)round(yin + pdeltay*k)));

				linein.push_back(xfinal + yfinal*imageWidth);
			}
			filamentlinecount[i+3]++;
			foregroundkympos.push_back(linein);
		}
	}
	//find everything to be cut around
	for (int i = 0; i < foregroundkympos.size(); i++)for (int j = 0; j < foregroundkympos[i].size(); j++) expandedbackground[foregroundkympos[i][j]] = 255;
	//calculate background pixels
	for (int i = 0; i < measurementresults.size(); i++) {
		deltax = measurementresults[i][4];
		deltay = measurementresults[i][5];
		deltat = sqrt(SQUARE(deltax) + SQUARE(deltay));
		if (deltax != 0 && deltay != 0) {
			pdeltax = 1 / deltax;
			pdeltay = -1 / deltay;
			pdeltat = sqrt(SQUARE(pdeltax) + SQUARE(pdeltay));
			pdeltax = pdeltax / pdeltat;
			pdeltay = pdeltay / pdeltat;
		}
		else { pdeltax = deltay; pdeltay = deltax; }
		int fillen = round(measurementresults[i][3] + kymographextension);

		for (int j = -round(kymographextension); j < fillen + 1; j++) {
			xin = measurementresults[i][10] + j*deltax;
			yin = measurementresults[i][11] + j*deltay;
			linein.clear();
			for (double k = -backgroundDist; k < backgroundDist + 0.05; k += 1) {
				xfinal = min(imageWidth - 1, max(0, (int)round(xin + pdeltax*k)));
				yfinal = min(imageHeight - 1, max(0, (int)round(yin + pdeltay*k)));

				if(expandedbackground[xfinal + yfinal*imageWidth]<1)linein.push_back(xfinal + yfinal*imageWidth);
			}
			backgroundkympos.push_back(linein);
		}
	}

	//write positions to file

	vector<uint8_t> outputimage(imagePoints, 0);
	for (int i = 0; i < foregroundkympos.size(); i++)for (int j = 0; j < foregroundkympos[i].size(); j++) outputimage[foregroundkympos[i][j]] = 255;
	BLTiffIO::TiffOutput(output + "_ROIs.tif", imageWidth, imageHeight, 8).write1dImage(outputimage);

	outputimage = vector<uint8_t>(imagePoints, 0);
	for (int i = 0; i < backgroundkympos.size(); i++)for (int j = 0; j < backgroundkympos[i].size(); j++) outputimage[backgroundkympos[i][j]] = 255;
	BLTiffIO::TiffOutput(output + "_Background_Regions.tif", imageWidth, imageHeight, 8).write1dImage(outputimage);

	foregroundkympos.insert(foregroundkympos.begin(), filamentlinecount);
	BLCSVIO::writeCSV(output + "_ROI_Positions.csv", foregroundkympos, "First Line is {imagewidth,height,count,then number of lines in each kymograph...}. Each Line is perpendicular line in a kymograph . Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	backgroundkympos.insert(backgroundkympos.begin(), filamentlinecount);
	BLCSVIO::writeCSV(output + "_Background_Positions.csv", backgroundkympos, "First Line is {imagewidth,height,count,then number of lines in each kymograph...}. Each Line is perpendicular line in a kymograph . Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

	return 0;
}