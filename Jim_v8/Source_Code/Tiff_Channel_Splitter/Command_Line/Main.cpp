#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>
#include <filesystem>
#include <math.h>
#include <stdint.h>

using namespace std;

int Tiff_Channel_Splitter(string fileBase, vector<string>& inputfiles, int numOfChan, int startFrame, int endFrame, vector<vector<int>>& tranformations, bool bBigTiff, bool bmetadata,bool bDetectMultifiles);

int main(int argc, char* argv[])
{
	std::cout << "TIFF CHANNEL SPLITTER\n";


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
	vector<string> inputfiles;

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

		
		if (!bDetectMultifiles) for (int i = 0; i < numInputFiles; i++)inputfiles.push_back(argv[i + 2]);

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

	return Tiff_Channel_Splitter(fileBase, inputfiles, numOfChan, startFrame, endFrame, tranformations, bBigTiff, bmetadata, bDetectMultifiles);


}











