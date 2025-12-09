#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"

int Mean_of_Frames(std::string outputfile, std::vector<std::string> inputfiles, std::string driftfile, std::string alignfile, std::vector<int> start, std::vector<int> end, bool bPercent, std::vector<int> bvMaxProject ,std::vector<float> weights, bool bNormalize) {

	std::vector<BLTiffIO::TiffInput*> vcinput(inputfiles.size());
	for (int i = 0; i < inputfiles.size(); i++)vcinput[i] = new BLTiffIO::TiffInput(inputfiles[i]);

	uint64_t imageDepth = vcinput[0]->imageDepth;
	uint64_t imageWidth = vcinput[0]->imageWidth;
	uint64_t imageHeight = vcinput[0]->imageHeight;
	uint64_t imagePoints = imageWidth * imageHeight;
	uint64_t totnumofframes = vcinput[0]->numOfFrames;



	//fix ends and percents

	for (uint64_t j = 0; j < inputfiles.size(); j++) {
		if (bPercent) {
			start[j] = (int) round((1 + (totnumofframes - 1) * start[j] / 100.0));
			end[j] = (int) round((1+(totnumofframes-1) * end[j]/100.0));
		}
		
		if (!bPercent && end[j] < 0)end[j] = totnumofframes + end[j] + 1;
		if (!bPercent && start[j] < -1)start[j] = totnumofframes + start[j] + 1;
		end[j] = std::min(end[j], (int)totnumofframes);
		start[j] = std::max(start[j], 0);
		std::cout << "Calculating mean of channel " << j + 1 <<" from frame "<< start[j] << " ending at frame " << end[j] << "\n";
	}

	//read in drifts
	std::vector< std::vector<double> > drifts(3000, std::vector<double>(2, 0.0));
	std::vector<std::string> headerLine;
	BLCSVIO::readCSV(driftfile, drifts, headerLine);
	//read in channel alignment
	std::vector< std::vector<double> > channelalignment(11, std::vector<double>(2, 0.0));
	if (inputfiles.size() > 1)BLCSVIO::readCSV(alignfile, channelalignment, headerLine);


	std::vector<float> alignedimage(imagePoints, 0.0);
	std::vector< std::vector<float> > meanimage(inputfiles.size(), std::vector<float>(imagePoints, 0.0));
	imageTransform_32f transformclass(imageWidth, imageHeight);
	std::vector<float> rotimage(imagePoints), scaleimage(imagePoints);
	std::vector<float> translated(imagePoints);

	std::vector<float>Combinedmeanimage(imagePoints, 0.0);

	float transxoffset, transyoffset;
	int count;
	float divisor;
	std::vector<float> image1(imagePoints);
	for (int channelcount = 0; channelcount < inputfiles.size(); channelcount++) {
		count = 0;
		if (channelcount == 0) {
			for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
				vcinput[channelcount]->read1dImage(imcount, image1);
				transformclass.translate(image1, alignedimage, -drifts[imcount][0], -drifts[imcount][1]);
				if (bvMaxProject[channelcount]) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), [](float a, float b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<float>());
				count++;
			}

		}
		else {
			for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
				transxoffset = (-drifts[imcount][0]) * channelalignment[channelcount - 1][5] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][6];
				transyoffset = (-drifts[imcount][0]) * channelalignment[channelcount - 1][7] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][8];
				vcinput[channelcount]->read1dImage(imcount, image1);
				transformclass.translate(image1, alignedimage, transxoffset, transyoffset);
				if (bvMaxProject[channelcount]) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), [](float a, float b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<float>());
				count++;
			}
		}
		divisor = weights[channelcount];
		std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [divisor](auto x) { return x * divisor; });


		if (count > 0 && bvMaxProject[channelcount] == false && bNormalize) std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [count](auto x) { return x / count; });

		if (channelcount > 0) {
			transformclass.transform(meanimage[channelcount], translated, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4], channelalignment[channelcount - 1][1], channelalignment[channelcount - 1][2]);
			std::transform(translated.begin(), translated.end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<float>());
		}
		else std::transform(meanimage[0].begin(), meanimage[0].end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<float>());
	}
	int numInputFiles = inputfiles.size();

	if (bNormalize) std::transform(Combinedmeanimage.begin(), Combinedmeanimage.end(), Combinedmeanimage.begin(), [numInputFiles](auto x) { return x / numInputFiles; });


	std::string adjustedOutputFilename = outputfile + "_Partial_Mean.tiff";

	if (bNormalize)BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, imageDepth).write1dImage(Combinedmeanimage);
	else BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, 32).write1dImage(Combinedmeanimage);


	for (int i = 0; i < inputfiles.size(); i++)delete vcinput[i];

	return 0;

}