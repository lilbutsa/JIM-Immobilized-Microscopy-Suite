#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include "BLCSVIO.h"


int Expand_Shapes(std::string foregroundposfile, std::string backgroundposfile,std::string extraBackgroundFileName,float boundaryDist,float backinnerradius, float backgroundDist, std::string output = "")
{
	bool bExtraBackground = false;
	if(extraBackgroundFileName!="")bExtraBackground = true;

	if (output == "")output = "Expanded";

	
	std::string filesepin(1, std::filesystem::path::preferred_separator);
	std::string filesep = filesepin;
	std::string fileBase = std::filesystem::path(foregroundposfile).parent_path().generic_string() + filesep + output;
	

	//read in foreground positions and get image size data out
	std::vector<std::vector<int>> labelledpos(3000, std::vector<int>(1000, 0));
	std::vector<std::string> headerLine;
	if(BLCSVIO::readVariableWidthCSV(foregroundposfile, labelledpos, headerLine)!=0)return 1;
	if (labelledpos.size() < 2) {
		std::cout << "Error : Empty ROI Positions File\n";
		return 1;
	}
	int imageWidth = labelledpos[0][0];
	int imageHeight = labelledpos[0][1];
	int imagePoints = labelledpos[0][2];
	labelledpos.erase(labelledpos.begin());

	//make foreground image
	std::vector<uint16_t> posImage(imagePoints, 0);
	for (int i = 0; i < labelledpos.size(); i++)for (int j = 0; j < labelledpos[i].size(); j++)posImage[labelledpos[i][j]] = i + 1;

	//BLTiffIO::TiffOutput(output + "_debug_posimage.tif", imageWidth, imageHeight, 16).write1dImage(posImage);



	//read in background
	std::vector<std::vector<int>> backgroundpos(3000, std::vector<int>(1000, 0));
	if(BLCSVIO::readVariableWidthCSV(backgroundposfile, backgroundpos, headerLine) != 0)return 1;
	backgroundpos.erase(backgroundpos.begin());

	//make background image
	std::vector<uint8_t>  backgroundImage(imagePoints, 0);
	for (int i = 0; i < backgroundpos.size(); i++)for (int j = 0; j < backgroundpos[i].size(); j++)backgroundImage[backgroundpos[i][j]] = 255;

	//read in extra background and add to background
	std::vector<std::vector<int>> extrabackgroundpos;
	if (bExtraBackground) {
		extrabackgroundpos = std::vector<std::vector<int>>(3000, std::vector<int>(1000, 0));
		if(BLCSVIO::readVariableWidthCSV(extraBackgroundFileName, extrabackgroundpos, headerLine) != 0)return 1;
		extrabackgroundpos.erase(extrabackgroundpos.begin());
		for (int i = 0; i < extrabackgroundpos.size(); i++)for (int j = 0; j < extrabackgroundpos[i].size(); j++)backgroundImage[extrabackgroundpos[i][j]] = 255;
	}
	//BLTiffIO::TiffOutput(fileBase + "_debug_backposimage.tif", imageWidth, imageHeight, 16).write1dImage(backgroundImage);

	//find search positions for each ring
	std::vector<std::vector<int>> foregroundSearchPos, midgroundSearchPos, backgroundSearchPos;
	for (int i = (int)(-ceil(backgroundDist)); i <= (int)ceil(backgroundDist);i++)
		for (int j = (int)(-ceil(backgroundDist)); j <= (int)ceil(backgroundDist);j++)
			if (i * i + j * j <= boundaryDist * boundaryDist + 0.000001)foregroundSearchPos.push_back({ i * i + j * j,i,j });
			else if (i * i + j * j <= backinnerradius * backinnerradius + 0.000001)midgroundSearchPos.push_back({ i * i + j * j,i,j });
			else if (i * i + j * j <= backgroundDist * backgroundDist + 0.000001)backgroundSearchPos.push_back({ i * i + j * j,i,j });

	std::sort(foregroundSearchPos.begin(), foregroundSearchPos.end(), [](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});
	std::sort(midgroundSearchPos.begin(), midgroundSearchPos.end(), [](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});
	std::sort(backgroundSearchPos.begin(), backgroundSearchPos.end(), [](const std::vector<int>& a, const std::vector<int>& b) {return a[0] < b[0];});


	//search around each pixel for foreground and background
	std::vector<std::vector<int>> expandedForeground(labelledpos.size(), std::vector<int>()), expandedBackground(labelledpos.size(), std::vector<int>());

	//std::vector<uint16_t> expandedForegrounddebugImage(imagePoints, 0);

	for (int x = 0;x < imageWidth;x++)for (int y = 0;y < imageHeight;y++) {
		bool notfound = true;
		std::vector<bool> bBackgroundFound(labelledpos.size(), true);

		for (int i = 0;i < foregroundSearchPos.size();i++) {//search for foreground
			int xIn = x + foregroundSearchPos[i][1];
			int yIn = y + foregroundSearchPos[i][2];
			if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight) {
				if (posImage[xIn + yIn * imageWidth] > 0) {//if found in the foreground points then add it to the list
					expandedForeground[posImage[xIn + yIn * imageWidth] - 1].push_back(x + y * imageWidth);
					//expandedForegrounddebugImage[x + y * imageWidth] = posImage[xIn + yIn * imageWidth];
					notfound = false;
					break;
				}
				else if (backgroundImage[xIn + yIn * imageWidth] > 0) {//if only found in the background points then discard
					notfound = false;
					//break;
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
				if (xIn >= 0 && xIn < imageWidth && yIn >= 0 && yIn < imageHeight && posImage[xIn + yIn * imageWidth] > 0 && bBackgroundFound[posImage[xIn + yIn * imageWidth] - 1]) {//add everything found
					//std::cout << xIn + yIn * imageWidth <<" "<< posImage[xIn + yIn * imageWidth] - 1 << " " << expandedBackground.size() << " " << expandedBackground[posImage[xIn + yIn * imageWidth] - 1].size() << "\n";
					expandedBackground[posImage[xIn + yIn * imageWidth] - 1].push_back(x + y * imageWidth);
					bBackgroundFound[posImage[xIn + yIn * imageWidth] - 1] = false;
				}
			}
		}
	}

	//BLTiffIO::TiffOutput(fileBase + "_debug_expandimage.tif", imageWidth, imageHeight, 16).write1dImage(expandedForegrounddebugImage);
	// 
	//filter background positions for unique values
	for (int i = 0; i < expandedBackground.size(); i++) {
		sort(expandedBackground[i].begin(), expandedBackground[i].end());
		//expandedBackground[i].erase(unique(expandedBackground[i].begin(), expandedBackground[i].end()), expandedBackground[i].end());
	}

	//write out foreground regions image
	std::vector<uint8_t> expandedForegroundBinaryImage(imagePoints, 0);
	for (int i = 0; i < expandedForeground.size(); i++)for (int j = 0; j < expandedForeground[i].size(); j++) expandedForegroundBinaryImage[expandedForeground[i][j]] = 255;
	BLTiffIO::TiffOutput(fileBase + "_ROIs.tif", imageWidth, imageHeight, 8).write1dImage(expandedForegroundBinaryImage);

	//write out background regions image
	std::vector<uint8_t> expandedBackgroundBinaryImage(imagePoints, 0);
	for (int i = 0; i < expandedBackground.size(); i++)for (int j = 0; j < expandedBackground[i].size(); j++) expandedBackgroundBinaryImage[expandedBackground[i][j]] = 255;
	BLTiffIO::TiffOutput(fileBase + "_Background_Regions.tif", imageWidth, imageHeight, 8).write1dImage(expandedBackgroundBinaryImage);

	//write out foreground positions file
	std::vector<std::vector<int>> transformPos = expandedForeground;
	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(fileBase + "_ROI_Positions.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

	//write out background positions file
	transformPos = expandedBackground;
	transformPos.insert(transformPos.begin(), { imageWidth,imageHeight,imagePoints });
	BLCSVIO::writeCSV(fileBase + "_Background_Positions.csv", transformPos, "First Line is Image Size. Each Line is an ROI. Numbers Go Horizontal. To get {x;y}->{n%width;Floor(n/width)}\n");

	return 0;

}

