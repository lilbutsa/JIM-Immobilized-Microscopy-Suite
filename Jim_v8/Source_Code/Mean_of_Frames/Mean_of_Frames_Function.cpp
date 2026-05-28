#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLImageTransform.h"
#include "BLCSVIO.h"

int Mean_of_Frames(std::string fileName,size_t positionIn, std::vector<int> start, std::vector<int> end, std::vector<int> bvMaxProject ,std::vector<float> weights, bool bNormalize,std::string driftfile = "", std::string alignfile="", std::string outputFileName = "") {

	BLTiffIO::MultiTiffInput allFiles(fileName);

	if (allFiles.allFilesFound == false) {
		std::cout << "Aborting as a file was not found\n";
		return 1;
	}

	/*
	std::cout << "filename = " << fileName << "\n";
	std::cout << "positionIn = " << positionIn << "\n";
	std::cout << "start = ";
	for (auto val : start)std::cout << val << " ";
	std::cout << "\n";
	std::cout << "end = ";
	for (auto val : end)std::cout << val << " ";
	std::cout << "\n";
	std::cout << "bvMaxProject = ";
	for (auto val : bvMaxProject)std::cout << val << " ";
	std::cout << "\n";
	std::cout << "weights = ";
	for (auto val : weights)std::cout << val << " ";
	std::cout << "\n";
	std::cout << "bNormalize = " << bNormalize << "\n";
	std::cout << "driftfile = " << driftfile << "\n";
	std::cout << "alignfile = " << alignfile << "\n";
	std::cout << "fileBase = " << fileBase << "\n";
	*/

	size_t totalPositions = allFiles.positionNames.size();
	size_t imageWidth, imageHeight, imagePoints, imageDepth, numOfChan, numOfFrame, numOfZ;
	allFiles.imageInfo(0, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);

	//Check inputs

	if (positionIn > totalPositions) {
		std::cout << "ERROR : Input position (" << positionIn << ") is greater than the detected number of positions in the data (" << totalPositions << ")\n";
		return 1;
	}

	if (start.size() == 0) {
		std::cout << "Using default start value of 1 for all channels\n";
		start = std::vector<int>(numOfChan,1);
	} else 	if (start.size() < numOfChan) {
		std::cout << "ERROR : Insuffiecient start values. Requires one for each channel\n";
		return 1;
	}
	else if (start.size() > numOfChan) {
		std::cout << "Warning : more start values than channels. Ignoring extra values.\n";
		start.resize(numOfChan);
	}


	if (end.size() ==0) {
		std::cout << "Using default end value of -1 for all channels\n";
		end = std::vector<int>(numOfChan, -1);
	} else 	if (end.size() < numOfChan) {
		std::cout << "ERROR : Insuffiecient end values. Requires one for each channel\n";
		return 1;
	}
	else if (end.size() > numOfChan) {
		std::cout << "Warning : more end values than channels. Ignoring extra values.\n";
		end.resize(numOfChan);
	}

	if (weights.size() ==0) {
		std::cout << "Using default weights value of 1 for all channels\n";
		weights = std::vector<float>(numOfChan, 1);
	} else 	if (weights.size() < numOfChan) {
		std::cout << "ERROR : Insuffiecient weights values. Requires one for each channel\n";
		return 1;
	} else if (weights.size() > numOfChan) {
		std::cout << "Warning : more weights values than channels. Ignoring extra values.\n";
		weights.resize(numOfChan);
	}

	if (bvMaxProject.size() ==0 ) {
		std::cout << "Warning : No preference input so using mean for all channels\n";
		bvMaxProject = std::vector<int>(numOfChan, false);
	} else if (bvMaxProject.size() < numOfChan) {
		std::cout << "ERROR : Insuffiecient Max/Mean project values. Requires one for each channel\n";
		return 1;
	} else if (bvMaxProject.size() > numOfChan) {
		std::cout << "Warning : more max/mean project preferences than channels. Ignoring extra values.\n";
		bvMaxProject.resize(numOfChan);
	}
	

	for (size_t posCount = (positionIn == 0 ? 0 : positionIn - 1); posCount < (positionIn == 0 ? totalPositions : positionIn); posCount++) {

		std::cout << "Analysing Position " << posCount + 1 << " : " << allFiles.positionNames[posCount] << "\n";

		allFiles.imageInfo(posCount, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);
		imagePoints = imageWidth * imageHeight;


		std::vector<size_t>startIn (numOfChan,0);
		std::vector<size_t>endIn(numOfChan, 0);


		for (size_t chanCount = 0; chanCount < numOfChan; chanCount++) {
			startIn[chanCount] = start[chanCount] < 0 ? numOfFrame + start[chanCount] : std::max(start[chanCount] - 1,0);
			endIn[chanCount] = end[chanCount] < 0 ? numOfFrame + end[chanCount] + 1 : end[chanCount];
			endIn[chanCount] = std::min(endIn[chanCount], numOfFrame);
		}

		//write out limits
		for (int chanCount = 0; chanCount < numOfChan; chanCount++) {
			std::cout << "Channel " << chanCount + 1;
			if (startIn[chanCount] < endIn[chanCount])std::cout << " combining from frame " << startIn[chanCount] + 1 << " to frame " << endIn[chanCount]<<"\n";
			else std::cout << " is not used.\n";
		}

		//read in files
		std::string myFolderName = allFiles.path.back() == '/' || allFiles.path.back() == '\\'? allFiles.path  + allFiles.positionNames[posCount] :allFiles.path + allFiles.filesep + allFiles.positionNames[posCount];
		if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
		std::string fileBase = myFolderName + allFiles.filesep;

		//drift file
		std::vector< std::vector<double> > drifts(numOfFrame, std::vector<double>(2, 0.0));
		std::vector<std::string> headerLine;
		if (driftfile == "") {//Try to find the default drift file
			driftfile = fileBase + "Aligned_Drifts.csv";
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


		std::vector<double> alignedimage(imagePoints, 0.0);
		std::vector< std::vector<double> > meanimage(numOfChan, std::vector<double>(imagePoints, 0.0));
		imageTransform_32f transformclass(imageWidth, imageHeight);
		std::vector<double> rotimage(imagePoints), scaleimage(imagePoints);
		std::vector<double> translated(imagePoints);

		std::vector<double>Combinedmeanimage(imagePoints, 0.0);

		double transxoffset, transyoffset;
		int count;
		double divisor;
		std::vector<double> image1(imagePoints);
		for (size_t channelcount = 0; channelcount < numOfChan; channelcount++) {
			count = 0;
			for (int imcount = startIn[channelcount]; imcount < endIn[channelcount]; imcount++) {


				transxoffset = channelcount == 0 ? -drifts[imcount][0] : (-drifts[imcount][0]) * channelalignment[channelcount - 1][5] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][6];
				transyoffset = channelcount == 0 ? -drifts[imcount][1] : (-drifts[imcount][0]) * channelalignment[channelcount - 1][7] + (-drifts[imcount][1]) * channelalignment[channelcount - 1][8];
				allFiles.read1dImage(posCount, imcount, channelcount, 0, image1);
				
				transformclass.translate(image1, alignedimage, transxoffset, transyoffset);
				if (bvMaxProject[channelcount]) std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), [](double a, double b) { return std::max(a, b); });
				else std::transform(alignedimage.begin(), alignedimage.end(), meanimage[channelcount].begin(), meanimage[channelcount].begin(), std::plus<double>());
				
				count++;
				
			}

			divisor = weights[channelcount];
			std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [divisor](auto x) { return x * divisor; });


			if (count > 0 && bvMaxProject[channelcount] == false && bNormalize) std::transform(meanimage[channelcount].begin(), meanimage[channelcount].end(), meanimage[channelcount].begin(), [count](auto x) { return x / count; });

			if (channelcount > 0) {
				transformclass.transform(meanimage[channelcount], translated, -channelalignment[channelcount - 1][3], -channelalignment[channelcount - 1][4], channelalignment[channelcount - 1][1], channelalignment[channelcount - 1][2]);
				std::transform(translated.begin(), translated.end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<double>());
			}
			else std::transform(meanimage[0].begin(), meanimage[0].end(), Combinedmeanimage.begin(), Combinedmeanimage.begin(), std::plus<double>());
		}

		//if (bNormalize) std::transform(Combinedmeanimage.begin(), Combinedmeanimage.end(), Combinedmeanimage.begin(), [numOfChan](auto x) { return x / numOfChan; });

		if (outputFileName == "")outputFileName = "Image_For_Detection_Partial_Mean";

		std::string adjustedOutputFilename = fileBase + outputFileName+".tiff";
		std::cout << "Saving generated file to : " << adjustedOutputFilename << "\n";


		if (bNormalize)BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, imageDepth).write1dImage(Combinedmeanimage);
		else BLTiffIO::TiffOutput(adjustedOutputFilename, imageWidth, imageHeight, 32).write1dImage(Combinedmeanimage);


	}


	return 0;

}