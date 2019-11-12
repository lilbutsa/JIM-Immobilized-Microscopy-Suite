#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"

using namespace std;

int main(int argc, char *argv[])
{
	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string output = argv[2];

	BLTiffIO::TiffInput imstackin(inputfile);

	int imageDepth = imstackin.imageDepth;
	int imageWidth = imstackin.imageWidth;
	int imageHeight = imstackin.imageHeight;
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = imstackin.numOfFrames;

	vector<vector<float>> image(imageWidth, vector<float>(imageHeight));
	vector<vector<float>> imageout(imageWidth, vector<float>(imageHeight));

	BLTiffIO::TiffOutput imstackout(output, imageWidth, imageHeight, imageDepth);

	for (int imagecount = 0; imagecount < totnumofframes; imagecount++) {
		imstackin.read2dImage(imagecount,image);
		for (int i = 0; i < imageWidth; i++)for (int j = 0; j < imageHeight; j++)imageout[i][imageHeight - j - 1] = image[i][j];
		imstackout.write2dImage(imageout);
	}

	return 0;
}