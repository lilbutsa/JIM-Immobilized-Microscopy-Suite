#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;


int main(int argc, char *argv[])
{

	if (argc < 3) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string driftfile = argv[2];
	std::string outputfile = argv[3];



	BLTiffIO::MultiPageTiffInput imclass(inputfile);

	int imageDepth = imclass.imageBitDepth();
	int imageWidth = imclass.imageWidth();
	int imageHeight = imclass.imageHeight();
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = imclass.totalNumberofFrames();

	int start = 1, end = totnumofframes;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Start") {
			if (i + 1 < argc) {
				start = stoi(argv[i + 1]);
				cout << "Calculating mean starting from " << start << endl;
			}
			else { std::cout << "error inputting start" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-End") {
			if (i + 1 < argc) {
				end = stoi(argv[i + 1]);
				cout << "Calculating mean up to frame " << end << endl;
			}
			else { std::cout << "error inputting end" << std::endl; return 1; }
		}
	}

	vector<vector<double>> drifts(3000, vector<double>(2, 0.0));
	BLCSVIO::readCSV(driftfile, drifts);

	vector<float> image1(imagePoints);
	vector<float> alignedimage(imagePoints, 0.0);
	vector<float> meanimage(imagePoints, 0.0);
	imageTransform_32f transformclass(imageWidth, imageHeight);

	IppiSize roiSize = { imageWidth,imageHeight };
	int srcStep = imageWidth * sizeof(float);

	for (int imcount = start - 1; imcount < end; imcount++) {
		imclass.GetImage1d(imcount, image1);
		transformclass.imageTranslate(image1, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);
		ippiAdd_32f_C1IR(alignedimage.data(), srcStep, meanimage.data(), srcStep, roiSize);
	}
	float invnum = 1.0 / (end - start + 1);

	ippiMulC_32f_C1IR(invnum, meanimage.data(), srcStep, roiSize);
	string adjustedOutputFilename = outputfile + "_Partial_Mean.tiff";
	BLTiffIO::WriteSinglePage1D(meanimage, adjustedOutputFilename, imageWidth, imageDepth);

}