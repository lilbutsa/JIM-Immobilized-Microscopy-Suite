#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"

int Mean_of_Frames(std::string fileName,int positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject ,std::vector<float> weights, bool bNormalize,std::string driftfile = "", std::string alignfile="" ) {


	BLTiffIO::MultiTiffInput allFiles(fileName);


	size_t totalPositions = allFiles.positionNames.size();
	size_t imageWidth, imageHeight, imagePoints, imageDepth, numOfChan, numOfFrame, numOfZ;

	for (size_t posCount = (positionIn == 0 ? 0 : positionIn - 1); posCount < (positionIn == 0 ? totalPositions : positionIn); posCount++) {

		std::cout << "Analysing Position " << posCount + 1 << " : " << allFiles.positionNames[posCount] << "\n";

		allFiles.imageInfo(posCount, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);
		imagePoints = imageWidth * imageHeight;


		std::vector<size_t>startIn (numOfChan,0);
		std::vector<size_t>endIn(numOfChan, 0);

		if (start.size() < numOfChan)start.resize(numOfChan);
		if (end.size() < numOfChan)end.resize(numOfChan);
		for (size_t chanCount = 0; chanCount < numOfChan; chanCount++) {
			startIn[chanCount] = start[chanCount] < 0 ? numOfFrame - start[posCount] : std::max(start[posCount] - 1,0);
			endIn[chanCount] = end[posCount] < 0 ? numOfFrame - end[posCount] + 1 : end[posCount];
			endIn[posCount] = std::min(endIn[posCount], numOfFrame);
		}

		//read in files
		std::string myFolderName = allFiles.path + allFiles.filesep + allFiles.positionNames[posCount];
		if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
		std::string fileBase = myFolderName + allFiles.filesep;

		//drift file
		std::vector< std::vector<double> > drifts(numOfFrame, std::vector<double>(2, 0.0));
		std::vector<std::string> headerLine;
		if (driftfile == "") {//Try to find the default drift file
			driftfile = fileBase + "Aligned_Channel_1.csv";
		}
		if (std::filesystem::exists(driftfile)) {
			std::cout << "Importing Drifts from : " << driftfile << "\n";
			BLCSVIO::readCSV(driftfile, drifts, headerLine);
		} else std::cout << "WARNING : No drift file found. Assuming sample has no drift\n";

		//read in channel alignment
		std::vector< std::vector<double> > channelalignment(numOfChan-1, {2.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,(double)imageWidth /2,(double)imageHeight/2});
		if (numOfChan > 1) {
			if (alignfile == "") {//Try to find the default drift file
				alignfile = fileBase + "Aligned_Channel_To_Channel_Alignment.csv";
			}
			if (std::filesystem::exists(alignfile)) {
				std::cout << "Importing Alignment from : " << alignfile << "\n";
				BLCSVIO::readCSV(alignfile, channelalignment, headerLine);
			} else std::cout << "WARNING : No align file found. Assuming sample is already aligned\n";
		}


		std::vector<float> alignedimage(imagePoints, 0.0);
		std::vector< std::vector<float> > meanimage(numOfChan, std::vector<float>(imagePoints, 0.0));
		imageTransform_32f transformclass(imageWidth, imageHeight);
		std::vector<float> rotimage(imagePoints), scaleimage(imagePoints);
		std::vector<float> translated(imagePoints);

		std::vector<float>Combinedmeanimage(imagePoints, 0.0);

		float transxoffset, transyoffset;
		int count;
		float divisor;
		std::vector<float> image1(imagePoints);
		for (int channelcount = 0; channelcount < numOfChan; channelcount++) {
			count = 0;
			for (int imcount = start[channelcount]; imcount < end[channelcount]; imcount++) {
				transxoffset = channelcount==0? -drifts[imcount][0] :(-drifts[imcount][0]) * channelalignment[channelcount - 1][5] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][6];
				transyoffset = channelcount == 0 ? -drifts[imcount][1] : (-drifts[imcount][0]) * channelalignment[channelcount - 1][7] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][8];
				allFiles.read1dImage(posCount, imcount, channelcount, 0, image1);
				transformclass.translate(image1, alignedimage, transxoffset, transyoffset);
				if (bvMaxProject[channelcount]) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), [](float a, float b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<float>());
				count++;
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

		if (bNormalize) std::transform(Combinedmeanimage.begin(), Combinedmeanimage.end(), Combinedmeanimage.begin(), [numOfChan](auto x) { return x / numInputFiles; });


		std::string adjustedOutputFilename = fileBase + "Image_For_Detection_Partial_Mean.tiff";

		if (bNormalize)BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, imageDepth).write1dImage(Combinedmeanimage);
		else BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, 32).write1dImage(Combinedmeanimage);


	}


	return 0;

}