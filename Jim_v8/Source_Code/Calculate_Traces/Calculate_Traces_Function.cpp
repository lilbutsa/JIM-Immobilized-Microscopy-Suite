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
#include "BLImageTransform.h"



double CalcMedian(std::vector<float> scores, int size)
{
	double median;

	sort(scores.begin(), scores.begin()+size);

	if (size % 2 == 0)
	{
		median = (scores[size / 2 - 1] + scores[size / 2]) / 2;
	}
	else
	{
		median = scores[size / 2];
	}

	return median;
}


int Calculate_Traces(std::string fileName, size_t positionIn, size_t channelIn, std::string ROIfile, std::string backgroundfile, int startFrame = 1, int endFrame = -1, bool veboseoutput = false, std::string driftfile = "", int numOfChannels = 1, bool filesSplitByChannelIn = false)
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
	if(veboseoutput)results = std::vector< std::vector<double> >(numOfFrame *numoffits, std::vector<double>(20, 0));//region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean *num of points),total- (back median *num of points)

	int startFrameIn = startFrame < 0 ? numOfFrame + startFrame : startFrame - 1;
	int endFrameIn = endFrame < 0 ? numOfFrame + endFrame + 1 : endFrame;
	int NOFMeasure = endFrameIn - startFrameIn;


	std::vector< std::vector<double> > amplitudevals(numoffits, std::vector<double>(NOFMeasure));
	std::vector< std::vector<double> > backgroundvals(numoffits, std::vector<double>(NOFMeasure));
	std::vector< std::vector<double> > gausvals(numoffits, std::vector<double>(NOFMeasure));

	std::vector< std::vector<float> > image(imageWidth, std::vector<float>(imageHeight));
	std::vector< std::vector<float> > ROIdata(labelledpos.size()), backgroundData(labelledpos.size());
	
	for (size_t i = 0; i < labelledpos.size(); i++) {
		ROIdata[i] = std::vector<float>(labelledpos[i].size());
		backgroundData[i] = std::vector<float>(backgroundpos[i].size());
	}

	int xdrift = 0, ydrift = 0, xin, yin;
	float mean, stddev;
	double median, xmid, ymid,totfluor;

	std::vector<double> gausresult, xyztoadd(3);
	std::vector< std::vector<double> > xyzvecin;

	int excludedcount = 0, pointcount,backcount;

	//cout << "num of fits = " << numoffits << "\n";



	for (size_t imagecount = 0; imagecount < NOFMeasure; imagecount++) {
		//cout << "Fitting Frame Number " << imagecount << endl;
		allFiles.read2dImage(positionIn-1,imagecount + startFrameIn,channelIn-1,0,image);
		if (bdrifts) {
			xdrift = (int)round(tableofdrifts[imagecount+startFrameIn][0]);
			ydrift = (int)round(tableofdrifts[imagecount + startFrameIn][1]);
		}

		for (size_t fitcount = 0; fitcount < numoffits; fitcount++) {
			xmid = 0;
			ymid = 0;
			excludedcount = 0;
			for (int i = 0; i < labelledpos[fitcount].size(); i++) {
				xin = labelledpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(labelledpos[fitcount][i] / imageWidth) - ydrift;
				xmid += xin;
				ymid += yin;
				if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight) ROIdata[fitcount][i-excludedcount] = image[xin][yin]; 
				else excludedcount++;
			}

			xmid *= 1.0 / labelledpos[fitcount].size();
			ymid *= 1.0 / labelledpos[fitcount].size();

			if (veboseoutput) {
				results[imagecount + fitcount* numOfFrame][0] = (double)fitcount;
				results[imagecount + fitcount* numOfFrame][1] = (double)imagecount;
				results[imagecount + fitcount* numOfFrame][2] = xmid;
				results[imagecount + fitcount* numOfFrame][3] = ymid;
			}

			pointcount = (int)ROIdata[fitcount].size() - excludedcount;

			meanAndStdDev(ROIdata[fitcount], mean, stddev);


			totfluor = mean *pointcount;

			if (veboseoutput) {
				results[imagecount + fitcount* numOfFrame][4] = totfluor;
				results[imagecount + fitcount* numOfFrame][5] = mean;
				results[imagecount + fitcount* numOfFrame][6] = stddev;

				results[imagecount + fitcount* numOfFrame][7] = CalcMedian(ROIdata[fitcount], pointcount);

				auto minMax = std::minmax_element(ROIdata[fitcount].begin(), ROIdata[fitcount].end());

				results[imagecount + fitcount* numOfFrame][8] = *minMax.first;
				results[imagecount + fitcount* numOfFrame][9] = *minMax.second;
				results[imagecount + fitcount* numOfFrame][10] = pointcount;
			}

			excludedcount = 0;
			for (size_t i = 0; i < backgroundpos[fitcount].size(); i++) {
				xin = backgroundpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(backgroundpos[fitcount][i] / imageWidth) - ydrift;
				if (xin >= 0 && xin < (int)imageWidth && yin >= 0 && yin < (int)imageHeight)backgroundData[fitcount][i- excludedcount] = image[xin][yin];
				else excludedcount++;
			}

			backcount = (int)backgroundData[fitcount].size() - excludedcount;

			meanAndStdDev(backgroundData[fitcount], mean, stddev);


			if (veboseoutput) {
				results[imagecount + fitcount* numOfFrame][11] = mean * backcount;
				results[imagecount + fitcount* numOfFrame][12] = mean;
				results[imagecount + fitcount* numOfFrame][13] = stddev;

				median = CalcMedian(backgroundData[fitcount], backcount);
				results[imagecount + fitcount* numOfFrame][14] = median;

				auto minMax = std::minmax_element(backgroundData[fitcount].begin(), backgroundData[fitcount].end());

				results[imagecount + fitcount* numOfFrame][15] = *minMax.first;
				results[imagecount + fitcount* numOfFrame][16] = *minMax.second;

				results[imagecount + fitcount* numOfFrame][17] = backcount;

				results[imagecount + fitcount* numOfFrame][18] = results[imagecount + fitcount* numOfFrame][4] - (mean *pointcount);
				results[imagecount + fitcount* numOfFrame][19] = results[imagecount + fitcount* numOfFrame][4] - (median *pointcount);
			}

			amplitudevals[fitcount][imagecount] = totfluor - (mean * pointcount);
			backgroundvals[fitcount][imagecount] = mean;

		}
	}
	std::cout << "Writing out traces to :" << fileBase + "\n";
	std::string output = fileBase + "Channel_" + std::to_string(channelIn);
	if(veboseoutput)BLCSVIO::writeCSV(output + "_Verbose_Traces.csv", results, "region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean * num of points),total- (back median * num of points)\n");
	BLCSVIO::writeCSV(output + "_Fluorescent_Intensities.csv", amplitudevals, "Each row is a particle. Each column is a Frame\n");
	BLCSVIO::writeCSV(output + "_Fluorescent_Backgrounds.csv", backgroundvals, "Each row is the mean background surrounding the particle. Each column is a Frame\n");
	
	return 0;

}