/*
 * Main.cpp - Expand_Shapes
 *
 * Description:
 *   This program generates expanded foreground and background pixel regions for each detected
 *   particle based on an input CSV of labeled pixel positions. These expanded regions can then
 *   be used to compute fluorescence traces for individual particles over time.
 *
 *
 * Input Arguments:
 *   argv[1]  - Path to CSV file with foreground pixel positions.
 *   argv[2]  - Path to CSV file with background pixel positions.
 *   argv[3]  - Output base name for image and CSV files.
 *
 * Optional Flags:
 *   --boundaryDist <float>        : Radius (in pixels) for foreground inclusion zone (default: 4.1)
 *   --backInnerRadius <float>    : Inner radius for background exclusion zone (default: = boundaryDist)
 *   --backgroundDist <float>     : Radius (in pixels) for background region (default: 20)
 *   --extraBackgroundFile <file> : Optional CSV file specifying additional background pixels
 *   --channelAlignment <file>    : CSV file containing alignment parameters for multi-channel output
 *
 * Output Files:
 *   - <output>_ROIs.tif                       : Binary image showing expanded foreground ROIs.
 *   - <output>_Background_Regions.tif         : Binary image of expanded background regions.
 *   - <output>_ROI_Positions_Channel_*.csv    : Foreground pixel positions per channel.
 *   - <output>_Background_Positions_Channel_*.csv : Background pixel positions per channel.
 *
 * Dependencies:
 *   - BLCSVIO: Custom CSV parser for variable-width image region data.
 *   - BLTiffIO: Custom TIFF image I/O for saving masks.
 *   - BLFlagParser: Lightweight CLI flag parsing utility.
 *
 * Notes:
 *   - Pixel coordinates are stored in raster-order linear index format: `x + y * width`.
 *   - The first line in each output CSV contains image dimensions and pixel count.
 *   - Pixels are only assigned to foreground/background if they pass all distance and exclusion checks.
 *   - The geometric transformation supports rigid and affine alignment using 2D matrices and translations.
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2025-07-14
 */


#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "BLFlagParser.h"
#include <math.h>

using namespace std;

vector<vector<int>> transformPosition(vector<double> alignIn, vector<vector<int>> positions, int imageWidth, int imageHeight);

