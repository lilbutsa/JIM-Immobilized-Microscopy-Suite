/*
 * Main.cpp - Tiff_Channel_Splitter
 *
 * Description:
 *   This utility separates multi-channel TIFF image stacks into individual per-channel TIFF files.
 *   Supports both OME-TIFF files with embedded metadata and standard TIFFs without metadata.
 *   Optionally applies channel-specific image transformations including vertical/horizontal flipping
 *   and 90/180/270-degree clockwise rotation.
 *
 *
 * Key Features:
 *   - Auto-detection of channels using OME metadata (if available).
 *   - Manual channel count specification for non-OME files.
 *   - Channel-specific spatial transformations.
 *   - Optional BigTIFF output for large datasets.
 *   - Frame range selection (e.g., -StartFrame / -EndFrame).
 *   - Multi-file input support and batch TIFF directory processing.
 *
 * Input Arguments:
 *   argv[1]            : Output filename base.
 *   argv[2]...[n]      : Input TIFF file(s).
 *
 * Optional Flags:
 *   -NumberOfChannels i    : Manually sets the number of channels to extract (default = 2).
 *   -StartFrame i          : Frame to start exporting from (1-based; negative for relative indexing).
 *   -EndFrame i            : Frame to stop exporting at (inclusive).
 *   -DisableMetadata       : Ignore OME metadata (assumes interleaved channel ordering).
 *   -BigTiff               : Force output in BigTIFF format (supports >4 GB files).
 *   -DisableBigTiff        : Force output in classic TIFF format.
 *   -Transform [...]       : Per-channel transforms. For each channel:
 *                            [Channel] [VertFlip] [HorzFlip] [RotateCW],
 *                            e.g., "-Transform 1 1 0 90 2 0 1 0".
 *   -DetectMultipleFiles   : Automatically detect and include all TIFFs in the input directory.
 *
 * Output:
 *   - One TIFF file per channel: <OutputBase>_Channel_<n>.tif
 *
 * Assumptions:
 *   - TIFF input images are grayscale.
 *   - Channels are interleaved frame-wise if no metadata is available.
 *
 * Dependencies:
 *   - BLTiffIO: Handles TIFF file reading/writing and metadata parsing.
 *   - C++17 or later (uses std::filesystem).
 *
 * Usage Example:
 *   ./Tiff_Channel_Splitter output image_stack.tif -NumberOfChannels 3 -Transform 1 1 0 90 2 0 1 0
 *
 * @author James Walsh james.walsh@phys.unsw.edu.au
 * @date 2020
 */

#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>
#include <filesystem>
#include <math.h>
#include <stdint.h>

using namespace std;

void getStackOrder(vector<BLTiffIO::TiffInput*>& vis, vector<vector<vector<int>>>& stackorderout);
void vertFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void horzFlipImage(std::vector< std::vector<uint16_t>>& imageio);
void rotateImage(std::vector< std::vector<uint16_t>>& imageio, int angle);

