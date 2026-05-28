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
 *
 * Usage:
 *   Calculate_Traces <TIFF_Image> <ROI_CSV> <Background_CSV> <Output_Base> [-Drift <Drift_CSV>] 
 *
 * Dependencies:
 *   - BLTiffIO: For reading TIFF image stacks.
 *   - BLCSVIO: For reading/writing CSV files.
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

void transformDrifts(std::vector<double> alignIn, std::vector< std::vector< double>>& driftsIn, std::vector< std::vector< double>>& driftsOut);
std::vector<std::vector<size_t>> transformPosition(std::vector<double> alignIn, std::vector<std::vector<size_t>> positions, size_t imageWidth, size_t imageHeight);


int Calculate_Traces(std::string fileName, size_t positionIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, std::string driftfile = "", std::string alignfile = "", std::string outputFileBase = "", int numOfChannels = 1, bool filesSplitByChannelIn = false)
{
	BLTiffIO::MultiTiffInput allFiles(fileName, numOfChannels, filesSplitByChannelIn);

	size_t totalPositions = allFiles.positionNames.size();


	if (allFiles.allFilesFound == false) {
		std::cout << "Aborting as a file was not found\n";
		return 1;
	}
	if (positionIn > totalPositions || positionIn == 0) {
		std::cout << "ERROR : Input position (" << positionIn << ") must be between 1 and the detected number of positions in the data (" << totalPositions << ")\n";
		return 1;
	}

	size_t imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ;
	allFiles.imageInfo(positionIn-1, imageWidth, imageHeight, imageDepth, numOfChan, numOfFrame, numOfZ);


	std::string myFolderName = allFiles.path + allFiles.filesep + allFiles.positionNames[positionIn-1];
	if (!std::filesystem::exists(myFolderName))std::filesystem::create_directories(myFolderName);
	std::string fileBase = myFolderName + allFiles.filesep;


	std::vector<std::string> headerLine;
	std::vector< std::vector<double> > tableofdrifts(numOfFrame, std::vector<double>(2, 0.0));
	std::vector< std::vector<double> >channelalignment(numOfChan - 1, { 0.0,0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,(double)imageWidth / 2,(double)imageHeight / 2 });


	if (driftfile == "") {//Try to find the default drift file
		driftfile = fileBase + "Aligned_Drifts.csv";
	}
	if (std::filesystem::exists(driftfile)) {
		std::cout << "Importing Drifts from : " << driftfile << "\n";
		BLCSVIO::readCSV(driftfile, tableofdrifts, headerLine);
	}
	else std::cout << "WARNING : No drift file found. Assuming sample has no drift\n";
	if (tableofdrifts.size() < numOfFrame || tableofdrifts[0].size() != 2) {
		std::cout << "ERROR : There must be an x and y drift value for every frame. The drift file contains " << tableofdrifts.size() << " values but should contain " << numOfFrame << "\n";
		return 1;
	}


	if (numOfChan > 1) {
		if (alignfile == "") {//Try to find the default drift file
			alignfile = fileBase + "Aligned_Channel_To_Channel_Alignment.csv";
		}
		if (std::filesystem::exists(alignfile)) {
			std::cout << "Importing Alignments from : " << alignfile << "\n";
			if (BLCSVIO::readCSV(alignfile, channelalignment, headerLine) != 0)return 1;
		}
		else {
			std::cout << "WARNING : No channel Alignments file found. Assuming sample is overlaid\n";
		}
		if (channelalignment.size() < numOfChan - 1 || channelalignment[0].size() != 11) {
			std::cout << "ERROR : Invalid Channel Alignment File\n";
			return 1;
		}
	}


	std::vector< std::vector<size_t> > labelledpos(3000, std::vector<size_t>(1000, 0));
	if(BLCSVIO::readVariableWidthCSV(ROIfile, labelledpos,headerLine)!=0)return 1;
	if (labelledpos.size() < 2) {
		std::cout<<"Error : Empty ROI Positions File\n"; 
		return 1;
	}
	labelledpos.erase(labelledpos.begin());

	std::vector< std::vector<size_t> > backgroundpos(3000, std::vector<size_t>(1000, 0));
	if (BLCSVIO::readVariableWidthCSV(backgroundfile, backgroundpos,headerLine) != 0)return 1;
	if (backgroundpos.size() != labelledpos.size()+1) {
		std::cout << "Error : Background File needs to have the same number of ROIs as the ROI file\n";
		return 1;
	}
	backgroundpos.erase(backgroundpos.begin());

	size_t numoffits = labelledpos.size();

	std::vector< std::vector<double> > results;
	
	size_t startFrameIn = startFrame < 0 ? numOfFrame + startFrame : startFrame - 1;
	size_t endFrameIn = endFrame < 0 ? numOfFrame + endFrame + 1 : endFrame;
	
	if (startFrameIn >= numOfFrame) {
		std::cout << "ERROR : Start frame (" << startFrameIn + 1 << ")is greater than images in stack (" << numOfFrame << ")\n";
		return 1;
	}
	if (endFrameIn > numOfFrame) {
		endFrameIn = numOfFrame;
		std::cout << "End frame set to end of stack (" << numOfFrame << ")\n";
	}
	int NOFMeasure = std::max((int)endFrameIn - (int)startFrameIn, 0);


	std::vector< std::vector<double> > amplitudevals(numoffits, std::vector<double>(NOFMeasure));
	std::vector< std::vector<double> > backgroundvals(numoffits, std::vector<double>(NOFMeasure));

	std::vector< std::vector<float> > image(imageWidth, std::vector<float>(imageHeight));
	std::vector< std::vector<float> > ROIdata(labelledpos.size()), backgroundData(labelledpos.size());

	auto transDrifts = tableofdrifts;
	auto transROIPos = labelledpos;
	auto transBackPos = backgroundpos;
      
	int pointcount,backcount, xdrift = 0, ydrift = 0, xin, yin;
	double totfluor, totalback;

	for (int chancount = 0; chancount < numOfChan; chancount++) {
		//calculate positions for channel
			//write out for other channels
		if (chancount>0) {
			transformDrifts(channelalignment[chancount - 1], tableofdrifts, transDrifts);
			transROIPos = transformPosition(channelalignment[chancount - 1], labelledpos, imageWidth, imageHeight);
			transBackPos = transformPosition(channelalignment[chancount - 1], backgroundpos, imageWidth, imageHeight);
		}

		for (size_t imagecount = 0; imagecount < NOFMeasure; imagecount++) {
			//cout << "Fitting Frame Number " << imagecount << endl;
			allFiles.read2dImage(positionIn - 1, imagecount + startFrameIn, chancount, 0, image);

			xdrift = (int)round(transDrifts[imagecount + startFrameIn][0]);
			ydrift = (int)round(transDrifts[imagecount + startFrameIn][1]);


			for (size_t fitcount = 0; fitcount < numoffits; fitcount++) {

				backcount = 0;
				totalback = 0;
				for (size_t i = 0; i < transBackPos[fitcount].size(); i++) {
					xin = transBackPos[fitcount][i] % imageWidth - xdrift;
					yin = (int)(transBackPos[fitcount][i] / imageWidth) - ydrift;
					if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight) {
						totalback += image[xin][yin];
						backcount++;
					}
				}

				if (backcount > 0) totalback = totalback / backcount;


				pointcount = 0;
				totfluor = 0;
				for (int i = 0; i < transROIPos[fitcount].size(); i++) {
					xin = transROIPos[fitcount][i] % imageWidth - xdrift;
					yin = (int)(transROIPos[fitcount][i] / imageWidth) - ydrift;
					if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight) {
						totfluor += image[xin][yin];
						pointcount++;
					}
				}

				if (pointcount > 0 && backcount > 0) {
					amplitudevals[fitcount][imagecount] = totfluor - (totalback * pointcount);
					backgroundvals[fitcount][imagecount] = totalback;
				}
				else {
					amplitudevals[fitcount][imagecount] = 0;
					backgroundvals[fitcount][imagecount] = 0;
				}


			}
		}

		std::cout << "Writing out traces to :" << fileBase + "\n";
		std::string output = fileBase + outputFileBase+ "Channel_" + std::to_string(chancount+1);
		BLCSVIO::writeCSV(output + "_Fluorescent_Intensities.csv", amplitudevals, "Each row is a particle. Each column is a Frame\n");
		BLCSVIO::writeCSV(output + "_Fluorescent_Backgrounds.csv", backgroundvals, "Each row is the mean background surrounding the particle. Each column is a Frame\n");
	}

	
	return 0;

}

