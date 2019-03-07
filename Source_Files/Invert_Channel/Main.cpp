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

	BLTiffIO::MultiPageTiffInput imclass(inputfile);
	
	int imageDepth = imclass.imageBitDepth();
	int imageWidth = imclass.imageWidth();
	int imageHeight = imclass.imageHeight();
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = imclass.totalNumberofFrames();

	vector<vector<float>> image(imageWidth, vector<float>(imageHeight));
	vector<vector<float>> imageout(imageWidth, vector<float>(imageHeight));

	BLTiffIO::MultiPageTiffOutput imoutclass(output, totnumofframes, imageDepth, imageWidth, imageHeight);

	for (int imagecount = 0; imagecount < totnumofframes; imagecount++) {
		imclass.GetImage2d(imagecount, image);
		for (int i = 0; i < imageWidth; i++)for (int j = 0; j < imageHeight; j++)imageout[i][imageHeight - j - 1] = image[i][j];
		imoutclass.WriteImage2d(imagecount, imageout);
	}

	return 0;
}