#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"
#include <math.h>

using namespace std;

vector<vector<int>> transformPosition(vector<double> alignIn, vector<vector<int>> positions, int imageWidth, int imageHeight);


#define SQUARE(x) ((x)*(x))




int main(int argc, char *argv[])
{

	double boundaryDist = 4.1, backgroundDist = 20, backinnerradius = 0;

	bool bExtraBackground = false, bChannelAlignment = false;
	std::string extraBackgroundFileName,channelAlignmentFileName;


	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string foregroundposfile = argv[1];
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
				cout << "Background Inner radius set to " << backinnerradius << endl;
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
		if (std::string(argv[i]) == "-extraBackgroundFile") {
			if (i + 1 < argc) {
				bExtraBackground = true;
				extraBackgroundFileName = argv[i + 1];
				cout << "Extra background file set to: " << extraBackgroundFileName << endl;
			}
			else { std::cout << "error inputting extra background file" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-channelAlignment") {
			if (i + 1 < argc) {
				bChannelAlignment = true;
				channelAlignmentFileName = argv[i + 1];
				cout << "Extra background file set to: " << extraBackgroundFileName << endl;
			}
			else { std::cout << "error inputting extra background file" << std::endl; return 1; }
		}
	}
	if (backinnerradius < boundaryDist)backinnerradius = boundaryDist;


	std::vector<std::vector<int>> labelledpos(3000, vector<int>(1000, 0));

	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(foregroundposfile, labelledpos, headerLine);

	int imageWidth = labelledpos[0][0];
	int imageHeight = labelledpos[0][1];
	int imagePoints = labelledpos[0][2];
	labelledpos.erase(labelledpos.begin());

	int masklength = 2 * backinnerradius + 1;
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
	ippiMorphologyBorderInit_8u_C1R(roiSize, mask.data(), maskSize, pSpec, pBuffer);

	std::vector<std::vector<int>> expandedpos(labelledpos.size(), vector<int>(1000, 0));


	for (int i = 0; i < labelledpos.size(); i++) {
		for (int j = 0; j < labelledpos[i].size(); j++) {
			initialBoundary[labelledpos[i][j]] = 255;
			if(labelledpos[i][j]==0)std::cout << "WARNING: Position " << j <<" of sample "<< i << " claims to be at 0. Total length = " << labelledpos[i].size() << "\n";
		}
		ippiDilateBorder_8u_C1R(initialBoundary.data(), imageWidth * sizeof(Ipp8u), expandedBoundary.data(), imageWidth * sizeof(Ipp8u), roiSize, borderType, borderValue, pSpec, pBuffer);
		expandedpos[i].clear();
		for (int j = 0; j < expandedBoundary.size(); j++)if (expandedBoundary[j] > 1)expandedpos[i].push_back(j);
		for (int j = 0; j < labelledpos[i].size(); j++) initialBoundary[labelledpos[i][j]] = 0;
	}




	vector<uint8_t> alledgeboundaries(imagePoints, 0);
	for (int i = 0; i < expandedpos.size(); i++)for (int j = 0; j < expandedpos[i].size(); j++) alledgeboundaries[expandedpos[i][j]] = 255;

	BLTiffIO::TiffOutput(output + "_ROIs.tif", imageWidth, imageHeight,8).write1dImage(alledgeboundaries);

	//read in alternative background

	std::vector<std::vector<int>> backgroundinit(3000, vector<int>(1000, 0));
	alledgeboundaries = vector<uint8_t>(imagePoints, 0);
	vector<uint8_t> expandedbackground(imagePoints, 0);

	BLCSVIO::readVariableWidthCSV(foregroundposfile, backgroundinit, headerLine);
	backgroundinit.erase(backgroundinit.begin());
	for (int i = 0; i < backgroundinit.size(); i++)for (int j = 0; j < backgroundinit[i].size(); j++) alledgeboundaries[backgroundinit[i][j]] = 255;

	if (bExtraBackground) {
		BLCSVIO::readVariableWidthCSV(extraBackgroundFileName, backgroundinit, headerLine);
		backgroundinit.erase(backgroundinit.begin());
		for (int i = 0; i < backgroundinit.size(); i++)for (int j = 0; j < backgroundinit[i].size(); j++) alledgeboundaries[backgroundinit[i][j]] = 255;
	}

	BLCSVIO::readVariableWidthCSV(backgroundposfile, backgroundinit, headerLine);
	backgroundinit.erase(backgroundinit.begin());

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


	masklength = 2 * backgroundDist + 1;

	vector<uint8_t>  backgoundBoundary(imagePoints, 0);
	mask.clear();
	mask.resize(masklength*masklength, 0);

	maskSize = { masklength,masklength };
	iboundaryDist = backgroundDist;

	for (int i = 0; i < masklength*masklength; i++) {
		xpos = i%masklength;
		ypos = i / masklength;
		if (SQUARE(xpos - iboundaryDist) + SQUARE(ypos - iboundaryDist) <= SQUARE(iboundaryDist)) mask[i] = 1;
	}


	ippiMorphologyBorderGetSize_8u_C1R(roiSize, maskSize, &specSize, &bufferSize);
	pSpec = (IppiMorphState*)ippsMalloc_8u(specSize);
	pBuffer = (Ipp8u*)ippsMalloc_8u(bufferSize);
	ippiMorphologyBorderInit_8u_C1R(roiSize, mask.data(), maskSize, pSpec, pBuffer);

	std::vector<std::vector<int>> backgroundpos(expandedpos.size(), vector<int>(1000, 0));


	for (int i = 0; i < expandedpos.size(); i++) {
		for (int j = 0; j < expandedpos[i].size(); j++) initialBoundary[expandedpos[i][j]] = 255;
		//cout << i<< " "<< expandedpos.size()<<" here\n";
		ippiDilateBorder_8u_C1R(initialBoundary.data(), imageWidth * sizeof(Ipp8u), expandedBoundary.data(), imageWidth * sizeof(Ipp8u), roiSize, borderType, borderValue, pSpec, pBuffer);
		//cout << "there\n";
		backgroundpos[i].clear();
		for (int j = 0; j < expandedBoundary.size(); j++)if (expandedBoundary[j] >= 1 && expandedbackground[j]<1)backgroundpos[i].push_back(j);
		for (int j = 0; j < expandedpos[i].size(); j++) initialBoundary[expandedpos[i][j]] = 0;
	}
	ippsFree(pBuffer);
	ippsFree(pSpec);


	vector<uint8_t> backgroundregion(imagePoints, 0);
	for (int i = 0; i < backgroundpos.size(); i++)for (int j = 0; j < backgroundpos[i].size(); j++) backgroundregion[backgroundpos[i][j]] = 255;
	BLTiffIO::TiffOutput(output + "_Background_Regions.tif", imageWidth, imageHeight,8).write1dImage(backgroundregion);

	std::vector<std::vector<int>> transformPos = expandedpos;

	//std::cout << "Channel 1 " << transformPos[0].size() << "\n";
	//for (int i = 0; i < transformPos[0].size(); i++)std::cout << transformPos[0][i] << " ";
	//std::cout << "\n";

	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_ROI_Positions_Channel_1.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	transformPos = backgroundpos;
	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Background_Positions_Channel_1.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	if (bChannelAlignment) {
		//std::cout << "Outputting MultiChannel Positions\n";
		vector<vector<double>> channelAlign(50, vector<double>(11, 0.0));
		BLCSVIO::readCSV(channelAlignmentFileName, channelAlign, headerLine);
		for (int chancount = 0; chancount < channelAlign.size(); chancount++) {
			
			transformPos = transformPosition(channelAlign[chancount], expandedpos, imageWidth, imageHeight);
			//std::cout << "Channel " << chancount + 2 <<" "<< transformPos[0].size()<< "\n";
			transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
			BLCSVIO::writeCSV(output + "_ROI_Positions_Channel_"+ to_string(chancount + 2) +".csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

			transformPos = transformPosition(channelAlign[chancount], backgroundpos, imageWidth, imageHeight);
			transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
			BLCSVIO::writeCSV(output + "_Background_Positions_Channel_" + to_string(chancount + 2) + ".csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
		}
	}

	return 0;
};

vector<vector<int>> transformPosition(vector<double> alignIn , vector<vector<int>> positions, int imageWidth, int imageHeight) {

	vector<vector<int>> positionslistout;
	vector<int> singleLine;
	double xcentre = alignIn[9];
	double ycentre = alignIn[10];

	for (int pos = 0; pos < positions.size(); pos++) {
		//cout <<"transform "<< pos << " " << positions[pos][0] << " " << positions[pos].size() << "\n";
		singleLine.clear();
		for (int i = 0; i < positions[pos].size(); i++) {
			double xin = (int)positions[pos][i] % imageWidth;
			double yin = (int)positions[pos][i] / imageWidth;
			xin += -xcentre;
			yin += -ycentre;
			double xout = xin * alignIn[5] + yin * alignIn[6];
			double yout = xin * alignIn[7] + yin * alignIn[8];
			xout += xcentre;
			yout += ycentre;
			xout += -alignIn[3];
			yout += -alignIn[4];
			if (xout < 0)xout = 0;
			if (yout < 0)yout = 0;
			if (xout > imageWidth - 1) xout = imageWidth - 1;
			if (yout > imageHeight - 1)yout = imageHeight - 1;
			singleLine.push_back(floor(xout) + floor(yout) * imageWidth);
			singleLine.push_back(ceil(xout) + floor(yout) * imageWidth);
			singleLine.push_back(floor(xout) + ceil(yout) * imageWidth);
			singleLine.push_back(ceil(xout) + ceil(yout) * imageWidth);
		}
		sort(singleLine.begin(), singleLine.end());
		singleLine.erase(unique(singleLine.begin(), singleLine.end()), singleLine.end());
		positionslistout.push_back(singleLine);
	}
		
	return positionslistout;
}