int main(int argc, char* argv[])
{
	std::cout << "TIFF CHANNEL SPLITTER\n";
	//for (int i = 1; i < argc; i++)std::cout << argv[i] << "\n";


	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: [Output File Base] [Input Image Stack file 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-NumberOfChannels i (Default i = 2) Sets the number of channels to split the file into. Only used if no OME metadata is present. \n";
		std::cout << "-BigTiff Write out images in Bigtiff Format regardless of input format. Default is to write out in the format of input\n";
		std::cout << "-DisableBigTiff Write out images as regular tiff format regardless of input. WARNING OUTPUT FILES OVER 4GB WILL CRASH.\n";
		std::cout << "-DisableMetadata Ignore OME metadata. Use if stack has been altered but meta data has not.\n";
		std::cout << "-Transform [Channels to transform] [Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)]\n";
		std::cout << "-DetectMultipleFiles Automatically detect all Tiff files in the same folder as the main file.\n";
		return 0;
	}

	string fileBase;
	vector<BLTiffIO::TiffInput*> vis;
	int numInputFiles = 0;
	int numOfChan = 2;
	bool bmetadata = true;
	bool bBigTiff = false;
	bool bDetectMultifiles = false;
	vector< vector<int>> tranformations;
	int startFrame = 1, endFrame = -1, startFramein, endFramein;


	try {
		if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
		fileBase = std::string(argv[1]);

		for (int i = 2; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if (numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

		
		for (int i = 1; i < argc; i++)if (std::string(argv[i]) == "-DisableMetadata") {
			std::cout << "Metadata Disabled\n";
			bmetadata = false;
		}

		for (int i = 1; i < argc; i++)if (std::string(argv[i]) == "-DetectMultipleFiles") {
			std::cout << "Detecting Multiple Files :\n";
			bDetectMultifiles = true;
		}

		vector<string> inputfiles;
		if (bDetectMultifiles) {
			std::string path = std::filesystem::path(argv[2]).parent_path().generic_string();
			for (const auto& entry : std::filesystem::directory_iterator(path)) {
				std::string myExt = entry.path().extension().generic_string();
				if (myExt.find("tif") != std::string::npos || myExt.find("Tif") != std::string::npos || myExt.find("TIF") != std::string::npos) {
					inputfiles.push_back(entry.path().generic_string());
					std::cout << entry.path().generic_string() << "\n";
				}
			}
			numInputFiles = inputfiles.size();
		} else for (int i = 0; i < numInputFiles; i++)inputfiles.push_back(argv[i + 2]);

		vis.resize(numInputFiles);
		
		for (int i = 0; i < numInputFiles; i++) {
			vis[i] = new BLTiffIO::TiffInput(inputfiles[i], bmetadata);
			if (vis[i]->bigtiff)bBigTiff = true;
		}
		if (numInputFiles > 1)bBigTiff = true;


		for (int i = 1; i < argc; i++) {
			if (std::string(argv[i]) == "-NumberOfChannels") {
				if (i + 1 >= argc)throw std::invalid_argument("No Number of Channels Value");
				try { numOfChan = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid Number of channels\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "Number of channels set to " << numOfChan << " \n";
			}
			if (std::string(argv[i]) == "-StartFrame") {
				if (i + 1 >= argc)throw std::invalid_argument("No Number for Start Frame");
				try { startFrame = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid start frame\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "Start Frame set to " << startFrame << " \n";
			}
			if (std::string(argv[i]) == "-EndFrame") {
				if (i + 1 >= argc)throw std::invalid_argument("No Number for End Frame");
				try { endFrame = stoi(argv[i + 1]); }
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid end frame\nInput :" + std::string(argv[i + 1]) + "\n"); }
				std::cout << "End Frame set to " << endFrame << " \n";
			}
			if (std::string(argv[i]) == "-BigTiff") bBigTiff = true;
			if (std::string(argv[i]) == "-DisableBigTiff") bBigTiff = false;
			if (std::string(argv[i]) == "-Transform") {
				std::vector<int> transformArguments;
				std::string delimiter = " ";
				for (int j = i + 1; j < argc && std::string(argv[j]).substr(0, 1) != "-"; j++) {
					size_t pos = 0;
					std::string inputStr = argv[j];

					while ((pos = inputStr.find(delimiter)) != std::string::npos) {
						transformArguments.push_back(stoi(inputStr.substr(0, pos)));
						inputStr.erase(0, pos + delimiter.length());
					}
					transformArguments.push_back(stoi(inputStr));
				}

				int channelsToTransform = transformArguments.size();
				if (channelsToTransform % 4 != 0)throw std::invalid_argument("Invalid Number of transform parameters.\n Four parameters required per channel:\n[Channels to transform] [Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)]");
				tranformations = vector<vector<int>>(channelsToTransform / 4, vector<int>(4, 0));
				try {

					for (int j = 0; j < channelsToTransform; j++) {
						tranformations[j%(channelsToTransform/4)][j /((channelsToTransform / 4))] = transformArguments[j];
					}
					for (int j = 0; j < channelsToTransform / 4; j++) {
						std::cout << "Transforming Channel " << tranformations[j][0];
						if (tranformations[j][1] == 1)std::cout << " Flipping Vertically ";
						if (tranformations[j][2] == 1)std::cout << " Flipping Vertically ";
						if (tranformations[j][3] > 1)std::cout << " Rotating "<< tranformations[j][3]<<" Degrees";
						std::cout << "\n";
					}
				}
				catch (const std::invalid_argument & e) { throw std::invalid_argument("Invalid transform input\nInput :" + std::string(argv[i + 1]) + "\n"); }
			}

		}
	}
	catch (const std::invalid_argument & e) {
		std::cout << "Error Inputting Parameters\n";
		std::cout << e.what() << "\n";
		std::cout << "See -Help for help\n";
		return 1;
	}


	int imageDepth = vis[0]->imageDepth;
	int imageWidth = vis[0]->imageWidth;
	int imageHeight = vis[0]->imageHeight;

	if (bBigTiff) std::cout << "Outputting Big Tiff" << endl;

	vector<vector<uint16_t>> image;
	bool horFlip = false, vertFlip = false;
	int rotate = 0;

	if (bmetadata && vis[0]->OMEmetadataDetected) {
		std::cout << "OME metadata Detected\n";
		vector < vector<vector<int>>> stackorderout;
		getStackOrder(vis, stackorderout);



		for (int i = 0; i < stackorderout.size(); i++) {
			horFlip = false; vertFlip = false; int rotate = 0;
			for (int j = 0; j < tranformations.size(); j++)if (tranformations[j][0] - 1 == i) {
				vertFlip = tranformations[j][1] == 1;
				horFlip = tranformations[j][2] == 1;
				rotate = tranformations[j][3];
			}

			string outputfilename = fileBase + "_Channel_" + to_string(i + 1) + ".tif";
			std::cout << "Writing out " << outputfilename << endl;

			BLTiffIO::TiffOutput* output;
			if(rotate==90 ||rotate == 270)output = new BLTiffIO::TiffOutput(outputfilename, imageHeight, imageWidth, imageDepth, bBigTiff);
			else output = new BLTiffIO::TiffOutput(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);

			if (startFrame < 1)startFramein = stackorderout[i].size() + startFrame;
			else startFramein = startFrame - 1;

			if (endFrame < 1)endFramein = stackorderout[i].size() + endFrame + 1;
			else endFramein = endFrame;
			endFramein = std::min(endFramein, (int)stackorderout[i].size());

			//for (int j = 0; j < stackorderout[i].size(); j++) {
			for (int j = startFramein; j < endFramein; j++) {
				if (stackorderout[i][j][0] == -1) {
					std::cout << "Warning image " << j + 1 << " of channel " << i+1 << " not found\n"; continue;
				}
				vis[stackorderout[i][j][0]]->read2dImage(stackorderout[i][j][1], image);
				if(vertFlip)vertFlipImage(image);
				if (horFlip)horzFlipImage(image);
				if (rotate != 0)rotateImage(image, rotate);

				output->write2dImage(image);
			}
			delete output;
		}

	}
	else {

		if(bmetadata==true) std::cout << "OME metadata was NOT Detected\n";
		int totnumofframes = 0;
		for (int i = 0; i < numInputFiles; i++) {
			totnumofframes += vis[i]->numOfFrames;
			if (vis[i]->imageDepth != imageDepth || vis[i]->imageHeight != imageHeight || vis[i]->imageWidth != imageWidth) {
				std::cout << "All Images Must Be the same size " << endl;
				return 2;
			}
		}

		int framesperchannel = totnumofframes / numOfChan;
		std::cout << "Total Number of Frames : " << totnumofframes << endl;
		std::cout << "Frames Per Channel : " << framesperchannel << endl;


		for (int i = 0; i < numOfChan; i++) {
			horFlip = false; vertFlip = false; int rotate = 0;
			for (int j = 0; j < tranformations.size(); j++)if (tranformations[j][0] - 1 == i) {
				vertFlip = tranformations[j][1] == 1;
				horFlip = tranformations[j][2] == 1;
				rotate = tranformations[j][3];
			}
			//cout << i + 1 << " " << vertFlip << " " << horFlip << " " << rotate << "\n";


			string outputfilename = fileBase+ "_Channel_" + to_string(i + 1) + ".tif";
			std::cout << "Writing out " << outputfilename << endl;

			BLTiffIO::TiffOutput* output;
			if (rotate == 90 || rotate == 270)output = new BLTiffIO::TiffOutput(outputfilename, imageHeight, imageWidth, imageDepth, bBigTiff);
			else output = new BLTiffIO::TiffOutput(outputfilename, imageWidth, imageHeight, imageDepth, bBigTiff);

			if (startFrame < 1)startFramein = framesperchannel + startFrame;
			else startFramein = startFrame - 1;

			if (endFrame < 1)endFramein = framesperchannel + endFrame + 1;
			else endFramein = endFrame;
			endFramein = std::min(endFramein, (int)framesperchannel);


			for (int j = startFramein*numOfChan+i; j < endFramein*numOfChan; j = j + numOfChan) {
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

	for (int i = 0; i < numInputFiles; i++) {
		delete vis[i];
	}



	return 0;

}