int main(int argc, char *argv[])
{

	float boundaryDist = 4.1, backgroundDist = 20, backinnerradius = 0;

	bool bExtraBackground = false, bChannelAlignment = false;
	std::string extraBackgroundFileName,channelAlignmentFileName;


	if (argc < 4) { std::cout << "could not read file name" << endl; return 1; }
	std::string foregroundposfile = argv[1];
	std::string backgroundposfile = argv[2];
	std::string output = argv[3];

	std::vector<std::pair<std::string, float*>> floatFlags = { {"boundaryDist", &boundaryDist},{"backInnerRadius", &backinnerradius},{"backgroundDist", &backgroundDist} };
	std::vector<std::pair<std::string, std::string*>> stringFlags = { {"extraBackgroundFile", &extraBackgroundFileName},{"channelAlignment", &channelAlignmentFileName}};

	if (BLFlagParser::parseValues(floatFlags, argc, argv)) return 1;
	if (BLFlagParser::parseValues(stringFlags, argc, argv)) return 1;

	if (extraBackgroundFileName.length() > 1)bExtraBackground = true;
	if (channelAlignmentFileName.length() > 1)bChannelAlignment = true;

	if (backinnerradius < boundaryDist)backinnerradius = boundaryDist;

	//read in foreground positions and get image size data out
	std::vector<std::vector<int>> labelledpos(3000, vector<int>(1000, 0));
	std::vector<std::string> headerLine;
	BLCSVIO::readVariableWidthCSV(foregroundposfile, labelledpos, headerLine);

	int imageWidth = labelledpos[0][0];
	int imageHeight = labelledpos[0][1];
	int imagePoints = labelledpos[0][2];
	labelledpos.erase(labelledpos.begin());

	//make foreground image
	std::vector<uint16_t> posImage(imagePoints, 0);
	for (int i = 0; i < labelledpos.size(); i++)for (int j = 0; j < labelledpos[i].size(); j++)posImage[labelledpos[i][j]] = i+1;

	//read in background
	std::vector<std::vector<int>> backgroundpos(3000, vector<int>(1000, 0));
	BLCSVIO::readVariableWidthCSV(backgroundposfile, backgroundpos, headerLine);
	backgroundpos.erase(backgroundpos.begin());

	//make background image
	std::vector<uint8_t>  backgroundImage(imagePoints, 0);
	for (int i = 0; i < backgroundpos.size(); i++)for (int j = 0; j < backgroundpos[i].size(); j++)backgroundImage[backgroundpos[i][j]] = 255;

	//read in extra background and add to background
	std::vector<std::vector<int>> extrabackgroundpos;
	if (bExtraBackground) {
		extrabackgroundpos = std::vector<std::vector<int>> (3000, vector<int>(1000, 0));
		BLCSVIO::readVariableWidthCSV(extraBackgroundFileName, extrabackgroundpos, headerLine);
		extrabackgroundpos.erase(extrabackgroundpos.begin());
		for (int i = 0; i < extrabackgroundpos.size(); i++)for (int j = 0; j < extrabackgroundpos[i].size(); j++)backgroundImage[extrabackgroundpos[i][j]] = 255;
	}

	
	//find search positions for each ring
	std::vector<std::vector<int>> foregroundSearchPos, midgroundSearchPos, backgroundSearchPos;
	for (int i = -ceil(backgroundDist); i <= ceil(backgroundDist);i++)
		for (int j = -ceil(backgroundDist); j <= ceil(backgroundDist);j++)
			if (i * i + j * j <= boundaryDist * boundaryDist + 0.000001)foregroundSearchPos.push_back({ i * i + j * j,i,j });
			else if (i * i + j * j <= backinnerradius * backinnerradius + 0.000001)midgroundSearchPos.push_back({ i * i + j * j,i,j });
			else if (i * i + j * j <= backgroundDist * backgroundDist + 0.000001)backgroundSearchPos.push_back({ i * i + j * j,i,j });

	std::sort(foregroundSearchPos.begin(), foregroundSearchPos.end(),[](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});
	std::sort(midgroundSearchPos.begin(), midgroundSearchPos.end(), [](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});
	std::sort(backgroundSearchPos.begin(), backgroundSearchPos.end(), [](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});

	

	//search around each pixel for foreground and background
	std::vector<std::vector<int>> expandedForeground(labelledpos.size(), std::vector<int>()), expandedBackground(labelledpos.size(), std::vector<int>());

	for (int x = 0;x < imageWidth;x++)for (int y = 0;y < imageHeight;y++) {
		bool notfound = true;
		std::vector<bool> bBackgroundFound(labelledpos.size(), true);

		for (int i = 0;i < foregroundSearchPos.size();i++) {//search for foreground
			int xIn = x + foregroundSearchPos[i][1];
			int yIn = y + foregroundSearchPos[i][2];
			if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight) {
				if (posImage[xIn + yIn * imageWidth] > 0) {//if found in the foreground points then add it to the list
					expandedForeground[posImage[xIn + yIn * imageWidth]-1].push_back(x + y * imageWidth);
					notfound = false;
					break;
				}
				else if (backgroundImage[xIn + yIn * imageWidth] > 0) {//if only found in the background points then discard
					notfound = false;
					break;
				}
			}
		}
		if (notfound) {
			for (int i = 0;i < midgroundSearchPos.size();i++) {//search for midground
				int xIn = x + midgroundSearchPos[i][1];
				int yIn = y + midgroundSearchPos[i][2];
				if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight && (posImage[xIn + yIn * imageWidth] > 0 || backgroundImage[xIn + yIn * imageWidth] > 0)) {//discard everything found
					notfound = false;
					break;
				}
			}
		}
		if (notfound) {
			for (int i = 0;i < backgroundSearchPos.size();i++) {//search for background
				int xIn = x + backgroundSearchPos[i][1];
				int yIn = y + backgroundSearchPos[i][2];
				if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight && posImage[xIn + yIn * imageWidth] > 0  && bBackgroundFound[posImage[xIn + yIn * imageWidth]-1]) {//add everything found
					//std::cout << xIn + yIn * imageWidth <<" "<< posImage[xIn + yIn * imageWidth] - 1 << " " << expandedBackground.size() << " " << expandedBackground[posImage[xIn + yIn * imageWidth] - 1].size() << "\n";
					expandedBackground[posImage[xIn + yIn * imageWidth]-1].push_back(x + y * imageWidth);
					bBackgroundFound[posImage[xIn + yIn * imageWidth] - 1] = false;
				}
			}
		}
	}
	//filter background positions for unique values
	for (int i = 0; i < expandedBackground.size(); i++) {
		sort(expandedBackground[i].begin(), expandedBackground[i].end());
		//expandedBackground[i].erase(unique(expandedBackground[i].begin(), expandedBackground[i].end()), expandedBackground[i].end());
	}

	//write out foreground regions image
	vector<uint8_t> expandedForegroundBinaryImage(imagePoints, 0);
	for (int i = 0; i < expandedForeground.size(); i++)for (int j = 0; j < expandedForeground[i].size(); j++) expandedForegroundBinaryImage[expandedForeground[i][j]] = 255;
	BLTiffIO::TiffOutput(output + "_ROIs.tif", imageWidth, imageHeight,8).write1dImage(expandedForegroundBinaryImage);

	//write out background regions image
	vector<uint8_t> expandedBackgroundBinaryImage(imagePoints, 0);
	for (int i = 0; i < expandedBackground.size(); i++)for (int j = 0; j < expandedBackground[i].size(); j++) expandedBackgroundBinaryImage[expandedBackground[i][j]] = 255;
	BLTiffIO::TiffOutput(output + "_Background_Regions.tif", imageWidth, imageHeight, 8).write1dImage(expandedBackgroundBinaryImage);

	//write out foreground positions file
	std::vector<std::vector<int>> transformPos = expandedForeground;
	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_ROI_Positions_Channel_1.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	
	//write out background positions file
	transformPos = expandedBackground;
	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(output + "_Background_Positions_Channel_1.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");
	
	//write out for other channels
	if (bChannelAlignment) {
		vector<vector<double>> channelAlign(50, vector<double>(11, 0.0));
		BLCSVIO::readCSV(channelAlignmentFileName, channelAlign, headerLine);
		for (int chancount = 0; chancount < channelAlign.size(); chancount++) {

			transformPos = transformPosition(channelAlign[chancount], expandedForeground, imageWidth, imageHeight);
			transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
			BLCSVIO::writeCSV(output + "_ROI_Positions_Channel_" + to_string(chancount + 2) + ".csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

			transformPos = transformPosition(channelAlign[chancount], expandedBackground, imageWidth, imageHeight);
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