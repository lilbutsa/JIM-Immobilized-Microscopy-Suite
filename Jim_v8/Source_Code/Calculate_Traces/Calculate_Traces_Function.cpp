/*
 * Calculate_Traces Main.cpp
 *
 * Description:
 *   This program extracts fluorescence intensity time traces from regions of interest (ROIs)
 *   in a multi-frame TIFF image stack. For each ROI, it computes total and background-subtracted
 *   fluorescence across all frames, with optional drift correction.
 *
 *   The program reads:
 *     - A TIFF image stack.
 *     - A CSV file listing ROI pixel indices.
 *     - A CSV file listing background pixel indices for each ROI.
 *     - (Optional) A CSV file with frame-by-frame XY drift values.
 *
 *   For each ROI and frame, it computes the background-subtracted total intensity.
 *
 *   The results are output to:
 *     - A fluorescence intensity CSV (background-subtracted).
 *     - A background intensity CSV.
 *     - A verbose trace CSV (if -Verbose flag is set), containing full statistical detail.
 *
 * Usage:
 *   Calculate_Traces <TIFF_Image> <ROI_CSV> <Background_CSV> <Output_Base> [-Drift <Drift_CSV>] [-Verbose]
 *
 * Dependencies:
 *   - BLTiffIO: For reading TIFF image stacks.
 *   - BLCSVIO: For reading/writing CSV files.
 *   - BLImageTransform: For drift correction handling (if used).
 *
 * Author: James Walsh
 * Date: July 2020
 */





#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include <cmath>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include <numeric>





