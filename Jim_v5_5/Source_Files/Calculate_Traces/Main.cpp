#include <string>
#include <iostream>
#include <vector>
#include <algorithm>
#include "BLTiffIO.h"
#include "BLCSVIO.h"
#include "ipp.h"

using namespace std;


double CalcMedian(vector<float> scores)
{
	double median;
	int size = scores.size();

	sort(scores.begin(), scores.end());

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
	if (argc < 5) { std::cout << "could not read file name" << endl; return 1; }
	std::string inputfile = argv[1];
	std::string ROIfile = argv[2];
	std::string backgroundfile = argv[3];
	std::string output = argv[4];

	bool bdrifts = false;
	bool veboseoutput = false;
	string driftfile;
	vector<vector<double>> tableofdrifts(3000, vector<double>(2, 0.0));



	for (int i = 1; i < argc; i++) {
		if (std::string(argv[i]) == "-Drift") {
			if (i + 1 < argc) {
				bdrifts = true;
				driftfile = argv[i + 1];
				BLCSVIO::readCSV(driftfile, tableofdrifts);
				cout << "Drifts imported from " << driftfile << endl;
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

	std::vector<std::vector<int>> labelledpos(3000, vector<int>(1000, 0));
	BLCSVIO::readVariableWidthCSV(ROIfile, labelledpos);
	labelledpos.erase(labelledpos.begin());

	std::vector<std::vector<int>> backgroundpos(3000, vector<int>(1000, 0));
	BLCSVIO::readVariableWidthCSV(backgroundfile, backgroundpos);
	backgroundpos.erase(backgroundpos.begin());

	int numoffits = labelledpos.size();

	vector<vector<double>> results;
	if(veboseoutput)results = vector<vector<double>>(totnumofframes*numoffits, vector<double>(20, 0));//region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean *num of points),total- (back median *num of points)

	vector<vector<double>> amplitudevals(numoffits, vector<double>(totnumofframes));
	vector<vector<double>> backgroundvals(numoffits, vector<double>(totnumofframes));
	vector<vector<double>> gausvals(numoffits, vector<double>(totnumofframes));

	vector<vector<float>> image(imageWidth, vector<float>(imageHeight));
	vector<vector<float>> ROIdata(labelledpos.size()), backgroundData(labelledpos.size());
	for (int i = 0; i < labelledpos.size(); i++) {
		ROIdata[i] = vector<float>(labelledpos[i].size());
		backgroundData[i] = vector<float>(backgroundpos[i].size());
	}

	int xdrift = 0, ydrift = 0, xin, yin;
	float mean, stddev, min, max;
	double median, xmid, ymid,totfluor;

	vector<double> gausresult, xyztoadd(3);
	vector<vector<double>> xyzvecin;

	for (int imagecount = 0; imagecount < totnumofframes; imagecount++) {
		cout << "Fitting Frame Number " << imagecount << endl;
		imclass.read2dImage(imagecount,image);

		if (bdrifts) {
			xdrift = round(tableofdrifts[imagecount][0]);
			ydrift = round(tableofdrifts[imagecount][1]);
		}

		for (int fitcount = 0; fitcount < numoffits; fitcount++) {
			xmid = 0;
			ymid = 0;
			for (int i = 0; i < labelledpos[fitcount].size(); i++) {
				xin = labelledpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(labelledpos[fitcount][i] / imageWidth) - ydrift;
				xmid += xin;
				ymid += yin;
				if (xin >= 0 && xin < imageWidth && yin >= 0 && yin < imageHeight)ROIdata[fitcount][i] = image[xin][yin];
				else ROIdata[fitcount][i] = 0;
			}

			xmid *= 1.0 / labelledpos[fitcount].size();
			ymid *= 1.0 / labelledpos[fitcount].size();

			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][0] = fitcount;
				results[imagecount + fitcount*totnumofframes][1] = imagecount;
				results[imagecount + fitcount*totnumofframes][2] = xmid;
				results[imagecount + fitcount*totnumofframes][3] = ymid;
			}

			ippsMeanStdDev_32f(ROIdata[fitcount].data(), ROIdata[fitcount].size(), &mean, &stddev, ippAlgHintAccurate);

			totfluor = mean * labelledpos[fitcount].size();

			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][4] = mean * labelledpos[fitcount].size();
				results[imagecount + fitcount*totnumofframes][5] = mean;
				results[imagecount + fitcount*totnumofframes][6] = stddev;

				results[imagecount + fitcount*totnumofframes][7] = CalcMedian(ROIdata[fitcount]);

				ippsMinMax_32f(ROIdata[fitcount].data(), ROIdata[fitcount].size(), &min, &max);

				results[imagecount + fitcount*totnumofframes][8] = min;
				results[imagecount + fitcount*totnumofframes][9] = max;
				results[imagecount + fitcount*totnumofframes][10] = ROIdata[fitcount].size();
			}

			for (int i = 0; i < backgroundpos[fitcount].size(); i++) {
				xin = backgroundpos[fitcount][i] % imageWidth - xdrift;
				yin = (int)(backgroundpos[fitcount][i] / imageWidth) - ydrift;
				if (xin >= 0 && xin < imageWidth && yin >= 0 && yin < imageHeight)backgroundData[fitcount][i] = image[xin][yin];
				else backgroundData[fitcount][i] = 0;
			}

			ippsMeanStdDev_32f(backgroundData[fitcount].data(), backgroundData[fitcount].size(), &mean, &stddev, ippAlgHintAccurate);

			if (veboseoutput) {
				results[imagecount + fitcount*totnumofframes][11] = mean * backgroundData[fitcount].size();
				results[imagecount + fitcount*totnumofframes][12] = mean;
				results[imagecount + fitcount*totnumofframes][13] = stddev;

				median = CalcMedian(backgroundData[fitcount]);
				results[imagecount + fitcount*totnumofframes][14] = median;

				ippsMinMax_32f(backgroundData[fitcount].data(), backgroundData[fitcount].size(), &min, &max);

				results[imagecount + fitcount*totnumofframes][15] = min;
				results[imagecount + fitcount*totnumofframes][16] = max;

				results[imagecount + fitcount*totnumofframes][17] = backgroundData[fitcount].size();

				results[imagecount + fitcount*totnumofframes][18] = results[imagecount + fitcount*totnumofframes][4] - (mean *ROIdata[fitcount].size());
				results[imagecount + fitcount*totnumofframes][19] = results[imagecount + fitcount*totnumofframes][4] - (median *ROIdata[fitcount].size());
			}

			amplitudevals[fitcount][imagecount] = totfluor - (mean *ROIdata[fitcount].size());;
			backgroundvals[fitcount][imagecount] = mean;

		}
	}
	cout << "Writing out traces to :" << output + "\n";
	if(veboseoutput)BLCSVIO::writeCSV(output + "_Traces.csv", results, "region num, frame no, x centre, y centre,  total,  mean, std dev, median,min, max, num of points, background total, back mean, back std dev, back median,back min,back max, back num of points, total- (back mean * num of points),total- (back median * num of points)\n");
	BLCSVIO::writeCSV(output + "_Flourescent_Intensities.csv", amplitudevals, "Each row is a particle. Each column is a Frame\n");
	BLCSVIO::writeCSV(output + "_Flourescent_Backgrounds.csv", backgroundvals, "Each row is the mean background surrounding the particle. Each column is a Frame\n");
	
}