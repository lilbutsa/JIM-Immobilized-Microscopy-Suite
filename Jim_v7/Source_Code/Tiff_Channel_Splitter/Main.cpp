#include <string>
#include <iostream>
#include <vector>
#include "BLTiffIO.h"
#include <algorithm>

using namespace std;

void getStackOrder(vector<BLTiffIO::TiffInput*>& vis, vector<vector<vector<int>>>& stackorderout);
void vertFlipImage(std::vector< std::vector<float>>& imageio);
void horzFlipImage(std::vector< std::vector<float>>& imageio);
void rotateImage(std::vector< std::vector<float>>& imageio, int angle);

int main(int argc, char* argv[])
{

	if (argc == 1 || (std::string(argv[1]).substr(0, 2) == "-h" || std::string(argv[1]).substr(0, 2) == "-H")) {
		std::cout << "Standard input: [Output File Base] [Input Image Stack file 1]... Options\n";
		std::cout << "Options:\n";
		std::cout << "-NumberOfChannels i (Default i = 2) Sets the number of channels to split the file into. Only used if no OME metadata is present. \n";
		std::cout << "-BigTiff Write out images in Bigtiff Format regardless of input format. Default is to write out in the format of input\n";
		std::cout << "-DisableBigTiff Write out images as regular tiff format regardless of input. WARNING OUTPUT FILES OVER 4GB WILL CRASH.\n";
		std::cout << "-DisableMetadata Ignore OME metadata. Use if stack has been altered but meta data has not.\n";
		std::cout << "-Transform [Channels to transform] [Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)]\n";
		return 0;
	}

	string fileBase;
	vector<BLTiffIO::TiffInput*> vis;
	int numInputFiles = 0;
	int numOfChan = 2;
	bool bmetadata = true;
	bool bBigTiff = false;
	vector< vector<int>> tranformations;
	int startFrame = 1, endFrame = -1, startFramein, endFramein;

	try {
		if (argc < 3)throw std::invalid_argument("Insufficient Arguments");
		fileBase = std::string(argv[1]);

		for (int i = 2; i < argc && std::string(argv[i]).substr(0, 1) != "-"; i++) numInputFiles++;
		if (numInputFiles == 0)throw std::invalid_argument("No Input Image Stacks Detected");

		vector<string> inputfiles(numInputFiles);
		for (int i = 0; i < numInputFiles; i++)inputfiles[i] = argv[i + 2];
		vis.resize(numInputFiles);
		for (int i = 0; i < numInputFiles; i++) {
			vis[i] = new BLTiffIO::TiffInput(inputfiles[i]);
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
			if (std::string(argv[i]) == "-DisableMetadata") bmetadata = false;
			if (std::string(argv[i]) == "-Transform") {
				int channelsToTransform = 0;
				for (int j = i + 1; j < argc && std::string(argv[j]).substr(0, 1) != "-"; j++) channelsToTransform++;
				if (channelsToTransform % 4 != 0)throw std::invalid_argument("Invalid Number of transform parameters.\n Four parameters required per channel:\n[Channels to transform] [Vertical Flip each channel (0 = no, 1 = yes)] [Horizontal Flip each channel (0 = no, 1 = yes)] [Rotate each channel clockwise (0, 90, 180 or 270)]");
				tranformations = vector<vector<int>>(channelsToTransform / 4, vector<int>(4, 0));
				try {
					for (int j = 0; j < channelsToTransform; j++) {
						tranformations[j%(channelsToTransform/4)][j /((channelsToTransform / 4))] = stoi(argv[i + 1 + j]);
					}
					for (int j = 0; j < channelsToTransform / 4; j++) {
						std::cout << "Transforming Channel " << tranformations[j][0] << " ";
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

	vector<vector<float>> image;
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
		}

	}
	else {
		std::cout << "OME metadata was NOT Detected\n";
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


				vis[fileNumber]->read2dImage(imageNumber, image);

				if (vertFlip)vertFlipImage(image);
				if (horFlip)horzFlipImage(image);
				if (rotate != 0)rotateImage(image, rotate);
				
				output->write2dImage(image);
			}
		}
	}

	return 0;

}











