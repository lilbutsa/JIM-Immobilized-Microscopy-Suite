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


int main(int argc, char *argv[])
{
	if (argc < 5) { std::cout << "could not read file name" << "\n"; return 1; }
	std::string inputfile = argv[1];
	std::string ROIfile = argv[2];
	std::string backgroundfile = argv[3];
	std::string output = argv[4];

	bool bdrifts = false;
	bool veboseoutput = false;
	std::string driftfile;
	std::vector< std::vector<double> > tableofdrifts(3000, std::vector<double>(2, 0.0));

	std::vector<std::string> headerLine;

	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Drift") {
			if (i + 1 < argc) {
				bdrifts = true;
				driftfile = argv[i + 1];
				BLCSVIO::readCSV(driftfile, tableofdrifts,headerLine);
				std::cout << "Drifts imported from " << driftfile << "\n";
			}
			else { std::cout << "error inputting drifts" << std::endl; return 1; }
		}
		if (std::string(argv[i]) == "-Verbose")veboseoutput = true;
	}


	BLTiffIO::TiffInput imclass(inputfile);

	int imageDepth = imclass.imageDepth;
	int imageWidth = imclass.imageWidth;
	int imageHeight = imclass.imageHeight;
	int imagePoints = imageWidth * imageHeight;
	int totnumofframes = imclass.numOfFrames;

	std::vector< std::vector<int> > labelledpos(3000, std::vector<int>(1000, 0));
	BLCSVIO::readVariableWidthCSV(ROIfile, labelledpos,headerLine);
	labelledpos.erase(labelledpos.begin());

	std::vector< std::vector<int> > backgroundpos(3000, std::vector<int>(1000, 0));
	BLCSVIO::readVariableWidthCSV(backgroundfile, backgroundpos,headerLine);
	backgroundpos.erase(backgroundpos.begin());

	int numoffits = labelledpos.size();

	std::vector< std::vector<double> > results;
	if(veboseoutput)results = std::vector< std::vector<double> >(totnumofframes*numoffits, std::vector<double>(20, 0));//region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean *num of points),total- (back median *num of points)

	std::vector< std::vector<double> > amplitudevals(numoffits, std::vector<double>(totnumofframes));
	std::vector< std::vector<double> > backgroundvals(numoffits, std::vector<double>(totnumofframes));
	std::vector< std::vector<double> > gausvals(numoffits, std::vector<double>(totnumofframes));

	std::vector< std::vector<float> > image(imageWidth, std::vector<float>(imageHeight));
	std::vector< std::vector<float> > ROIdata(labelledpos.size()), backgroundData(labelledpos.size());
	
	for (int i = 0; i < labelledpos.size(); i++) {
		ROIdata[i] = std::vector<float>(labelledpos[i].size());
		backgroundData[i] = std::vector<float>(backgroundpos[i].size());
	}

	int xdrift = 0, ydrift = 0, xin, yin;
	float mean, stddev, min, max;
	double median, xmid, ymid,totfluor;

	std::vector<double> gausresult, xyztoadd(3);
	std::vector< std::vector<double> > xyzvecin;

	int excludedcount = 0, pointcount,backcount;

	//cout << "num of fits = " << numoffits << "\n";

	for (int imagecount = 0; imagecount < totnumofframes; imagecount++) {
		//cout << "Fitting Frame Number " << imagecount << endl;
		imclass.read2dImage(imagecount,image);
		if (bdrifts) {
			xdrift = round(tableofdrifts[imagecount][0]);
			ydrift = round(tableofdrifts[imagecount][1]);
		}

		for (int fitcount = 0; fitcount < numoffits; fitcount++) {
			xmid = 0;
			ymid = 0;
			excludedcount = 0;
			for (int i = 0; i < labelledpos[fitcount].size(); i++) {
				xin = labelledpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(labelledpos[fitcount][i] / imageWidth) - ydrift;
				xmid += xin;
				ymid += yin;
				if (xin >= 0 && xin < imageWidth && yin >= 0 && yin < imageHeight) ROIdata[fitcount][i-excludedcount] = image[xin][yin]; 
				else excludedcount++;
			}

			xmid *= 1.0 / labelledpos[fitcount].size();
			ymid *= 1.0 / labelledpos[fitcount].size();

			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][0] = fitcount;
				results[imagecount + fitcount*totnumofframes][1] = imagecount;
				results[imagecount + fitcount*totnumofframes][2] = xmid;
				results[imagecount + fitcount*totnumofframes][3] = ymid;
			}

			pointcount = ROIdata[fitcount].size() - excludedcount;

			meanAndStdDev(ROIdata[fitcount], mean, stddev);


			totfluor = mean *pointcount;

			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][4] = totfluor;
				results[imagecount + fitcount*totnumofframes][5] = mean;
				results[imagecount + fitcount*totnumofframes][6] = stddev;

				results[imagecount + fitcount*totnumofframes][7] = CalcMedian(ROIdata[fitcount], pointcount);

				auto minMax = std::minmax_element(ROIdata[fitcount].begin(), ROIdata[fitcount].end());

				results[imagecount + fitcount*totnumofframes][8] = *minMax.first;
				results[imagecount + fitcount*totnumofframes][9] = *minMax.second;
				results[imagecount + fitcount*totnumofframes][10] = pointcount;
			}

			excludedcount = 0;
			for (int i = 0; i < backgroundpos[fitcount].size(); i++) {
				xin = backgroundpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(backgroundpos[fitcount][i] / imageWidth) - ydrift;
				if (xin >= 0 && xin < imageWidth && yin >= 0 && yin < imageHeight)backgroundData[fitcount][i- excludedcount] = image[xin][yin];
				else excludedcount++;
			}

			backcount = backgroundData[fitcount].size() - excludedcount;

			meanAndStdDev(backgroundData[fitcount], mean, stddev);


			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][11] = mean * backcount;
				results[imagecount + fitcount*totnumofframes][12] = mean;
				results[imagecount + fitcount*totnumofframes][13] = stddev;

				median = CalcMedian(backgroundData[fitcount], backcount);
				results[imagecount + fitcount*totnumofframes][14] = median;

				auto minMax = std::minmax_element(backgroundData[fitcount].begin(), backgroundData[fitcount].end());

				results[imagecount + fitcount*totnumofframes][15] = *minMax.first;
				results[imagecount + fitcount*totnumofframes][16] = *minMax.second;

				results[imagecount + fitcount*totnumofframes][17] = backcount;

				results[imagecount + fitcount*totnumofframes][18] = results[imagecount + fitcount*totnumofframes][4] - (mean *pointcount);
				results[imagecount + fitcount*totnumofframes][19] = results[imagecount + fitcount*totnumofframes][4] - (median *pointcount);
			}

			amplitudevals[fitcount][imagecount] = totfluor - (mean * pointcount);
			backgroundvals[fitcount][imagecount] = mean;

		}
	}
	std::cout << "Writing out traces to :" << output + "\n";
	if(veboseoutput)BLCSVIO::writeCSV(output + "_Verbose_Traces.csv", results, "region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean * num of points),total- (back median * num of points)\n");
	BLCSVIO::writeCSV(output + "_Fluorescent_Intensities.csv", amplitudevals, "Each row is a particle. Each column is a Frame\n");
	BLCSVIO::writeCSV(output + "_Fluorescent_Backgrounds.csv", backgroundvals, "Each row is the mean background surrounding the particle. Each column is a Frame\n");
	
}