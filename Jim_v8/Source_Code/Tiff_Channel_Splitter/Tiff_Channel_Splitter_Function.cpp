#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>
#include <filesystem>
#include <math.h>
#include <stdint.h>



void getStackOrder(std::vector<BLTiffIO::TiffInput*>& vis, std::vector<std::vector<std::vector<int>>>& stackorderout);
void vertFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void horzFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void rotateImage(std::vector< std::vector<uint16_t>>& imageio, int angle);

int Tiff_Channel_Splitter(std::string fileBase, std::vector<std::string>& inputfiles, int numOfChan, int startFrame, int endFrame, std::vector<std::vector<int>>& tranformations,bool bBigTiff, bool bmetadata,bool bDetectMultifiles) {

	BLTiffIO::MultiTiffInput mymulti(inputfiles[0]);

	return 0;

	std::vector<BLTiffIO::TiffInput*> vis;
	int startFramein, endFramein;

	if (bDetectMultifiles) {
		std::string path = std::filesystem::path(inputfiles[0]).parent_path().generic_string();
		inputfiles.clear();
		for (const auto& entry : std::filesystem::directory_iterator(path)) {
			std::string myExt = entry.path().extension().generic_string();
			if (myExt.find("tif") != std::string::npos || myExt.find("Tif") != std::string::npos || myExt.find("TIF") != std::string::npos) {
				inputfiles.push_back(entry.path().generic_string());
				std::cout << entry.path().generic_string() << "\n";
			}
		}
	}



	vis.resize(inputfiles.size());

	for (int i = 0; i < vis.size(); i++) {
		vis[i] = new BLTiffIO::TiffInput(inputfiles[i], bmetadata);
		if (vis[i]->bigtiff)bBigTiff = true;
	}
	if (inputfiles.size() > 1)bBigTiff = true;

	int imageDepth = vis[0]->imageDepth;
	int imageWidth = vis[0]->imageWidth;
	int imageHeight = vis[0]->imageHeight;

	if (bBigTiff) std::cout << "Outputting Big Tiff\n";

	std::vector<std::vector<uint16_t>> image;
	bool horFlip = false, vertFlip = false;
	int rotate = 0;

	if (bmetadata && vis[0]->OMEmetadataDetected) {
		std::cout << "OME metadata Detected\n";
		std::vector < std::vector<std::vector<int>>> stackorderout;
		getStackOrder(vis, stackorderout);



		for (int i = 0; i < stackorderout.size(); i++) {
			horFlip = false; vertFlip = false; int rotate = 0;
			for (int j = 0; j < tranformations.size(); j++)if (tranformations[j][0] - 1 == i) {
				vertFlip = tranformations[j][1] == 1;
				horFlip = tranformations[j][2] == 1;
				rotate = tranformations[j][3];
			}

			std::string outputfilename = fileBase + "_Channel_" + std::to_string(i + 1) + ".tif";
			std::cout << "Writing out " << outputfilename << "\n";

			BLTiffIO::TiffOutput* output;
			if (rotate == 90 || rotate == 270)output = new BLTiffIO::TiffOutput(outputfilename, imageHeight, imageWidth, imageDepth, bBigTiff);
			else output = new BLTiffIO::TiffOutput(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);

			if (startFrame < 1)startFramein = stackorderout[i].size() + startFrame;
			else startFramein = startFrame - 1;

			if (endFrame < 1)endFramein = stackorderout[i].size() + endFrame + 1;
			else endFramein = endFrame;
			endFramein = std::min(endFramein, (int)stackorderout[i].size());

			for (int j = startFramein; j < endFramein; j++) {
				if (stackorderout[i][j][0] == -1) {
					std::cout << "Warning image " << j + 1 << " of channel " << i + 1 << " not found\n"; continue;
				}
				vis[stackorderout[i][j][0]]->read2dImage(stackorderout[i][j][1], image);
				if (vertFlip)vertFlipImage(image);
				if (horFlip)horzFlipImage(image);
				if (rotate != 0)rotateImage(image, rotate);

				output->write2dImage(image);
			}
			delete output;
		}

	}
	else {

		if (bmetadata == true) std::cout << "OME metadata was NOT Detected\n";
		int totnumofframes = 0;
		for (int i = 0; i < vis.size(); i++) {
			totnumofframes += vis[i]->numOfFrames;
			if (vis[i]->imageDepth != imageDepth || vis[i]->imageHeight != imageHeight || vis[i]->imageWidth != imageWidth) {
				std::cout << "All Images Must Be the same size " << "\n";
				return 2;
			}
		}

		int framesperchannel = totnumofframes / numOfChan;
		std::cout << "Total Number of Frames : " << totnumofframes << "\n";
		std::cout << "Frames Per Channel : " << framesperchannel << "\n";


		for (int i = 0; i < numOfChan; i++) {
			horFlip = false; vertFlip = false; int rotate = 0;
			for (int j = 0; j < tranformations.size(); j++)if (tranformations[j][0] - 1 == i) {
				vertFlip = tranformations[j][1] == 1;
				horFlip = tranformations[j][2] == 1;
				rotate = tranformations[j][3];
			}
			//cout << i + 1 << " " << vertFlip << " " << horFlip << " " << rotate << "\n";


			std::string outputfilename = fileBase + "_Channel_" + std::to_string(i + 1) + ".tif";
			std::cout << "Writing out " << outputfilename << "\n";

			BLTiffIO::TiffOutput* output;
			if (rotate == 90 || rotate == 270)output = new BLTiffIO::TiffOutput(outputfilename, imageHeight, imageWidth, imageDepth, bBigTiff);
			else output = new BLTiffIO::TiffOutput(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);

			if (startFrame < 1)startFramein = framesperchannel + startFrame;
			else startFramein = startFrame - 1;

			if (endFrame < 1)endFramein = framesperchannel + endFrame + 1;
			else endFramein = endFrame;
			endFramein = std::min(endFramein, (int)framesperchannel);


			for (int j = startFramein * numOfChan + i; j < endFramein * numOfChan; j = j + numOfChan) {
				int imageNumber = j;
				int fileNumber = 0;
				while (imageNumber >= (vis[fileNumber]->numOfFrames)) {
					imageNumber = imageNumber - (vis[fileNumber]->numOfFrames);
					fileNumber++;
				}
				//std::cout << fileNumber<<" " << vis[fileNumber]->numOfFrames << "\n";

				vis[fileNumber]->read2dImage(imageNumber, image);

				if (vertFlip)vertFlipImage(image);
				if (horFlip)horzFlipImage(image);
				if (rotate != 0)rotateImage(image, rotate);

				output->write2dImage(image);

				//std::cout << imageNumber << " " << vis[fileNumber]->numOfFrames << " " << j << " " << fileNumber << "\n";
			}
			delete output;
		}
	}

	for (int i = 0; i < vis.size(); i++) {
		delete vis[i];
	}



	return 0;

}