int Calculate_Traces(std::string fileName, size_t positionIn, size_t channelIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, std::string driftfile = "", std::string weightImageFile = "", int numOfChannels = 1, bool filesSplitByChannelIn = false)
{
	BLTiffIO::MultiTiffInput allFiles(fileName, numOfChannels, filesSplitByChannelIn);


	size_t totalPositions = allFiles.positionNames.size();

	std::string myFolderName = allFiles.path + allFiles.filesep + allFiles.positionNames[positionIn-1];
	if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
	std::string fileBase = myFolderName + allFiles.filesep;


	std::vector<std::string> headerLine;
	std::vector< std::vector<double> > tableofdrifts(3000, std::vector<double>(2, 0.0));
	bool bdrifts = false;
	if (driftfile == "") {//Try to find the default drift file
		driftfile = fileBase + "Aligned_Channel_" + std::to_string(channelIn) + ".csv";
	}
	if (std::filesystem::exists(driftfile)) {
		std::cout << "Importing Drifts from : " << driftfile << "\n";
		BLCSVIO::readCSV(driftfile, tableofdrifts, headerLine);
		bdrifts = true;
	}
	else std::cout << "WARNING : No drift file found. Assuming sample has no drift\n";


	size_t imageWidth, imageHeight, imagePoints, imageDepth, numOfChan, numOfFrame, numOfZ;
	allFiles.imageInfo(positionIn-1, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);


	std::vector< std::vector<size_t> > labelledpos(3000, std::vector<size_t>(1000, 0));
	BLCSVIO::readVariableWidthCSV(ROIfile, labelledpos,headerLine);
	labelledpos.erase(labelledpos.begin());

	std::vector< std::vector<size_t> > backgroundpos(3000, std::vector<size_t>(1000, 0));
	BLCSVIO::readVariableWidthCSV(backgroundfile, backgroundpos,headerLine);
	backgroundpos.erase(backgroundpos.begin());

	size_t numoffits = labelledpos.size();

	std::vector< std::vector<double> > results;
	
	int startFrameIn = startFrame < 0 ? numOfFrame + startFrame : startFrame - 1;
	int endFrameIn = endFrame < 0 ? numOfFrame + endFrame + 1 : endFrame;
	int NOFMeasure = endFrameIn - startFrameIn;


	std::vector< std::vector<double> > amplitudevals(numoffits, std::vector<double>(NOFMeasure));
	std::vector< std::vector<double> > backgroundvals(numoffits, std::vector<double>(NOFMeasure));
	std::vector< std::vector<double> > fitvals(numoffits, std::vector<double>(NOFMeasure));

	std::vector< std::vector<float> > image(imageWidth, std::vector<float>(imageHeight));
	std::vector< std::vector<float> > ROIdata(labelledpos.size()), backgroundData(labelledpos.size());
      

	int xdrift = 0, ydrift = 0, xin, yin;
	

	int pointcount,backcount;
	double totfluor, totalback, weightedtotfluor;

	//cout << "num of fits = " << numoffits << "\n";
	//setup image weights if image file is input
	bool bweights = false;
	std::vector< std::vector<float> > weights(labelledpos.size());
	if (std::filesystem::exists(weightImageFile)) {
		std::cout << "Importing weights from : " << weightImageFile << "\n";
		BLTiffIO::TiffInput weightImage(weightImageFile);
		std::vector<float> imagef(weightImage.imageWidth*weightImage.imageHeight, 0);
		weightImage.read1dImage(0, imagef);

		for (size_t i = 0; i < labelledpos.size(); i++) {
			weights[i] = std::vector<float>(labelledpos[i].size());

			double backgroundsum = 0;
			for (size_t j = 0; j < backgroundpos[i].size(); j++)backgroundsum += imagef[backgroundpos[i][j]];
			backgroundsum = backgroundsum / backgroundpos[i].size();

			double weightsum = 0, weightsum2;
			for (size_t j = 0; j < labelledpos[i].size(); j++) {
				weights[i][j] = imagef[labelledpos[i][j]] - backgroundsum;
				weightsum += weights[i][j];
				weightsum2 += weights[i][j]* weights[i][j];
			}
			for (size_t j = 0; j < labelledpos[i].size(); j++)weights[i][j] = weights[i][j] * weightsum / weightsum2;

		}

		bweights = true;
	}

	for (size_t imagecount = 0; imagecount < NOFMeasure; imagecount++) {
		//cout << "Fitting Frame Number " << imagecount << endl;
		allFiles.read2dImage(positionIn-1,imagecount + startFrameIn,channelIn-1,0,image);
		if (bdrifts) {
			xdrift = (int)round(tableofdrifts[imagecount+startFrameIn][0]);
			ydrift = (int)round(tableofdrifts[imagecount + startFrameIn][1]);
		}

		for (size_t fitcount = 0; fitcount < numoffits; fitcount++) {

			backcount = 0;
			totalback = 0;
			for (size_t i = 0; i < backgroundpos[fitcount].size(); i++) {
				xin = backgroundpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(backgroundpos[fitcount][i] / imageWidth) - ydrift;
				if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight) {
					totalback += image[xin][yin];
					backcount++;
				}
			}

			totalback = totalback / backcount;


			pointcount = 0;
			totfluor = 0;
			weightedtotfluor = 0;
			for (int i = 0; i < labelledpos[fitcount].size(); i++) {
				xin = labelledpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(labelledpos[fitcount][i] / imageWidth) - ydrift;
				if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight) {
					totfluor += image[xin][yin];
					if(bweights)weightedtotfluor += weights[fitcount][i] * (image[xin][yin]- totalback);
					pointcount++;
				}
			}


			amplitudevals[fitcount][imagecount] = totfluor - (totalback * pointcount);
			backgroundvals[fitcount][imagecount] = totalback;
			if (bweights)fitvals[fitcount][imagecount] = weightedtotfluor;

		}
	}
	std::cout << "Writing out traces to :" << fileBase + "\n";
	std::string output = fileBase + "Channel_" + std::to_string(channelIn);
	BLCSVIO::writeCSV(output + "_Fluorescent_Intensities.csv", amplitudevals, "Each row is a particle. Each column is a Frame\n");
	if (bweights)BLCSVIO::writeCSV(output + "_Fluorescent_Weighted_Fits.csv", fitvals, "Each row is a particle. Each column is a Frame\n");
	BLCSVIO::writeCSV(output + "_Fluorescent_Backgrounds.csv", backgroundvals, "Each row is the mean background surrounding the particle. Each column is a Frame\n");
	
	return 0;

}