void transformDrifts(std::vector<double> alignIn,std::vector< std::vector< double>>& driftsIn, std::vector< std::vector< double>>& driftsOut) {

	if (driftsOut.size() != driftsIn.size())driftsOut = driftsIn;

	for (int pos = 0; pos < driftsIn.size(); pos++) {
		driftsOut[pos][0] = driftsIn[pos][0] * alignIn[5] + driftsIn[pos][1] * alignIn[6];
		driftsOut[pos][1] = driftsIn[pos][0] * alignIn[7] + driftsIn[pos][1] * alignIn[8];
	}

}


std::vector<std::vector<size_t>> transformPosition(std::vector<double> alignIn, std::vector<std::vector<size_t>> positions, size_t imageWidth, size_t imageHeight) {

	std::vector<std::vector<size_t>> positionslistout;
	std::vector<size_t> singleLine;
	double xcentre = alignIn[9];
	double ycentre = alignIn[10];

	for (size_t pos = 0; pos < positions.size(); pos++) {
		//cout <<"transform "<< pos << " " << positions[pos][0] << " " << positions[pos].size() << "\n";
		singleLine.clear();
		for (size_t i = 0; i < positions[pos].size(); i++) {
			double xin = (size_t)positions[pos][i] % imageWidth;
			double yin = (size_t)positions[pos][i] / imageWidth;
			xin += -xcentre;
			yin += -ycentre;
			double xout = xin * alignIn[5] + yin * alignIn[6];
			double yout = xin * alignIn[7] + yin * alignIn[8];
			xout += xcentre;
			yout += ycentre;
			xout += -alignIn[3];
			yout += -alignIn[4];
			if (xout < 0)xout = 0;
			if (yout < 0)yout = 0;
			if (xout > imageWidth - 1) xout = imageWidth - 1;
			if (yout > imageHeight - 1)yout = imageHeight - 1;
			singleLine.push_back((size_t)(floor(xout) + floor(yout) * imageWidth));
			singleLine.push_back((size_t)(ceil(xout) + floor(yout) * imageWidth));
			singleLine.push_back((size_t)(floor(xout) + ceil(yout) * imageWidth));
			singleLine.push_back((size_t)(ceil(xout) + ceil(yout) * imageWidth));
		}
		sort(singleLine.begin(), singleLine.end());
		singleLine.erase(unique(singleLine.begin(), singleLine.end()), singleLine.end());
		positionslistout.push_back(singleLine);
	}

	return positionslistout;
}